library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_uart;

entity uart_tb is
end entity uart_tb;

architecture tb of uart_tb is

  constant c_clk_period : time := 8 ns;
  constant c_rst_period : time := 4 * c_clk_period;

  type t_parity_type is (parity_none, parity_odd, parity_even);

  procedure pcdr_uart_transmit(
    baud_rate   : in  natural := 921600;
    parity      : in  t_parity_type := parity_none;
    stop2       : in  boolean := false;
    err_parity  : in  boolean := false;
    err_stop    : in  boolean := false;
    err_baud    : in  boolean := false;
    data        : in  std_logic_vector;
    signal tx   : out std_logic
  ) is
    variable v_bits   : natural;
    variable v_data   : std_logic_vector(10 downto 0);
    variable v_parity : std_logic := '0';
    variable v_baud   : time := integer(1.0e12 / real(baud_rate)) * 1 ps;
  begin
    v_bits := 1 + data'length + 1;
    v_data(0)                     := '0'; -- start bit
    v_data(data'length downto 1)  := data;
    v_data(data'length + 1)       := '1'; -- stop bit
    if parity /= parity_none then
      for i in data'length - 1 downto 1 loop
        v_parity := v_parity xor data(i);
      end loop;
      if parity = parity_odd then
        v_data(data'length) := not v_parity;  -- parity bit
      elsif parity = parity_even then
        v_data(data'length) := v_parity;      -- parity bit
      end if;
    end if;
    if stop2 then
      v_bits := v_bits + 1;
      v_data(data'length + 2) := '1';       -- stop2 bit
    end if;

    for i in 0 to v_bits - 1 loop
      tx <= v_data(i);
      wait for v_baud;
    end loop;

    tx <= '1';
  end procedure;

  -- Clock and reset
  signal clk         : std_logic := '1';
  signal rst         : std_logic := '1';
  signal en          : std_logic := '0';
  -- Config
  -- [   20] '0' one stop bit, '1' two stop bits
  -- [   19] '0' even parity, '1' odd parity
  -- [   18] '0' parity disabled, '1' parity enabled
  -- [17:16] "10" 7, "01" 9 or "00" 8 bits
  -- [15: 0] Clocks per baud
  signal config      : std_logic_vector(20 downto 0);
  -- Status
  signal err_ovrn    : std_logic := '0';
  signal err_frame   : std_logic := '0';
  signal err_parity  : std_logic := '0';
  signal err_break   : std_logic := '0';
  -- RX data
  signal dout_ready  : std_logic := '1';
  signal dout_valid  : std_logic := '0';
  signal dout        : std_logic_vector(7 downto 0) := (others => '0');
  -- TX data
  signal din_ready   : std_logic := '1';
  signal din_valid   : std_logic;
  signal din         : std_logic_vector(7 downto 0);
  -- RX/TX IO
  signal uart_rxd    : std_logic := '1';
  signal uart_txd    : std_logic := '1';

begin

  clk <= not clk after c_clk_period / 2;
  rst <= '0' after c_rst_period;
  en  <= '1';-- after 2 * c_rst_period;

  config <= '0' & "00" & "00" & std_logic_vector(to_unsigned(125000000 / 921600, 16));

  i_dut : entity lib_uart.uart(rtl)
  port map (
    clk         => clk,
    rst         => rst,
    en          => en,
    config      => config,
    err_ovrn    => err_ovrn,
    err_frame   => err_frame,
    err_parity  => err_parity,
    err_break   => err_break,
    dout_ready  => dout_ready,
    dout_valid  => dout_valid,
    dout        => dout,
    din_ready   => din_ready,
    din_valid   => din_valid,
    din         => din,
    uart_rxd    => uart_rxd,
    uart_txd    => uart_txd
  );

  p_test : process
  begin

  wait until rst = '0';

  wait for 1 ms;

  pcdr_uart_transmit(
    data    => x"55",
    parity  => parity_none,
    stop2   => false,
    tx      => uart_rxd
  );
  pcdr_uart_transmit(
    data    => x"be",
    parity  => parity_none,
    stop2   => false,
    tx      => uart_rxd
  );
  pcdr_uart_transmit(
    data    => x"ef",
    parity  => parity_none,
    stop2   => false,
    tx      => uart_rxd
  );
  pcdr_uart_transmit(
    data    => x"02",
    parity  => parity_none,
    stop2   => false,
    tx      => uart_rxd
  );

  wait for 100 ns;

  uart_rxd <= '0';

  wait for 15 us;

  uart_rxd <= '1';

  wait;
  end process;

end architecture tb;