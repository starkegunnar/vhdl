library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity lfsr_crc_wrapper is
  generic (
    g_width       : positive;
    g_polynomial  : std_logic_vector
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    en      : in  std_logic;
    data_in : in  std_logic_vector(g_width-1 downto 0);
    crc_out : out std_logic_vector(abs(fn_mssb_index(g_polynomial)-g_polynomial'right)-1 downto 0)
  );
end entity lfsr_crc_wrapper;

architecture rtl of lfsr_crc_wrapper is

  signal crc_in : std_logic_vector(g_width-1 downto 0) := (others => '1');

begin

  i_crc : entity lib_common.lfsr_crc(rtl)
  generic map (
    g_width       => g_width,
    g_polynomial  => g_polynomial
  )
  port map (
    crc_in  => crc_in,
    data_in => data_in,
    crc_out => crc_out
  );

  -- Compute next combinational Value
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        crc_in <= (others => '1');
      elsif en = '1' then
        crc_in <= crc_out;
      end if;
    end if;
  end process;

end architecture rtl;