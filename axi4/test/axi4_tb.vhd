
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;
use lib_common.random_2008.all;

library lib_axi4;
use lib_axi4.axi4_pkg.all;

entity axi4_tb is
end entity;

architecture tb of axi4_tb is

begin

  p_tb : process
    variable addr       : std_logic_vector(11 downto 0);
    variable strb       : std_logic_vector(7 downto 0);
    variable len        : t_axlen;
    variable size       : t_axsize;
    variable burst      : t_axburst;
    variable incr       : unsigned(7 downto 0);
  begin
    addr  := random(12);
    addr  := random(12);
    len   := "0000" & random(4);
    size  := '0' & random(2);
    burst := AXBURST_FIXED;
    strb  := f_axi_wstrb(addr, size, 64);

    wait for 10 ns;

    for i in 0 to to_integer(unsigned(len)) loop
      addr := f_axi_axaddr_next(addr, len, size, burst);
      strb := f_axi_wstrb(addr, size, 64);
      wait for 10 ns;
    end loop;

    for i in 0 to 9 loop
      addr  := random(12);
      len   := "0000" & random(4);
      size  := '0' & random(2);
      burst := AXBURST_INCR;
      strb := f_axi_wstrb(addr, size, 64);
      wait for 10 ns;

      incr := f_axi_axaddr_incr(size);

      for i in 0 to to_integer(unsigned(len)) loop
        addr := f_axi_axaddr_next(addr, len, size, burst);
        strb := f_axi_wstrb(addr, size, 64);
        wait for 10 ns;
      end loop;
    end loop;

    addr  := random(10) & "00";
    len   := x"07";
    size  := "010";
    burst := AXBURST_WRAP;
    wait for 10 ns;

    incr := f_axi_axaddr_incr(size);

    for i in 0 to to_integer(unsigned(len)) loop
      addr := f_axi_axaddr_next(addr, len, size, burst);
      strb := f_axi_wstrb(addr, size, 64);
      wait for 10 ns;
    end loop;

    wait;
  end process;

end architecture;