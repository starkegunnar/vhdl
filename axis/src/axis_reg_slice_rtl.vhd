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
    g_s_tkeep_width : positive;
    g_s_tid_width   : natural := 0;
    g_s_tdest_width : natural := 0;
    g_s_tuser_width : natural := 0;
    g_m_tkeep_width : positive := g_s_tkeep_width;
    g_m_tid_width   : natural := g_s_tid_width;
    g_m_tdest_width : natural := g_s_tdest_width;
    g_m_tuser_width : natural := g_s_tuser_width
  );
  port (
    -- Clock and reset
    aclk          : in  std_logic;
    aresetn       : in  std_logic;
    -- Data and flow control
    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic;
    s_axis        : in  t_axis(tdata(8*g_s_tkeep_width-1 downto 0),
                               tkeep(g_s_tkeep_width-1 downto 0),
                               tid(g_s_tid_width-1 downto 0),
                               tdest(g_s_tdest_width-1 downto 0),
                               tuser(g_s_tuser_width-1 downto 0));
    m_axis_tvalid : out std_logic;
    m_axis_tready : in  std_logic
    m_axis        : out t_axis(tdata(8*g_m_tkeep_width-1 downto 0),
                               keep(g_m_tkeep_width-1 downto 0),
                               id(g_m_tid_width-1 downto 0),
                               dest(g_m_tdest_width-1 downto 0),
                               user(g_m_tuser_width-1 downto 0))
  );
end entity reg_slice_srl;