library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axis;
use lib_axis.axis_pkg.all;

entity axis_fifo is
  generic (
    DW          : integer;
    IDW         : integer := 0;
    DSTW        : integer := 0;
    USRW        : integer := 0;
    DEPTH       : integer := 16;
    COMMON_CLK  : integer range 0 to 1
  );
  port (
    aclk          : in  std_logic;
    aresetn       : in  std_logic;
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic;
    s_axis        : in  t_axis(
      data(DW-1 downto 0),
      keep(DW/8-1 downto 0),
      id(maximum(IDW, 1)-1 downto 0),
      dest(maximum(DSTW, 1)-1 downto 0),
      user(maximum(USRW, 1)-1 downto 0)
    );
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic;
    m_axis        : out t_axis(
      data(DW-1 downto 0),
      keep(DW/8-1 downto 0),
      id(maximum(IDW, 1)-1 downto 0),
      dest(maximum(DSTW, 1)-1 downto 0),
      user(maximum(USRW, 1)-1 downto 0)
    )
  );
end entity axis_fifo;

architecture rtl of axis_fifo is
  constant C_PACKED_WIDTH : integer := f_axis_width(DW, IDW, DSTW, USRW);

  signal s_payload : std_logic_vector(C_PACKED_WIDTH-1 downto 0);
  signal m_payload : std_logic_vector(C_PACKED_WIDTH-1 downto 0);
begin
  s_payload <= f_axis_serialize(s_axis, DW, IDW, DSTW, USRW);
  m_axis <= f_axis_deserialize(m_payload, DW, IDW, DSTW, USRW);

  i_fifo : entity lib_common.fifo(rtl)
    generic map (
      DW           => C_PACKED_WIDTH,
      DEPTH        => DEPTH,
      FWFT         => 1,
      READ_LATENCY => 1,
      COMMON_CLK   => COMMON_CLK
    )
    port map (
      wclk   => aclk,
      wrstn  => aresetn,
      wdata  => s_payload,
      we     => s_axis_tvalid,
      wfull  => open,
      wready => s_axis_tready,
      rclk   => aclk,
      rrstn  => aresetn,
      rdata  => m_payload,
      ren    => m_axis_tready,
      rempty => open,
      rvalid => m_axis_tvalid
    );
end architecture rtl;
