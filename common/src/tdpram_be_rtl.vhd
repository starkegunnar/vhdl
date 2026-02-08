library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity tdpram_be is
  generic (
    AW            : integer;
    DEPTH         : integer := 0;
    COLW          : integer;
    N_COL         : integer;
    COMMON_CLK    : integer range 0 to 1;
    RAM_MODE_A    : integer range RAM_READ_FIRST to RAM_NO_CHANGE := RAM_READ_FIRST;
    RAM_MODE_B    : integer range RAM_READ_FIRST to RAM_NO_CHANGE := RAM_READ_FIRST;
    INIT_FILE     : string := ""
  );
  port (
    clka    : in  std_logic;
    ena     : in  std_logic;
    addra   : in  std_logic_vector(AW-1 downto 0);
    wea     : in  std_logic_vector(N_COL-1 downto 0);
    dina    : in  std_logic_vector(N_COL*COLW-1 downto 0);
    douta   : out std_logic_vector(N_COL*COLW-1 downto 0);
    clkb    : in  std_logic;
    enb     : in  std_logic;
    addrb   : in  std_logic_vector(AW-1 downto 0);
    web     : in  std_logic_vector(N_COL-1 downto 0);
    dinb    : in  std_logic_vector(N_COL*COLW-1 downto 0);
    doutb   : out std_logic_vector(N_COL*COLW-1 downto 0)
  );
end entity tdpram_be;

architecture rtl of tdpram_be is

  constant DW : integer := N_COL*COLW;

  function f_depth return integer is
  begin
    if DEPTH > 0 then
      return minimum(DEPTH, 2**AW);
    else
      return 2**AW;
    end if;
  end function;

  signal mem      : t_slv_array(0 to f_depth-1)(DW-1 downto 0);
  signal clkb_int : std_logic;

begin

  clkb_int <= clka when COMMON_CLK /= 0 else clkb;

  gen_ram_read_first_a : if RAM_MODE_A = RAM_READ_FIRST generate
    p_mem : process(clka)
    begin
      if rising_edge(clka) then
        if ena = '1' then
          douta <= mem(to_integer(unsigned(addra)));
          for i in 0 to N_COL-1 loop
            if wea(i) = '1' then
              mem(to_integer(unsigned(addra)))((i+1)*COLW-1 downto i*COLW) <= dina((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_read_first_a;

  gen_ram_read_first_b : if RAM_MODE_B = RAM_READ_FIRST generate
    p_mem : process(clkb_int)
    begin
      if rising_edge(clkb_int) then
        if enb = '1' then
          doutb <= mem(to_integer(unsigned(addrb)));
          for i in 0 to N_COL-1 loop
            if web(i) = '1' then
              mem(to_integer(unsigned(addrb)))((i+1)*COLW-1 downto i*COLW) <= dinb((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_read_first_b;

  gen_ram_write_first_a : if RAM_MODE_A = RAM_WRITE_FIRST generate
    p_mem : process(clka)
    begin
      if rising_edge(clka) then
        if ena = '1' then
          for i in 0 to N_COL-1 loop
            if wea(i) = '1' then
              mem(to_integer(unsigned(addra)))((i+1)*COLW-1 downto i*COLW) <= dina((i+1)*COLW-1 downto i*COLW);
              douta((i+1)*COLW-1 downto i*COLW) <= dina((i+1)*COLW-1 downto i*COLW);
            else
              douta((i+1)*COLW-1 downto i*COLW) <= mem(to_integer(unsigned(addra)))((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_write_first_a;

  gen_ram_write_first_b : if RAM_MODE_B = RAM_WRITE_FIRST generate
    p_mem : process(clkb_int)
    begin
      if rising_edge(clkb_int) then
        if enb = '1' then
          for i in 0 to N_COL-1 loop
            if web(i) = '1' then
              mem(to_integer(unsigned(addrb)))((i+1)*COLW-1 downto i*COLW) <= dinb((i+1)*COLW-1 downto i*COLW);
              doutb((i+1)*COLW-1 downto i*COLW) <= dinb((i+1)*COLW-1 downto i*COLW);
            else
              doutb((i+1)*COLW-1 downto i*COLW) <= mem(to_integer(unsigned(addrb)))((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_write_first_b;

  gen_ram_no_change_a : if RAM_MODE_A = RAM_NO_CHANGE generate
    p_mem : process(clka)
    begin
      if rising_edge(clka) then
        if ena = '1' then
          if nor wea = '1' then
            douta <= mem(to_integer(unsigned(addra)));
          end if;
          for i in 0 to N_COL-1 loop
            if wea(i) = '1' then
              mem(to_integer(unsigned(addra)))((i+1)*COLW-1 downto i*COLW) <= dina((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_no_change_a;

  gen_ram_no_change_b : if RAM_MODE_B = RAM_NO_CHANGE generate
    p_mem : process(clkb_int)
    begin
      if rising_edge(clkb_int) then
        if enb = '1' then
          if nor web = '1' then
            doutb <= mem(to_integer(unsigned(addrb)));
          end if;
          for i in 0 to N_COL-1 loop
            if web(i) = '1' then
              mem(to_integer(unsigned(addrb)))((i+1)*COLW-1 downto i*COLW) <= dinb((i+1)*COLW-1 downto i*COLW);
            end if;
          end loop;
        end if;
      end if;
    end process;
  end generate gen_ram_no_change_b;

end architecture;