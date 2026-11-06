library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library lib_axis;
use lib_axis.axis_pkg.all;
use lib_axis.axis_tb_pkg.all;

entity axis_tb is
end entity axis_tb;

architecture tb of axis_tb is

  constant DW : positive := 32;
  constant IDW : positive := 2;
  constant DSTW : positive := 2;
  constant USRW : positive := 2;
  constant CLK_PERIOD : time := 10 ns;
  constant TRANSFER_TIMEOUT : time := 10 us;
  type t_packet_lengths is array (natural range <>) of positive;
  constant PACKET_LENGTHS : t_packet_lengths := (1, 2, 17, 64, 129);
  type t_rates is array (natural range <>) of real;
  constant WRITE_RATES : t_rates := (1.0, 0.25, 0.6);
  constant READ_RATES : t_rates := (0.25, 1.0, 0.4);

  function packet_beat_count return positive is
    variable total : natural := 0;
  begin
    for packet_index in PACKET_LENGTHS'range loop
      total := total + PACKET_LENGTHS(packet_index);
    end loop;
    return total;
  end function;

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

  function packet_beat(
    source : natural;
    mode_index : natural;
    packet_index : natural;
    beat_index : natural
  ) return t_axis_data is
    variable result : t_axis_data;
  begin
    result := make_axis(
      source * 16#1000000# + mode_index * 16#10000# + packet_index * 256 + beat_index,
      (source + packet_index) mod 4, (packet_index mod 2) * 2,
      (mode_index + beat_index) mod 4, '0'
    );
    if beat_index = PACKET_LENGTHS(packet_index) - 1 then
      result.last := '1';
      result.keep := "0111";
    end if;
    return result;
  end function;

  procedure write_packets(
    signal clock : in std_logic;
    signal payload : out t_axis_data;
    signal valid : inout std_logic;
    signal ready : in std_logic;
    signal select_port : out std_logic_vector(0 downto 0);
    constant source : in natural
  ) is
  begin
    for mode_index in WRITE_RATES'range loop
      for packet_index in PACKET_LENGTHS'range loop
        select_port <= std_logic_vector(to_unsigned(packet_index mod 2, 1));
        for beat_index in 0 to PACKET_LENGTHS(packet_index) - 1 loop
          pcdr_write(clock, payload, valid, ready,
            packet_beat(source, mode_index, packet_index, beat_index),
            TRANSFER_TIMEOUT, WRITE_RATES(mode_index));
        end loop;
      end loop;
    end loop;
  end procedure;

  procedure read_packets(
    signal clock : in std_logic;
    signal payload : in t_axis_data;
    signal valid : in std_logic;
    signal ready : inout std_logic;
    signal done : out std_logic;
    constant source : in natural;
    constant test_name : in string;
    constant route : in integer := -1
  ) is
    variable actual : t_axis_data;
  begin
    for mode_index in READ_RATES'range loop
      for packet_index in PACKET_LENGTHS'range loop
        if route = -1 or packet_index mod 2 = route then
          for beat_index in 0 to PACKET_LENGTHS(packet_index) - 1 loop
            pcdr_read(clock, payload, valid, ready, actual,
              TRANSFER_TIMEOUT, READ_RATES(mode_index));
            check_axis(actual, packet_beat(source, mode_index, packet_index, beat_index),
              test_name & " mode" & integer'image(mode_index) &
              " packet" & integer'image(packet_index) & " beat" & integer'image(beat_index));
          end loop;
        end if;
      end loop;
    end loop;
    report test_name & ": completed all pressure modes" severity note;
    done <= '1';
    ready <= '1';
    loop
      wait until rising_edge(clock);
      assert valid = '0' report test_name & ": unexpected extra beat" severity failure;
    end loop;
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

  signal unused_sel : std_logic_vector(0 to 5) := (others => '0');
  signal writers_done : std_logic_vector(0 to 6) := (others => '0');
  signal readers_done : std_logic_vector(0 to 8) := (others => '0');
  signal observed_valid : std_logic_vector(0 to 8);
  signal observed_ready : std_logic_vector(0 to 8);
  signal stalls_seen : std_logic_vector(0 to 8) := (others => '0');
  signal gaps_seen : std_logic_vector(0 to 8) := (others => '0');
  signal observed_data : t_axis_array(0 to 8)(
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

  p_control : process
  begin
    wait for 4 * CLK_PERIOD;
    rstn <= '1';
    wait until writers_done = (writers_done'range => '1') and
               readers_done = (readers_done'range => '1');
    wait for 10 * CLK_PERIOD;
    assert stalls_seen = (stalls_seen'range => '1')
      report "axis_tb: backpressure was not observed on every output" severity failure;
    assert gaps_seen = (gaps_seen'range => '1')
      report "axis_tb: forward pressure was not observed on every output" severity failure;
    report "axis_tb: PASS (long packets, backpressure, forward pressure, mixed pressure)" severity note;
    stop;
    wait;
  end process;

  p_slice_writer : process
  begin
    wait until rstn = '1';
    write_packets(clk, slice_s, slice_s_valid, slice_s_ready, unused_sel(0 to 0), 0);
    writers_done(0) <= '1';
    wait;
  end process;

  p_slice_reader : process
  begin
    wait until rstn = '1';
    read_packets(clk, slice_m, slice_m_valid, slice_m_ready, readers_done(0), 0, "axis_reg_slice");
  end process;

  p_fifo_writer : process
  begin
    wait until rstn = '1';
    write_packets(clk, fifo_s, fifo_s_valid, fifo_s_ready, unused_sel(1 to 1), 1);
    writers_done(1) <= '1';
    wait;
  end process;

  p_fifo_reader : process
  begin
    wait until rstn = '1';
    read_packets(clk, fifo_m, fifo_m_valid, fifo_m_ready, readers_done(1), 1, "axis_fifo");
  end process;

  p_demux_writer : process
  begin
    wait until rstn = '1';
    write_packets(clk, demux_s, demux_s_valid, demux_s_ready, demux_sel, 2);
    writers_done(2) <= '1';
    wait;
  end process;

  p_tdest_writer : process
  begin
    wait until rstn = '1';
    write_packets(clk, tdest_s, tdest_s_valid, tdest_s_ready, unused_sel(2 to 2), 3);
    writers_done(3) <= '1';
    wait;
  end process;

  g_ports : for port_index in 0 to 1 generate
    p_demux_reader : process
    begin
      wait until rstn = '1';
      read_packets(clk, demux_m(port_index), demux_m_valid(port_index),
        demux_m_ready(port_index), readers_done(2 + port_index), 2,
        "axis_demux port" & integer'image(port_index), port_index);
    end process;

    p_tdest_reader : process
    begin
      wait until rstn = '1';
      read_packets(clk, tdest_m(port_index), tdest_m_valid(port_index),
        tdest_m_ready(port_index), readers_done(4 + port_index), 3,
        "axis_demux TDEST port" & integer'image(port_index), port_index);
    end process;

    p_mux_writer : process
    begin
      wait until rstn = '1';
      write_packets(clk, mux_s(port_index), mux_s_valid(port_index),
        mux_s_ready(port_index), unused_sel(3 + port_index to 3 + port_index), 4 + port_index);
      writers_done(4 + port_index) <= '1';
      wait;
    end process;

    p_broadcast_reader : process
    begin
      wait until rstn = '1';
      read_packets(clk, broadcast_m(port_index), broadcast_m_valid(port_index),
        broadcast_m_ready(port_index), readers_done(7 + port_index), 6,
        "axis_broadcast port" & integer'image(port_index));
    end process;
  end generate;

  p_mux_reader : process
    type t_progress is array (0 to 1) of natural;
    variable modes : t_progress := (others => 0);
    variable packets : t_progress := (others => 0);
    variable beats : t_progress := (others => 0);
    variable actual : t_mux_axis;
    variable expected : t_axis_data;
    variable narrowed : t_axis_data;
    variable source_index : natural;
    variable locked_source : integer := -1;
  begin
    wait until rstn = '1';
    for mode_index in READ_RATES'range loop
      for transfer_index in 1 to 2 * packet_beat_count loop
        pcdr_read(clk, mux_m, mux_m_valid, mux_m_ready, actual,
          TRANSFER_TIMEOUT, READ_RATES(mode_index));
        source_index := to_integer(unsigned(actual.id(IDW downto IDW)));
        assert modes(source_index) < WRITE_RATES'length
          report "axis_mux: extra beat from completed input" severity failure;
        assert locked_source = -1 or locked_source = source_index
          report "axis_mux: interleaved packets" severity failure;
        expected := packet_beat(4 + source_index, modes(source_index),
          packets(source_index), beats(source_index));
        narrowed := (data => actual.data, keep => actual.keep, last => actual.last,
          id => actual.id(IDW-1 downto 0), dest => actual.dest, user => actual.user);
        check_axis(narrowed, expected, "axis_mux input" & integer'image(source_index));
        locked_source := source_index;
        if expected.last = '1' then
          locked_source := -1;
          beats(source_index) := 0;
          if packets(source_index) = PACKET_LENGTHS'high then
            packets(source_index) := 0;
            modes(source_index) := modes(source_index) + 1;
          else
            packets(source_index) := packets(source_index) + 1;
          end if;
        else
          beats(source_index) := beats(source_index) + 1;
        end if;
      end loop;
    end loop;
    assert modes = (modes'range => WRITE_RATES'length)
      report "axis_mux: missing packets" severity failure;
    report "axis_mux: completed all pressure modes" severity note;
    readers_done(6) <= '1';
    mux_m_ready <= '1';
    loop
      wait until rising_edge(clk);
      assert mux_m_valid = '0' report "axis_mux: unexpected extra beat" severity failure;
    end loop;
  end process;

  p_broadcast_writer : process
  begin
    wait until rstn = '1';
    write_packets(clk, broadcast_s, broadcast_s_valid, broadcast_s_ready, unused_sel(5 to 5), 6);
    writers_done(6) <= '1';
    wait;
  end process;

  observed_valid <= (slice_m_valid, fifo_m_valid, demux_m_valid(0), demux_m_valid(1),
    tdest_m_valid(0), tdest_m_valid(1), mux_m_valid, broadcast_m_valid(0), broadcast_m_valid(1));
  observed_ready <= (slice_m_ready, fifo_m_ready, demux_m_ready(0), demux_m_ready(1),
    tdest_m_ready(0), tdest_m_ready(1), mux_m_ready, broadcast_m_ready(0), broadcast_m_ready(1));
  observed_data <= (slice_m, fifo_m, demux_m(0), demux_m(1), tdest_m(0), tdest_m(1),
    (data => mux_m.data, keep => mux_m.keep, last => mux_m.last,
     id => mux_m.id(IDW-1 downto 0), dest => mux_m.dest, user => mux_m.user),
    broadcast_m(0), broadcast_m(1));

  g_monitors : for output_index in observed_valid'range generate
    p_coverage : process
    begin
      wait until readers_done(output_index) = '1';
      assert stalls_seen(output_index) = '1'
        report "axis_tb: no backpressure on output" & integer'image(output_index) severity failure;
      assert gaps_seen(output_index) = '1'
        report "axis_tb: no forward pressure on output" & integer'image(output_index) severity failure;
      wait;
    end process;

    p_stability : process(clk)
      variable stalled : boolean := false;
      variable held : t_axis_data;
      variable held_mux_id : std_logic_vector(IDW downto 0);
    begin
      if rising_edge(clk) and rstn = '1' then
        if stalled then
          assert observed_valid(output_index) = '1'
            report "axis_tb: valid dropped while stalled on output" & integer'image(output_index)
            severity failure;
          check_axis(observed_data(output_index), held,
            "axis_tb stalled output" & integer'image(output_index));
          if output_index = 6 then
            assert mux_m.id = held_mux_id report "axis_mux: ID changed while stalled" severity failure;
          end if;
        end if;
        stalled := observed_valid(output_index) = '1' and observed_ready(output_index) = '0';
        held := observed_data(output_index);
        held_mux_id := mux_m.id;
        if readers_done(output_index) = '0' then
          if stalled then
            stalls_seen(output_index) <= '1';
          end if;
          if observed_valid(output_index) = '0' and observed_ready(output_index) = '1' then
            gaps_seen(output_index) <= '1';
          end if;
        end if;
      end if;
    end process;
  end generate;

  p_timeout : process
  begin
    wait for 100 us;
    assert false report "axis_tb: timeout" severity failure;
    stop(1);
    wait;
  end process;

end architecture tb;
