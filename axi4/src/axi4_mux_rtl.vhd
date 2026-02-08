library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axi4;
use lib_axi4.axi4_pkg.all;

entity axi4_mux_rtl is
  generic (
    N_S_PORTS     : natural := 3;
    MAX_TRANS     : natural := 4;
    AW            : natural := 32;
    DW            : natural := 32;
    IDW           : natural := 1;
    AWUW          : natural := 0;
    WUW           : natural := 0;
    BUW           : natural := 0;
    ARUW          : natural := 0;
    RUW           : natural := 0;
    ASYNC_RESET   : integer := 0;
    BYPASS        : integer := 0;
    AW_SLICE_TYPE : t_reg_slice_type := e_reg_slice_full;
    W_SLICE_TYPE  : t_reg_slice_type := e_reg_slice_full;
    B_SLICE_TYPE  : t_reg_slice_type := e_reg_slice_spill;
    AR_SLICE_TYPE : t_reg_slice_type := e_reg_slice_full;
    R_SLICE_TYPE  : t_reg_slice_type := e_reg_slice_spill
  );
  port (
    aclk          : in  std_logic;
    aresetn       : in  std_logic;

    s_axi_aw      : in  t_axi_ax_array(N_S_PORTS-1 downto 0)(id(IDW-1 downto 0), addr(AW-1 downto 0), user(AWUW-1 downto 0));
    s_axi_awvalid : in  std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_awready : out std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_w       : in  t_axi_w_array(N_S_PORTS-1 downto 0)(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(WUW-1 downto 0));
    s_axi_wvalid  : in  std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_wready  : out std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_b       : out t_axi_b_array(N_S_PORTS-1 downto 0)(id(IDW-1 downto 0), user(BUW-1 downto 0));
    s_axi_bvalid  : out std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_bready  : in  std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_ar      : in  t_axi_ax_array(N_S_PORTS-1 downto 0)(id(IDW-1 downto 0), addr(AW-1 downto 0), user(ARUW-1 downto 0));
    s_axi_arvalid : in  std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_arready : out std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_r       : out t_axi_r_array(N_S_PORTS-1 downto 0)(id(IDW-1 downto 0), data(DW-1 downto 0), user(RUW-1 downto 0));
    s_axi_rvalid  : out std_logic_vector(N_S_PORTS-1 downto 0);
    s_axi_rready  : in  std_logic_vector(N_S_PORTS-1 downto 0);

    m_axi_aw      : out t_axi_ax(id(IDW+f_log2nz(N_S_PORTS)-1 downto 0), addr(AW-1 downto 0), user(AWUW-1 downto 0));
    m_axi_awvalid : out std_logic;
    m_axi_awready : in  std_logic;
    m_axi_w       : out t_axi_w(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(WUW-1 downto 0));
    m_axi_wvalid  : out std_logic;
    m_axi_wready  : in  std_logic;
    m_axi_b       : in  t_axi_b(id(IDW+f_log2nz(N_S_PORTS)-1 downto 0), user(BUW-1 downto 0));
    m_axi_bvalid  : in  std_logic;
    m_axi_bready  : out std_logic;
    m_axi_ar      : out t_axi_ax(id(IDW+f_log2nz(N_S_PORTS)-1 downto 0), addr(AW-1 downto 0), user(ARUW-1 downto 0));
    m_axi_arvalid : out std_logic;
    m_axi_arready : in  std_logic;
    m_axi_r       : in  t_axi_r(id(IDW+f_log2nz(N_S_PORTS)-1 downto 0), data(DW-1 downto 0), user(RUW-1 downto 0));
    m_axi_rvalid  : in  std_logic;
    m_axi_rready  : out std_logic
  );
end entity;

