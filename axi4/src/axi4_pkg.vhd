library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

--! AXI4 package
--!
package axi4_pkg is

  -- Signal     Source  Description
  -- AWID       Master  Identification tag for a write transaction.
  -- AWADDR     Master  The address of the first transfer in a write transaction.
  -- AWLEN      Master  Length, the exact number of data transfers in a write transaction.
  --                    This information determines the number of data transfers associated
  --                    with the address.
  -- AWSIZE     Master  Size, the number of bytes in each data transfer in a write transaction.
  -- AWBURST    Master  Burst type, indicates how address changes between each transfer in a write
  --                    transaction.
  -- AWLOCK     Master  Provides information about the atomic characteristics of a write transaction.
  -- AWCACHE    Master  Indicates how a write transaction is required to progress through a system.
  -- AWPROT     Master  Protection attributes of a write transaction: privilege, security level,
  --                    and access type.
  -- AWQOS      Master  Quality of Service identifier for a write transaction.
  -- AWREGION   Master  Region indicator for a write transaction.
  -- AWUSER     Master  User-defined extension for the write address channel.

  constant AXI_AW_MAX         : natural := 64;
  constant AXI_DW_MAX         : natural := 1024;
  constant AXI_BURST_LIMIT    : natural := 4096;

  constant AXI_DW_8           : natural := 8;
  constant AXI_DW_16          : natural := 16;
  constant AXI_DW_32          : natural := 32;
  constant AXI_DW_64          : natural := 64;
  constant AXI_DW_128         : natural := 128;
  constant AXI_DW_256         : natural := 256;
  constant AXI_DW_512         : natural := 512;
  constant AXI_DW_1024        : natural := AXI_DW_MAX;

  subtype t_axlen is std_logic_vector(7 downto 0);

  subtype t_axsize is std_logic_vector(2 downto 0);

  constant AXSIZE_BYTE        : t_axsize := "000";
  constant AXSIZE_HWORD       : t_axsize := "001";
  constant AXSIZE_WORD        : t_axsize := "010";
  constant AXSIZE_DWORD       : t_axsize := "011";
  constant AXSIZE_QWORD       : t_axsize := "100";
  constant AXSIZE_32B         : t_axsize := "101";
  constant AXSIZE_64B         : t_axsize := "110";
  constant AXSIZE_128B        : t_axsize := "111";

  constant AXSIZE_BYTE_INT    : integer := to_integer(unsigned(AXSIZE_BYTE));
  constant AXSIZE_HWORD_INT   : integer := to_integer(unsigned(AXSIZE_HWORD));
  constant AXSIZE_WORD_INT    : integer := to_integer(unsigned(AXSIZE_WORD));
  constant AXSIZE_DWORD_INT   : integer := to_integer(unsigned(AXSIZE_DWORD));
  constant AXSIZE_QWORD_INT   : integer := to_integer(unsigned(AXSIZE_QWORD));
  constant AXSIZE_32B_INT     : integer := to_integer(unsigned(AXSIZE_32B));
  constant AXSIZE_64B_INT     : integer := to_integer(unsigned(AXSIZE_64B));
  constant AXSIZE_128B_INT    : integer := to_integer(unsigned(AXSIZE_128B));

  subtype t_axburst is std_logic_vector(1 downto 0);

  constant AXBURST_FIXED      : t_axburst := "00";
  constant AXBURST_INCR       : t_axburst := "01";
  constant AXBURST_WRAP       : t_axburst := "10";
  constant AXBURST_RESERVED   : t_axburst := "11";

  constant AXLOCK_NORMAL      : std_logic := '0';
  constant AXLOCK_EXCLUSIVE   : std_logic := '1';

  subtype t_axcache is std_logic_vector(3 downto 0);

  constant AXCACHE_BUFFERABLE : t_axcache := "0001";
  constant AXCACHE_MODIFIABLE : t_axcache := "0010";
  constant AWCACHE_OTHR_ALLOC : t_axcache := "0100";
  constant ARCACHE_ALLOCATE   : t_axcache := "0100";
  constant AWCACHE_ALLOCATE   : t_axcache := "1000";
  constant ARCACHE_OTHR_ALLOC : t_axcache := "1000";

  subtype t_axprot is std_logic_vector(2 downto 0);

  constant AXPROT_PRIVILEDGED : t_axprot := "001";
  constant AXPROT_NON_SECURE  : t_axprot := "010";
  constant AXPROT_INSTRUCTION : t_axprot := "100";

  subtype t_axqos is std_logic_vector(3 downto 0);
  subtype t_axregion is std_logic_vector(3 downto 0);

  subtype t_axresp is std_logic_vector(1 downto 0);

  constant AXRESP_OKAY        : t_axresp := "00";
  constant AXRESP_EXOKAY      : t_axresp := "01";
  constant AXRESP_SLVERR      : t_axresp := "10";
  constant AXRESP_DECERR      : t_axresp := "11";

  type t_axi_ax_signals is (AxID, AxADDR, AxLEN, AxSIZE, AxBURST, AxLOCK,
                            AxCACHE, AxPROT, AxQOS, AxREGION, AxUSER);

  type t_axi_ax is record
    id      : std_logic_vector;
    addr    : std_logic_vector;
    len     : t_axlen;
    size    : t_axsize;
    burst   : t_axburst;
    lock    : std_logic;
    cache   : t_axcache;
    prot    : t_axprot;
    qos     : t_axqos;
    region  : t_axregion;
    user    : std_logic_vector;
  end record;

  type t_axi_ax_array is array(natural range <>) of t_axi_ax;

  -- Signal   Source    Description
  -- WDATA    Master    Write data.
  -- WSTRB    Master    Write strobes, indicate which byte lanes hold valid data.
  -- WLAST    Master    Indicates whether this is the last data transfer in a write transaction.
  -- WUSER    Master    User-defined extension for the write data channel.

  type t_axi_w_signals is (WDATA, WSTRB, WLAST, WUSER);

  type t_axi_w is record
    data    : std_logic_vector;
    strb    : std_logic_vector;
    last    : std_logic;
    user    : std_logic_vector;
  end record;

  type t_axi_w_array is array(natural range <>) of t_axi_w;

  -- Signal   Source    Description
  -- BID      Slave     Identification tag for a write response.
  -- BRESP    Slave     Write response, indicates the status of a write transaction.
  -- BUSER    Slave     User-defined extension for the write response channel.

  type t_axi_b_signals is (BID, BRESP, BUSER);

  type t_axi_b is record
    id      : std_logic_vector;
    resp    : t_axresp;
    user    : std_logic_vector;
  end record;

  type t_axi_b_array is array(natural range <>) of t_axi_b;

  -- Signal   Source    Description
  -- RID      Slave     Identification tag for read data and response.
  -- RDATA    Slave     Read data.
  -- RRESP    Slave     Read response, indicates the status of a read transfer.
  -- RLAST    Slave     Indicates whether this is the last data transfer in a read transaction.
  -- RUSER    Slave     User-defined extension for the read data channel.

  type t_axi_r_signals is (RID, RDATA, RRESP, RLAST, RUSER);

  type t_axi_r is record
    id      : std_logic_vector;
    data    : std_logic_vector;
    resp    : t_axresp;
    last    : std_logic;
    user    : std_logic_vector;
  end record;

  type t_axi_r_array is array(natural range <>) of t_axi_r;

  type t_axi_mosi is record
    aw      : t_axi_ax;
    awvalid : std_logic;
    w       : t_axi_w;
    wvalid  : std_logic;
    bready  : std_logic;
    ar      : t_axi_ax;
    arvalid : std_logic;
    rready  : std_logic;
  end record;

  type t_axi_miso is record
    awready : std_logic;
    wready  : std_logic;
    b       : t_axi_b;
    bvalid  : std_logic;
    r       : t_axi_r;
    rvalid  : std_logic;
  end record;

  type t_axi is record
    aw      : t_axi_ax;
    w       : t_axi_w;
    b       : t_axi_b;
    ar      : t_axi_ax;
    r       : t_axi_r;
  end record;

  type t_axil_ax is record
    addr    : std_logic_vector;
    prot    : t_axprot;
  end record;

  type t_axil_w is record
    data    : std_logic_vector;
    strb    : std_logic_vector;
  end record;

  type t_axil_b is record
    resp    : t_axresp;
  end record;

  type t_axil_r is record
    data    : std_logic_vector;
    resp    : t_axresp;
  end record;

  type t_axil is record
    aw      : t_axil_ax;
    w       : t_axil_w;
    b       : t_axil_b;
    ar      : t_axil_ax;
    r       : t_axil_r;
  end record;

  function f_axi_ax_width(IDW, AW, UW : integer) return integer;
  function f_axi_ax_width(ax : t_axi_ax) return integer;
  function f_axi_w_width(DW, UW : integer) return integer;
  function f_axi_w_width(w : t_axi_w) return integer;
  function f_axi_b_width(IDW, UW : integer) return integer;
  function f_axi_b_width(b : t_axi_b) return integer;
  function f_axi_r_width(IDW, DW, UW : integer) return integer;
  function f_axi_r_width(r : t_axi_r) return integer;

  function f_axi_ax_serialize(ax : t_axi_ax) return std_logic_vector;
  function f_axi_w_serialize(w : t_axi_w) return std_logic_vector;
  function f_axi_b_serialize(b : t_axi_b) return std_logic_vector;
  function f_axi_r_serialize(r : t_axi_r) return std_logic_vector;

  function f_axi_ax_serialize(ax : t_axi_ax_array) return t_slv_array;
  function f_axi_w_serialize(w : t_axi_w_array) return t_slv_array;
  function f_axi_b_serialize(b : t_axi_b_array) return t_slv_array;
  function f_axi_r_serialize(r : t_axi_r_array) return t_slv_array;

  function f_axi_ax_deserialize(v : std_logic_vector; IDW, AW, UW : integer) return t_axi_ax;
  function f_axi_w_deserialize(v : std_logic_vector; DW, UW : integer) return t_axi_w;
  function f_axi_b_deserialize(v : std_logic_vector; IDW, UW : integer) return t_axi_b;
  function f_axi_r_deserialize(v : std_logic_vector; IDW, DW, UW : integer) return t_axi_r;

  function f_axi_axid_resize(ax : t_axi_ax; idw : integer) return t_axi_ax;
  function f_axi_bid_resize(b : t_axi_b; idw : integer) return t_axi_b;
  function f_axi_rid_resize(r : t_axi_r; idw : integer) return t_axi_r;

  function f_axi_axaddr_incr(size : t_axsize) return unsigned;

  function f_axi_wrap_mask(len : t_axlen; size : t_axsize) return unsigned;

  function f_axi_axaddr_next(
    addr : std_logic_vector;
    len : t_axlen;
    size : t_axsize;
    burst : t_axburst
  ) return std_logic_vector;

  function f_axi_wstrb(addr : std_logic_vector; size : t_axsize; DW : positive) return std_logic_vector;

  component axi4_slice_rtl is
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
  end component;

