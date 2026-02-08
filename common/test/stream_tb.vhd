library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;

package slv_stream_tb_pkg is new lib_common.generic_stream_tb_pkg generic map (t_data => std_logic_vector(7 downto 0));
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library lib_common;
use lib_common.common_pkg.all;
use lib_common.random_2008.all;
use lib_common.slv_stream_tb_pkg.all;

entity stream_tb is
end entity stream_tb;

architecture tb of stream_tb is

  constant c_num_std_streams  : natural := 5;
  constant c_num_arb_streams  : natural := 3;
  constant c_num_streams      : natural := c_num_std_streams+c_num_arb_streams;
  constant c_num_test_data    : natural := 256;
  constant c_s                : natural := c_num_std_streams;
  constant c_a                : natural := c_num_arb_streams;

  type t_stream is record
    n       : natural;
    s_data  : std_logic_vector(7 downto 0);
    s_valid : std_logic;
    s_ready : std_logic;
    m_data  : std_logic_vector(7 downto 0);
    m_valid : std_logic;
    m_ready : std_logic;
  end record;
  type t_streams is array (c_num_streams-1 downto 0) of t_stream;

  impure function f_fill_test_data return t_slv_array is
    variable v_test_data : t_slv_array(c_num_test_data-1 downto 0)(7 downto 0);
  begin
    for i in 0 to c_num_test_data-1 loop
      v_test_data(i) := random(8);
    end loop;
    return v_test_data;
  end function f_fill_test_data;

  constant c_clk_period : time := 10 ns;

  signal tb_clk       : std_logic := '1';
  signal tb_rst       : std_logic := '0';

  signal all_done     : boolean_vector(c_num_streams-1 downto 0) := (others => false);

  signal streams_in   : t_streams := (others => (n => 0, s_data => (others => '0'), s_valid => '0', s_ready => '0', m_data => (others => '0'), m_valid => '0', m_ready => '0'));
  signal test_data    : t_slv_array(c_num_test_data-1 downto 0)(7 downto 0);

  signal req          : std_logic_vector(c_a-1 downto 0);
  signal gnt          : std_logic_vector(c_a-1 downto 0);
  signal ack          : std_logic_vector(c_a-1 downto 0);
  signal gnt_index    : std_logic_vector(f_log2(c_a)-1 downto 0);

begin

  tb_clk <= '0' when all_done = (all_done'high downto all_done'low => true) else not tb_clk after c_clk_period / 2;
  tb_rst <= '0' when all_done = (all_done'high downto all_done'low => true) else '1' after 16 * c_clk_period;

  test_data <= f_fill_test_data;

  b_gen_ctrl : for i in 0 to c_num_streams-1 generate

  p_write : process
    variable v_data : std_logic_vector(7 downto 0) := (others => '0');
    variable rate   : real;
  begin
    streams_in(i).n       <= i;
    streams_in(i).s_data  <= (others => '0');
    streams_in(i).s_valid <= '0';

    if i < c_num_std_streams then
      rate := 1.0;
    else
      rate := 0.3;
    end if;

    wait until tb_rst = '1';
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      v_data := test_data(j);
      pr_write_stream(
        tb_clk,
        streams_in(i).s_data,
        streams_in(i).s_valid,
        streams_in(i).s_ready,
        v_data,
        100 * c_clk_period,
        rate);
    end loop;
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      v_data := test_data(j);
      pr_write_stream(
        tb_clk,
        streams_in(i).s_data,
        streams_in(i).s_valid,
        streams_in(i).s_ready,
        v_data,
        100 * c_clk_period,
        0.7);
    end loop;
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      v_data := test_data(j);
      pr_write_stream(
        tb_clk,
        streams_in(i).s_data,
        streams_in(i).s_valid,
        streams_in(i).s_ready,
        v_data,
        100 * c_clk_period,
        0.9);
    end loop;

    wait;
  end process;

  p_read : process
    variable v_data : std_logic_vector(7 downto 0) := (others => '0');
    variable rate   : real;
  begin
    streams_in(i).m_ready <= '0';

    if i < c_num_std_streams then
      rate := 1.0;
    else
      rate := 0.3;
    end if;

    wait until tb_rst = '1';
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      pr_read_stream(
        tb_clk,
        streams_in(i).m_data,
        streams_in(i).m_valid,
        streams_in(i).m_ready,
        v_data,
        100 * c_clk_period,
        rate);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_hstring(test_data(j)) & " got " & to_hstring(v_data) severity warning;
    end loop;
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      pr_read_stream(
        tb_clk,
        streams_in(i).m_data,
        streams_in(i).m_valid,
        streams_in(i).m_ready,
        v_data,
        100 * c_clk_period,
        0.9);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_hstring(test_data(j)) & " got " & to_hstring(v_data) severity warning;
    end loop;
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      pr_read_stream(
        tb_clk,
        streams_in(i).m_data,
        streams_in(i).m_valid,
        streams_in(i).m_ready,
        v_data,
        100 * c_clk_period,
        0.7);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_hstring(test_data(j)) & " got " & to_hstring(v_data) severity warning;
    end loop;

    all_done(i) <= true;
    wait until rising_edge(tb_clk);

    wait;
  end process;

  end generate b_gen_ctrl;

  i_dut_full : entity lib_common.reg_slice_full(rtl)
  generic map (
    DW  => 8
  )
  port map (
    clk     => tb_clk,
    rst_n   => tb_rst,
    s_data  => streams_in(0).s_data,
    s_valid => streams_in(0).s_valid,
    s_ready => streams_in(0).s_ready,
    m_data  => streams_in(0).m_data,
    m_valid => streams_in(0).m_valid,
    m_ready => streams_in(0).m_ready
  );

  i_dut_pipe : entity lib_common.reg_slice_pipe(rtl)
  generic map (
    DW  => 8
  )
  port map (
    clk     => tb_clk,
    rst_n   => tb_rst,
    s_data  => streams_in(1).s_data,
    s_valid => streams_in(1).s_valid,
    s_ready => streams_in(1).s_ready,
    m_data  => streams_in(1).m_data,
    m_valid => streams_in(1).m_valid,
    m_ready => streams_in(1).m_ready
  );

  i_dut_spill : entity lib_common.reg_slice_spill(rtl)
  generic map (
    DW  => 8
  )
  port map (
    clk     => tb_clk,
    rst_n   => tb_rst,
    s_data  => streams_in(2).s_data,
    s_valid => streams_in(2).s_valid,
    s_ready => streams_in(2).s_ready,
    m_data  => streams_in(2).m_data,
    m_valid => streams_in(2).m_valid,
    m_ready => streams_in(2).m_ready
  );

  i_dut_cdc_4phase : entity lib_common.cdc_4phase(rtl)
  generic map (
    DW  => 8
  )
  port map (
    s_clk   => tb_clk,
    s_rst_n => tb_rst,
    s_data  => streams_in(3).s_data,
    s_valid => streams_in(3).s_valid,
    s_ready => streams_in(3).s_ready,
    m_clk   => tb_clk,
    m_rst_n => tb_rst,
    m_data  => streams_in(3).m_data,
    m_valid => streams_in(3).m_valid,
    m_ready => streams_in(3).m_ready
  );

  i_dut_fifo : entity lib_common.fifo(rtl)
  generic map (
    DW            => 8,
    DEPTH         => 32,
    FWFT          => 1,
    READ_LATENCY  => 1,
    COMMON_CLK    => 1,
    ASYNC_RESET   => 0
  )
  port map (
    wclk      => tb_clk,
    wrst_n    => tb_rst,
    wdata     => streams_in(4).s_data,
    we        => streams_in(4).s_valid,
    wready    => streams_in(4).s_ready,
    rclk      => tb_clk,
    rrst_n    => tb_rst,
    rdata     => streams_in(4).m_data,
    ren       => streams_in(4).m_ready,
    rvalid    => streams_in(4).m_valid
  );


