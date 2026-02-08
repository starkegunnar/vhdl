library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity up_down_counter is
  generic (
    WIDTH       : integer;
    ASYNC_RESET : integer range 0 to 1 := 0;
    RESET_VAL   : std_logic_vector(WIDTH-1 downto 0) := (others => '0')
  );
  port (
    clk   : in  std_logic;
    rstn  : in  std_logic;
    clear : in  std_logic := '0';
    en    : in  std_logic;
    up    : in  std_logic;
    down  : in  std_logic;
    delta : in  std_logic_vector(WIDTH-1 downto 0) := std_logic_vector(to_unsigned(1, WIDTH));
    count : out std_logic_vector(WIDTH-1 downto 0);
    zero  : out std_logic
  );
end entity up_down_counter;

architecture rtl of up_down_counter is

  signal q, d : unsigned(WIDTH-1 downto 0);

begin

  P_comb : process(all)
    variable v : unsigned(WIDTH-1 downto 0);
  begin
    v := q;

    if en = '1' then
      v := q + unsigned(up and delta) - unsigned(down and delta);
    end if;
    if clear = '1' then
      v := unsigned(RESET_VAL);
    end if;
    if ASYNC_RESET = 0 and rstn = '0' then
      v := unsigned(RESET_VAL);
    end if;

    d <= v;

    count <= std_logic_vector(q);
    zero  <= nor q;
  end process;

  p_reg : process(clk, rstn)
  begin
    if ASYNC_RESET /= 0 and rstn = '0' then
      q <= unsigned(RESET_VAL);
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture;