library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axis;
use lib_axis.axis_pkg.all;

entity axis_demux is
  generic (
    N           : positive := 2;
    DW          : positive;
    IDW         : integer := 0;
    DSTW        : integer := 0;
    USRW        : integer := 0;
    ASYNC_RESET : integer range 0 to 1 := 0;
    USE_TDEST   : integer range 0 to 1 := 0;
    TDEST_OFFS  : natural := 0
  );
  port (
    aclk          : in  std_logic;
    aresetn       : in  std_logic;
    sel           : in  std_logic_vector(f_log2nz(N)-1 downto 0);

    s_axis_tvalid : in  std_logic;
    s_axis_tready : out std_logic;
    s_axis        : in  t_axis(
      data(DW-1 downto 0),
      keep(DW/8-1 downto 0),
      id(maximum(IDW, 1)-1 downto 0),
      dest(maximum(DSTW, 1)-1 downto 0),
      user(maximum(USRW, 1)-1 downto 0)
    );

    m_axis_tvalid : out std_logic_vector(N-1 downto 0);
    m_axis_tready : in  std_logic_vector(N-1 downto 0);
    m_axis        : out t_axis_array(0 to N-1)(
      data(DW-1 downto 0),
      keep(DW/8-1 downto 0),
      id(maximum(IDW, 1)-1 downto 0),
      dest(maximum(DSTW, 1)-1 downto 0),
      user(maximum(USRW, 1)-1 downto 0)
    )
  );
end entity axis_demux;

architecture rtl of axis_demux is

  subtype t_sel is unsigned(f_log2nz(N)-1 downto 0);

  subtype t_dst_range is integer range TDEST_OFFS+f_log2nz(N)-1 downto TDEST_OFFS;

  constant VW : integer := 2**t_sel'length;

  type t_reg is record
    locked  : std_logic;
    sel     : t_sel;
    t       : t_axis_array(0 to 1)(data(DW-1 downto 0),
                                   keep(DW/8-1 downto 0),
                                   id(maximum(IDW, 1)-1 downto 0),
                                   dest(maximum(DSTW, 1)-1 downto 0),
                                   user(maximum(USRW, 1)-1 downto 0));
    sel_reg : t_sel;
    valid   : std_logic;
    tvalid  : std_logic_vector(VW-1 downto 0);
    tready  : std_logic;
  end record;

  constant C_RST : t_reg := (
    locked  => '0',
    sel     => (others => '0'),
    t       => (others => f_axis_reset(DW, IDW, DSTW, USRW)),
    sel_reg => (others => '0'),
    valid   => '0',
    tvalid  => (others => '0'),
    tready  => '1'
  );

  signal q, d : t_reg;

begin

  assert USE_TDEST = 0 or DSTW-TDEST_OFFS >= f_log2nz(N)
    report "axis_demux: DSTW is too small for USE_TDEST"
    severity failure;

  -- Combinational next-state and output logic
  p_comb : process(all)
    variable v       : t_reg;
    variable v_ready : std_logic_vector(VW-1 downto 0);
    variable v_valid : std_logic_vector(VW-1 downto 0);
    variable v_sel   : t_sel;
    variable v_last  : std_logic;
  begin
    v := q;

    v_last := (s_axis.last and q.tready) or (q.t(0).last and not q.tready);
    v_ready := (others => '1');
    v_ready(N-1 downto 0) := m_axis_tready;

    if USE_TDEST /= 0 then
      if q.tready = '0' then
        v_sel := unsigned(q.t(0).dest(t_dst_range));
      else
        v_sel := unsigned(s_axis.dest(t_dst_range));
      end if;
    else
      if q.locked = '1' then
        v_sel := q.sel;
      elsif q.tready = '0' then
        v_sel := q.sel_reg;
      else
        v_sel := unsigned(sel);
      end if;
    end if;

    if s_axis_tvalid = '1' and q.tready = '1' and q.valid = '1' and
       (q.tvalid and v_ready) = (VW-1 downto 0 => '0') then
      -- No downstream ready, deassert tready to stall input
      v.tready := '0';
    elsif (q.tvalid and v_ready) /= (VW-1 downto 0 => '0') then
      -- Downstream ready, assert tready to allow input
      v.tready := '1';
    end if;

    if q.tready = '1' and s_axis_tvalid = '1' then
      -- Capture the selection for the downstream channel
      v.t(0)    := s_axis;
      v.sel_reg := unsigned(sel);
    end if;

    if q.valid = '0' or (q.tvalid and v_ready) /= (VW-1 downto 0 => '0') then
      -- Determine which downstream channel to select based on v_sel
      v.valid := s_axis_tvalid or not q.tready;
      v.tvalid := (others => '0');
      v.tvalid(to_integer(v_sel)) := s_axis_tvalid or not q.tready;
      if q.tready = '1' then
        v.t(1) := s_axis;
      else
        v.t(1) := q.t(0);
      end if;
      if USE_TDEST = 0 and (s_axis_tvalid = '1' or q.tready = '0') then
        if v_last = '1' then
          v.locked := '0';
        elsif q.locked = '0' then
          v.sel := v_sel;
          v.locked := '1';
        end if;
      end if;
    end if;

    if ASYNC_RESET = 0 and aresetn = '0' then
      if USE_TDEST = 0 then
        v.locked  := C_RST.locked;
        v.sel     := C_RST.sel;
      end if;
      v.valid   := C_RST.valid;
      v.tvalid  := C_RST.tvalid;
      v.tready  := C_RST.tready;
    end if;

    d <= v;

    s_axis_tready <= q.tready;

    m_axis <= (others => q.t(1));
    m_axis_tvalid <= q.tvalid(N-1 downto 0);
  end process p_comb;

  -- aresetn is active-low.
  p_seq : process(aclk, aresetn)
  begin
    if rising_edge(aclk) then
      q <= d;
    end if;
    if ASYNC_RESET = 1 and aresetn = '0' then
      if USE_TDEST = 0 then
        q.locked  <= C_RST.locked;
        q.sel     <= C_RST.sel;
      end if;
      q.valid   <= C_RST.valid;
      q.tvalid  <= C_RST.tvalid;
      q.tready  <= C_RST.tready;
    end if;
  end process p_seq;

end architecture rtl;
