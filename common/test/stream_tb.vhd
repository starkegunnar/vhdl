library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;

package slv_stream_tb_pkg is new lib_common.generic_stream_tb_pkg generic map (t_data => std_logic_vector(7 downto 0));
library lib_common;
use lib_common.slv_stream_tb_pkg.all;
use lib_common.common_pkg.all;
use lib_common.random_2008.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stream_tb is
end entity stream_tb;

architecture tb of stream_tb is

  constant c_num_streams    : natural := 8;
  constant c_num_test_data  : natural := 256;

  type t_stream is record
    s_data  : std_logic_vector(7 downto 0);
    s_valid : std_logic;
    s_ready : std_logic;
    m_data  : std_logic_vector(7 downto 0);
    m_valid : std_logic;
    m_ready : std_logic;
  end record;
  type t_streams is array (c_num_streams-1 downto 0) of t_stream;

  impure function fn_fill_test_data return t_slv_array is
    variable v_test_data : t_slv_array(c_num_test_data-1 downto 0)(7 downto 0);
  begin
    for i in 0 to c_num_test_data-1 loop
      v_test_data(i) := random(8);
    end loop;
    return v_test_data;
  end function fn_fill_test_data;

  constant c_clk_period : time := 10 ns;

  signal tb_clk       : std_logic := '0';
  signal tb_rst       : std_logic := '1';

  signal all_done     : boolean_vector(c_num_streams-1 downto 0) := (others => false);

  signal streams_in   : t_streams := (others => (s_data => (others => '0'), s_valid => '0', s_ready => '0', m_data => (others => '0'), m_valid => '0', m_ready => '0'));
  signal s_arb_data   : t_slv_array(c_num_streams-1 downto 0)(7 downto 0);
  signal s_arb_valid  : std_logic_vector(c_num_streams-1 downto 0);
  signal s_arb_ready  : std_logic_vector(c_num_streams-1 downto 0);
  signal m_arb_data   : std_logic_vector(7 downto 0);
  signal m_arb_valid  : std_logic;
  signal m_arb_ready  : std_logic;
  signal index        : std_logic_vector(fn_log2(c_num_streams)-1 downto 0);
  signal streams_out  : t_streams := (others => (s_data => (others => '0'), s_valid => '0', s_ready => '0', m_data => (others => '0'), m_valid => '0', m_ready => '0'));
  signal test_data    : t_slv_array(c_num_test_data-1 downto 0)(7 downto 0);

