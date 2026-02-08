library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity sdpram is
  generic (
    AW            : integer := 9;
    DEPTH         : integer := 0;
    DW            : integer := 64;
    COMMON_CLK    : integer range 0 to 1;
    READ_LATENCY  : integer range 0 to 1 := 1;
    INIT_FILE     : string := ""
  );
  port (
    wclk    : in  std_logic;
    waddr   : in  std_logic_vector(AW-1 downto 0);
    we      : in  std_logic;
    wdata   : in  std_logic_vector(DW-1 downto 0);
    rclk    : in  std_logic;
    raddr   : in  std_logic_vector(AW-1 downto 0);
    rden    : in  std_logic := '1';
    rdata   : out std_logic_vector(DW-1 downto 0)
  );
end entity sdpram;

architecture rtl of sdpram is

begin

  i_sdpram_be : entity lib_common.sdpram_be(rtl)
  generic map (
    AW            => AW,
    DEPTH         => DEPTH,
    COLW          => DW,
    N_COL         => 1,
    COMMON_CLK    => COMMON_CLK,
    READ_LATENCY  => READ_LATENCY,
    INIT_FILE     => INIT_FILE
  )
  port map (
    wclk    => wclk,
    waddr   => waddr,
    we(0)   => we,
    wdata   => wdata,
    rclk    => rclk,
    raddr   => raddr,
    rden    => rden,
    rdata   => rdata
  );

end architecture;