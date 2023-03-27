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
    signal r_ready_dly  : std_logic := '0';
    signal r_dout_en    : std_logic := '0';
    signal r_din_en     : std_logic := '0';
    signal fifo         : t_slv_array(2 downto 0)(g_data_width - 1 downto 0);
    signal raddr        : unsigned(1 downto 0) := (others => '0');
    signal waddr        : unsigned(1 downto 0) := (others => '0');
    signal count        : unsigned(1 downto 0) := (others => '0');
    signal we, re       : std_logic := '0';
    signal empty        : std_logic := '1';
    attribute keep of r_dout_en : signal is "true";
    attribute keep of r_din_en  : signal is "true";
  begin
    with empty select m_data <=
      fifo(to_integer(raddr)) when '0',
      r_data  when others;
    m_valid <= not empty or (r_valid and r_dout_en);

    -- Read from fifo if a transfer happens
    re <= not empty and m_ready;
    -- Write to fifo if receiver is not ready or if we have data in fifo and a transfer would happen
    we <= r_valid and r_din_en and (not m_ready or re);

    p_reg_input : process(clk)
    begin
      if rising_edge(clk) then
        r_data  <= s_data;
        r_valid <= s_valid;
        s_ready <= r_ready;

        if re = '1' then
          case raddr is
          when "00"   => raddr <= "01";
          when "01"   => raddr <= "10";
          when others => raddr <= "00";
          end case;
        end if;

        if we = '1' then
          case waddr is
          when "00"   => waddr <= "01";
          when "01"   => waddr <= "10";
          when others => waddr <= "00";
          end case;
        end if;

        if r_din_en = '1' then
          fifo(to_integer(unsigned(waddr))) <= r_data;
        end if;

        if re = '1' and we = '0' then
          count <= count + "11";
        elsif re = '0' and we = '1' then
          count <= count + "01";
        end if;

        if re = '1' and we = '0' and count = "01" then
          empty <= '1';
        elsif re = '0' and we = '1' then
          empty <= '0';
        end if;

        r_ready     <= re or (not we and empty);
        r_ready_dly <= r_ready;
        r_dout_en   <= r_ready_dly;
        r_din_en    <= r_ready_dly;

        if rst = '1' then
          empty       <= '1';
          r_ready     <= '0';
          r_ready_dly <= '0';
          r_en        <= '0';
          raddr       <= (others => '0');
          waddr       <= (others => '0');
          count       <= (others => '0');
        end if;
      end if;
    end process;

  else generate -- impl_pass

    m_valid <= s_valid;
    m_data  <= s_data;
    s_ready <= m_ready;

  end generate b_impl;


end architecture rtl;