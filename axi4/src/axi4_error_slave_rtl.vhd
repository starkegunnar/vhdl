library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axi4;
use lib_axi4.axi4_pkg.all;

entity axi4_error_slave is
  generic (
    AW            : integer;
    DW            : integer;
    IDW           : integer := 0;
    AWUW          : integer := 0;
    WUW           : integer := 0;
    BUW           : integer := 0;
    ARUW          : integer := 0;
    RUW           : integer := 0;
    ASYNC_RESET   : integer := 0;
    RESP          : t_axresp := AXRESP_DECERR;
    RESP_DATA     : std_logic_vector(DW-1 downto 0) := (others => '0');
    AW_SLICE_TYPE : t_reg_slice_type := e_reg_slice_spill;
    B_SLICE_TYPE  : t_reg_slice_type := e_reg_slice_full;
    AR_SLICE_TYPE : t_reg_slice_type := e_reg_slice_spill;
    R_SLICE_TYPE  : t_reg_slice_type := e_reg_slice_full
  );
  port (
    aclk          : in  std_logic;
    aresetn       : in  std_logic;

    s_axi_aw      : in  t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(AWUW-1 downto 0));
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    s_axi_w       : in  t_axi_w(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(WUW-1 downto 0));
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    s_axi_b       : out t_axi_b(id(IDW-1 downto 0), user(BUW-1 downto 0));
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    s_axi_ar      : in  t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(ARUW-1 downto 0));
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    s_axi_r       : out t_axi_r(id(IDW-1 downto 0), data(DW-1 downto 0), user(RUW-1 downto 0));
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic
  );
end;

architecture rtl of axi4_error_slave is

  signal err_awid     : std_logic_vector(IDW-1 downto 0);
  signal err_awvalid  : std_logic;
  signal err_awready  : std_logic;

  signal err_bvalid   : std_logic;
  signal err_bready   : std_logic;

  signal err_arid     : std_logic_vector(IDW-1 downto 0);
  signal err_arlen    : std_logic_vector(7 downto 0);
  signal err_arvalid  : std_logic;
  signal err_arready  : std_logic;

  signal err_rlast    : std_logic;
  signal err_rvalid   : std_logic;
  signal err_rready   : std_logic;
  signal q, d         : unsigned(7 downto 0);

begin

  i_aw_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => IDW,
      RESET_DATA  => 0,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => 0,
      SLICE_TYPE  => AW_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => s_aw.id,
      s_valid   => s_axi_awvalid,
      s_ready   => s_axi_awready,
      m_data    => err_awid,
      m_valid   => err_awvalid,
      m_ready   => err_awready
    );

  wready      <= err_awvalid and err_bready;
  err_awready <= err_bready and s_axi_wvalid and s_axi_w.last;
  err_bvalid  <= err_awvalid and s_axi_wvalid and s_axi_w.last;

  i_b_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => IDW,
      RESET_DATA  => 0,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => 0,
      SLICE_TYPE  => B_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => err_awid,
      s_valid   => err_bvalid,
      s_ready   => err_bready,
      m_data    => s_axi_b.id,
      m_valid   => s_axi_bvalid,
      m_ready   => s_axi_bready
    );
  s_axi_b.resp <= RESP;
  s_axi_b.user <= (others => '0');

  i_ar_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => IDW + 8,
      RESET_DATA  => 0,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => 0,
      SLICE_TYPE  => AR_SLICE_TYPE
    )
    port map (
      clk                     => aclk,
      rst_n                   => aresetn,
      s_data                  => s_ar.id & s_ar.len,
      s_valid                 => s_axi_awvalid,
      s_ready                 => s_axi_awready,
      m_data(IDW+7 downto 8)  => err_arid,
      m_data(7 downto 0)      => err_arlen,
      m_valid                 => err_awvalid,
      m_ready                 => err_awready
    );

  i_r_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => IDW+1,
      RESET_DATA  => 0,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => 0,
      SLICE_TYPE  => AW_SLICE_TYPE
    )
    port map (
      clk                   => aclk,
      rst_n                 => aresetn,
      s_data                => err_arid & err_rlast,
      s_valid               => err_rvalid,
      s_ready               => err_rready,
      m_data(IDW downto 1)  => s_axi_r.id,
      m_data(0)             => s_axi_r.last,
      m_valid               => s_axi_rvalid,
      m_ready               => s_axi_rready
    );
  s_axi_r.data <= RESP_DATA;
  s_axi_r.resp <= RESP;
  s_axi_r.user <= (others => '0');

  p_comb : process(all)
    variable v        : unsigned(7 downto 0);
    variable rready   : std_logic;
    variable rlast    : std_logic;
  begin
    v := q;

    rready  := '0';
    rlast   := '0';

    if err_arvalid = '1' and err_rready = '1' then
      if q = 0 then
        v := err_arlen;
      else
        v := q - 1;
      end if;
    end if;

    if q = 0 and err_arvalid = '1' then
      rlast   := '1';
      rready  := '1';
    end if;

    d <= v;

    err_arready <= rready and err_rready;
    err_rlast   <= rlast;
  end process;

end architecture;