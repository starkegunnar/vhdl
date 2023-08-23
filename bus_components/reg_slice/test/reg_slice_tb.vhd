library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_bus_components;
library lib_common;
use lib_common.random_2008.all;
library lib_bus_testbench;
use lib_bus_testbench.axis_pkg.all;

entity reg_slice_tb is
end entity reg_slice_tb;

architecture tb of reg_slice_tb is

  type t_all_done is array (0 to 3) of boolean;
  type t_reg_slice is record
    s_data  : std_logic_vector(7 downto 0);
    s_valid : std_logic;
    s_ready : std_logic;
    m_data  : std_logic_vector(7 downto 0);
    m_valid : std_logic;
    m_ready : std_logic;
  end record;
  type t_reg_slices is array (0 to 3) of t_reg_slice;
  type t_slv_array is array (0 to 255) of std_logic_vector(7 downto 0);

  impure function fn_fill_test_data return t_slv_array is
    variable v_test_data : t_slv_array;
  begin
    for i in v_test_data'range loop
      v_test_data(i) := random(8);
    end loop;
    return v_test_data;
  end function fn_fill_test_data;

  constant c_clk_period : time := 10 ns;

  signal tb_clk : std_logic := '0';
  signal tb_rst : std_logic := '1';

  signal all_done : t_all_done := (others => false);

  signal reg_slices : t_reg_slices;
  signal test_data : t_slv_array;

begin

  tb_clk <= '0' when all_done = (all_done'low to all_done'high => true) else not tb_clk after c_clk_period / 2;
  tb_rst <= '1' when all_done = (all_done'low to all_done'high => true) else '0' after 3 * c_clk_period;

  test_data <= fn_fill_test_data;

  b_gen_ctrl : for i in 0 to 3 generate

  p_write : process
    variable v_data : std_logic_vector(7 downto 0);
  begin
    reg_slices(i).s_data  <= (others => '0');
    reg_slices(i).s_valid <= '0';

    wait until tb_rst = '0';
    wait until rising_edge(tb_clk);

    for j in test_data'range loop
      v_data := test_data(j);
      pcdr_write(
        tb_clk,
        reg_slices(i).s_data,
        reg_slices(i).s_valid,
        reg_slices(i).s_ready,
        v_data,
        100 * c_clk_period,
        1.0);
    end loop;
    wait until rising_edge(tb_clk);

    for j in test_data'range loop
      v_data := test_data(j);
      pcdr_write(
        tb_clk,
        reg_slices(i).s_data,
        reg_slices(i).s_valid,
        reg_slices(i).s_ready,
        v_data,
        100 * c_clk_period,
        0.7);
    end loop;
    wait until rising_edge(tb_clk);

    for j in test_data'range loop
      v_data := test_data(j);
      pcdr_write(
        tb_clk,
        reg_slices(i).s_data,
        reg_slices(i).s_valid,
        reg_slices(i).s_ready,
        v_data,
        100 * c_clk_period,
        0.9);
    end loop;

    wait;
  end process;

  p_read : process
    variable v_data : std_logic_vector(7 downto 0);
  begin
    reg_slices(i).m_ready <= '0';

    wait until tb_rst = '0';
    wait until rising_edge(tb_clk);

    for j in test_data'range loop
      pcdr_read(
        tb_clk,
        reg_slices(i).m_data,
        reg_slices(i).m_valid,
        reg_slices(i).m_ready,
        v_data,
        100 * c_clk_period,
        1.0);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_hstring(test_data(j)) & " got " & to_hstring(v_data) severity warning;
    end loop;
    wait until rising_edge(tb_clk);

    for j in test_data'range loop
      pcdr_read(
        tb_clk,
        reg_slices(i).m_data,
        reg_slices(i).m_valid,
        reg_slices(i).m_ready,
        v_data,
        100 * c_clk_period,
        0.9);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_hstring(test_data(j)) & " got " & to_hstring(v_data) severity warning;
    end loop;
    wait until rising_edge(tb_clk);

    for j in test_data'range loop
      pcdr_read(
        tb_clk,
        reg_slices(i).m_data,
        reg_slices(i).m_valid,
        reg_slices(i).m_ready,
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

  i_dut_full_impl : entity lib_bus_components.reg_slice(rtl)
  generic map (
    g_data_width  => 8,
    g_impl        => "full"
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => reg_slices(0).s_data,
    s_valid => reg_slices(0).s_valid,
    s_ready => reg_slices(0).s_ready,
    m_data  => reg_slices(0).m_data,
    m_valid => reg_slices(0).m_valid,
    m_ready => reg_slices(0).m_ready
  );

  i_dut_half_impl : entity lib_bus_components.reg_slice(rtl)
  generic map (
    g_data_width  => 8,
    g_impl        => "half"
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => reg_slices(1).s_data,
    s_valid => reg_slices(1).s_valid,
    s_ready => reg_slices(1).s_ready,
    m_data  => reg_slices(1).m_data,
    m_valid => reg_slices(1).m_valid,
    m_ready => reg_slices(1).m_ready
  );

  i_dut_registered_input : entity lib_bus_components.reg_slice(rtl)
  generic map (
    g_data_width  => 8,
    g_impl        => "reg_input"
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => reg_slices(2).s_data,
    s_valid => reg_slices(2).s_valid,
    s_ready => reg_slices(2).s_ready,
    m_data  => reg_slices(2).m_data,
    m_valid => reg_slices(2).m_valid,
    m_ready => reg_slices(2).m_ready
  );

  i_dut_passthrough : entity lib_bus_components.reg_slice(rtl)
  generic map (
    g_data_width  => 8,
    g_impl        => "passthrough"
  )
  port map (
    clk     => tb_clk,
    rst     => tb_rst,
    s_data  => reg_slices(3).s_data,
    s_valid => reg_slices(3).s_valid,
    s_ready => reg_slices(3).s_ready,
    m_data  => reg_slices(3).m_data,
    m_valid => reg_slices(3).m_valid,
    m_ready => reg_slices(3).m_ready
  );

end architecture tb;