--  i_fifo_srl : entity lib_common.fifo_srl(rtl)
--  generic map (
--    t_data          => std_logic_vector(7 downto 0),
--    g_bypass_empty  => true
--  )
--  port map (
--    clk     => tb_clk,
--    rst     => tb_rst,
--    s_data  => streams_in(3).s_data,
--    s_valid => streams_in(3).s_valid,
--    s_ready => streams_in(3).s_ready,
--    m_data  => streams_in(3).m_data,
--    m_valid => streams_in(3).m_valid,
--    m_ready => streams_in(3).m_ready
--  );

--  i_fifo : entity lib_common.fifo(rtl)
--  generic map (
--    t_data  => std_logic_vector(7 downto 0)
--  )
--  port map (
--    clk     => tb_clk,
--    rst     => tb_rst,
--    s_data  => streams_in(4).s_data,
--    s_valid => streams_in(4).s_valid,
--    s_ready => streams_in(4).s_ready,
--    m_data  => streams_in(4).m_data,
--    m_valid => streams_in(4).m_valid,
--    m_ready => streams_in(4).m_ready
--  );

--  i_spill : entity lib_common.reg_slice_spill(rtl)
--  generic map (
--    t_data  => std_logic_vector(7 downto 0)
--  )
--  port map (
--    clk     => tb_clk,
--    rst     => tb_rst,
--    s_data  => streams_in(4).s_data,
--    s_valid => streams_in(4).s_valid,
--    s_ready => streams_in(4).s_ready,
--    m_data  => streams_in(4).m_data,
--    m_valid => streams_in(4).m_valid,
--    m_ready => streams_in(4).m_ready
--  );

  b_req : for i in 0 to c_a-1 generate
    req(i) <= streams_in(c_s+i).s_valid;
    ack(i) <= streams_in(c_s+i).s_valid and streams_in(c_s+i).s_ready and gnt(i);
  end generate;

  --i_arbiter : entity lib_common.arbiter(rtl)
  --generic map (
  --  WIDTH  => c_num_arb_streams
  --)
  --port map (
  --  clk         => tb_clk,
  --  rst_n       => tb_rst,
  --  req         => req,
  --  ack         => ack,
  --  grant       => gnt,
  --  grant_valid => open,
  --  grant_index => gnt_index
  --);
  i_arbiter_tree : entity lib_common.arbiter_tree(rtl)
  generic map (
    N_REQ       => c_num_arb_streams,
    DW          => 8,
    ARB_PRIO    => 2,
    ARB_LOCK    => 1,
    ASYNC_RESET => 0
  )
  port map (
    clk       => tb_clk,
    rst_n     => tb_rst,
    ext_prio  => (others => '0'),
    ireq      => req,
    idata     => (others => (others => '0')),
    ognt      => gnt,
    oreq      => open,
    ignt      => streams_in(c_s+to_integer(unsigned(gnt_index))).m_ready,
    oidx      => gnt_index
  );

  b_gnt : for i in 0 to c_a-1 generate
    streams_in(c_s+i).m_valid <= streams_in(c_s+i).s_valid and gnt(i);
    streams_in(c_s+i).m_data  <= streams_in(c_s+i).s_data;
    streams_in(c_s+i).s_ready <= streams_in(c_s+i).m_ready and gnt(i);
  end generate;

end architecture tb;