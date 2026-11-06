library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

--! AXIS package
--!
package axis_pkg is

  type t_axis is record
    data  : std_logic_vector;
    keep  : std_logic_vector;
    last  : std_logic;
    id    : std_logic_vector;
    dest  : std_logic_vector;
    user  : std_logic_vector;
  end record;

  type t_axis_array is array(natural range <>) of t_axis;

  type t_axis_vector is record
    data  : t_slv_array;
    keep  : t_slv_array;
    last  : std_logic_vector;
    id    : t_slv_array;
    dest  : t_slv_array;
    user  : t_slv_array;
  end record;

  function f_axis_width(
    DW    : positive;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return integer;

  function f_axis_serialize(
    t     : t_axis;
    DW    : positive;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return std_logic_vector;

  function f_axis_deserialize(
    v     : std_logic_vector;
    DW    : positive;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return t_axis;

  function f_axis_extend_id(
    t      : t_axis;
    ext_id : std_logic_vector;
    IDW    : natural
  ) return t_axis;

  function f_axis_reset(
    DW    : positive;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return t_axis;

  component axis_reg_slice is
    generic (
      DW          : positive;
      IDW         : integer := 0;
      DSTW        : integer := 0;
      USRW        : integer := 0;
      SLICE_TYPE  : integer range 0 to 3 := 1
    );
    port (
      -- Clock and reset
      aclk          : in  std_logic;
      aresetn       : in  std_logic;
      -- Data and flow control
      s_axis_tvalid : in  std_logic;
      s_axis_tready : out std_logic;
      s_axis        : in  t_axis(data(DW-1 downto 0),
                                 keep(DW/8-1 downto 0),
                                 id(maximum(IDW,1)-1 downto 0),
                                 dest(maximum(DSTW,1)-1 downto 0),
                                 user(maximum(USRW,1)-1 downto 0));
      m_axis_tvalid : out std_logic;
      m_axis_tready : in  std_logic;
      m_axis        : out t_axis(data(DW-1 downto 0),
                                 keep(DW/8-1 downto 0),
                                 id(maximum(IDW,1)-1 downto 0),
                                 dest(maximum(DSTW,1)-1 downto 0),
                                 user(maximum(USRW,1)-1 downto 0))
    );
  end component axis_reg_slice;

  component axis_mux is
    generic (
      N           : positive := 2;
      DW          : positive;
      IDW         : integer := 0;
      DSTW        : integer := 0;
      USRW        : integer := 0;
      ARB_PRIO    : integer range 0 to 2 := 2;
      ARB_LOCK    : integer range 0 to 1 := 0;
      INTERLEAVED : integer range 0 to 1 := 0;
      ASYNC_RESET : integer range 0 to 1 := 0
    );
    port (
      aclk          : in  std_logic;
      aresetn       : in  std_logic;
      s_axis_tvalid : in  std_logic_vector(N-1 downto 0);
      s_axis_tready : out std_logic_vector(N-1 downto 0);
      s_axis        : in  t_axis_array(N-1 downto 0)(
        data(DW-1 downto 0),
        keep(DW/8-1 downto 0),
        id(maximum(IDW, 1)-1 downto 0),
        dest(maximum(DSTW, 1)-1 downto 0),
        user(maximum(USRW, 1)-1 downto 0)
      );
      m_axis_tvalid : out std_logic;
      m_axis_tready : in  std_logic;
      m_axis        : out t_axis(
        data(DW-1 downto 0),
        keep(DW/8-1 downto 0),
        id(IDW+f_log2nz(N)-1 downto 0),
        dest(maximum(DSTW, 1)-1 downto 0),
        user(maximum(USRW, 1)-1 downto 0)
      )
    );
  end component axis_mux;

  component axis_fifo is
    generic (
      DW         : integer;
      IDW        : integer := 0;
      DSTW       : integer := 0;
      USRW       : integer := 0;
      DEPTH      : integer := 16;
      COMMON_CLK : integer range 0 to 1
    );
    port (
      aclk          : in  std_logic;
      aresetn       : in  std_logic;
      s_axis_tvalid : in  std_logic;
      s_axis_tready : out std_logic;
      s_axis        : in  t_axis(
        data(DW-1 downto 0),
        keep(DW/8-1 downto 0),
        id(maximum(IDW, 1)-1 downto 0),
        dest(maximum(DSTW, 1)-1 downto 0),
        user(maximum(USRW, 1)-1 downto 0)
      );
      m_axis_tvalid : out std_logic;
      m_axis_tready : in  std_logic;
      m_axis        : out t_axis(
        data(DW-1 downto 0),
        keep(DW/8-1 downto 0),
        id(maximum(IDW, 1)-1 downto 0),
        dest(maximum(DSTW, 1)-1 downto 0),
        user(maximum(USRW, 1)-1 downto 0)
      )
    );
  end component axis_fifo;

end package axis_pkg;

package body axis_pkg is

  function f_axis_width(
    DW    : positive;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return integer is
  begin
    return DW+DW/8+1+IDW+DSTW+USRW;
  end function;

  function f_axis_serialize(
    t     : t_axis;
    DW    : positive;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return std_logic_vector is
    variable v : std_logic_vector(f_axis_width(DW, IDW, DSTW, USRW)-1 downto 0);
  begin
    v(DW+DW/8 downto 0) := t.last & t.keep & t.data;
    if IDW > 0 then
      v(DW+DW/8+1+IDW-1 downto DW+DW/8+1) := t.id;
    end if;
    if DSTW > 0 then
      v(DW+DW/8+1+DSTW+IDW-1 downto DW+DW/8+1+IDW) := t.dest;
    end if;
    if USRW > 0 then
      v(DW+DW/8+1+USRW+DSTW+IDW-1 downto DW+DW/8+1+DSTW+IDW) := t.user;
    end if;
    return v;
  end function;

  function f_axis_deserialize(
    v     : std_logic_vector;
    DW    : positive;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return t_axis is
    variable vv  : std_logic_vector(v'length-1 downto 0);
    variable t   : t_axis(data(DW-1 downto 0),
                          keep(DW/8-1 downto 0),
                          id(maximum(IDW, 1)-1 downto 0),
                          dest(maximum(DSTW, 1)-1 downto 0),
                          user(maximum(USRW, 1)-1 downto 0));
  begin
    vv := v;
    (t.last, t.keep, t.data) := vv(DW+DW/8 downto 0);
    t.id    := (others => '0');
    if IDW > 0 then
      t.id := vv(DW+DW/8+1+IDW-1 downto DW+DW/8+1);
    end if;
    t.dest  := (others => '0');
    if DSTW > 0 then
      t.dest := vv(DW+DW/8+1+DSTW+IDW-1 downto DW+DW/8+1+IDW);
    end if;
    t.user  := (others => '0');
    if USRW > 0 then
      t.user := vv(DW+DW/8+1+USRW+DSTW+IDW-1 downto DW+DW/8+1+DSTW+IDW);
    end if;
    return t;
  end function;

  function f_axis_extend_id(
    t      : t_axis;
    ext_id : std_logic_vector;
    IDW    : natural
  ) return t_axis is
    variable v : t_axis(
      data(t.data'range),
      keep(t.keep'range),
      id(ext_id'length+IDW-1 downto 0),
      dest(t.dest'range),
      user(t.user'range)
    );
  begin
    v.data := t.data;
    v.keep := t.keep;
    v.last := t.last;
    v.dest := t.dest;
    v.user := t.user;

    v.id(v.id'high downto IDW) := ext_id;
    if IDW > 0 then
      v.id(IDW-1 downto 0) := t.id;
    end if;

    return v;
  end function;

  function f_axis_reset(
    DW    : positive;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return t_axis is
    variable t : t_axis(data(DW-1 downto 0),
                        keep(DW/8-1 downto 0),
                        id(maximum(IDW, 1)-1 downto 0),
                        dest(maximum(DSTW, 1)-1 downto 0),
                        user(maximum(USRW, 1)-1 downto 0));
  begin
    t.data  := (others => '0');
    t.keep  := (others => '0');
    t.last  := '0';
    t.id    := (others => '0');
    t.dest  := (others => '0');
    t.user  := (others => '0');
    return t;
  end function;

end package body axis_pkg;