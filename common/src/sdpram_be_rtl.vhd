library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity sdpram_be is
  generic (
    AW            : integer;
    DEPTH         : integer := 0;
    COLW          : integer;
    N_COL         : integer;
    COMMON_CLK    : integer range 0 to 1;
    READ_LATENCY  : integer range 0 to 1;
    INIT_FILE     : string := ""
  );
  port (
    wclk    : in  std_logic;
    waddr   : in  std_logic_vector(AW-1 downto 0);
    we      : in  std_logic_vector(N_COL-1 downto 0);
    wdata   : in  std_logic_vector(N_COL*COLW-1 downto 0);
    rclk    : in  std_logic;
    raddr   : in  std_logic_vector(AW-1 downto 0);
    rden    : in  std_logic;
    rdata   : out std_logic_vector(N_COL*COLW-1 downto 0)
  );
end entity sdpram_be;

architecture rtl of sdpram_be is

  constant DW : integer := N_COL*COLW;

  function f_depth return integer is
  begin
    if DEPTH > 0 then
      return minimum(DEPTH, 2**AW);
    else
      return 2**AW;
    end if;
  end function;

  signal mem      : t_slv_array(0 to f_depth-1)(DW-1 downto 0);
  signal dout     : t_slv_array(0 to 1)(DW-1 downto 0);
  signal rclk_int : std_logic;

begin

  rclk_int <= wclk when COMMON_CLK /= 0 else rclk;

  p_write : process(wclk)
  begin
    if rising_edge(wclk) then
      for i in 0 to N_COL-1 loop
        if we(i) = '1' then
          mem(to_integer(unsigned(waddr)))((i+1)*COLW-1 downto i*COLW) <= wdata((i+1)*COLW-1 downto i*COLW);
        end if;
      end loop;
    end if;
  end process;

  dout(0) <= mem(to_integer(unsigned(raddr)));

  p_read : process(rclk_int)
  begin
    if rising_edge(rclk_int) then
      if rden = '1' then
        dout(1) <= dout(0);
      end if;
    end if;
  end process;

  rdata <= dout(READ_LATENCY);

end architecture;