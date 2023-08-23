library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_uart;

entity uart_loopback is
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
    -- LED
    rx_busy     : out std_logic;
    tx_busy     : out std_logic;
    -- Debug
    dbg_valid   : out std_logic;
    dbg_ready   : out std_logic;
    dbg_data    : out std_logic_vector(7 downto 0);
    -- RX/TX IO
    uart_rxd    : in  std_logic := '1';
    uart_txd    : out std_logic := '1'
  );
end entity uart_loopback;

architecture rtl of uart_loopback is

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
    rx_busy           => rx_busy,
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
    tx_busy           => tx_busy,
    -- Rx
    uart_txd          => uart_txd
  );

  dbg_valid <= data_valid;
  dbg_ready <= data_ready;
  dbg_data  <= data(7 downto 0);

  i_baud_generator : entity lib_uart.uart_baud_gen(rtl)
  port map (
    -- Clock and reset
    clk           => clk,
    rst           => rst,
    en            => en,
    -- Config
    baud_div      => config(15 downto 0),
    -- Status
    err_div_zero  => open,
    -- Baudrate
    baud16_en     => baud16_en
  );

end architecture rtl;