library ieee;
use ieee.std_logic_1164.all;

entity test is
  generic (
    type t_data
  );
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst     : in  std_logic;
    -- Data and flow control
    s_data  : in  t_data;
    s_valid : in  std_logic_vector(3 downto 0);
    s_ready : out std_logic_vector(3 downto 0);
    m_data  : out t_data'element;
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity test;

architecture rtl of test is

begin

  m_data  <= s_data(0);
  m_valid <= s_valid(0);
  s_ready <= (m_ready);

end architecture rtl;