architecture rtl of axi4_mux_rtl is

  constant IDW_EXT  : integer := f_log2nz(N_S_PORTS);
  constant IDW_OUT  : integer := IDW_EXT + IDW;
  constant AW_DW    : integer := f_axi_ax_width(IDW, AW, AWUW);
  constant W_DW     : integer := f_axi_w_width(DW, WUW);
  constant AR_DW    : integer := f_axi_ax_width(IDW, AW, ARUW);

  -- Slice outputs
  signal axi_aw         : t_axi_ax(id(IDW_OUT-1 downto 0), addr(AW-1 downto 0), user(AWUW-1 downto 0));
  signal axi_awvalid_i  : std_logic;
  signal axi_awready_i  : std_logic;
  signal axi_awvalid_o  : std_logic;
  signal axi_awready_o  : std_logic;
  signal axi_w          : t_axi_w(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(WUW-1 downto 0));
  signal axi_wvalid     : std_logic;
  signal axi_wready     : std_logic;
  signal axi_b          : t_axi_b(id(IDW_OUT-1 downto 0), user(BUW-1 downto 0));
  signal axi_bvalid     : std_logic;
  signal axi_bready     : std_logic;
  signal axi_ar         : t_axi_ax(id(IDW_OUT-1 downto 0), addr(AW-1 downto 0), user(ARUW-1 downto 0));
  signal axi_arvalid    : std_logic;
  signal axi_arready    : std_logic;
  signal axi_r          : t_axi_r(id(IDW_OUT-1 downto 0), data(DW-1 downto 0), user(RUW-1 downto 0));
  signal axi_rvalid     : std_logic;
  signal axi_rready     : std_logic;

  signal awslv          : std_logic_vector(IDW_EXT + AW_DW-1 downto 0);
  signal wslv           : std_logic_vector(W_DW-1 downto 0);
  signal arslv          : std_logic_vector(IDW_EXT + AR_DW-1 downto 0);

  signal wfifo_ready    : std_logic;
  signal wfifo_push     : std_logic;
  signal wfifo_pop      : std_logic;
  signal wfifo_valid    : std_logic;
  signal wfifo_sel      : std_logic_vector(IDW_EXT-1 downto 0);

