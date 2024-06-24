library ieee;
use ieee.std_logic_1164.all;

entity reg_slice_full is
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
end entity reg_slice_full;

architecture rtl of reg_slice_full is

  signal s_data_r : t_data;

begin

  p_slice : process(clk)
  begin
    if rising_edge(clk) then

      if s_valid = '1' and s_ready = '1' and m_valid = '1' and m_ready = '0' then
        s_ready <= '0';
      elsif m_ready = '1' then
        s_ready <= '1';
      end if;

      if s_ready = '1' then
        s_data_r <= s_data;
      end if;

      if m_valid = '0' or m_ready = '1' then
        m_valid <= s_valid or not s_ready;
        if s_ready = '0' then
          m_data <= s_data_r;
        else
          m_data <= s_data;
        end if;
      end if;

      if rst = '1' then
        s_ready <= '1';
        m_valid <= '0';
      end if;
    end if;
  end process;

end architecture rtl;