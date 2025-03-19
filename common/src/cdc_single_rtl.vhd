library ieee;
use ieee.std_logic_1164.all;

entity cdc_single is
  generic (
    g_dst_sync_ff : natural range 2 to 12 := 2;
    g_reg_input   : boolean := true;
    g_init_val    : std_logic := '0'
  );
  port (
    -- Source
    src_clk   : in  std_logic;
    src_data  : in  std_logic;
    -- Destination
    dst_clk   : in  std_logic;
    dst_data  : in  std_logic
  );
end entity cdc_single;

architecture rtl of cdc_single is

  signal src_data_reg   : std_logic;
  signal src_data_comb  : std_logic;
  signal dst_data_sync  : std_logic_vector(g_dst_sync_ff-1 downto 0) := (others => g_init_val);

begin

  src_data_reg  <= src_data when rising_edge(src_clk);
  src_data_comb <= src_data_reg when g_reg_input else src_data;

  dst_data_sync <= dst_data_sync(g_dst_sync_ff-2 downto 0) & src_data_comb when rising_edge(dst_clk);
  dst_data      <= dst_data_sync(g_dst_sync_ff-1);


end architecture rtl;