library ieee;
use ieee.std_logic_1164.all;

entity cdc_2phase is
  generic (
    type t_data;
    g_reset_data  : boolean := false;
    g_reset_value : t_data;
    g_src_sync_ff : natural range 2 to 12 := 2;
    g_dst_sync_ff : natural range 2 to 12 := 2
  );
  port (
    -- Source clock and reset
    src_clk   : in  std_logic;
    src_rst   : in  std_logic;
    -- Source data and flow control
    src_data  : in  t_data;
    src_valid : in  std_logic;
    src_ready : out std_logic;
    -- Destination clock and reset
    dst_clk   : in  std_logic;
    dst_rst   : in  std_logic;
    -- Destination data and flow control
    dst_data  : out t_data;
    dst_valid : out std_logic;
    dst_ready : in  std_logic
  );
end entity cdc_2phase;

architecture rtl of cdc_2phase is

  signal src_req    : std_logic := '0';
  signal src_ack    : std_logic_vector(g_src_sync_ff-1 downto 0) := (others => '0');
  signal src_data_r : t_data;

  signal dst_ack    : std_logic := '0';
  signal dst_req    : std_logic_vector(g_dst_sync_ff-1 downto 0) := (others => '0');

begin

  -- Ready when req and ack are equal
  src_ready <= src_req xnor src_ack(src_ack'high);

  p_src : process(src_clk)
  begin
    if rising_edge(src_clk) then
      -- Synchronize ack from destination
      src_ack <= src_ack(src_ack'high-1 downto 0) & dst_ack;

      if src_valid = '1' and src_ready = '1' then
        -- Send request when valid and ready are set
        src_req     <= not src_req;
        -- Sample data
        src_data_r  <= src_data;
      end if;

      if src_rst = '1' then
        src_req <= '0';
        src_ack <= (others => '0');
        if g_reset_data then
          src_data_r <= g_reset_value;
        end if;
      end if;
    end if;
  end process;

  p_dst : process(dst_clk)
  begin
    if rising_edge(dst_clk) then
      -- Synchronize request from source
      dst_req <= dst_req(dst_req'high-1 downto 0) & src_req;

      if dst_valid = '0' or dst_ready = '1' then
        -- Data is valid when when req /= ack
        dst_valid <= dst_req(dst_req'high) xor dst_ack;
        if dst_req(dst_req'high) /= dst_ack then
          dst_data  <= src_data_r;
        end if;
        -- Set ack equal to req
        dst_ack   <= dst_req(dst_req'high);
      end if;

      if dst_rst = '1' then
        dst_ack   <= '0';
        dst_req   <= (others => '0');
        dst_valid <= '0';
        if g_reset_data then
          dst_data <= g_reset_value;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;