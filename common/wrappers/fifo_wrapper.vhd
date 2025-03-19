library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity fifo_wrapper is
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst     : in  std_logic;
    -- Data and flow control
    s_data  : in  t_data;
    s_valid : in  std_logic;
    s_ready : out std_logic;
    s_full  : out std_logic;
    m_data  : out t_data;
    m_valid : out std_logic;
    m_empty : out std_logic;
    m_ready : in  std_logic
  );
end entity fifo_wrapper;

architecture rtl of fifo_wrapper is

begin

  i_fifo : entity lib_common.fifo(rtl)
  generic map (
    t_data          => std_logic_vector(7 downto 0),
    g_depth         => 16,
    g_read_latency  => 2
  )
  port map (
    clk       => clk,
    rst       => rst,
    s_data    => s_data,
    s_valid   => s_valid,
    s_ready   => s_ready,
    s_full    => s_full,
    m_data    => m_data,
    m_valid   => m_valid,
    m_empty   => m_empty,
    m_ready   => m_ready
  );

end architecture rtl;