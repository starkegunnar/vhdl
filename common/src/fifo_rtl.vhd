library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity fifo is
  generic (
    type t_data;
    g_depth               : positive;
    g_read_latency        : natural range 0 to 2  := 2;
    g_prog_full_thresh    : natural               := 0;
    g_prog_empty_thresh   : natural               := 0;
    g_common_clock        : boolean;
    g_s_sync_ff           : natural range 2 to 12 := 2;
    g_m_sync_ff           : natural range 2 to 12 := 2

  );
  port (
    -- Clock and reset
    -- Subordinate interface
    s_clk           : in  std_logic;
    s_rst           : in  std_logic;
    s_data          : in  t_data;
    s_valid         : in  std_logic;
    s_ready         : out std_logic;
    s_full          : out std_logic;
    s_prog_ready    : out std_logic;
    s_prog_full     : out std_logic;
    -- Manager interface
    m_clk           : in  std_logic;
    m_data          : out t_data;
    m_valid         : out std_logic;
    m_empty         : out std_logic;
    m_prog_valid    : out std_logic;
    m_prog_empty    : out std_logic;
    m_ready         : in  std_logic
  );
end entity fifo;

architecture rtl of fifo is

  constant c_aw       : natural := fn_log2(g_depth);
  constant c_cw       : natural := c_aw+1;
  constant c_depth    : natural := fn_ceil_pow2(g_depth);

  type t_data_array is array(natural range <>) of t_data;

  signal s_clk_int, m_clk_int : std_logic;
  signal s_rst_int, m_rst_int : std_logic;

  signal mem                  : t_data_array(0 to c_depth);
  signal waddr, raddr         : std_logic_vector(c_aw-1 downto 0);
  signal s_wcount, s_rcount   : std_logic_vector(c_cw-1 downto 0);
  signal m_wcount, m_rcount   : std_logic_vector(c_cw-1 downto 0);
  signal wcount_p1, rcount_p1 : std_logic_vector(c_aw-1 downto 0);

  signal empty, going_empty   : std_logic;
  signal full, going_full     : std_logic;

  signal rdata                : t_data_array(2 downto 0);
  signal rdata_valid          : std_logic_vector(2 downto 0);
  signal rdata_empty          : std_logic_vector(2 downto 0);
  signal rdata_prog_valid     : std_logic_vector(2 downto 0);
  signal rdata_prog_empty     : std_logic_vector(2 downto 0);
  signal rdata_ready          : std_logic_vector(2 downto 0);

