library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_sync is
  generic (
    WIDTH     : integer;
    CDC_TYPE  : string := "cdc_sync";
    SYNC_FF   : integer range 2 to 15 := 2;
    RESET_VAL : std_logic := '0'
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic := '1';
    d     : in  std_logic_vector(WIDTH-1 downto 0);
    q     : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity cdc_sync;

architecture rtl of cdc_sync is

  constant RST : t_slv_array(SYNC_FF-1 downto 0)(WIDTH-1 downto 0) := (others => (others => RESET_VAL));

  signal q_sync : t_slv_array(SYNC_FF-1 downto 0)(WIDTH-1 downto 0);

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of q_sync : signal is "true";

begin

  p_reg : process(clk, rst_n)
  begin
    if rst_n = '0' then
      q_sync <= RST;
    elsif rising_edge(clk) then
      q_sync <= q_sync(SYNC_FF-2 downto 0) & d;
    end if;
  end process;
  q <= q_sync(SYNC_FF-1);

end architecture rtl;