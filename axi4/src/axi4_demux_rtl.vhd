library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axi4;
use lib_axi4.axi4_pkg.all;

entity axi4_demux_rtl is
  generic (
    N_M_PORTS     : natural := 3;
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

    s_axi_aw      : in  t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(AWUW-1 downto 0));
    s_axi_awsel   : in  std_logic_vector(f_log2nz(N_M_PORTS)-1 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    s_axi_w       : in  t_axi_w(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(WUW-1 downto 0));
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    s_axi_b       : out t_axi_b(id(IDW-1 downto 0), user(BUW-1 downto 0));
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    s_axi_ar      : in  t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(ARUW-1 downto 0));
    s_axi_arsel   : in  std_logic_vector(f_log2nz(N_M_PORTS)-1 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    s_axi_r       : out t_axi_r(id(IDW-1 downto 0), data(DW-1 downto 0), user(RUW-1 downto 0));
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic;

    m_axi_aw      : out t_axi_ax_array(N_M_PORTS-1 downto 0)(id(IDW-1 downto 0), addr(AW-1 downto 0), user(AWUW-1 downto 0));
    m_axi_awvalid : out std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_awready : in  std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_w       : out t_axi_w_array(N_M_PORTS-1 downto 0)(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(WUW-1 downto 0));
    m_axi_wvalid  : out std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_wready  : in  std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_b       : in  t_axi_b_array(N_M_PORTS-1 downto 0)(id(IDW-1 downto 0), user(BUW-1 downto 0));
    m_axi_bvalid  : in  std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_bready  : out std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_ar      : out t_axi_ax_array(N_M_PORTS-1 downto 0)(id(IDW-1 downto 0), addr(AW-1 downto 0), user(ARUW-1 downto 0));
    m_axi_arvalid : out std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_arready : in  std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_r       : in  t_axi_r_array(N_M_PORTS-1 downto 0)(id(IDW-1 downto 0), data(DW-1 downto 0), user(RUW-1 downto 0));
    m_axi_rvalid  : in  std_logic_vector(N_M_PORTS-1 downto 0);
    m_axi_rready  : out std_logic_vector(N_M_PORTS-1 downto 0)
  );
end entity;

architecture rtl of axi4_demux_rtl is

  constant N_IDC  : integer := 2**IDW;
  constant CW     : integer := f_log2nz(MAX_TRANS)+1;
  constant SELW   : integer := f_log2nz(N_M_PORTS);
  constant B_DW   : integer := f_axi_b_width(IDW, BUW);
  constant R_DW   : integer := f_axi_r_width(IDW, DW, RUW);

  type t_axsel_array is array(0 to N_IDC-1) of std_logic_vector(SELW-1 downto 0);
  type t_axcounter_array is array(0 to N_IDC-1) of unsigned(CW-1 downto 0);

  -- Slice outputs
  signal axi_aw       : t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(AWUW-1 downto 0));
  signal axi_awsel    : std_logic_vector(f_log2nz(N_M_PORTS)-1 downto 0);
  signal axi_awvalid  : std_logic;
  signal axi_awready  : std_logic;
  signal axi_w        : t_axi_w(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(WUW-1 downto 0));
  signal axi_wvalid   : std_logic;
  signal axi_wready   : std_logic;
  signal axi_b        : t_axi_b(id(IDW-1 downto 0), user(BUW-1 downto 0));
  signal axi_bvalid   : std_logic;
  signal axi_bready   : std_logic;
  signal axi_ar       : t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(ARUW-1 downto 0));
  signal axi_arsel    : std_logic_vector(f_log2nz(N_M_PORTS)-1 downto 0);
  signal axi_arvalid  : std_logic;
  signal axi_arready  : std_logic;
  signal axi_r        : t_axi_r(id(IDW-1 downto 0), data(DW-1 downto 0), user(RUW-1 downto 0));
  signal axi_rvalid   : std_logic;
  signal axi_rready   : std_logic;

  signal bslv         : std_logic_vector(B_DW-1 downto 0);
  signal rslv         : std_logic_vector(R_DW-1 downto 0);

  type t_reg is record
    awidselects   : t_axsel_array;
    awidcounters  : t_axcounter_array;
    wcount        : unsigned(CW-1 downto 0);
    wselect       : std_logic_vector(SELW-1 downto 0);
    wselect_valid : std_logic;
    aridselects   : t_axsel_array;
    aridcounters  : t_axcounter_array;
  end record;

  constant RST : t_reg := (
    awidselects   => (others => (others => '0')),
    awidcounters  => (others => (others => '0')),
    wcount        => (others => '0'),
    wselect       => (others => '0'),
    wselect_valid => '0',
    aridselects   => (others => (others => '0')),
    aridcounters  => (others => (others => '0'))
  );

  signal q, d : t_reg;

