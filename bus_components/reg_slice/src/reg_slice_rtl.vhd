library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
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

  attribute keep          : string;

begin

  b_impl : if c_impl = impl_full generate
    signal r_data       : std_logic_vector(g_data_width - 1 downto 0);
    signal r_valid      : std_logic;
    signal m_valid_int  : std_logic;
    attribute keep of r_valid     : signal is "true";
    attribute keep of m_valid_int : signal is "true";
  begin
    m_data <= fifo(0);

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
    signal s_data_r     : std_logic_vector(g_data_width - 1 downto 0);
    signal s_valid_r    : std_logic := '0';
    signal s_ready_r    : std_logic := '0';
    signal m_ready_r2   : std_logic_vector(1 downto 0) := (others => '0');
    signal we, re       : std_logic := '0';
    signal fifo         : t_slv_array(3 downto 0)(g_data_width - 1 downto 0);
    signal fifo_count   : std_logic_vector(2 downto 0) := "011";
    signal fifo_valid   : std_logic;
    signal fifo_addr    : std_logic_vector(1 downto 0);
    signal fifo_data    : std_logic_vector(g_data_width - 1 downto 0);
  begin
    -- Read from fifo if a transfer happens
    re <= fifo_valid and m_ready;
    -- Write to fifo if receiver is not ready or if we have data in fifo and a transfer would happen
    we <= s_valid_r and s_ready_r and (not m_ready or fifo_valid);

    fifo_valid  <= fifo_count(2);
    fifo_addr   <= fifo_count(1 downto 0);
    fifo_data   <= fifo(to_integer(unsigned(fifo_addr)));

    m_valid <= fifo_valid or (s_valid_r and s_ready_r);
    m_data  <= fifo_data when fifo_valid = '1' else s_data_r;
    s_ready <= m_ready_r2(1);

    p_reg_input : process(clk)
    begin
      if rising_edge(clk) then
        s_data_r    <= s_data;
        s_valid_r   <= s_valid;
        m_ready_r2  <= m_ready_r2(0) & m_ready;
        s_ready_r   <= m_ready_r2(1);

        if we = '1' then
          fifo <= fifo(fifo'high - 1 downto 0) & s_data_r;
        end if;

        if re = '1' and we = '0' then
          fifo_count <= std_logic_vector(unsigned(fifo_count) - 1);
        elsif re = '0' and we = '1' then
          fifo_count <= std_logic_vector(unsigned(fifo_count) + 1);
        end if;

        if rst = '1' then
          s_ready_r   <= '0';
          s_valid_r   <= '0';
          m_ready_r2  <= (others => '0');
          fifo_count  <= "011";
        end if;
      end if;
    end process;

  else generate -- impl_pass

    m_valid <= s_valid;
    m_data  <= s_data;
    s_ready <= m_ready;

  end generate b_impl;


end architecture rtl;