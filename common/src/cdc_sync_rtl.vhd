library ieee;
use ieee.std_logic_1164.all;

entity cdc_sync is
  generic (
    SYNC_FF   : integer range 2 to 15;
    RST_VAL   : std_logic := '0'
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    d     : in  std_logic;
    q     : out std_logic
  );
end entity cdc_sync;

architecture rtl of cdc_sync is

  signal q_sync : std_logic_vector(SYNC_FF-2 downto 0);

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of q_sync : signal is "true";

begin

  p_reg : process(clk, rst_n)
  begin
    if rst_n = '0' then
      (q, q_sync) <= std_logic_vector'(SYNC_FF-1 downto 0 => RST_VAL);
    elsif rising_edge(clk) then
      (q, q_sync) <= q_sync & d;
    end if;
  end process;

end architecture rtl;