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
    -- Config baud divider
    baud_div      : in  std_logic_vector(15 downto 0);
    -- Status
    err_baud_div  : out std_logic := '0';
    -- Baudrate x16 sample enable
    sample_x16_en : out std_logic := '0'
  );
end entity uart_baud_gen;

architecture rtl of uart_baud_gen is

  signal baud_reload    : std_logic := '0';
  signal baud_divi      : unsigned(11 downto 0) := (others => '0');
  signal baud_divf      : unsigned(3 downto 0) := (others => '0');
  signal baud_counter   : unsigned(11 downto 0) := (others => '0');

  signal divf_acc       : unsigned(3 downto 0) := (others => '0');
  signal divf_acc_ovfl  : std_ulogic := '0';

begin

  -- Split baud div into integer and fraction of 16x sample rate
  (baud_divi, baud_divf) <= unsigned(baud_div);

  sample_x16_en <= baud_reload;

  p_baud_generator : process(clk)
  begin
    if rising_edge(clk) then

      -- Defaults
      baud_reload   <= '0';
      divf_acc_ovfl <= '0';

      if rst = '1' then
        baud_counter <= (others => '1');
      elsif en = '1' then
        if baud_reload = '1' then
          -- Reload baud counter
          baud_counter <= baud_divi - 1;
        else
          -- Count down
          baud_counter <= baud_counter - 1 + divf_acc_ovfl;
        end if;
      else
        baud_counter <= baud_divi;
      end if;

      if baud_counter = 1 then
        baud_reload <= en;
      end if;

      if rst = '1' or en = '0' then
        -- Clear fraction accumulator when disabled
        divf_acc_ovfl <= '0';
        divf_acc      <= (others => '0');
      elsif en = '1' and baud_reload = '1' then
        -- Accumulate fraction on baud reload
        (divf_acc_ovfl, divf_acc) <= ('0' & divf_acc) + ('0' & baud_divf);
      end if;

      err_baud_div <= '0';
      if baud_divi = 0 then
        err_baud_div <= '1';
      end if;
    end if;
  end process;

end architecture rtl;