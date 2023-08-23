library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_uart;

entity uart_baud_gen is
  port (
    -- Clock and reset
    clk           : in  std_logic;
    rst           : in  std_logic;
    en            : in  std_logic;
    -- Config
    baud_div      : in  std_logic_vector(15 downto 0);
    -- Status
    err_div_zero  : out std_logic := '0';
    -- Baudrate
    baud16_en     : out std_logic := '0'
  );
end entity uart_baud_gen;

architecture rtl of uart_baud_gen is

  signal en_r           : std_logic := '0';

  signal baud_zero      : std_logic := '0';
  signal baud_reload    : std_logic;
  signal baud_divi      : unsigned(11 downto 0) := (others => '0');
  signal baud_divf      : unsigned(3 downto 0) := (others => '0');
  signal baud_counter_r : unsigned(11 downto 0) := (others => '0');
  signal baud_counter   : unsigned(11 downto 0) := (others => '0');

  signal divf_acc       : unsigned(3 downto 0) := (others => '0');
  signal divf_acc_cout  : std_ulogic := '0';

begin

  baud_reload   <= baud_zero or divf_acc_cout or not en_r;
  baud_counter  <= baud_divi when baud_reload = '1' else baud_counter_r;

  p_baud_generator : process(clk)
  begin
    if rising_edge(clk) then
      en_r <= en;

      baud_counter_r <= baud_counter - 1;

      baud_zero <= '0';
      if en_r = '1' and baud_counter_r = 1 then
        baud_zero <= '1';
      end if;

      divf_acc_cout <= '0';
      if en_r = '0' then
        divf_acc <= (others => '0');
      elsif baud_zero = '1' then
        (divf_acc_cout, divf_acc) <= ('0' & divf_acc) + ('0' & baud_divf);
      end if;

      err_div_zero <= '0';
      if en_r = '1' and baud_divi = 0 then
        err_div_zero <= '1';
      end if;

      if en_r = '0' then
        (baud_divi, baud_divf) <= unsigned(baud_div);
      end if;

      baud16_en <= baud_zero;

      if rst = '1' then
        en_r          <= '0';
        divf_acc_cout <= '0';
        divf_acc      <= (others => '0');
      end if;
    end if;
  end process;

end architecture rtl;