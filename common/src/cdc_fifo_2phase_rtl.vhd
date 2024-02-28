library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_fifo_2phase is
  generic (
    type t_data;
    g_log2_depth  : natural range 2 to 31 := 4;
    g_sync_ram    : boolean := true;
    g_reg_output  : boolean := true;
    g_src_sync_ff : natural range 2 to 12 := 2;
    g_dst_sync_ff : natural range 2 to 12 := 2
  );
  port (
    -- Clock and reset
    src_clk   : in  std_logic;
    src_rst   : in  std_logic;
    -- Data and flow control
    src_data  : in  t_data;
    src_valid : in  std_logic;
    src_ready : out std_logic;
    -- Clock and reset
    dst_clk   : in  std_logic;
    dst_rst   : in  std_logic;
    -- Data and flow control
    dst_data  : out t_data;
    dst_valid : out std_logic;
    dst_ready : in  std_logic
  );
end entity cdc_fifo_2phase;

architecture rtl of cdc_fifo_2phase is

  type t_fifo is array(2**g_log2_depth-1 downto 0) of t_data;

  signal we, re       : std_logic;
  signal src_waddr    : unsigned(g_log2_depth downto 0) := (others => '0');
  signal dst_waddr    : unsigned(g_log2_depth downto 0) := (others => '0');
  signal src_raddr    : unsigned(g_log2_depth downto 0) := (others => '0');
  signal dst_raddr    : unsigned(g_log2_depth downto 0) := (others => '0');
  signal fifo         : t_fifo;
  signal empty        : std_logic;
  signal full         : std_logic;
  signal fifo_ren     : std_logic;

  signal mem_data     : t_data;
  signal mem_valid    : std_logic;
  signal mem_ready    : std_logic;

begin

  we <= src_valid and not full;

  p_src : process(src_clk)
  begin
    if rising_edge(src_clk) then
      if we = '1' then
        fifo(to_integer(src_waddr(src_waddr'high-1 downto 0))) <= src_data;

        src_waddr <= src_waddr + 1;
      end if;

      if src_rst = '1' then
        src_waddr <= (others => '0');
      end if;
    end if;
  end process;

  full  <= '1' when src_waddr(src_waddr'high) /= src_raddr(src_raddr'high) and
                    src_waddr(src_waddr'high-1 downto 0) = src_raddr(src_raddr'high-1 downto 0) else '0';

  src_ready <= not full;

  i_cdc_waddr_src2dst : entity lib_common.cdc_2phase(rtl)
  generic map (
    t_data        => unsigned(g_log2_depth downto 0),
    g_reset_data  => true,
    g_reset_value => (others => '0'),
    g_src_sync_ff => g_src_sync_ff,
    g_dst_sync_ff => g_dst_sync_ff
  )
  port map (
    src_clk   => src_clk,
    src_rst   => src_rst,
    src_data  => src_waddr,
    src_valid => '1',
    src_ready => open,
    dst_clk   => dst_clk,
    dst_rst   => dst_rst,
    dst_data  => dst_waddr,
    dst_valid => open,
    dst_ready => '1'
  );

  i_cdc_raddr_dst2src : entity lib_common.cdc_2phase(rtl)
  generic map (
    t_data        => unsigned(g_log2_depth downto 0),
    g_reset_data  => true,
    g_reset_value => (others => '0'),
    g_src_sync_ff => g_dst_sync_ff,
    g_dst_sync_ff => g_src_sync_ff
  )
  port map (
    src_clk   => dst_clk,
    src_rst   => dst_rst,
    src_data  => dst_raddr,
    src_valid => '1',
    src_ready => open,
    dst_clk   => src_clk,
    dst_rst   => src_rst,
    dst_data  => src_raddr,
    dst_valid => open,
    dst_ready => '1'
  );

  empty <= '1' when dst_raddr = dst_waddr else '0';

  re <= fifo_ren and not empty;

  p_dst : process(dst_clk)
  begin
    if rising_edge(dst_clk) then
      if re = '1' then
        dst_raddr <= dst_raddr + 1;
      end if;

      if dst_rst = '1' then
        dst_raddr <= (others => '0');
      end if;
    end if;
  end process;

  b_sync_ram : if g_sync_ram generate
    i_reg_slice_fallthrough : entity lib_common.reg_slice_fallthrough(rtl)
    generic map (
      t_data => t_data
    )
    port map (
      clk       => dst_clk,
      rst       => dst_rst,
      s_data    => fifo(to_integer(dst_raddr(dst_raddr'high-1 downto 0))),
      s_valid   => not empty,
      s_ready   => fifo_ren,
      m_data    => mem_data,
      m_valid   => mem_valid,
      m_ready   => mem_ready
    );
  else generate
    mem_data  <= fifo(to_integer(dst_raddr(dst_raddr'high-1 downto 0)));
    mem_valid <= not empty;
    fifo_ren  <= mem_ready;
  end generate b_sync_ram;

  b_reg_output : if g_reg_output generate
    i_reg_slice_fallthrough : entity lib_common.reg_slice_fallthrough(rtl)
    generic map (
      t_data => t_data
    )
    port map (
      clk       => dst_clk,
      rst       => dst_rst,
      s_data    => mem_data,
      s_valid   => mem_valid,
      s_ready   => mem_ready,
      m_data    => dst_data,
      m_valid   => dst_valid,
      m_ready   => dst_ready
    );
  else generate
    dst_data    <= mem_data;
    dst_valid   <= mem_valid;
    mem_ready   <= dst_ready;
  end generate b_reg_output;

end architecture rtl;