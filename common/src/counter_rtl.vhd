library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
  generic (
    WIDTH       : integer;
    MAX_VALUE   : std_logic_vector(WIDTH-1 downto 0) := (others => '1');
    RESET_VAL   : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    ASYNC_RESET : integer range 0 to 1 := 0
  );
  port (
    clk   : in  std_logic;
    rstn  : in  std_logic;
    clear : in  std_logic := '0';
    en    : in  std_logic;
    count : out std_logic_vector(WIDTH-1 downto 0);
    wrap  : out std_logic;
    zero  : out std_logic
  );
end entity counter;

architecture rtl of counter is

  signal q, d : unsigned(WIDTH downto 0);

begin

  P_comb : process(all)
    variable v : unsigned(WIDTH downto 0);
  begin
    v := q;

    if en = '1' then
      v := q + 1;
      if MAX_VALUE /= (WIDTH-1 downto 0 => '1') then
        if q(WIDTH-1 downto 0) = unsigned(MAX_VALUE) then
          v(WIDTH) := not q(WIDTH);
          v(WIDTH-1 downto 0) := (others => '0');
        end if;
      end if;
    end if;
    if clear = '1' then
      v := (others => '0');
    end if;
    if ASYNC_RESET = 0 and rstn = '0' then
      v := '0' & unsigned(RESET_VAL);
    end if;

    d <= v;

    count <= std_logic_vector(q(WIDTH-1 downto 0));
    wrap  <= q(WIDTH);
    zero  <= nor q;
  end process;

  p_reg : process(clk, rstn)
  begin
    if ASYNC_RESET /= 0 and rstn = '0' then
      q <= '0' & unsigned(RESET_VAL);
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture;