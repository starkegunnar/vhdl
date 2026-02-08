library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axi4;
use lib_axi4.axi4_pkg.all;

entity axi4_slice is
  generic (
    AW            : natural;
    DW            : natural;
    IDW           : natural := 0;
    AWUW          : natural := 0;
    WUW           : natural := 0;
    BUW           : natural := 0;
    ARUW          : natural := 0;
    RUW           : natural := 0;
    RESET_DATA    : integer := 0;
    ASYNC_RESET   : integer := 0;
    BYPASS        : integer := 0;
    AW_SLICE_TYPE : t_reg_slice_type := e_reg_slice_full;
    W_SLICE_TYPE  : t_reg_slice_type := e_reg_slice_full;
    B_SLICE_TYPE  : t_reg_slice_type := e_reg_slice_full;
    AR_SLICE_TYPE : t_reg_slice_type := e_reg_slice_full;
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
    s_axi_rready  : in  std_logic;

    m_axi_aw      : out t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(AWUW-1 downto 0));
    m_axi_awvalid : out std_logic;
    m_axi_awready : in  std_logic;
    m_axi_w       : out t_axi_w(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(WUW-1 downto 0));
    m_axi_wvalid  : out std_logic;
    m_axi_wready  : in  std_logic;
    m_axi_b       : in  t_axi_b(id(IDW-1 downto 0), user(BUW-1 downto 0));
    m_axi_bvalid  : in  std_logic;
    m_axi_bready  : out std_logic;
    m_axi_ar      : out t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(ARUW-1 downto 0));
    m_axi_arvalid : out std_logic;
    m_axi_arready : in  std_logic;
    m_axi_r       : in  t_axi_r(id(IDW-1 downto 0), data(DW-1 downto 0), user(RUW-1 downto 0));
    m_axi_rvalid  : in  std_logic;
    m_axi_rready  : out std_logic
  );
end entity;

architecture rtl of axi4_slice is

  signal s_b  : std_logic_vector(f_axi_b_width(IDW, BUW)-1 downto 0);
  signal s_r  : std_logic_vector(f_axi_r_width(IDW, DW, RUW)-1 downto 0);

  signal m_aw : std_logic_vector(f_axi_ax_width(IDW, AW, AWUW)-1 downto 0);
  signal m_w  : std_logic_vector(f_axi_w_width(DW, WUW)-1 downto 0);
  signal m_ar : std_logic_vector(f_axi_ax_width(IDW, AW, ARUW)-1 downto 0);

begin

  i_aw_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => f_axi_ax_width(IDW, AW, AWUW),
      RESET_DATA  => RESET_DATA,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS,
      SLICE_TYPE  => AW_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => f_axi_ax_serialize(s_axi_aw),
      s_valid   => s_axi_awvalid,
      s_ready   => s_axi_awready,
      m_data    => m_aw,
      m_valid   => m_axi_awvalid,
      m_ready   => m_axi_awready
    );
  m_axi_aw <= f_axi_ax_deserialize(m_aw, IDW, AW, AWUW);

  i_w_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => f_axi_w_width(DW, WUW),
      RESET_DATA  => RESET_DATA,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS,
      SLICE_TYPE  => AW_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => f_axi_w_serialize(s_axi_w),
      s_valid   => s_axi_wvalid,
      s_ready   => s_axi_wready,
      m_data    => m_w,
      m_valid   => m_axi_wvalid,
      m_ready   => m_axi_wready
    );
  m_axi_w <= f_axi_w_deserialize(m_w, DW, WUW);

  i_b_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => f_axi_b_width(IDW, BUW),
      RESET_DATA  => RESET_DATA,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS,
      SLICE_TYPE  => B_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => f_axi_b_serialize(m_axi_b),
      s_valid   => m_axi_bvalid,
      s_ready   => m_axi_bready,
      m_data    => s_b,
      m_valid   => s_axi_bvalid,
      m_ready   => s_axi_bready
    );
  s_axi_b <= f_axi_b_deserialize(s_b, IDW, BUW);

  i_ar_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => f_axi_ax_width(IDW, AW, ARUW),
      RESET_DATA  => RESET_DATA,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS,
      SLICE_TYPE  => AR_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => f_axi_ax_serialize(s_axi_ar),
      s_valid   => s_axi_arvalid,
      s_ready   => s_axi_arready,
      m_data    => m_ar,
      m_valid   => m_axi_arvalid,
      m_ready   => m_axi_arready
    );
  m_axi_ar <= f_axi_ax_deserialize(m_ar, IDW, AW, ARUW);

  i_r_slice : entity lib_common.reg_slice(rtl)
    generic map (
      DW          => f_axi_r_width(IDW, DW, RUW),
      RESET_DATA  => RESET_DATA,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS,
      SLICE_TYPE  => R_SLICE_TYPE
    )
    port map (
      clk       => aclk,
      rst_n     => aresetn,
      s_data    => f_axi_r_serialize(m_axi_r),
      s_valid   => m_axi_rvalid,
      s_ready   => m_axi_rready,
      m_data    => s_r,
      m_valid   => s_axi_rvalid,
      m_ready   => s_axi_rready
    );
  s_axi_r <= f_axi_r_deserialize(s_r, IDW, DW, RUW);

end architecture;