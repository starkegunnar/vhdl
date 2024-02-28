library ieee;
use ieee.std_logic_1164.all;

entity reg_slice_fallthrough is
  generic (
    type t_data
  );
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
end entity reg_slice_fallthrough;

architecture rtl of reg_slice_fallthrough is

begin

  s_ready <= not m_valid or m_ready;

  p_slice : process(clk)
  begin
    if rising_edge(clk) then

      if m_valid = '0' or m_ready = '1' then
        m_valid <= s_valid;
        m_data  <= s_data;
      end if;

      if rst = '1' then
        m_valid   <= '0';
      end if;
    end if;
  end process;

end architecture rtl;