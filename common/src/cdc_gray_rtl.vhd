library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_gray is
  generic (
    g_width       : positive := 8;
    g_dst_sync_ff : natural range 2 to 12 := 2
  );
  port (
    src_clk   : in  std_logic;
    src_bin   : in  std_logic_vector(g_width-1 downto 0);
    dst_clk   : in  std_logic;
    dst_gray  : out std_logic_vector(g_width-1 downto 0);
    dst_bin   : out std_logic_vector(g_width-1 downto 0)
  );
end entity cdc_gray;

architecture rtl of cdc_gray is

  signal src_gray       : std_logic_vector(g_width-1 downto 0) := (others => '0');
  signal dst_gray_sync  : t_slv_array(g_dst_sync_ff-1 downto 0)(g_width-1 downto 0) := (others => (others => '0'));

begin

  src_gray      <= fn_bin2gray(src_bin) when rising_edge(src_clk);

  dst_gray_sync <= dst_gray_sync(dst_gray_sync'high-1 downto 0) & src_gray when rising_edge(dst_clk);
  dst_gray      <= dst_gray_sync(dst_gray_sync'high);
  dst_bin       <= fn_gray2bin(dst_gray);

end architecture rtl;