begin

  i_awtree : entity lib_common.arbiter_tree(rtl)
    generic map (
      N_REQ       => N_S_PORTS,
      DW          => f_axi_ax_width(IDW, AW, AWUW),
      ARB_PRIO    => 2,
      ARB_LOCK    => 1,
      ASYNC_RESET => ASYNC_RESET
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      ext_prio  => (others => '0'),
      ireq      => s_axi_awvalid,
      idata     => f_axi_ax_serialize(s_axi_aw),
      ognt      => s_axi_awready,
      oreq      => axi_awvalid_i,
      odata     => awslv(AW_DW-1 downto 0),
      ignt      => axi_awready_o,
      oidx      => awslv(awslv'high downto AW_DW)
    );
  axi_aw <= f_axi_ax_deserialize(awslv, IDW_OUT, AW, AWUW);

  axi_awvalid_o <= wfifo_ready and axi_awvalid_i;
  axi_awready_o <= wfifo_ready and axi_awready_i;
  wfifo_push <= axi_awvalid_i and axi_awready_i;

  i_wsel_fifo : entity lib_common.fifo(rtl)
  generic map (
    DW            => IDW_EXT,
    DEPTH         => MAX_TRANS,
    FWFT          => 1,
    READ_LATENCY  => 1,
    COMMON_CLK    => 1,
    ASYNC_RESET   => ASYNC_RESET
  )
  port map (
    wclk      => aclk,
    wrst_n    => aresetn,
    wdata     => awslv(awslv'high downto AW_DW),
    we        => wfifo_push,
    wready    => wfifo_ready,
    rclk      => aclk,
    rrst_n    => aresetn,
    rdata     => wfifo_sel,
    ren       => wfifo_pop,
    rvalid    => wfifo_valid
  );
  axi_wvalid <= wfifo_valid and s_axi_wvalid(to_integer(unsigned(wfifo_sel)));
  p_wready_demux : process(all)
  begin
    s_axi_wready <= (others => '0');
    for i in 0 to N_S_PORTS-1 loop
      if i = unsigned(wfifo_sel) then
        s_axi_wready(i) <= wfifo_valid and axi_wready;
      end if;
    end loop;
  end process;
  axi_w <= s_axi_w(to_integer(unsigned(wfifo_sel)));
  wfifo_pop <= axi_wvalid and s_axi_wvalid(to_integer(unsigned(wfifo_sel))) and axi_w.last;

  p_b_demux : process(all)
  begin
    s_axi_bvalid <= (others => '0');
    for i in 0 to N_S_PORTS-1 loop
      if i = unsigned(axi_b.id(IDW_OUT-1 downto IDW)) then
        s_axi_bvalid(i) <= axi_bvalid;
      end if;
    end loop;
  end process;
  axi_bready <= s_axi_bready(to_integer(unsigned(axi_b.id(IDW_OUT-1 downto IDW))));
  s_axi_b <= (others => f_axi_bid_resize(axi_b, IDW));

  i_artree : entity lib_common.arbiter_tree(rtl)
    generic map (
      N_REQ       => N_S_PORTS,
      DW          => f_axi_ax_width(IDW, AW, ARUW),
      ARB_PRIO    => 2,
      ARB_LOCK    => 1,
      ASYNC_RESET => ASYNC_RESET
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      ext_prio  => (others => '0'),
      ireq      => s_axi_arvalid,
      idata     => f_axi_ax_serialize(s_axi_ar),
      ognt      => s_axi_arready,
      oreq      => axi_arvalid,
      odata     => arslv(AR_DW-1 downto 0),
      ignt      => axi_arready,
      oidx      => arslv(arslv'high downto AR_DW)
    );
  axi_ar <= f_axi_ax_deserialize(arslv, IDW_OUT, AW, ARUW);

  p_r_demux : process(all)
  begin
    s_axi_rvalid <= (others => '0');
    for i in 0 to N_S_PORTS-1 loop
      if i = unsigned(axi_r.id(IDW_OUT-1 downto IDW)) then
        s_axi_rvalid(i) <= axi_rvalid;
      end if;
    end loop;
  end process;
  axi_rready <= s_axi_rready(to_integer(unsigned(axi_r.id(IDW_OUT-1 downto IDW))));
  s_axi_r <= (others => f_axi_rid_resize(axi_r, IDW));

  i_slice : entity lib_axi4.axi4_slice(rtl)
    generic map (
      AW            => AW,
      DW            => DW,
      IDW           => IDW_OUT,
      AWUW          => AWUW,
      WUW           => WUW,
      BUW           => BUW,
      ARUW          => ARUW,
      RUW           => RUW,
      RESET_DATA    => 0,
      ASYNC_RESET   => ASYNC_RESET,
      BYPASS        => BYPASS,
      AW_SLICE_TYPE => AW_SLICE_TYPE,
      W_SLICE_TYPE  => W_SLICE_TYPE,
      B_SLICE_TYPE  => B_SLICE_TYPE,
      AR_SLICE_TYPE => AR_SLICE_TYPE,
      R_SLICE_TYPE  => R_SLICE_TYPE
    )
    port map (
      aclk          => aclk,
      aresetn       => aresetn,

      s_axi_aw      => axi_aw,
      s_axi_awvalid => axi_awvalid_o,
      s_axi_awready => axi_awready_i,
      s_axi_w       => axi_w,
      s_axi_wvalid  => axi_wvalid,
      s_axi_wready  => axi_wready,
      s_axi_b       => axi_b,
      s_axi_bvalid  => axi_bvalid,
      s_axi_bready  => axi_bready,
      s_axi_ar      => axi_ar,
      s_axi_arvalid => axi_arvalid,
      s_axi_arready => axi_arready,
      s_axi_r       => axi_r,
      s_axi_rvalid  => axi_rvalid,
      s_axi_rready  => axi_rready,

      m_axi_aw      => m_axi_aw,
      m_axi_awvalid => m_axi_awvalid,
      m_axi_awready => m_axi_awready,
      m_axi_w       => m_axi_w,
      m_axi_wvalid  => m_axi_wvalid,
      m_axi_wready  => m_axi_wready,
      m_axi_b       => m_axi_b,
      m_axi_bvalid  => m_axi_bvalid,
      m_axi_bready  => m_axi_bready,
      m_axi_ar      => m_axi_ar,
      m_axi_arvalid => m_axi_arvalid,
      m_axi_arready => m_axi_arready,
      m_axi_r       => m_axi_r,
      m_axi_rvalid  => m_axi_rvalid,
      m_axi_rready  => m_axi_rready
    );

end architecture;