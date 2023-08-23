library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity uart_tx is
  port (
    -- Clock and reset
    clk         : in  std_logic;
    rst         : in  std_logic;
    en          : in  std_logic;
    -- Config
    -- [  4] '0' one stop bit, '1' two stop bits
    -- [  3] '0' even parity, '1' odd parity
    -- [  2] '0' parity disabled, '1' parity enabled
    -- [1:0] "10" 7, "01" 9 or "00" 8 bits
    config      : in  std_logic_vector(4 downto 0);
    -- Baud
    baud16_en   : in  std_logic; -- baud period
    -- Data
    txwe        : in  std_logic := '1';             -- Transmitter write enable
    txe         : out std_logic;                    -- Transmitter empty
    txdr        : in  std_logic_vector(7 downto 0); -- Transmitter data register
    -- Status led
    tx_busy     : out std_logic;
    -- Tx
    uart_txd    : out  std_logic
  );
end entity uart_tx;

architecture rtl of uart_tx is

  attribute shreg_extract : string;

  type t_tx_state is (s_idle, s_start, s_bits, s_parity, s_stop1, s_stop2);
  signal state              : t_tx_state := s_idle;

  signal uart_txd_r         : std_logic_vector(1 downto 0) := (others => '1');
  attribute shreg_extract of uart_txd_r : signal is "no";

  signal uart_txd_out       : std_logic := '1';

  signal num_bits           : std_logic_vector(1 downto 0); -- "10" 7, "01" 9 or "00" 8 bits
  signal parity_en          : std_logic;
  signal parity_odd         : std_logic;
  signal stop_bits          : std_logic;            -- '0' 1 or '1' 2
  signal baud16_count       : unsigned(3 downto 0);
  signal baud_done          : std_logic;

  signal bit_count          : unsigned(3 downto 0) := (others => '0');
  signal parity             : std_logic := '0';

  signal data_srl           : std_logic_vector(7 downto 0) := (others => '0');
  signal txdr_r             : std_logic_vector(7 downto 0) := (others => '0');
  signal txe_r              : std_logic;

begin

  p_txd : process(clk)
  begin
    if rising_edge(clk) then
      (uart_txd, uart_txd_r) <= uart_txd_r & uart_txd_out;
      if rst = '1' then
        uart_txd   <= '1';
        uart_txd_r <= (others => '1');
      end if;
    end if;
  end process;

  p_config : process(clk)
  begin
    if rising_edge(clk) then
      if state = s_idle then
        num_bits    <= config(1 downto 0);
        parity_en   <= config(2);
        parity_odd  <= config(3);
        stop_bits   <= config(4);
      end if;
    end if;
  end process;


  p_tx_state : process(clk)
  begin
    if rising_edge(clk) then
      if baud16_en = '1' then
        if baud16_count = x"e" then
          baud_done <= '1';
        else
          baud_done <= '0';
        end if;
      end if;

      tx_busy <= '0';
      if state /= s_idle then
        tx_busy <= '1';
      end if;

      if state = s_idle then
        baud16_count <= (others => '0');
      elsif baud16_en = '1' then
        baud16_count <= baud16_count + 1;
      end if;

      if state = s_bits then
        if baud16_en = '1' and baud_done = '1' then
          bit_count <= bit_count - 1;
        end if;
      else
        case num_bits is
        when "01" =>
          bit_count <= x"8";
        when "10" =>
          bit_count <= x"6";
        when others =>
          bit_count <= x"7";
        end case;
      end if;

      if en = '1' then
        if baud16_en = '1' then
          case state is
          when s_idle =>
            if txe_r = '0' then
              state <= s_start;
            end if;
          when s_start =>
            if baud_done = '1' then
              state <= s_bits;
            end if;
          when s_bits =>
            if baud_done = '1' and bit_count = 0 then
              if parity_en = '1' then
                state <= s_parity;
              else
                state <= s_stop1;
              end if;
            end if;
          when s_parity =>
            if baud_done = '1' then
              state <= s_stop1;
            end if;
          when s_stop1 =>
            if baud_done = '1' then
              if stop_bits = '1' then
                state <= s_stop2;
              elsif txe_r = '0' then
                state <= s_start;
              else
                state <= s_idle;
              end if;
            end if;
          when s_stop2 =>
            if baud_done = '1' then
              if txe_r = '0' then
                state <= s_start;
              else
                state <= s_idle;
              end if;
            end if;
          when others =>
          end case;
        end if;
      else
        state <= s_idle;
      end if;

      if rst = '1' then
        state <= s_idle;
      end if;
    end if;
  end process;

  txe <= txe_r;

  p_data_register : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        if txe_r = '1' and txwe = '1' then
          txe_r   <= '0';
          txdr_r  <= txdr;
        elsif(baud16_en = '1' and state = s_idle) or (state = s_stop1 and stop_bits = '0') or state = s_stop2 then
          txe_r   <= '1';
        end if;
      else
        txe_r <= '1';
      end if;

      if rst = '1' then
        txe_r <= '1';
      end if;
    end if;
  end process;

  p_shift_register : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        if state = s_bits then
          if baud16_en = '1' and baud_done = '1' then
            parity <= parity xor data_srl(0);
            data_srl <= '1' & data_srl(data_srl'high downto 1);
          end if;
        elsif txe_r = '0' then
          data_srl  <= txdr_r;
          parity    <= '0';
        end if;
      end if;

      case state is
      when s_start =>
        uart_txd_out <= '0';
      when s_bits =>
        uart_txd_out <= data_srl(0);
      when s_parity =>
        if parity_odd = '1' then
          uart_txd_out <= not parity;
        else
          uart_txd_out <= parity;
        end if;
      when others =>
        uart_txd_out <= '1';
      end case;

      if rst = '1' then
        uart_txd_out <= '1';
      end if;
    end if;
  end process;

end architecture rtl;