library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_single_array is
  generic (
    g_width       : positive := 8;
    g_dst_sync_ff : natural range 2 to 12 := 2;
    g_reg_input   : boolean := true;
    g_init_val    : std_logic_vector(g_width-1 downto 0) := (others => '0')
  );
  port (
    src_clk   : in  std_logic;
    src_data  : in  std_logic_vector(g_width-1 downto 0);
    dst_clk   : in  std_logic;
    dst_data  : out std_logic_vector(g_width-1 downto 0)
  );
end entity cdc_single_array;

architecture rtl of cdc_single_array is

begin

  b_cdc_single_array : for i in 0 to g_width-1 generate
    i_cdc_single : entity lib_common.cdc_single(rtl)
    generic map (
      g_dst_sync_ff => g_dst_sync_ff,
      g_reg_input   => g_reg_input,
      g_init_val    => g_init_val(i),
    )
    port map (
      src_clk       => src_clk,
      src_data      => src_data(i),
      dst_clk       => dst_clk,
      dst_data      => dst_data(i),
    );
  end generate b_cdc_single_array;

end architecture rtl;