begin

  i_slice : entity lib_axi4.axi4_slice(rtl)
    generic map (
      AW            => AW,
      DW            => DW,
      IDW           => IDW,
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

      s_axi_aw      => s_axi_aw,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_w       => s_axi_w,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_b       => s_axi_b,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,
      s_axi_ar      => s_axi_ar,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_r       => s_axi_r,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready,

      m_axi_aw      => axi_aw,
      m_axi_awvalid => axi_awvalid,
      m_axi_awready => axi_awready,
      m_axi_w       => axi_w,
      m_axi_wvalid  => axi_wvalid,
      m_axi_wready  => axi_wready,
      m_axi_b       => axi_b,
      m_axi_bvalid  => axi_bvalid,
      m_axi_bready  => axi_bready,
      m_axi_ar      => axi_ar,
      m_axi_arvalid => axi_arvalid,
      m_axi_arready => axi_arready,
      m_axi_r       => axi_r,
      m_axi_rvalid  => axi_rvalid,
      m_axi_rready  => axi_rready
    );

  i_awsel_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => SELW,
      RESET_DATA  => 0,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS,
      SLICE_TYPE  => AW_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => s_axi_awsel,
      s_valid   => s_axi_awvalid,
      s_ready   => s_axi_awready,
      m_data    => axi_awsel,
      m_valid   => axi_awvalid,
      m_ready   => axi_awready
    );

  i_arsel_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => SELW,
      RESET_DATA  => 0,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS,
      SLICE_TYPE  => AR_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => s_axi_arsel,
      s_valid   => s_axi_arvalid,
      s_ready   => s_axi_arready,
      m_data    => axi_arsel,
      m_valid   => axi_arvalid,
      m_ready   => axi_arready
    );

  p_aw : process(all)
    procedure pr_idcounters(
      axsel     : in    std_logic_vector(SELW-1 downto 0);
      push_id   : in    std_logic_vector(IDW-1 downto 0);
      push      : in    std_logic;
      pop_id    : in    std_logic_vector(IDW-1 downto 0);
      pop       : in    std_logic;
      counters  : inout t_axcounter_array;
      selects   : inout t_axsel_array
    ) is
      variable vpush : std_logic;
      variable vpop  : std_logic;
    begin
      for i in 0 to N_IDC-1 loop
        vpush := f_cond(i = unsigned(push_id), push, '0');
        vpop  := f_cond(i = unsigned(pop_id), pop, '0');
        if vpush = '1' and counters(i) = 0 then
          selects(i) := axsel;
        end if;
        if vpush = '1' and vpop = '0' then
          counters(i) := counters(i) + 1;
        elsif vpush = '0' and vpop = '1' then
          counters(i) := counters(i) - 1;
        end if;
      end loop;
    end procedure;

    procedure pr_idsel(
      axid      : in  std_logic_vector(IDW-1 downto 0);
      axsel     : in  std_logic_vector(SELW-1 downto 0);
      counters  : in  t_axcounter_array;
      selects   : in  t_axsel_array;
      match     : out std_logic;
      ready     : out std_logic
    ) is
    begin
      match := '0';
      ready := '0';
      for i in 0 to N_IDC-1 loop
        if unsigned(axid) = i then
          if axsel = selects(i) or counters(i) = 0 then
            match := '1';
          end if;
          ready := not std_logic(counters(i)(CW-1));
        end if;
      end loop;
    end procedure;

    variable v          : t_reg;
    variable awvalid    : std_logic;
    variable awready    : std_logic;
    variable awmatch    : std_logic;
    variable awidready  : std_logic;
    variable awpush     : std_logic;
    variable wselect    : std_logic_vector(SELW-1 downto 0);
    variable wvalid     : std_logic;
    variable wready     : std_logic;
    variable arvalid    : std_logic;
    variable arready    : std_logic;
    variable armatch    : std_logic;
    variable aridready  : std_logic;
    variable arpush     : std_logic;
    variable wpop       : std_logic;
    variable bpop       : std_logic;
    variable rpop       : std_logic;
  begin
    v := q;

    awvalid := '0';
    awready := '0';
    for i in 0 to N_M_PORTS-1 loop
      if i = unsigned(axi_awsel) then
        awready := m_axi_awready(i);
      end if;
    end loop;

    pr_idsel(axi_aw.id, axi_awsel, q.awidcounters, q.awidselects, awmatch, awidready);

    wselect := f_cond(q.wselect_valid = '1', q.wselect, axi_awsel);
    wready  := '0';

    if axi_awvalid = '1' and
       (q.wcount = 0 or q.wselect = axi_awsel) and
       (awidready = '1' or awmatch = '1') then
      awvalid   := '1';
      v.wselect := axi_awsel;
      if awready = '1' then
        awpush  := '1';
      end if;
    end if;

    wvalid  := (awpush or q.wselect_valid) and axi_wvalid;
    for i in 0 to N_M_PORTS-1 loop
      if i = unsigned(wselect) then
        wready := m_axi_wready(i);
      end if;
    end loop;
    wpop    := wvalid and wready and axi_w.last;
    if awpush = '1' and wpop = '0' then
      v.wcount        := q.wcount + 1;
      v.wselect_valid := '1';
    elsif awpush = '0' and wpop = '1' then
      v.wcount := q.wcount - 1;
      if q.wcount = 1 then
        v.wselect_valid := '0';
      end if;
    end if;

    bpop := axi_bvalid and axi_bready;

    pr_idcounters(axi_awsel, axi_aw.id, awpush, axi_b.id, bpop, v.awidcounters, v.awidselects);

    arvalid     := '0';
    arready     := '0';

    pr_idsel(axi_ar.id, axi_arsel, q.aridcounters, q.aridselects, armatch, aridready);

    if axi_arvalid = '1' and
          (aridready = '1' or armatch = '1') then
      arvalid := '1';
      if arready = '1' then
        arpush  := '1';
      end if;
    end if;

    rpop := axi_rvalid and axi_rready and axi_r.last;

    pr_idcounters(axi_arsel, axi_ar.id, arpush, axi_r.id, rpop, v.aridcounters, v.aridselects);

    if ASYNC_RESET = 0 and aresetn = '0' then
      v := RST;
    end if;

    d <= v;

    -- Demux AW
    m_axi_awvalid <= (others => '0');
    for i in 0 to N_M_PORTS-1 loop
      if i = unsigned(axi_awsel) then
        m_axi_awvalid(i) <= awvalid;
      end if;
    end loop;
    if awvalid = '1' then
      axi_awready <= awready;
    end if;
    m_axi_aw <= (others => axi_aw);

    -- Demux W
    m_axi_wvalid <= (others => '0');
    for i in 0 to N_M_PORTS-1 loop
      if i = unsigned(wselect) then
        m_axi_wvalid(i) <= wvalid;
      end if;
    end loop;
    if wvalid = '1' then
      axi_wready <= wready;
    end if;
    m_axi_w <= (others => axi_w);

    -- Demux AR
    m_axi_arvalid <= (others => '0');
    for i in 0 to N_M_PORTS-1 loop
      if i = unsigned(axi_arsel) then
        m_axi_arvalid(i) <= arvalid;
      end if;
    end loop;
    if arvalid = '1' then
      axi_arready <= arready;
    end if;
    m_axi_ar <= (others => axi_ar);

  end process;

  p_reg : process(aclk, aresetn)
  begin
    if ASYNC_RESET /= 0 and aresetn = '0' then
      q <= RST;
    elsif rising_edge(aclk) then
      q <= d;
    end if;
  end process;

  i_btree : entity lib_common.arbiter_tree(rtl)
    generic map (
      N_REQ       => N_M_PORTS,
      DW          => B_DW,
      ARB_PRIO    => 2,
      ARB_LOCK    => 1,
      ASYNC_RESET => ASYNC_RESET
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      ext_prio  => (others => '0'),
      ireq      => m_axi_bvalid,
      idata     => f_axi_b_serialize(m_axi_b),
      ognt      => m_axi_bready,
      oreq      => axi_bvalid,
      odata     => bslv,
      ignt      => axi_bready,
      oidx      => open
    );
  axi_b <= f_axi_b_deserialize(bslv, IDW, BUW);

  i_rtree : entity lib_common.arbiter_tree(rtl)
    generic map (
      N_REQ       => N_M_PORTS,
      DW          => R_DW,
      ARB_PRIO    => 2,
      ARB_LOCK    => 1,
      ASYNC_RESET => ASYNC_RESET
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      ext_prio  => (others => '0'),
      ireq      => m_axi_rvalid,
      idata     => f_axi_r_serialize(m_axi_r),
      ognt      => m_axi_rready,
      oreq      => axi_rvalid,
      odata     => rslv,
      ignt      => axi_rready,
      oidx      => open
    );
    axi_r <= f_axi_r_deserialize(rslv, IDW, DW, RUW);

end architecture;