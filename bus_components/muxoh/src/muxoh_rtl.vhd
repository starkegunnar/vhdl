library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

Library unisim;
use unisim.vcomponents.all;

entity muxoh is
  generic (
    g_dw  : positive        := 32;      -- Data bits per select line
    g_sw  : positive        := 12;      -- Number of select lines
    g_lw  : positive        := 6;       -- Native LUT size
    g_opt : t_optimization  := opt_none -- Optimizations
  );
  port (
    d     : in  t_slv_array(g_sw-1 downto 0)(g_dw-1 downto 0);  -- Input Data vectors
    s     : in  std_logic_vector(g_sw-1 downto 0);              -- One-hot select vector
    y     : out std_logic_vector(g_dw-1 downto 0)               -- Selected output data
  );
end entity muxoh;

architecture rtl of muxoh is

  constant c_bpl  : positive := fn_max(g_lw/2, 1);        -- Buses per LUT
  constant c_nl   : positive := fn_ceil_div(g_sw, c_bpl); -- Number of LUTs
  constant c_nc4  : positive := fn_ceil_div(c_nl, 4);     -- Number of CARRY4
  constant c_ones : unsigned(c_nl-1 downto 0) := (others => '1');

  -- Signals
  -- Data reordered to select lines
  signal ds   : t_slv_array(g_dw-1 downto 0)(g_sw-1 downto 0);
  signal sel  : t_slv_array(g_dw-1 downto 0)(g_sw-1 downto 0);

begin

  p_ds_map : process(d)
  begin
    for i in 0 to g_dw-1 loop
      for j in 0 to g_sw-1 loop
        ds(i)(j) <= d(j)(i);
      end loop;
    end loop;
  end process;

  p_sel_map : process(s)
  begin
    for i in 0 to g_dw-1 loop
      for j in 0 to g_sw-1 loop
        sel(i)(j) <= s(j);
      end loop;
    end loop;
  end process;

  b_sel : if g_sw > 1 generate
    b_ds : for i in 0 to g_dw-1 generate
      signal l  : std_logic_vector(c_nl-1 downto 0);
      signal cy : std_logic_vector(c_nl downto 0);
    begin
      b_luts : for j in 0 to c_nl-1 generate
        constant c_bits     : positive := fn_min(c_bpl, g_sw-j*c_bpl);
        subtype t_lut_range is natural range j*c_bpl+c_bits-1 downto j*c_bpl;
      begin
        l(j) <= or_reduce(ds(i)(t_lut_range) and sel(i)(t_lut_range));
      end generate b_luts;

      b_opt: case g_opt generate
      when opt_xilinx_7series =>
        b_carry4 : for k in 0 to fn_ceil_div(l'length, 4)-1 generate
          constant c_bits : positive := fn_min(4, l'length-k*c_bpl);
          subtype t_c4_range is natural range k*4+c_bits-1 downto k*4;
          signal ci       : std_logic;
          signal co       : std_logic_vector(3 downto 0) := (others => '0');
          signal cs       : std_logic_vector(3 downto 0) := (others => '0');
        begin
          ci <= '0' when k = 0 else co(4*k-1);
          cs(c_bits-1 downto 0) <= l(t_c4_range);
          i_carry4 : carry4
          port map (
            CO      => co,              -- 4-bit carry out
            O       => open,            -- 4-bit carry chain XOR data out
            CI      => ci,              -- 1-bit carry cascade input
            CYINIT  => '0',             -- 1-bit carry initialization
            DI      => (others => '1'), -- 4-bit carry-MUX data in
            S       => cs               -- 4-bit carry-MUX select input
          );
          cy(k*4+c_bits downto k*4+1) <= co(c_bits-1 downto 0);
        end generate b_carry4;
      when opt_xilinx_ultrascale =>
        b_carry8 : for k in 0 to fn_ceil_div(l'length, 8)-1 generate
          constant c_bits : positive := fn_min(8, l'length-k*c_bpl);
          subtype t_c8_range is natural range k*8+c_bits-1 downto k*8;
          signal ci       : std_logic;
          signal co       : std_logic_vector(7 downto 0) := (others => '0');
          signal cs       : std_logic_vector(7 downto 0) := (others => '0');
        begin
          ci <= '0' when k = 0 else co(8*k-1);
          cs(c_bits-1 downto 0) <= l(t_c8_range);
          i_carry8 : carry8
          generic map (
            CARRY_TYPE => "SINGLE_CY8"  -- 8-bit or dual 4-bit carry (DUAL_CY4, SINGLE_CY8)
          )
          port map (
            CO      => co,              -- 8-bit carry out
            O       => open,            -- 8-bit carry chain XOR data out
            CI      => ci,              -- 1-bit input: Lower Carry-In
            CI_TOP  => '0',             -- 1-bit input: Upper Carry-In
            DI      => (others => '1'), -- 8-bit carry-MUX data in
            S       => cs               -- 8-bit carry-MUX select input
          );
          cy(k*8+c_bits downto k*8+1) <= co(c_bits-1 downto 0);
        end generate b_carry8;
      when others =>
        cy <= std_logic_vector(unsigned('0' & l) + c_ones);
      end generate b_opt;

      y(i) <= cy(c_nl) when c_nl > 1 else l(0);

    end generate b_ds;
  else generate
    y <= d(0);
  end generate b_sel;

end architecture rtl;