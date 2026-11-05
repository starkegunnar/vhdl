library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity spram_be is
  generic (
    AW        : integer;
    DEPTH     : integer := 0;
    COLW      : integer;
    N_COL     : integer;
    RAM_MODE  : integer range RAM_READ_FIRST to RAM_NO_CHANGE := RAM_READ_FIRST;
    INIT_FILE : string := ""
  );
  port (
    clk   : in  std_logic;
    en    : in  std_logic;
    addr  : in  std_logic_vector(AW-1 downto 0);
    we    : in  std_logic_vector(N_COL-1 downto 0);
    din   : in  std_logic_vector(N_COL*COLW-1 downto 0);
    dout  : out std_logic_vector(N_COL*COLW-1 downto 0)
  );
end entity spram_be;

architecture rtl of spram_be is

  constant DW : integer := N_COL*COLW;

  function f_depth return integer is
  begin
    if DEPTH > 0 then
      return minimum(DEPTH, 2**AW);
    else
      return 2**AW;
    end if;
  end function;

  signal mem : t_slv_array(0 to f_depth-1)(DW-1 downto 0);

begin

  gen_ram_read_first : if RAM_MODE = RAM_READ_FIRST generate
    p_mem : process(clk)
    begin
      if rising_edge(clk) then
        if en = '1' then
          dout <= mem(to_integer(unsigned(addr)));
          for i in 0 to N_COL-1 loop
            if we(i) = '1' then
              mem(to_integer(unsigned(addr)))((i+1)*COLW-1 downto i*COLW) <= din((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_read_first;

  gen_ram_write_first : if RAM_MODE = RAM_WRITE_FIRST generate
    p_mem : process(clk)
    begin
      if rising_edge(clk) then
        if en = '1' then
          for i in 0 to N_COL-1 loop
            if we(i) = '1' then
              mem(to_integer(unsigned(addr)))((i+1)*COLW-1 downto i*COLW) <= din((i+1)*COLW-1 downto i*COLW);
              dout((i+1)*COLW-1 downto i*COLW) <= din((i+1)*COLW-1 downto i*COLW);
            else
              dout((i+1)*COLW-1 downto i*COLW) <= mem(to_integer(unsigned(addr)))((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_write_first;

  gen_ram_no_change : if RAM_MODE = RAM_NO_CHANGE generate
    p_mem : process(clk)
    begin
      if rising_edge(clk) then
        if en = '1' then
          if nor we = '1' then
            dout <= mem(to_integer(unsigned(addr)));
          end if;
          for i in 0 to N_COL-1 loop
            if we(i) = '1' then
              mem(to_integer(unsigned(addr)))((i+1)*COLW-1 downto i*COLW) <= din((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_no_change;

end architecture;