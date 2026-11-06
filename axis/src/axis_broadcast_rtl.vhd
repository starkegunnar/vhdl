library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axis;
use lib_axis.axis_pkg.all;

entity axis_broadcast is
  generic (
    N           : positive := 2;
    DW          : positive;
    IDW         : integer := 0;
    DSTW        : integer := 0;
    USRW        : integer := 0;
    ASYNC_RESET : integer range 0 to 1 := 0
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
end entity axis_broadcast;

architecture rtl of axis_broadcast is

  type t_reg is record
    t       : t_axis_array(0 to 1)(data(DW-1 downto 0),
                                   keep(DW/8-1 downto 0),
                                   id(maximum(IDW, 1)-1 downto 0),
                                   dest(maximum(DSTW, 1)-1 downto 0),
                                   user(maximum(USRW, 1)-1 downto 0));
    valid   : std_logic;
    tvalid  : std_logic_vector(N-1 downto 0);
    tready  : std_logic;
  end record;

  constant C_RST : t_reg := (
    t       => (others => f_axis_reset(DW, IDW, DSTW, USRW)),
    valid   => '0',
    tvalid  => (others => '0'),
    tready  => '1'
  );

  signal q, d : t_reg;

begin

  -- Combinational next-state and output logic
  p_comb : process(all)
    variable v       : t_reg;
    variable v_ready : std_logic;
    variable v_valid : std_logic_vector(N-1 downto 0);
  begin
    v := q;

    v_ready := '0';
    if (q.tvalid and m_axis_tready) = q.tvalid then
      v_ready := q.valid;
    end if;

    if s_axis_tvalid = '1' and q.tready = '1' and q.valid = '1' and v_ready = '0' then
      -- No downstream ready, deassert tready to stall input
      v.tready := '0';
    elsif q.valid = '1' and v_ready = '1' then
      -- Downstream ready, assert tready to allow input
      v.tready := '1';
    end if;

    if q.tready = '1' and s_axis_tvalid = '1' then
      -- Capture the selection for the downstream channel
      v.t(0) := s_axis;
    end if;

    for i in 0 to N-1 loop
      if m_axis_tready(i) = '1' then
        -- Clear the tvalid flag for this downstream channel as it has been accepted
        v.tvalid(i) := '0';
      end if;
    end loop;
    if v_ready = '1' then
      -- Clear the valid flag as all downstream channels have accepted the data
      v.valid := '0';
    end if;
    if q.valid = '0' or v_ready = '1' then
      -- Update the valid and tvalid signals based on input and downstream readiness
      v.valid   := s_axis_tvalid or not q.tready;
      v.tvalid  := (others => s_axis_tvalid or not q.tready);
      if q.tready = '1' then
        v.t(1) := s_axis;
      else
        v.t(1) := q.t(0);
      end if;
    end if;

    if ASYNC_RESET = 0 and aresetn = '0' then
      v.valid   := C_RST.valid;
      v.tvalid  := C_RST.tvalid;
      v.tready  := C_RST.tready;
    end if;

    d <= v;

    s_axis_tready <= q.tready;

    m_axis <= (others => q.t(1));
    m_axis_tvalid <= q.tvalid;
  end process p_comb;

  -- aresetn is active-low.
  p_seq : process(aclk, aresetn)
  begin
    if rising_edge(aclk) then
      q <= d;
    end if;
    if ASYNC_RESET = 1 and aresetn = '0' then
      q.valid   <= C_RST.valid;
      q.tvalid  <= C_RST.tvalid;
      q.tready  <= C_RST.tready;
    end if;
  end process p_seq;

end architecture rtl;
