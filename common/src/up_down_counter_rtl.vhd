library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity up_down_counter is
  generic (
    g_counter_width : positive;
    g_reset_value   : std_logic_vector(g_counter_width-1 downto 0) := (others => '0')
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    en    : in  std_logic;
    up    : in  std_logic;
    down  : in  std_logic;
    count : out std_logic_vector(g_counter_width-1 downto 0)
  );
end entity up_down_counter;

architecture rtl of up_down_counter is

  signal counter : unsigned(g_counter_width-1 downto 0) := unsigned(g_reset_value);

begin

  count <= std_logic_vector(counter);

  p_counter : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        counter <= unsigned(g_reset_value);
      elsif en = '1' then
        counter <= counter + std_ulogic(up) - std_ulogic(down);
      end if;
    end if;
  end process;

end architecture;