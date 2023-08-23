library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity uart_rx is
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
    -- Status
    err_ovrn    : out std_logic := '0';
    err_frame   : out std_logic := '0';
    err_parity  : out std_logic := '0';
    err_noise   : out std_logic := '0';
    err_break   : out std_logic := '0';
    -- Baud
    baud16_en   : in  std_logic; -- 16 * baud
    -- Data
    rxre        : in  std_logic := '1';             -- Receiver read enable
    rxne        : out std_logic;                    -- Receiver not empty
    rxdr        : out std_logic_vector(8 downto 0); -- Receiver data register
    -- Status led
    rx_busy     : out std_logic;
    -- Rx
    uart_rxd    : in  std_logic
  );
end entity uart_rx;

architecture rtl of uart_rx is

  attribute async_reg : string;

  type t_rx_state is (s_reset, s_idle, s_break, s_start, s_bits, s_stop1, s_stop2);
  signal state              : t_rx_state := s_reset;

  signal uart_rxd_r          : std_logic_vector(2 downto 0) := (others => '0');
  attribute async_reg of uart_rxd_r : signal is "true";

  signal uart_rxd_in        : std_logic := '0';
  signal falling            : std_logic;

  signal num_bits           : std_logic_vector(1 downto 0); -- "10" 7, "01" 9 or "00" 8 bits
  signal parity_en          : std_logic;
  signal parity_odd         : std_logic;
  signal stop_bits          : std_logic;            -- '0' 1 or '1' 2

  signal bit_count          : unsigned(3 downto 0) := (others => '0');
  signal parity             : std_logic := '0';

  signal sample_start       : std_logic := '0';
  signal sample_done        : std_logic;
  signal sample_count       : unsigned(3 downto 0);
  signal sample_srl         : std_logic_vector(2 downto 0);
  signal sample_bit         : std_logic;
  signal sample_noise       : std_logic;
  signal end_of_bit         : std_logic;

  signal data_srl           : std_logic_vector(9 downto 0) := (others => '0');
  signal rxne_r             : std_logic;
  signal rxne_out           : std_logic;
  signal rxdr_r             : std_logic_vector(8 downto 0);

  signal idle_frame         : std_logic := '0';
  signal break_frame        : std_logic := '0';
  signal err_frame_r        : std_logic := '0';
  signal err_parity_r       : std_logic := '0';
  signal err_noise_r        : std_logic := '0';

