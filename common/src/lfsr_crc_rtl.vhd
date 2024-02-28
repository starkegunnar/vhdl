library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity lfsr_crc is
  generic (
    g_width       : positive;
    g_polynomial  : std_logic_vector
  );
  port (
    crc_in  : in  std_logic_vector(abs(fn_mssb_index(g_polynomial)-g_polynomial'right)-1 downto 0);
    data_in : in  std_logic_vector(g_width-1 downto 0);
    crc_out : out std_logic_vector(abs(fn_mssb_index(g_polynomial)-g_polynomial'right)-1 downto 0)
  );
end entity lfsr_crc;

architecture rtl of lfsr_crc is

  function fn_normalize_polynomial return std_logic_vector is
    variable v_poly_norm : std_logic_vector(g_polynomial'length-1 downto 0);
  begin
    v_poly_norm := g_polynomial;
    for i in v_poly_norm'left downto 1 loop
      if v_poly_norm(i) = '1' then
        return v_poly_norm(i-1 downto 0);
      end if;
    end loop;
    report "Invalid polynomial" severity failure;
    return v_poly_norm;
  end function fn_normalize_polynomial;

  constant c_polynomial : std_logic_vector := fn_normalize_polynomial;

  signal crc : std_logic_vector(crc_out'range) := (others => '0');

begin

  -- Compute next combinational Value
  process(crc_in, data_in)
    variable v : std_logic_vector(c_polynomial'range);
  begin
    v := crc_in(c_polynomial'range);
    for i in g_width-1 downto 0 loop
      v := (v(v'left-1 downto 0) & '0') xor
           (c_polynomial and (c_polynomial'range => (data_in(i) xor v(v'left))));
    end loop;
      crc(v'range) <= v;
  end process;

  cdc_out <= crc;

end architecture rtl;