library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity tdpram is
  generic (
    AW            : integer;
    DEPTH         : integer := 0;
    DW            : integer;
    COMMON_CLK    : integer range 0 to 1;
    RAM_MODE_A    : integer range RAM_READ_FIRST to RAM_NO_CHANGE := RAM_READ_FIRST;
    RAM_MODE_B    : integer range RAM_READ_FIRST to RAM_NO_CHANGE := RAM_READ_FIRST;
    INIT_FILE     : string := ""
  );
  port (
    clka    : in  std_logic;
    ena     : in  std_logic;
    addra   : in  std_logic_vector(AW-1 downto 0);
    wea     : in  std_logic;
    dina    : in  std_logic_vector(DW-1 downto 0);
    douta   : out std_logic_vector(DW-1 downto 0);
    clkb    : in  std_logic;
    enb     : in  std_logic;
    addrb   : in  std_logic_vector(AW-1 downto 0);
    web     : in  std_logic;
    dinb    : in  std_logic_vector(DW-1 downto 0);
    doutb   : out std_logic_vector(DW-1 downto 0)
  );
end entity tdpram;

architecture rtl of tdpram is

begin

  i_tdpram : tdpram_be
  generic map (
    AW            => AW,
    DEPTH         => DEPTH,
    COLW          => DW,
    N_COL         => 1,
    COMMON_CLK    => COMMON_CLK,
    RAM_MODE_A    => RAM_MODE_A,
    RAM_MODE_B    => RAM_MODE_B,
    INIT_FILE     => INIT_FILE
  )
  port map (
    clka    => clka,
    ena     => ena,
    addra   => addra,
    wea(0)  => wea,
    dina    => dina,
    douta   => douta,
    clkb    => clkb,
    enb     => enb,
    addrb   => addrb,
    web(0)  => web,
    dinb    => dinb,
    doutb   => doutb
  );

end architecture;