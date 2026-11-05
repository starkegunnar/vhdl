library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity gray_counter is
  generic (
    WIDTH       : integer := 8;
    RESET_VAL   : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    ASYNC_RESET : integer range 0 to 1 := 0
  );
  port (
    clk   : in  std_logic;
    rstn  : in  std_logic;
    clear : in  std_logic := '0';
    en    : in  std_logic;
    count : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity gray_counter;

architecture rtl of gray_counter is

  constant RST : unsigned(WIDTH-1 downto 0):= f_bin2gray(unsigned(RESET_VAL));

  signal q, d : unsigned(WIDTH-1 downto 0);

begin

  p_comb : process(all)
    variable v : unsigned(WIDTH-1 downto 0);
  begin
    v := q;

    if en = '1' then
      v := f_bin2gray(f_gray2bin(q) + 1);
    end if;
    if clear = '1' then
      v := RST;
    end if;
    if ASYNC_RESET = 0 and rstn = '0' then
      v := RST;
    end if;

    d <= v;

    count <= std_logic_vector(q);
  end process;

  p_reg : process(clk, rstn)
  begin
    if ASYNC_RESET /= 0 and rstn = '0' then
      q <= RST;
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture;