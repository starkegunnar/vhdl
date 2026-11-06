library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library lib_axis;
use lib_axis.axis_pkg.all;

entity axis_tb is
end entity axis_tb;

architecture tb of axis_tb is

  constant DW : positive := 32;
  constant IDW : positive := 2;
  constant DSTW : positive := 2;
  constant USRW : positive := 2;
  constant CLK_PERIOD : time := 10 ns;

  subtype t_axis_data is t_axis(
    data(DW-1 downto 0),
    keep(DW/8-1 downto 0),
    id(IDW-1 downto 0),
    dest(DSTW-1 downto 0),
    user(USRW-1 downto 0)
  );

  subtype t_mux_axis is t_axis(
    data(DW-1 downto 0),
    keep(DW/8-1 downto 0),
    id(IDW downto 0),
    dest(DSTW-1 downto 0),
    user(USRW-1 downto 0)
  );

  constant C_IDLE_AXIS : t_axis_data := (
    data => (others => '0'),
    keep => (others => '0'),
    last => '0',
    id => (others => '0'),
    dest => (others => '0'),
    user => (others => '0')
  );

  function make_axis(
    data_value : natural;
    id_value   : natural;
    dest_value : natural;
    user_value : natural;
    last_value : std_logic
  ) return t_axis_data is
    variable result : t_axis_data := C_IDLE_AXIS;
  begin
    result.data := std_logic_vector(to_unsigned(data_value, DW));
    result.keep := (others => '1');
    result.last := last_value;
    result.id := std_logic_vector(to_unsigned(id_value, IDW));
    result.dest := std_logic_vector(to_unsigned(dest_value, DSTW));
    result.user := std_logic_vector(to_unsigned(user_value, USRW));
    return result;
  end function;

  procedure check_axis(
    constant actual    : in t_axis_data;
    constant expected  : in t_axis_data;
    constant test_name : in string
  ) is
  begin
    assert actual.data = expected.data and
           actual.keep = expected.keep and
           actual.last = expected.last and
           actual.id = expected.id and
           actual.dest = expected.dest and
           actual.user = expected.user
      report test_name & ": AXIS payload mismatch"
      severity failure;
  end procedure;

  procedure check_mux_axis(
    constant actual    : in t_mux_axis;
    constant expected  : in t_axis_data;
    constant test_name : in string
  ) is
  begin
    assert actual.data = expected.data and
           actual.keep = expected.keep and
           actual.last = expected.last and
           actual.dest = expected.dest and
           actual.user = expected.user
      report test_name & ": AXIS payload mismatch"
      severity failure;
  end procedure;

  signal clk  : std_logic := '0';
  signal rstn : std_logic := '0';

  signal slice_s_valid : std_logic := '0';
  signal slice_s_ready : std_logic;
  signal slice_s       : t_axis_data := C_IDLE_AXIS;
  signal slice_m_valid : std_logic;
  signal slice_m_ready : std_logic := '0';
  signal slice_m       : t_axis_data;

  signal fifo_s_valid : std_logic := '0';
  signal fifo_s_ready : std_logic;
  signal fifo_s       : t_axis_data := C_IDLE_AXIS;
  signal fifo_m_valid : std_logic;
  signal fifo_m_ready : std_logic := '0';
  signal fifo_m       : t_axis_data;

  signal demux_s_valid : std_logic := '0';
  signal demux_s_ready : std_logic;
  signal demux_s       : t_axis_data := C_IDLE_AXIS;
  signal demux_sel     : std_logic_vector(0 downto 0) := "0";
  signal demux_m_valid : std_logic_vector(1 downto 0);
  signal demux_m_ready : std_logic_vector(1 downto 0) := "11";
  signal demux_m       : t_axis_array(0 to 1)(
    data(DW-1 downto 0), keep(DW/8-1 downto 0),
    id(IDW-1 downto 0), dest(DSTW-1 downto 0), user(USRW-1 downto 0)
  );

  signal tdest_s_valid : std_logic := '0';
  signal tdest_s_ready : std_logic;
  signal tdest_s       : t_axis_data := C_IDLE_AXIS;
  signal tdest_sel     : std_logic_vector(0 downto 0) := "0";
  signal tdest_m_valid : std_logic_vector(1 downto 0);
  signal tdest_m_ready : std_logic_vector(1 downto 0) := "11";
  signal tdest_m       : t_axis_array(0 to 1)(
    data(DW-1 downto 0), keep(DW/8-1 downto 0),
    id(IDW-1 downto 0), dest(DSTW-1 downto 0), user(USRW-1 downto 0)
  );

  signal mux_s_valid : std_logic_vector(1 downto 0) := "00";
  signal mux_s_ready : std_logic_vector(1 downto 0);
  signal mux_s       : t_axis_array(0 to 1)(
    data(DW-1 downto 0), keep(DW/8-1 downto 0),
    id(IDW-1 downto 0), dest(DSTW-1 downto 0), user(USRW-1 downto 0)
  ) := (others => C_IDLE_AXIS);
  signal mux_m_valid : std_logic;
  signal mux_m_ready : std_logic := '1';
  signal mux_m       : t_mux_axis;

  signal broadcast_s_valid : std_logic := '0';
  signal broadcast_s_ready : std_logic;
  signal broadcast_s       : t_axis_data := C_IDLE_AXIS;
  signal broadcast_m_valid : std_logic_vector(1 downto 0);
  signal broadcast_m_ready : std_logic_vector(1 downto 0) := "00";
  signal broadcast_m       : t_axis_array(0 to 1)(
    data(DW-1 downto 0), keep(DW/8-1 downto 0),
    id(IDW-1 downto 0), dest(DSTW-1 downto 0), user(USRW-1 downto 0)
  );

begin

  clk <= not clk after CLK_PERIOD / 2;

  i_axis_reg_slice : entity lib_axis.axis_reg_slice(rtl)
    generic map (DW => DW, IDW => IDW, DSTW => DSTW, USRW => USRW)
    port map (
      aclk => clk, aresetn => rstn,
      s_axis_tvalid => slice_s_valid, s_axis_tready => slice_s_ready, s_axis => slice_s,
      m_axis_tvalid => slice_m_valid, m_axis_tready => slice_m_ready, m_axis => slice_m
    );

  i_axis_fifo : entity lib_axis.axis_fifo(rtl)
    generic map (DW => DW, IDW => IDW, DSTW => DSTW, USRW => USRW,
                 DEPTH => 4, COMMON_CLK => 1)
    port map (
      aclk => clk, aresetn => rstn,
      s_axis_tvalid => fifo_s_valid, s_axis_tready => fifo_s_ready, s_axis => fifo_s,
      m_axis_tvalid => fifo_m_valid, m_axis_tready => fifo_m_ready, m_axis => fifo_m
    );

  i_axis_demux : entity lib_axis.axis_demux(rtl)
    generic map (N => 2, DW => DW, IDW => IDW, DSTW => DSTW, USRW => USRW)
    port map (
      aclk => clk, aresetn => rstn, sel => demux_sel,
      s_axis_tvalid => demux_s_valid, s_axis_tready => demux_s_ready, s_axis => demux_s,
      m_axis_tvalid => demux_m_valid, m_axis_tready => demux_m_ready, m_axis => demux_m
    );

  i_axis_demux_tdest : entity lib_axis.axis_demux(rtl)
    generic map (
      N => 2, DW => DW, IDW => IDW, DSTW => DSTW, USRW => USRW,
      USE_TDEST => 1, TDEST_OFFS => 1
    )
    port map (
      aclk => clk, aresetn => rstn, sel => tdest_sel,
      s_axis_tvalid => tdest_s_valid, s_axis_tready => tdest_s_ready, s_axis => tdest_s,
      m_axis_tvalid => tdest_m_valid, m_axis_tready => tdest_m_ready, m_axis => tdest_m
    );

  i_axis_mux : entity lib_axis.axis_mux(rtl)
    generic map (N => 2, DW => DW, IDW => IDW, DSTW => DSTW, USRW => USRW)
    port map (
      aclk => clk, aresetn => rstn,
      s_axis_tvalid => mux_s_valid, s_axis_tready => mux_s_ready, s_axis => mux_s,
      m_axis_tvalid => mux_m_valid, m_axis_tready => mux_m_ready, m_axis => mux_m
    );

  i_axis_broadcast : entity lib_axis.axis_broadcast(rtl)
    generic map (N => 2, DW => DW, IDW => IDW, DSTW => DSTW, USRW => USRW)
    port map (
      aclk => clk, aresetn => rstn,
      s_axis_tvalid => broadcast_s_valid, s_axis_tready => broadcast_s_ready,
      s_axis => broadcast_s,
      m_axis_tvalid => broadcast_m_valid, m_axis_tready => broadcast_m_ready,
      m_axis => broadcast_m
    );

  p_stimulus : process
    procedure send_axis(
      signal valid   : out std_logic;
      signal ready   : in std_logic;
      signal payload : out t_axis_data;
      constant value : in t_axis_data
    ) is
    begin
      payload <= value;
      valid <= '1';
      loop
        wait until rising_edge(clk);
        exit when ready = '1';
      end loop;
      wait for 1 ns;
      valid <= '0';
    end procedure;

    procedure receive_axis(
      signal valid   : in std_logic;
      signal ready   : in std_logic;
      signal payload : in t_axis_data;
      constant value : in t_axis_data;
      constant test_name : in string
    ) is
    begin
      loop
        wait until rising_edge(clk);
        exit when valid = '1' and ready = '1';
      end loop;
      check_axis(payload, value, test_name);
      wait for 1 ns;
    end procedure;

    variable payload  : t_axis_data;
    variable expected : t_axis_data;
  begin
    slice_s_valid <= '0';
    slice_m_ready <= '0';
    fifo_s_valid <= '0';
    fifo_m_ready <= '0';
    demux_s_valid <= '0';
    demux_m_ready <= "11";
    tdest_s_valid <= '0';
    tdest_m_ready <= "11";
    mux_s_valid <= "00";
    mux_m_ready <= '1';
    broadcast_s_valid <= '0';
    broadcast_m_ready <= "00";

    for i in 1 to 4 loop
      wait until rising_edge(clk);
    end loop;
    wait for 1 ns;
    rstn <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;

    payload := make_axis(16#10203040#, 1, 2, 3, '1');
    slice_m_ready <= '0';
    send_axis(slice_s_valid, slice_s_ready, slice_s, payload);
    assert slice_m_valid = '1' report "axis_reg_slice did not present accepted beat" severity failure;
    for i in 1 to 3 loop
      wait until rising_edge(clk);
      wait for 1 ns;
      assert slice_m_valid = '1' report "axis_reg_slice dropped a stalled beat" severity failure;
      check_axis(slice_m, payload, "axis_reg_slice stall");
    end loop;
    slice_m_ready <= '1';
    receive_axis(slice_m_valid, slice_m_ready, slice_m, payload, "axis_reg_slice");

    fifo_m_ready <= '0';
    for i in 0 to 2 loop
      payload := make_axis(16#20000000# + i, i mod 4, i mod 4, (i + 1) mod 4, '1');
      send_axis(fifo_s_valid, fifo_s_ready, fifo_s, payload);
    end loop;
    fifo_m_ready <= '1';
    for i in 0 to 2 loop
      expected := make_axis(16#20000000# + i, i mod 4, i mod 4, (i + 1) mod 4, '1');
      receive_axis(fifo_m_valid, fifo_m_ready, fifo_m, expected, "axis_fifo ordering");
    end loop;

    demux_m_ready <= "11";
    demux_sel <= "1";
    payload := make_axis(16#30000001#, 1, 2, 3, '1');
    send_axis(demux_s_valid, demux_s_ready, demux_s, payload);
    loop
      wait until rising_edge(clk);
      exit when demux_m_valid(1) = '1' and demux_m_ready(1) = '1';
    end loop;
    check_axis(demux_m(1), payload, "axis_demux select 1");

    demux_sel <= "0";
    payload := make_axis(16#30000000#, 2, 1, 1, '1');
    send_axis(demux_s_valid, demux_s_ready, demux_s, payload);
    loop
      wait until rising_edge(clk);
      exit when demux_m_valid(0) = '1' and demux_m_ready(0) = '1';
    end loop;
    check_axis(demux_m(0), payload, "axis_demux select 0");

    payload := make_axis(16#31000001#, 1, 2, 3, '1');
    send_axis(tdest_s_valid, tdest_s_ready, tdest_s, payload);
    loop
      wait until rising_edge(clk);
      exit when tdest_m_valid(1) = '1' and tdest_m_ready(1) = '1';
    end loop;
    check_axis(tdest_m(1), payload, "axis_demux TDEST offset");

    payload := make_axis(16#40000001#, 1, 2, 3, '1');
    mux_s(0) <= payload;
    mux_s_valid <= "01";
    loop
      wait until rising_edge(clk);
      if mux_m_valid = '1' and mux_m_ready = '1' then
        check_mux_axis(mux_m, payload, "axis_mux input 0");
        assert mux_m.id = std_logic_vector(to_unsigned(1, mux_m.id'length))
          report "axis_mux input 0 ID extension mismatch" severity failure;
      end if;
      exit when mux_s_ready(0) = '1';
    end loop;
    wait for 1 ns;
    mux_s_valid <= "00";

    payload := make_axis(16#40000002#, 2, 1, 2, '1');
    mux_s(1) <= payload;
    mux_s_valid <= "10";
    loop
      wait until rising_edge(clk);
      if mux_m_valid = '1' and mux_m_ready = '1' then
        check_mux_axis(mux_m, payload, "axis_mux input 1");
        assert mux_m.id = std_logic_vector(to_unsigned(6, mux_m.id'length))
          report "axis_mux input 1 ID extension mismatch" severity failure;
      end if;
      exit when mux_s_ready(1) = '1';
    end loop;
    wait for 1 ns;
    mux_s_valid <= "00";

    broadcast_m_ready <= "01";
    payload := make_axis(16#50000001#, 3, 2, 1, '1');
    send_axis(broadcast_s_valid, broadcast_s_ready, broadcast_s, payload);
    wait until rising_edge(clk);
    wait for 1 ns;
    assert broadcast_m_valid = "10"
      report "axis_broadcast did not retain the stalled recipient" severity failure;
    check_axis(broadcast_m(1), payload, "axis_broadcast stalled output");
    broadcast_m_ready <= "11";
    wait until rising_edge(clk);
    wait for 1 ns;
    assert broadcast_m_valid = "00"
      report "axis_broadcast did not clear completed recipients" severity failure;

    report "axis_tb: PASS" severity note;
    stop;
    wait;
  end process;

  p_timeout : process
  begin
    wait for 100 us;
    assert false report "axis_tb: timeout" severity failure;
    wait;
  end process;

end architecture tb;
