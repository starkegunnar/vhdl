library ieee;
use ieee.std_logic_1164.all;

entity cdc_4phase is
  generic (
    type t_data;
    g_src_sync_ff : natural range 2 to 12 := 2;
    g_dst_sync_ff : natural range 2 to 12 := 2;
    g_reg_output  : boolean := true
  );
  port (
    -- Source clock and reset
    src_clk   : in  std_logic;
    -- Source data and flow control
    src_data  : in  t_data;
    src_valid : in  std_logic;
    src_ready : out std_logic;
    -- Destination clock and reset
    dst_clk   : in  std_logic;
    -- Destination data and flow control
    dst_data  : out t_data;
    dst_valid : out std_logic;
    dst_ready : in  std_logic
  );
end entity cdc_4phase;

architecture rtl of cdc_4phase is

  signal src_req    : std_logic := '0';
  signal src_ack    : std_logic := '0';
  signal src_data_r : t_data;

  signal dst_ack    : std_logic := '0';
  signal dst_req    : std_logic := '0';

begin

  -- Ready when req and ack are equal
  src_ready <= src_req xnor src_ack;

  p_src : process(src_clk)
  begin
    if rising_edge(src_clk) then
      if src_valid = '1' and src_ready = '1' then
        -- Send request when valid and ready are set
        src_req <= not src_req;
      end if;

      if src_ready = '1' then
        -- Sample data
        src_data_r <= src_data;
      end if;
    end if;
  end process;

  i_cdc_single_req : entity lib_common.cdc_single(rtl)
  generic map (
    g_dst_sync_ff => g_dst_sync_ff,
    g_reg_input   => false,
    g_init_val    => '0',
  )
  port map (
    src_clk       => src_clk,
    src_data      => src_req,
    dst_clk       => dst_clk,
    dst_data      => dst_req,
  );

  i_cdc_single_ack : entity lib_common.cdc_single(rtl)
  generic map (
    g_dst_sync_ff => g_src_sync_ff,
    g_reg_input   => false,
    g_init_val    => '0',
  )
  port map (
    src_clk       => dst_clk,
    src_data      => dst_ack,
    dst_clk       => src_clk,
    dst_data      => src_ack,
  );

  b_dst : if g_reg_output generate
    p_dst : process(dst_clk)
    begin
      if rising_edge(dst_clk) then
        if dst_valid = '0' or dst_ready = '1' then
          -- Data is valid when when req /= ack
          dst_valid <= dst_req xor dst_ack;
          if dst_req /= dst_ack then
            dst_data  <= src_data_r;
          end if;
          -- Set ack equal to req
          dst_ack <= dst_req;
        end if;
      end if;
    end process;
  else generate
    p_dst : process(dst_clk)
    begin
      dst_valid <= dst_req xor dst_ack;
      dst_data  <= src_data_r;
      if rising_edge(dst_clk) then
        if dst_ready = '1' then
          -- Set ack equal to req
          dst_ack <= dst_req;
        end if;
      end if;
    end process;
  end b_dst;

end architecture rtl;