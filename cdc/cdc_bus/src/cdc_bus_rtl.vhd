library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_bus is
  generic (
    g_data_width    : positive := 8;
    g_src_ff_stages : natural range 2 to 10 := 2;
    g_dst_ff_stages : natural range 2 to 10 := 2;
    g_rst_polarity  : std_logic := '1'
  );
  port (
    src_clk   : in  std_logic;
    src_rst   : in  std_logic := not g_rst_polarity;
    src_data  : in  std_logic_vector(g_data_width - 1 downto 0);
    src_valid : in  std_logic := '1';
    src_ready : out std_logic := '0';
    dst_clk   : in  std_logic;
    dst_rst   : in  std_logic := not g_rst_polarity;
    dst_data  : out std_logic_vector(g_data_width - 1 downto 0);
    dst_valid : out std_logic := '0';
    dst_ready : in  std_logic := '1'
  );
end entity cdc_bus;

architecture rtl of cdc_bus is

  signal src_ping       : std_logic := '0';
  signal src_data_r     : std_logic_vector(g_data_width - 1 downto 0) := (others => '0');
  signal src_pong_cdc   : std_logic_vector(g_src_ff_stages - 1 downto 0) := (others => '0');
  signal src_pong       : std_logic := '0';
  signal src_ready_int  : std_logic := '0';

  signal dst_ping       : std_logic := '0';
  signal dst_ping_cdc   : std_logic_vector(g_dst_ff_stages - 1 downto 0) := (others => '0');
  signal dst_pong       : std_logic := '0';
  signal dst_valid_int  : std_logic := '0';

  attribute shreg_extract : string;
  attribute async_reg     : string;
  attribute keep          : string;

  attribute shreg_extract of dst_ping_cdc : signal is "no";
  attribute shreg_extract of src_pong_cdc : signal is "no";
  attribute async_reg of dst_ping_cdc : signal is "true";
  attribute async_reg of src_pong_cdc : signal is "true";

begin

  p_src_ping : process(src_clk, src_rst)
  begin
    if rising_edge(src_clk) then
      -- Initiate new handshake if source is valid and ready
      if src_valid = '1' and src_ready_int = '1' then
        src_ping <= not src_ping;
      end if;
      -- Sample data if valid and ready
      if src_valid = '1' and src_ready_int = '1' then
        src_data_r <= src_data;
      end if;
      -- Shift in pong from destination
      (src_pong, src_pong_cdc) <= src_pong_cdc & dst_ping;
    end if;
    -- Async reset
    if src_rst = g_rst_polarity then
      src_ping      <= '0';
      src_pong      <= '0';
      src_pong_cdc  <= (others => '0');
    end if;
  end process;

  src_ready_int <= src_ping xnor src_pong;
  src_ready     <= src_ready_int;

  p_dst : process(dst_clk, dst_rst)
  begin
    if rising_edge(dst_clk) then
      -- Shift in ping from source
      (dst_ping, dst_ping_cdc) <= dst_ping_cdc & src_ping;
      if dst_valid_int = '1' and dst_ready = '0' then
        -- Prevent ping from propagating if destination is stalled
        dst_ping <= dst_ping;
      end if;
      -- Sample ping if destination is not valid, or destination ready is high,
      if dst_valid_int = '0' or dst_ready = '1' then
        -- Valid is set on rising or falling edge of ping
        dst_valid_int <= dst_ping xor dst_ping_cdc(dst_ping_cdc'high);
      end if;
      -- If destination is not valid, or destination ready is high and new value on ping
      -- sample data
      if dst_ping /= dst_ping_cdc(dst_ping_cdc'high) and (dst_valid_int = '0' or dst_ready = '1') then
        dst_data <= src_data_r;
      end if;
    end if;
    -- Async reset
    if dst_rst = g_rst_polarity then
      dst_ping      <= '0';
      dst_ping_cdc  <= (others => '0');
      dst_valid_int <= '0';
    end if;
  end process;

  dst_valid <= dst_valid_int;


end architecture rtl;