begin

  tb_clk <= '0' when all_done = (all_done'high downto all_done'low => true) else not tb_clk after c_clk_period / 2;
  tb_rst <= '1' when all_done = (all_done'high downto all_done'low => true) else '0' after 16 * c_clk_period;

  test_data <= fn_fill_test_data;

  b_gen_ctrl : for i in 0 to c_num_streams-1 generate

  p_write : process
    variable v_data : std_logic_vector(7 downto 0) := (others => '0');
  begin
    streams_in(i).s_data  <= (others => '0');
    streams_in(i).s_valid <= '0';

    wait until tb_rst = '0';
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
        1.0);
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
  begin
    streams_out(i).m_ready <= '0';

    wait until tb_rst = '0';
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      pr_read_stream(
        tb_clk,
        streams_out(i).m_data,
        streams_out(i).m_valid,
        streams_out(i).m_ready,
        v_data,
        100 * c_clk_period,
        1.0);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_string(test_data(j)) & " got " & to_string(v_data) severity warning;
    end loop;
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      pr_read_stream(
        tb_clk,
        streams_out(i).m_data,
        streams_out(i).m_valid,
        streams_out(i).m_ready,
        v_data,
        100 * c_clk_period,
        0.9);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_string(test_data(j)) & " got " & to_string(v_data) severity warning;
    end loop;
    wait until rising_edge(tb_clk);

    for j in 0 to c_num_test_data-1 loop
      pr_read_stream(
        tb_clk,
        streams_out(i).m_data,
        streams_out(i).m_valid,
        streams_out(i).m_ready,
        v_data,
        100 * c_clk_period,
        0.7);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_string(test_data(j)) & " got " & to_string(v_data) severity warning;
    end loop;

    all_done(i) <= true;
    wait until rising_edge(tb_clk);

    wait;
  end process;

  end generate b_gen_ctrl;

  i_dut_fallthrough : entity lib_common.reg_slice_fallthrough(rtl)
  generic map (
    t_data  => std_logic_vector(7 downto 0)
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => streams_in(0).s_data,
    s_valid => streams_in(0).s_valid,
    s_ready => streams_in(0).s_ready,
    m_data  => streams_in(0).m_data,
    m_valid => streams_in(0).m_valid,
    m_ready => streams_in(0).m_ready
  );

  i_dut_full : entity lib_common.reg_slice_full(rtl)
  generic map (
    t_data  => std_logic_vector(7 downto 0)
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => streams_in(1).s_data,
    s_valid => streams_in(1).s_valid,
    s_ready => streams_in(1).s_ready,
    m_data  => streams_in(1).m_data,
    m_valid => streams_in(1).m_valid,
    m_ready => streams_in(1).m_ready
  );

  i_dut_registered_input : entity lib_common.reg_slice_input(rtl)
  generic map (
    t_data  => std_logic_vector(7 downto 0)
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => streams_in(2).s_data,
    s_valid => streams_in(2).s_valid,
    s_ready => streams_in(2).s_ready,
    m_data  => streams_in(2).m_data,
    m_valid => streams_in(2).m_valid,
    m_ready => streams_in(2).m_ready
  );

  i_srl_fifo : entity lib_common.srl_fifo(rtl)
  generic map (
    t_data  => std_logic_vector(7 downto 0)
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => streams_in(3).s_data,
    s_valid => streams_in(3).s_valid,
    s_ready => streams_in(3).s_ready,
    m_data  => streams_in(3).m_data,
    m_valid => streams_in(3).m_valid,
    m_ready => streams_in(3).m_ready
  );

  i_fifo : entity lib_common.fifo(rtl)
  generic map (
    t_data  => std_logic_vector(7 downto 0)
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => streams_in(4).s_data,
    s_valid => streams_in(4).s_valid,
    s_ready => streams_in(4).s_ready,
    m_data  => streams_in(4).m_data,
    m_valid => streams_in(4).m_valid,
    m_ready => streams_in(4).m_ready
  );

  i_cdc_2phase : entity lib_common.cdc_2phase(rtl)
  generic map (
    t_data        => std_logic_vector(7 downto 0),
    g_reset_data  => false,
    g_reset_value => (others => '0')
  )
  port map (
    src_clk   => tb_clk,
    src_rst   => tb_rst,
    src_data  => streams_in(5).s_data,
    src_valid => streams_in(5).s_valid,
    src_ready => streams_in(5).s_ready,
    dst_clk   => tb_clk,
    dst_rst   => tb_rst,
    dst_data  => streams_in(5).m_data,
    dst_valid => streams_in(5).m_valid,
    dst_ready => streams_in(5).m_ready
  );

  i_cdc_fifo_2phase : entity lib_common.cdc_fifo_2phase(rtl)
  generic map (
    t_data  => std_logic_vector(7 downto 0)
  )
  port map (
    src_clk   => tb_clk,
    src_rst   => tb_rst,
    src_data  => streams_in(6).s_data,
    src_valid => streams_in(6).s_valid,
    src_ready => streams_in(6).s_ready,
    dst_clk   => tb_clk,
    dst_rst   => tb_rst,
    dst_data  => streams_in(6).m_data,
    dst_valid => streams_in(6).m_valid,
    dst_ready => streams_in(6).m_ready
  );

  i_cdc_fifo_gray : entity lib_common.cdc_fifo_gray(rtl)
  generic map (
    t_data  => std_logic_vector(7 downto 0)
  )
  port map (
    src_clk   => tb_clk,
    src_rst   => tb_rst,
    src_data  => streams_in(7).s_data,
    src_valid => streams_in(7).s_valid,
    src_ready => streams_in(7).s_ready,
    dst_clk   => tb_clk,
    dst_rst   => tb_rst,
    dst_data  => streams_in(7).m_data,
    dst_valid => streams_in(7).m_valid,
    dst_ready => streams_in(7).m_ready
  );

  b_arb_in : for i in 0 to c_num_streams-1 generate
    s_arb_data(i)         <= streams_in(i).m_data;
    s_arb_valid(i)        <= streams_in(i).m_valid;
    streams_in(i).m_ready <= s_arb_ready(i);
  end generate;

  i_arbiter_tree : entity lib_common.arbiter_tree(rtl)
  generic map (
    g_data_width  => 8,
    g_num_inputs  => c_num_streams
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => s_arb_data,
    s_valid => s_arb_valid,
    s_ready => s_arb_ready,
    m_data  => m_arb_data,
    m_valid => m_arb_valid,
    m_ready => m_arb_ready,
    index   => index
  );

  m_arb_ready <= streams_out(to_integer(unsigned(index))).m_ready;
  b_arb_out : for i in 0 to c_num_streams-1 generate
    streams_out(i).m_data   <= m_arb_data;
    streams_out(i).m_valid  <= m_arb_valid when i = to_integer(unsigned(index)) else '0';
  end generate;

end architecture tb;