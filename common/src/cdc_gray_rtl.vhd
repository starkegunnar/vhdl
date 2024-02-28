library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_gray is
  generic (
    g_data_width  : positive := 8;
    g_sync_ff     : natural range 2 to 12 := 2
  );
  port (
    src_clk   : in  std_logic;
    src_rst   : in  std_logic;
    src_en    : in  std_logic;
    src_bin   : in  std_logic_vector(g_data_width-1 downto 0);
    dst_clk   : in  std_logic;
    dst_rst   : in  std_logic;
    dst_gray  : out std_logic_vector(g_data_width-1 downto 0);
    dst_bin   : out std_logic_vector(g_data_width-1 downto 0)
  );
end entity cdc_gray;

architecture rtl of cdc_gray is

  signal src_gray     : std_logic_vector(g_data_width-1 downto 0);

  signal dst_gray_cdc : t_slv_array(g_sync_ff-1 downto 0)(g_data_width-1 downto 0) := (others => (others => '0'));
  signal dst_bin_comb : std_logic_vector(g_data_width-1 downto 0);

begin

  p_src_gray : process(src_clk)
  begin
    if rising_edge(src_clk) then
      if src_en = '1' then
        src_gray <= fn_bin2gray(src_bin);
      end if;
      if src_rst = '1' then
        src_gray <= (others => '0');
      end if;
    end if;
  end process;

  p_dst : process(dst_clk, dst_rst)
  begin
    if rising_edge(dst_clk) then
      dst_gray_cdc <= dst_gray_cdc(dst_gray_cdc'high-1 downto 0) & src_gray;
      if dst_rst = '1' then
        dst_gray_cdc <= (others => (others => '0'));
      end if;
    end if;
  end process;

  dst_gray  <= dst_gray_cdc(dst_gray_cdc'high);
  dst_bin   <= fn_gray2bin(dst_gray_cdc(dst_gray_cdc'high));

end architecture rtl;