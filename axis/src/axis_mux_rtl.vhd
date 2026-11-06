library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_axis;
use lib_axis.axis_pkg.all;

entity axis_mux is
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
    s_axis        : in  t_axis_array(0 to N-1)(
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
end entity axis_mux;

architecture rtl of axis_mux is

  constant C_PACKED_WIDTH : integer := f_axis_width(DW, IDW, DSTW, USRW);

  type t_reg is record
    locked  : std_logic;
    lock_id : unsigned(f_log2nz(N)-1 downto 0);
  end record;

  constant RST : t_reg := (
    locked  => '0',
    lock_id => (others => '0')
  );

  signal q, d : t_reg;

  signal s_payload : t_slv_array(N-1 downto 0)(C_PACKED_WIDTH-1 downto 0);
  signal m_payload : std_logic_vector(C_PACKED_WIDTH-1 downto 0);

  signal port_mask : std_logic_vector(N-1 downto 0);
  signal arb_valid : std_logic_vector(N-1 downto 0);
  signal arb_ready : std_logic_vector(N-1 downto 0);
  signal arb_id    : std_logic_vector(f_log2nz(N)-1 downto 0);
  signal out_valid : std_logic;

begin

  assert DW mod 8 = 0
    report "axis_mux: DW must be a multiple of 8"
    severity failure;

  g_pack_inputs : for i in 0 to N-1 generate
    s_payload(i) <= f_axis_serialize(
      s_axis(i), DW, IDW, DSTW, USRW
    );

    port_mask(i) <= '1' when INTERLEAVED = 1 or
                            q.locked = '0' or
                            q.lock_id = to_unsigned(i, q.lock_id'length)
                   else '0';
  end generate;

  arb_valid     <= s_axis_tvalid and port_mask;
  s_axis_tready <= arb_ready and port_mask;
  m_axis_tvalid <= out_valid;

  m_axis <= f_axis_extend_id(
    f_axis_deserialize(m_payload, DW, IDW, DSTW, USRW),
    arb_id,
    IDW
  );

  i_arbiter : arbiter_tree
    generic map (
      N           => N,
      DW          => C_PACKED_WIDTH,
      ARB_PRIO    => ARB_PRIO,
      ARB_LOCK    => ARB_LOCK,
      ASYNC_RESET => ASYNC_RESET
    )
    port map (
      clk     => aclk,
      rstn    => aresetn,
      s_data  => s_payload,
      s_valid => arb_valid,
      s_ready => arb_ready,
      m_data  => m_payload,
      m_id    => arb_id,
      m_valid => out_valid,
      m_ready => m_axis_tready
    );

  p_comb : process(all)
    variable v : t_reg;
  begin
    v := q;

    if INTERLEAVED = 0 then
      if out_valid = '1' then
        -- TLAST occupies bit DW+DW/8 in the serialized payload.
        if m_axis_tready = '1' and m_payload(DW+DW/8) = '1' then
          v.locked := '0';
        elsif q.locked = '0' then
          -- Hold the selection through stalls and packet gaps.
          v.locked  := '1';
          v.lock_id := unsigned(arb_id);
        end if;
      end if;
    else
      v := RST;
    end if;

    if ASYNC_RESET = 0 and aresetn = '0' then
      v := RST;
    end if;

    d <= v;
  end process;

  p_reg : process(aclk, aresetn)
  begin
    if ASYNC_RESET /= 0 and aresetn = '0' then
      q <= RST;
    elsif rising_edge(aclk) then
      q <= d;
    end if;
  end process;

end architecture rtl;
