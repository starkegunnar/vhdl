library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity reg_slice is
  generic (
    g_data_width : natural := 8;
    g_impl       : string := "full"
  );
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst     : in  std_logic;
    -- Data and flow control
    s_data  : in  std_logic_vector(g_data_width - 1 downto 0);
    s_valid : in  std_logic;
    s_ready : out std_logic := '0';
    m_data  : out std_logic_vector(g_data_width - 1 downto 0);
    m_valid : out std_logic := '0';
    m_ready : in  std_logic
  );
end entity reg_slice;

architecture rtl of reg_slice is

  type t_impl is (impl_full, impl_half, impl_reg_input, impl_pass);

  -- Functions
  function f_impl_type return t_impl is
  begin
    if g_impl = "half" then
      return impl_half;
    elsif g_impl = "reg_input" then
      return impl_reg_input;
    elsif g_impl = "passthrough" then
      return impl_pass;
    else
      return impl_full;
    end if;
  end function f_impl_type;

  constant c_impl : t_impl := f_impl_type;
  constant c_fifo_depth   : natural := 3;
  constant c_fifo_ptr_max : natural := c_fifo_depth - 1;

  attribute keep          : string;

begin

  b_impl : if c_impl = impl_full generate
    signal r_data       : std_logic_vector(g_data_width - 1 downto 0);
    signal r_valid      : std_logic;
    signal m_valid_int  : std_logic;
    attribute keep of m_valid_int : signal is "true";
  begin
    p_full : process(clk)
    begin
      if rising_edge(clk) then

        if s_valid = '1' and r_valid = '0' and m_valid_int = '1' and m_ready = '0' then
          r_valid     <= '1';
          s_ready     <= '0';
        elsif m_ready = '1' then
          r_valid     <= '0';
          s_ready     <= '1';
        elsif r_valid = '0' and m_valid_int = '0' then
          s_ready     <= '1';
        end if;

        if s_valid = '1' and r_valid = '0' then
          r_data <= s_data;
        end if;

        if m_valid_int = '0' or m_ready = '1' then
          m_valid_int <= r_valid or s_valid;
          m_valid     <= r_valid or s_valid;
        end if;

        if m_valid_int = '0' or m_ready = '1' then
          if r_valid = '1' then
            m_data <= r_data;
          else
            m_data <= s_data;
          end if;
        end if;

        if rst = '1' then
          m_valid_int <= '0';
          s_ready     <= '0';
          m_valid     <= '0';
          r_valid     <= '0';
        end if;
      end if;
    end process;

  elsif c_impl = impl_half generate
    signal m_valid_int : std_logic;
    attribute keep of m_valid_int : signal is "true";
  begin
    p_half : process(clk)
    begin
      if rising_edge(clk) then
        if m_valid_int = '0' then
          if s_valid = '1' then
            m_valid_int <= '1';
            m_valid     <= '1';
            s_ready     <= '0';
          else
            s_ready     <= '1';
          end if;
        elsif m_ready = '1' then
          m_valid_int <= '0';
          m_valid     <= '0';
          s_ready     <= '1';
        end if;

        if m_valid_int = '0' or m_ready = '1' then
          m_data <= s_data;
        end if;

        if rst = '1' then
          m_valid_int <= '0';
          s_ready     <= '0';
          m_valid     <= '0';
        end if;
      end if;
    end process;

  elsif c_impl = impl_reg_input generate
    signal r_data       : std_logic_vector(g_data_width - 1 downto 0);
    signal r_valid      : std_logic := '0';
    signal r_ready      : std_logic := '0';
    signal r_ready_srl  : std_logic_vector(1 downto 0) := (others => '0');
    signal fifo         : t_slv_array(0 to c_fifo_ptr_max)(g_data_width - 1 downto 0);
    signal wptr         : unsigned(1 downto 0) := (others => '0');
    signal rptr         : unsigned(1 downto 0) := (others => '0');
    signal cnt          : unsigned(1 downto 0) := (others => '0');
    signal we, re       : std_logic := '0';
    signal f_valid      : std_logic := '0';
  begin

    m_data  <= fifo(to_integer(rptr(1 downto 0))) when f_valid = '1' else r_data;
    m_valid <= f_valid or (r_valid and r_ready_srl(r_ready_srl'high));

    -- Read from fifo if a transfer happens
    re <= f_valid and m_ready;
    -- Write to fifo if receiver is not ready or if we have data in fifo and a transfer would happen
    we <= r_valid and r_ready_srl(r_ready_srl'high) and (not m_ready or (f_valid and m_ready));

    p_reg_input : process(clk)
    begin
      if rising_edge(clk) then
        r_data  <= s_data;
        r_valid <= s_valid;
        s_ready <= r_ready;

        if re = '1' then
          if rptr(1) = '1' then
            -- wrap
            rptr <= (others => '0');
          else
            rptr <= rptr + 1;
          end if;
        end if;

        if we = '1' then
          fifo(to_integer(wptr)) <= r_data;
          if wptr(1) = '1' then
            -- wrap
            wptr <= (others => '0');
          else
            wptr <= wptr + 1;
          end if;
        end if;

        if re = '1' and we = '0' then
          f_valid <= std_logic(cnt(cnt'high));
          r_ready <= '1';
          cnt     <= cnt - 1;
        elsif re = '0' and we = '1' then
          f_valid <= '1';
          r_ready <= '0';
          cnt     <= cnt + 1;
        elsif re = '1' and we = '1' then
          r_ready <= '1';
        else
          if cnt = 0 then
            r_ready <= '1';
          else
            r_ready <= '0';
          end if;
        end if;

        r_ready_srl <= r_ready_srl(r_ready_srl'low) & r_ready;

        if rst = '1' then
          f_valid     <= '0';
          r_ready     <= '0';
          r_ready_srl <= (others => '0');
          wptr        <= (others => '0');
          rptr        <= (others => '0');
          cnt         <= (others => '0');
        end if;
      end if;
    end process;

  else generate -- impl_pass

    m_valid <= s_valid;
    m_data  <= s_data;
    s_ready <= m_ready;

  end generate b_impl;


end architecture rtl;