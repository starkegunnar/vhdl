library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity up_down_counter_rtl is
  generic (
    g_counter_width : positive;
    g_reset_value   : natural range 0 to 2**g_counter_width-1
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    cnt_en    : in  std_logic;
    cnt_up    : in  std_logic;
    cnt_down  : in  std_logic;
    cnt_value : out std_logic_vector(g_counter_width-1 downto 0);
  );
end entity up_down_counter_rtl;

architecture rtl of up_down_counter_rtl is

  signal cnt_value_r : unsigned(g_counter_width-1 downto 0) := to_unsigned(g_reset_value, g_counter_width);

begin

  cnt_value <= std_logic_vector(cnt_value_r);

  p_counter : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt_value_r <= to_unsigned(g_reset_value, g_counter_width);
      elsif cnt_en = '1' then
        cnt_value_r <= cnt_value_r + std_ulogic(cnt_up) - std_ulogic(cnt_down);
      end if;
    end if;
  end process;

end architecture;