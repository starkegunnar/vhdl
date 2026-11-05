library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity spram is
  generic (
    AW        : integer;
    DEPTH     : integer := 0;
    DW        : integer;
    RAM_MODE  : integer range RAM_READ_FIRST to RAM_NO_CHANGE := RAM_READ_FIRST;
    INIT_FILE : string := ""
  );
  port (
    clk   : in  std_logic;
    en    : in  std_logic;
    addr  : in  std_logic_vector(AW-1 downto 0);
    we    : in  std_logic;
    din   : in  std_logic_vector(DW-1 downto 0);
    dout  : out std_logic_vector(DW-1 downto 0)
  );
end entity spram;

architecture rtl of spram is

begin

  i_spram : spram_be
  generic map (
    AW        => AW,
    DEPTH     => DEPTH,
    COLW      => DW,
    N_COL     => 1,
    RAM_MODE  => RAM_MODE,
    INIT_FILE => INIT_FILE
  )
  port map (
    clk   => clk,
    en    => en,
    addr  => addr,
    we(0) => we,
    din   => din,
    dout  => dout
  );

end architecture;