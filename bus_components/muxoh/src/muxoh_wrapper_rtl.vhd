library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library xil_defaultlib;

entity muxoh_wrapper is
  generic (
    g_dw  : positive := 64;   -- Data bits per select line
    g_sw  : positive := 16;   -- Number of select lines
    g_lw  : positive := 6     -- Native LUT size
  );
  port (
    clk   : in std_logic;
    d     : in  t_slv_array(g_sw-1 downto 0)(g_dw-1 downto 0);  -- Input Data vectors
    s     : in  std_logic_vector(g_sw-1 downto 0);              -- One-hot select vector
    y     : out std_logic_vector(g_dw-1 downto 0)               -- Selected output data
  );
end entity muxoh_wrapper;

architecture rtl of muxoh_wrapper is

  signal d_r    : t_slv_array(g_sw-1 downto 0)(g_dw-1 downto 0);
  signal s_r    : std_logic_vector(g_sw-1 downto 0);
  signal y_comb : std_logic_vector(g_dw-1 downto 0);

begin

  i_mux : entity xil_defaultlib.muxoh(rtl)
  generic map (
    g_dw => g_dw,
    g_sw => g_sw,
    g_lw => g_lw
  )
  port map (
    d => d_r,
    s => s_r,
    y => y_comb
  );

  p_sync : process(clk)
  begin
    if rising_edge(clk) then
      d_r <= d;
      s_r <= s;
      y   <= y_comb;
    end if;
  end process;

end architecture rtl;