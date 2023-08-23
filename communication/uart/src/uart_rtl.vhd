library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_uart;

entity uart is
  port (
    -- Clock and reset
    clk         : in  std_logic;
    rst         : in  std_logic;
    en          : in  std_logic;
    -- Config
    -- [   20] '0' one stop bit, '1' two stop bits
    -- [   19] '0' even parity, '1' odd parity
    -- [   18] '0' parity disabled, '1' parity enabled
    -- [17:16] "10" 7, "01" 9 or "00" 8 bits
    -- [15: 0] Clocks per baud
    config      : in  std_logic_vector(20 downto 0);
    -- Status
    err_ovrn    : out std_logic := '0';
    err_frame   : out std_logic := '0';
    err_parity  : out std_logic := '0';
    err_noise   : out std_logic := '0';
    err_break   : out std_logic := '0';
    -- RX data
    dout_ready  : in  std_logic;
    dout_valid  : out std_logic := '0';
    dout        : out std_logic_vector(7 downto 0) := (others => '0');
    -- TX data
    din_ready   : out std_logic := '1';
    din_valid   : in  std_logic;
    din         : in  std_logic_vector(7 downto 0);
    -- RX/TX IO
    uart_rxd    : in  std_logic := '1';
    uart_txd    : out std_logic := '1'
  );
end entity uart;

architecture rtl of uart is

  signal baud16_en  : std_logic;

  signal data       : std_logic_vector(8 downto 0);
  signal data_valid : std_logic;
  signal data_ready : std_logic;

begin

  i_uart_rx : entity lib_uart.uart_rx(rtl)
  port map (
    -- Clock and reset
    clk               => clk,
    rst               => rst,
    en                => en,
    -- Config
    config            => config(20 downto 16),
    -- Status
    err_ovrn          => err_ovrn,
    err_frame         => err_frame,
    err_parity        => err_parity,
    err_noise         => err_noise,
    err_break         => err_break,
    -- Baud
    baud16_en         => baud16_en,
    -- Data
    rxre              => data_ready,
    rxne              => data_valid,
    rxdr              => data,
    -- led
    rx_busy           => open,
    -- Rx
    uart_rxd          => uart_rxd
  );

  i_uart_tx : entity lib_uart.uart_tx(rtl)
  port map (
    -- Clock and reset
    clk               => clk,
    rst               => rst,
    en                => en,
    -- Config
    config            => config(20 downto 16),
    -- Baud
    baud16_en         => baud16_en,
    -- Data
    txwe              => data_valid,
    txe               => data_ready,
    txdr              => data(7 downto 0),
    -- led
    tx_busy           => open,
    -- Rx
    uart_txd          => uart_txd
  );

  i_baud_generator : entity lib_uart.uart_baud_gen(rtl)
  port map (
    -- Clock and reset
    clk           => clk, --: in  std_logic;
    rst           => rst, --: in  std_logic;
    en            => en, --: in  std_logic;
    -- Config
    baud_div      => config(15 downto 0),--: in  std_logic_vector(15 downto 0);
    -- Status
    err_div_zero  => open,--: out std_logic := '0';
    -- Baudrate
    baud16_en     => baud16_en--: out std_logic := '0';
  );

end architecture rtl;