begin

  s_clk_int <= s_clk;
  m_clk_int <= s_clk when g_common_clock else m_clk;

  i_wcount : entity lib_common.up_down_counter(rtl)
  generic map (
    g_counter_width => c_cw,
    g_reset_value   => (others => '0')
  )
  port map (
    clk   => s_clk_int,
    rst   => s_rst_int,
    en    => s_valid,
    up    => s_ready,
    down  => '0',
    count => s_wcount
  );

  waddr <= s_wcount(c_aw-1 downto 0);

  i_wcount_p1 : entity lib_common.up_down_counter(rtl)
  generic map (
    g_counter_width => c_aw,
    g_reset_value   => std_logic_vector(to_unsigned(1, c_aw))
  )
  port map (
    clk   => s_clk_int,
    rst   => s_rst_int,
    en    => s_valid,
    up    => s_ready,
    down  => '0',
    count => wcount_p1
  );

  full        <= '1' when s_wcount = (not s_rcount(c_aw) & s_rcount(c_aw-1 downto 0)) else '0';
  going_full  <= s_valid when wcount_p1 = s_rcount(c_aw-1 downto 0) else '0';

  p_write : process(s_clk_int)
  begin
    if rising_edge(s_clk_int) then
      s_ready <= going_full nor full;
      s_full  <= going_full or full;

      if s_ready = '1' then
        mem(to_integer(unsigned(waddr))) <= s_data;
      end if;

      if s_rst_int = '1' then
        s_ready <= '0';
        s_full  <= '1';
      end if;
    end if;
  end process;

  b_counters : if not g_common_clock generate
    signal s_rcount_comb, m_wcount_comb : std_logic_vector(c_cw-1 downto 0) := (others => '0');
  begin
    i_s2m_gray : entity lib_common.cdc_gray(rtl)
    generic map (
      g_width       => c_cw,
      g_dst_sync_ff => g_m_sync_ff
    )
    port map (
      src_clk => s_clk_int,
      src_bin => s_wcount,
      dst_clk => m_clk_int,
      dst_bin => m_wcount_comb
    );

    p_m_wcount : process(m_clk_int)
    begin
      if rising_edge(m_clk_int) then
        if m_rst_int = '1' then
          m_wcount <= (others => '0');
        else
          m_wcount <= m_wcount_comb;
        end if;
      end if;
    end process;

    i_m2s_gray : entity lib_common.cdc_gray(rtl)
    generic map (
      g_width       => c_cw,
      g_dst_sync_ff => g_s_sync_ff
    )
    port map (
      src_clk => m_clk_int_clk_int,
      src_bin => m_rcount,
      dst_clk => s_clk_int,
      dst_bin => s_rcount_comb
    );

    p_s_rcount : process(s_clk_int)
    begin
      if rising_edge(s_clk_int) then
        if s_rst_int = '1' then
          s_rcount <= (others => '0');
        else
          s_rcount <= s_rcount_comb;
        end if;
      end if;
    end process;

  else generate

    s_rcount  <= m_rcount;
    m_wcount  <= s_wcount;
    s_rst_int <= s_rst;
    m_rst_int <= s_rst;

  end generate b_counters;

  i_rcount : entity lib_common.up_down_counter(rtl)
  generic map (
    g_counter_width => c_cw,
    g_reset_value   => (others => '0')
  )
  port map (
    clk   => m_clk_int,
    rst   => m_rst_int,
    en    => rdata_ready(0),
    up    => rdata_valid(0),
    down  => '0',
    count => rcount
  );

  raddr <= rcount(c_aw-1 downto 0);

  i_rcount_p1 : entity lib_common.up_down_counter(rtl)
  generic map (
    g_counter_width => c_aw,
    g_reset_value   => std_logic_vector(to_unsigned(1, c_aw))
  )
  port map (
    clk   => m_clk_int,
    rst   => m_rst_int,
    en    => rdata_ready(0),
    up    => rdata_valid(0),
    down  => '0',
    count => rcount_p1
  );

  empty       <= '1' when rcount = wcount else '0';
  going_empty <= rdata_ready(0) when rcount_p1 = wcount(c_aw-1 downto 0) else '0';

  rdata(0) <= mem(to_integer(unsigned(raddr)));
  rdata_ready(0) <= m_ready when g_read_latency = 0 else
                    rdata_empty(1) or m_ready when g_read_latency = 1 else
                    or rdata_empty(2 downto 1) or m_ready;
  rdata_ready(1) <= m_ready when g_read_latency = 1 else
                    not rdata_empty(2) or m_ready when g_read_latency = 2 else
                    '0';
  rdata_ready(2) <= m_ready when g_read_latency = 2 else '0';

  p_read : process(m_clk_int)
  begin
    if rising_edge(m_clk_int) then
      rdata_valid(0)  <= going_empty nor empty;
      rdata_empty(0)  <= going_empty or empty;

      if rdata_ready(1) = '1' then
        rdata(1)        <= rdata(0);
        rdata_valid(1)  <= rdata_valid(0);
        rdata_empty(1)  <= rdata_empty(0);
      end if;

      if rdata_ready(2) = '1' then
        rdata(2)        <= rdata(1);
        rdata_valid(2)  <= rdata_valid(1);
        rdata_empty(2)  <= rdata_empty(1);
      end if;

      if m_rst_int = '1' then
        rdata_valid <= (others => '0');
        rdata_empty <= (others => '1');
      end if;
    end if;
  end process;

  m_data  <= rdata(g_read_latency);
  m_valid <= rdata_valid(g_read_latency);
  m_empty <= rdata_empty(g_read_latency);

end architecture rtl;