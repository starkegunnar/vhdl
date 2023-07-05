library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_grey is
  generic (
    g_data_width    : positive := 8;
    g_ff_stages     : positive := 2;
    g_rst_polarity  : std_logic := '1'
  );
  port (
    src_clk   : in  std_logic;
    src_rst   : in  std_logic := not g_rst_polarity;
    src_bin   : in  std_logic_vector(g_data_width - 1 downto 0);
    dst_clk   : in  std_logic;
    dst_rst   : in  std_logic := not g_rst_polarity;
    dst_grey  : out std_logic_vector(g_data_width - 1 downto 0);
    dst_bin   : out std_logic_vector(g_data_width - 1 downto 0)
  );
end entity cdc_grey;

architecture rtl of cdc_grey is

  signal src_grey       : std_logic_vector(g_data_width - 1 downto 0);

  signal dst_grey_cdc   : t_slv_array(g_ff_stages - 1 downto 0)(g_data_width - 1 downto 0) := (others => (others => '0'));
  signal dst_bin_comb   : std_logic_vector(g_data_width - 1 downto 0);

  attribute shreg_extract : string;
  attribute async_reg     : string;

  attribute shreg_extract of dst_grey_cdc : signal is "no";
  attribute async_reg of dst_grey_cdc : signal is "true";

begin

  p_src_grey : process(src_clk, src_rst)
  begin
    if rising_edge(src_clk) then
      src_grey <= src_bin xor std_logic_vector(shift_right(unsigned(src_bin)));
    end if;
    -- Async reset
    if src_rst = g_rst_polarity then
      src_grey <= (others => '0');
    end if;
  end process;

  p_dst : process(dst_clk, dst_rst)
  begin
    if rising_edge(dst_clk) then
      dst_grey_cdc <= dst_grey_cdc(dst_grey_cdc'high - 1 downto 0) & src_grey;
    end if;
    -- Async reset
    if dst_rst = g_rst_polarity then
      dst_grey_cdc <= (others => (others => '0'));
    end if;
  end process;

  dst_grey  <= dst_grey_cdc(dst_grey_cdc'high);
  p_dst_bin : process(all)
  begin
    dst_bin_comb(dst_bin_comb'high) <= dst_grey_cdc(dst_grey_cdc'high)(dst_bin_comb'high);
    for i in dst_bin_comb'high - 1 downto 0 loop
      dst_bin_comb(i) <= dst_bin_comb(i + 1) xor dst_grey_cdc(dst_grey_cdc'high)(i);
    end loop;
  end process;
  dst_bin <= dst_bin_comb;

end architecture rtl;