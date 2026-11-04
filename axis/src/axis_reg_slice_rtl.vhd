library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axis;
use lib_axis.axis_pkg.all;

entity axis_reg_slice is
  generic (
    DW          : integer;
    IDW         : integer := 0;
    DSTW        : integer := 0;
    USRW        : integer := 0;
    SLICE_TYPE  : integer range 0 to 3 := 1;
  );
  port (
    -- Clock and reset
    aclk          : in  std_logic;
    aresetn       : in  std_logic;
    -- Data and flow control
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic;
    s_axis        : in  t_axis(data(DW-1 downto 0),
                               keep(DW/8-1 downto 0),
                               id(maximum(IDW,1)-1 downto 0),
                               dest(maximum(DSTW,1)-1 downto 0),
                               user(maximum(USRW,1)-1 downto 0));
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic
    m_axis        : out t_axis(data(DW-1 downto 0),
                               keep(DW/8-1 downto 0),
                               id(maximum(IDW,1)-1 downto 0),
                               dest(maximum(DSTW,1)-1 downto 0),
                               user(maximum(USRW,1)-1 downto 0))
  );
end entity axis_reg_slice;

architecture rtl of axis_reg_slice is

begin

end;