end package axi4_pkg;

package body axi4_pkg is

  function f_axi_ax_width(IDW, AW, UW : integer) return integer is
  begin
    return IDW + AW + 8 + 3 + 2 + 1 + 4 + 3 + 4 + 4 + UW;
  end function;

  function f_axi_ax_width(ax : t_axi_ax) return integer is
  begin
    return ax.id'length + ax.addr'length + ax.len'length + ax.size'length +
           ax.burst'length + 1 + ax.cache'length + ax.prot'length +
           ax.qos'length + ax.region'length + ax.user'length;
  end function;

  function f_axi_w_width(DW, UW : integer) return integer is
  begin
    return DW + DW/8 + 1 + UW;
  end function;

  function f_axi_w_width(w : t_axi_w) return integer is
  begin
    return w.data'length + w.strb'length + 1 + w.user'length;
  end function;

  function f_axi_b_width(IDW, UW : integer) return integer is
  begin
    return IDW + 2 + UW;
  end function;

  function f_axi_b_width(b : t_axi_b) return integer is
  begin
    return b.id'length + b.resp'length + b.user'length;
  end function;

  function f_axi_r_width(IDW, DW, UW : integer) return integer is
  begin
    return IDW + DW + 2 + 1 + UW;
  end function;

  function f_axi_r_width(r : t_axi_r) return integer is
  begin
    return r.id'length + r.data'length + r.resp'length + 1 + r.user'length;
  end function;

  function f_axi_ax_serialize(ax : t_axi_ax) return std_logic_vector is
    variable v : std_logic_vector(f_axi_ax_width(ax)-1 downto 0);
  begin
    v := ax.id & ax.addr & ax.len & ax.size & ax.burst &
         ax.lock & ax.cache & ax.prot & ax.qos & ax.region & ax.user;
    return v;
  end function;

  function f_axi_w_serialize(w : t_axi_w) return std_logic_vector is
    variable v : std_logic_vector(f_axi_w_width(w)-1 downto 0);
  begin
    v := w.data & w.strb & w.last & w.user;
    return v;
  end function;

  function f_axi_b_serialize(b : t_axi_b) return std_logic_vector is
    variable v : std_logic_vector(f_axi_b_width(b)-1 downto 0);
  begin
    v := b.id & b.resp & b.user;
    return v;
  end function;

  function f_axi_r_serialize(r : t_axi_r) return std_logic_vector is
    variable v : std_logic_vector(f_axi_r_width(r)-1 downto 0);
  begin
    v := r.id & r.data & r.resp & r.last & r.user;
    return v;
  end function;

  function f_axi_ax_serialize(ax : t_axi_ax_array) return t_slv_array is
    variable v : t_slv_array(ax'range)(f_axi_ax_width(ax(ax'low))-1 downto 0);
  begin
    for i in v'range loop
      v(i) := f_axi_ax_serialize(ax(i));
    end loop;
    return v;
  end function;

  function f_axi_w_serialize(w : t_axi_w_array) return t_slv_array is
    variable v : t_slv_array(w'range)(f_axi_w_width(w(w'low))-1 downto 0);
  begin
    for i in v'range loop
      v(i) := f_axi_w_serialize(w(i));
    end loop;
    return v;
  end function;

  function f_axi_b_serialize(b : t_axi_b_array) return t_slv_array is
    variable v : t_slv_array(b'range)(f_axi_b_width(b(b'low))-1 downto 0);
  begin
    for i in v'range loop
      v(i) := f_axi_b_serialize(b(i));
    end loop;
    return v;
  end function;

  function f_axi_r_serialize(r : t_axi_r_array) return t_slv_array is
    variable v : t_slv_array(r'range)(f_axi_r_width(r(r'low))-1 downto 0);
  begin
    for i in v'range loop
      v(i) := f_axi_r_serialize(r(i));
    end loop;
    return v;
  end function;


  function f_axi_ax_deserialize(v : std_logic_vector; IDW, AW, UW : integer) return t_axi_ax is
    variable vv : std_logic_vector(v'length-1 downto 0) := v;
    variable ax : t_axi_ax(id(IDW-1 downto 0), addr(AW-1 downto 0), user(UW-1 downto 0));
  begin
    ax.id     := vv(UW+29+AW+IDW-1 downto UW+29+AW);
    ax.addr   := vv(UW+29+AW-1 downto UW+29);
    ax.len    := vv(UW+28 downto UW+21);
    ax.size   := vv(UW+20 downto UW+18);
    ax.burst  := vv(UW+17 downto UW+16);
    ax.lock   := vv(UW+15);
    ax.cache  := vv(UW+14 downto UW+11);
    ax.prot   := vv(UW+10 downto UW+8);
    ax.qos    := vv(UW+7 downto UW+4);
    ax.region := vv(UW+3 downto UW);
    ax.user   := vv(UW-1 downto 0);
    return ax;
  end function;

  function f_axi_w_deserialize(v : std_logic_vector; DW, UW : integer) return t_axi_w is
    variable vv : std_logic_vector(v'length-1 downto 0) := v;
    variable w  : t_axi_w(data(DW-1 downto 0), strb(DW/8-1 downto 0), user(UW-1 downto 0));
  begin
    w.data := vv(UW+1+DW/8+DW-1 downto UW+1+DW/8);
    w.strb := vv(UW+1+DW/8-1 downto UW+1);
    w.last := vv(UW);
    w.user := vv(UW-1 downto 0);
    return w;
  end function;

  function f_axi_b_deserialize(v : std_logic_vector; IDW, UW : integer) return t_axi_b is
    variable vv : std_logic_vector(v'length-1 downto 0) := v;
    variable b  : t_axi_b(id(IDW-1 downto 0), user(UW-1 downto 0));
  begin
    b.id    := vv(UW+2+IDW-1 downto UW+2);
    b.resp  := vv(UW+1 downto UW);
    b.user  := vv(UW-1 downto 0);
    return b;
  end function;

  function f_axi_r_deserialize(v : std_logic_vector; IDW, DW, UW : integer) return t_axi_r is
    variable vv : std_logic_vector(v'length-1 downto 0) := v;
    variable r  : t_axi_r(id(IDW-1 downto 0), data(DW-1 downto 0), user(UW-1 downto 0));
  begin
    r.id    := vv(UW+3+DW+IDW-1 downto UW+3+DW);
    r.data  := vv(UW+3+DW-1 downto UW+3);
    r.resp  := vv(UW+2 downto UW+1);
    r.last  := vv(UW);
    r.user  := vv(UW-1 downto 0);
    return r;
  end function;

  function f_axi_axid_resize(ax : t_axi_ax; idw : integer) return t_axi_ax is
    variable v : t_axi_ax(id(idw-1 downto 0), addr(ax.addr'range), user(ax.user'range));
  begin
    if idw > ax.id'length then
      v.id(idw-1 downto ax.id'length) := (others => '0');
      v.id(ax.id'length-1 downto 0)   := ax.id;
    else
      v.id(idw-1 downto 0) := ax.id(idw-1 downto 0);
    end if;
    v.addr    := ax.addr;
    v.len     := ax.len;
    v.size    := ax.size;
    v.burst   := ax.burst;
    v.lock    := ax.lock;
    v.cache   := ax.cache;
    v.prot    := ax.prot;
    v.qos     := ax.qos;
    v.region  := ax.region;
    v.user    := ax.user;
    return v;
  end function;

  function f_axi_bid_resize(b : t_axi_b; idw : integer) return t_axi_b is
    variable v : t_axi_b(id(idw-1 downto 0), user(b.user'range));
  begin
    if idw > b.id'length then
      v.id(idw-1 downto b.id'length)  := (others => '0');
      v.id(b.id'length-1 downto 0)    := b.id;
    else
      v.id(idw-1 downto 0) := b.id(idw-1 downto 0);
    end if;
    v.resp  := b.resp;
    v.user  := b.user;
    return v;
  end function;

  function f_axi_rid_resize(r : t_axi_r; idw : integer) return t_axi_r is
    variable v : t_axi_r(id(idw-1 downto 0), data(r.data'range), user(r.user'range));
  begin
    if idw > r.id'length then
      v.id(idw-1 downto r.id'length) := (others => '0');
      v.id(r.id'length-1 downto 0)    := r.id;
    else
      v.id(idw-1 downto 0) := r.id(idw-1 downto 0);
    end if;
    v.data  := r.data;
    v.resp  := r.resp;
    v.last  := r.last;
    v.user  := r.user;
    return v;
  end function;

  function f_axi_axaddr_incr(size : t_axsize) return unsigned is
    variable incr : unsigned(7 downto 0) := to_unsigned(1, 8);
  begin
    return shift_left(incr, to_integer(unsigned(size)));
  end function;

  function f_axi_wrap_mask(len : t_axlen; size : t_axsize) return unsigned is
    variable transfer_size : unsigned(11 downto 0) := resize(unsigned(len), 12);
  begin
    return shift_left(transfer_size, to_integer(unsigned(size)));
  end function;

  function f_axi_axaddr_next(
    addr  : std_logic_vector;
    len   : t_axlen;
    size  : t_axsize;
    burst : t_axburst
  ) return std_logic_vector is
    constant SZ           : integer := AXSIZE_128B_INT;
    constant AW           : integer := 12;
    variable aligned_addr : unsigned(AW-1 downto 0);
    variable curr_addr    : unsigned(AW-1 downto 0);
    variable next_addr    : unsigned(AW-1 downto 0);
    variable align_mask   : unsigned(AW-1 downto 0) := (others => '1');
    variable wrap_mask    : unsigned(AW-1 downto 0) := f_axi_wrap_mask(len, size);
    variable incr         : unsigned(7 downto 0) := f_axi_axaddr_incr(size);
  begin
    -- Current address
    curr_addr := resize(unsigned(addr), AW);
    -- Get size mask to align address
    align_mask(SZ-1 downto 0) := shift_left(align_mask(SZ-1 downto 0), to_integer(unsigned(size)));
    -- Aligned address
    aligned_addr := curr_addr and align_mask;
    case burst is
    when AXBURST_FIXED =>
      next_addr := curr_addr;
    when AXBURST_INCR =>
      -- Calculate next incrementing address
      next_addr := aligned_addr + incr;
      assert next_addr > curr_addr report "f_axi_axaddr_next: Incrementing burst wrapped, crossed 4KB boundary" severity error;
    when AXBURST_WRAP =>
      if not is_X(addr) and not is_X(size) then
        assert curr_addr = aligned_addr report "f_axi_axaddr_next: Unaligned address in wrapped burst" severity error;
      end if;
      case len is
      when x"01" | x"03" | x"07" | x"0f" =>
      when others =>
        report "f_axi_axaddr_next: Invalid wrap burst length, 0x"&to_hstring(len) severity error;
      end case;
      -- Calculate next wrapping address
      next_addr := (curr_addr and not wrap_mask) or ((curr_addr + incr) and wrap_mask);
    when others =>
      if burst = AXBURST_RESERVED then
        report "f_axi_axaddr_next: Invalid burst type, AXBURST_RESERVED" severity error;
      end if;
    end case;
    if addr'length > AW then
      return addr(addr'high downto addr'low+AW) & std_logic_vector(next_addr);
    else
      return std_logic_vector(resize(next_addr(addr'length-1 downto 0), addr'length));
    end if;
  end function;

  function f_axi_wstrb(addr : std_logic_vector; size : t_axsize; DW : positive) return std_logic_vector is
    constant AW         : natural := f_log2(DW/8);
    variable vaddr      : unsigned(AW-1 downto 0) := unsigned(addr(addr'low+AW-1 downto addr'low));
    variable shamt      : natural := to_integer(vaddr);
    variable addr_mask  : unsigned(AW-1 downto 0) := (others => '1');
    variable mask       : unsigned(DW/8-1 downto 0);
    variable strb       : unsigned(DW/8-1 downto 0) := (others => '1');
  begin
    -- Example
    -- Initial strb "11111111", DW = 8, AW 3
    -- shamt = 3, size = 1, 3-1=2 -> halve two times
    -- i = 2: "00001111" -> i = 1: "00000011"
    -- shamt = 3: "00011000", mask = "00001100"
    -- strb: "00001000"
    if AW > 0 then
      addr_mask := shift_left(addr_mask, to_integer(unsigned(size)));
      for i in AW-1 downto 0 loop
        if i >= unsigned(size) then
          strb := shift_right(strb, 2**i);
        end if;
      end loop;
      mask := shift_left(strb, to_integer(vaddr and addr_mask));
      return std_logic_vector(shift_left(strb, shamt) and mask);
    else
      return std_logic_vector(strb);
    end if;
  end function;




end package body axi4_pkg;