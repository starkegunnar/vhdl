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

  signal s_valid_r  : std_logic := '0';
  signal s_data_r   : t_data;

begin

  s_ready <= not s_valid_r;

  p_slice : process(clk)
  begin
    if rising_edge(clk) then

      if s_valid = '1' and s_valid_r = '0' and m_valid = '1' and m_ready = '0' then
        s_valid_r <= '1';
      elsif m_ready = '1' then
        s_valid_r <= '0';
      end if;

      if s_valid_r = '0' then
        s_data_r <= s_data;
      end if;

      if m_valid = '0' or m_ready = '1' then
        m_valid <= s_valid or s_valid_r;
        if s_valid_r = '1' then
          m_data <= s_data_r;
        else
          m_data <= s_data;
        end if;
      end if;

      if rst = '1' then
        s_valid_r <= '0';
        m_valid   <= '0';
      end if;
    end if;
  end process;

end architecture rtl;