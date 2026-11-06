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
    DW          : positive;
    IDW         : integer := 0;
    DSTW        : integer := 0;
    USRW        : integer := 0;
    SLICE_TYPE  : integer range 0 to 3 := 1
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
    m_axis_tready : in  std_logic;
    m_axis        : out t_axis(data(DW-1 downto 0),
                               keep(DW/8-1 downto 0),
                               id(maximum(IDW,1)-1 downto 0),
                               dest(maximum(DSTW,1)-1 downto 0),
                               user(maximum(USRW,1)-1 downto 0))
  );
end entity axis_reg_slice;

architecture rtl of axis_reg_slice is

  constant C_PACKED_WIDTH : integer := f_axis_width(DW, IDW, DSTW, USRW);

  signal s_payload : std_logic_vector(C_PACKED_WIDTH-1 downto 0);
  signal m_payload : std_logic_vector(C_PACKED_WIDTH-1 downto 0);

begin

  s_payload <= f_axis_serialize(s_axis, DW, IDW, DSTW, USRW);

  i_reg_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW         => C_PACKED_WIDTH,
      SLICE_TYPE => SLICE_TYPE
    )
    port map (
      clk     => aclk,
      rstn    => aresetn,
      s_data  => s_payload,
      s_valid => s_axis_tvalid,
      s_ready => s_axis_tready,
      m_data  => m_payload,
      m_valid => m_axis_tvalid,
      m_ready => m_axis_tready
    );

  m_axis <= f_axis_deserialize(m_payload, DW, IDW, DSTW, USRW);

end;