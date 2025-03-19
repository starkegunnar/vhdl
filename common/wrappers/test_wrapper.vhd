library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity test_wrapper is
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst     : in  std_logic;
    -- Data and flow control
    s_data  : in  t_data;
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out t_data;
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity test_wrapper;

architecture rtl of test_wrapper is

begin

  i_test : entity lib_common.test(rtl)
  generic map (
    t_data          => t_slv_array(3 downto 0)(7 downto 0),
  )
  port map (
    clk       => clk,
    rst       => rst,
    s_data    => s_data,
    s_valid   => s_valid,
    s_ready   => s_ready,
    m_data    => m_data,
    m_valid   => m_valid,
    m_ready   => m_ready
  );

end architecture rtl;