begin

  p_uart_rx : process(clk)
  begin
    if rising_edge(clk) then
      (uart_rxd_in, uart_rxd_r) <= uart_rxd_r & uart_rxd;
      falling <= '0';
      if uart_rxd_in = '1' and uart_rxd_r(uart_rxd_r'high) = '0' then
        falling <= '1';
      end if;
    end if;
  end process;

  p_config : process(clk)
  begin
    if rising_edge(clk) then
      if state <= s_idle then
        num_bits    <= config(1 downto 0);
        parity_en   <= config(2);
        parity_odd  <= config(3);
        stop_bits   <= config(4);
      end if;
    end if;
  end process;

  sample_bit    <= (sample_srl(0) and sample_srl(1)) or (sample_srl(1) and sample_srl(2)) or (sample_srl(0) and sample_srl(2));
  sample_noise  <= (sample_srl(0) xor sample_srl(1)) or (sample_srl(1) xor sample_srl(2)) or (sample_srl(0) xor sample_srl(2));

  p_sample : process(clk)
  begin
    if rising_edge(clk) then
      sample_done <= '0';
      end_of_bit  <= '0';
      if state = s_idle and falling = '1' and sample_start = '0' then
        sample_count <= (others => '0');
      elsif baud16_en = '1' then
        sample_count <= sample_count + 1;
        case sample_count is
        when x"1" | x"3" | x"5" | x"7" | x"8" | x"9" =>
          sample_srl <= sample_srl(sample_srl'high - 1 downto 0) & uart_rxd_in;
        when x"6" =>
          sample_done <= sample_start;
        when x"a" =>
          sample_done <= '1';
        when x"f" =>
          if state >= s_start then
            end_of_bit <= '1';
          end if;
        when others =>
        end case;
      end if;

      if rst = '1' then
        sample_count <= (others => '0');
      end if;
    end if;
  end process;

  p_state : process(clk)
  begin
    if rising_edge(clk) then

      rx_busy <= '0';
      if state >= s_start then
        rx_busy <= '1';
      end if;

      if en = '1' then
        case state is
        when s_reset =>
          if idle_frame = '1' then
            state <= s_idle;
          end if;
        when s_idle =>
          if sample_start = '0' and falling = '1' then
            sample_start <= '1';
          elsif sample_done = '1' then
            sample_start <= '0';
            if sample_bit = '0' then
              state <= s_start;
            end if;
          end if;
        when s_break =>
          if data_srl(data_srl'high downto data_srl'high - 1) = "11" then
            state <= s_idle;
          end if;
        when s_start =>
          case num_bits is
          when "01" =>
            bit_count <= x"8";
          when "10" =>
            bit_count <= x"6";
          when others =>
            bit_count <= x"7";
          end case;
          if end_of_bit = '1' then
            if sample_bit = '0' then
              state <= s_bits;
            else
              state <= s_idle;
            end if;
          end if;
        when s_bits =>
          if end_of_bit = '1' then
            if 0 < bit_count then
              bit_count <= bit_count - 1;
            else
              state <= s_stop1;
            end if;
          end if;
        when s_stop1 =>
          if end_of_bit = '1' then
            if break_frame = '1' then
              state <= s_break;
            elsif sample_bit = '0' then
              state <= s_reset;
            elsif stop_bits = '1' then
              state <= s_stop2;
            else
              state <= s_idle;
            end if;
          end if;
        when s_stop2 =>
          if end_of_bit = '1' then
            if sample_bit = '0' then
              state <= s_reset;
            else
              state <= s_idle;
            end if;
          end if;
        when others =>
          state <= s_reset;
        end case;
      else
        state <= s_reset;
      end if;
    end if;
  end process;

  p_data : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        idle_frame <= and_reduce(data_srl);
        if state = s_idle then
          err_noise_r <= '0';
        elsif sample_done = '1' then
          err_noise_r <= err_noise_r or sample_noise;
          data_srl    <= sample_bit & data_srl(data_srl'high downto 1);
        end if;
      else
        idle_frame <= '0';
      end if;
    end if;
  end process;

  p_parity : process(clk)
  begin
    if rising_edge(clk) then
      case state is
      when s_idle =>
        parity <= '0';
      when s_bits =>
        if sample_done = '1' then
          parity <= parity xor sample_bit;
        end if;
      when others =>
      end case;
    end if;

    if state = s_idle then
      err_parity_r <= '0';
    elsif state = s_stop1 and sample_done = '1' then
      if parity_odd = '1' then
        err_parity_r <= parity_en and not parity;
      else
        err_parity_r <= parity_en and parity;
      end if;
    end if;

    if rst = '1' then
      parity <= '0';
    end if;
  end process;

  p_stop : process(clk)
  begin
    if rising_edge(clk) then
      if sample_done = '1' then
        case state is
        when s_stop1 | s_stop2 =>
          err_frame_r <= err_frame_r or not sample_bit;
        when others =>
          err_frame_r <= '0';
        end case;
      end if;
    end if;
  end process;

  rxne <= rxne_out;

  p_dout : process(clk)
  begin
    if rising_edge(clk) then
      if rxre = '1' and rxne_out = '1' then
        rxne_out <= '0';
      end if;

      if rxne_r = '0' then
        if end_of_bit = '1' and state = s_stop1 then
          case num_bits is
          when "01" =>
            rxdr_r      <= data_srl(8 downto 0);
            break_frame <= nor_reduce(data_srl);
          when "10" =>
            rxdr_r      <= "00" & data_srl(8 downto 2);
            break_frame <= nor_reduce(data_srl(data_srl'high downto 2));
          when others =>
            rxdr_r      <= "0" & data_srl(8 downto 1);
            break_frame <= nor_reduce(data_srl(data_srl'high downto 1));
          end case;
          rxne_r  <= '1';
        end if;
      elsif state = s_idle or end_of_bit = '1' then
        if break_frame = '0' and err_frame_r = '0' then
          if rxne_out = '0' or rxre = '1' then
            rxdr <= rxdr_r;
          end if;
          rxne_out <= rxne_r;
        end if;
        rxne_r      <= '0';
        break_frame <= '0';
      end if;

      if rst = '1' then
        rxne_r      <= '0';
        rxne_out    <= '0';
        break_frame <= '0';
      end if;
    end if;
  end process;

  p_errors : process(clk)
  begin
    if rising_edge(clk) then
      err_ovrn    <= '0';
      err_parity  <= '0';
      err_frame   <= '0';
      err_noise   <= '0';

      if rxne_r = '1' and (state = s_idle or end_of_bit = '1') then
        if break_frame = '1' then
          err_break   <= '1';
        else
          err_ovrn    <= rxne_out and not rxre;
          err_parity  <= err_parity_r;
          err_frame   <= err_frame_r;
          err_noise   <= err_noise_r;
        end if;
      elsif state = s_idle then
        err_break <= '0';
      end if;

      if rst = '1' then
        err_break <= '0';
      end if;
    end if;
  end process;

end architecture rtl;