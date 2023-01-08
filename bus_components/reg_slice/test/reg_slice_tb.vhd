library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_bus_common;
library lib_common;
use lib_common.random_2008.all;
library lib_bus_testbench;
use lib_bus_testbench.axis_pkg.all;

entity reg_slice_tb is
end entity reg_slice_tb;

architecture tb of reg_slice_tb is

  type t_all_done is array (0 to 3) of boolean;
  type t_reg_slice is record
    i_data  : std_logic_vector(7 downto 0);
    i_valid : std_logic;
    o_ready : std_logic;
    o_data  : std_logic_vector(7 downto 0);
    o_valid : std_logic;
    i_ready : std_logic;
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
    reg_slices(i).i_data  <= (others => '0');
    reg_slices(i).i_valid <= '0';

    wait until tb_rst = '0';
    wait until rising_edge(tb_clk);

    for j in test_data'range loop
      v_data := test_data(j);
      pcdr_write(
        tb_clk,
        reg_slices(i).i_data,
        reg_slices(i).i_valid,
        reg_slices(i).o_ready,
        v_data,
        100 * c_clk_period,
        0.7);
    end loop;

    wait;
  end process;

  p_read : process
    variable v_data : std_logic_vector(7 downto 0);
  begin
    reg_slices(i).i_ready <= '0';

    wait until tb_rst = '0';
    wait until rising_edge(tb_clk);

    for j in test_data'range loop
      pcdr_read(
        tb_clk,
        reg_slices(i).o_data,
        reg_slices(i).o_valid,
        reg_slices(i).i_ready,
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

  i_dut_full_impl : entity lib_bus_common.reg_slice(rtl)
  generic map (
    g_data_width  => 8,
    g_impl        => "full"
  )
  port map (
    i_clk     => tb_clk,
    i_rst     => tb_rst,
    i_data    => reg_slices(0).i_data,
    i_valid   => reg_slices(0).i_valid,
    o_ready   => reg_slices(0).o_ready,
    o_data    => reg_slices(0).o_data,
    o_valid   => reg_slices(0).o_valid,
    i_ready   => reg_slices(0).i_ready
  );

  i_dut_half_impl : entity lib_bus_common.reg_slice(rtl)
  generic map (
    g_data_width  => 8,
    g_impl        => "half"
  )
  port map (
    i_clk     => tb_clk,
    i_rst     => tb_rst,
    i_data    => reg_slices(1).i_data,
    i_valid   => reg_slices(1).i_valid,
    o_ready   => reg_slices(1).o_ready,
    o_data    => reg_slices(1).o_data,
    o_valid   => reg_slices(1).o_valid,
    i_ready   => reg_slices(1).i_ready
  );

  i_dut_registered_input : entity lib_bus_common.reg_slice(rtl)
  generic map (
    g_data_width  => 8,
    g_impl        => "reg_input"
  )
  port map (
    i_clk     => tb_clk,
    i_rst     => tb_rst,
    i_data    => reg_slices(2).i_data,
    i_valid   => reg_slices(2).i_valid,
    o_ready   => reg_slices(2).o_ready,
    o_data    => reg_slices(2).o_data,
    o_valid   => reg_slices(2).o_valid,
    i_ready   => reg_slices(2).i_ready
  );

  i_dut_passthrough : entity lib_bus_common.reg_slice(rtl)
  generic map (
    g_data_width  => 8,
    g_impl        => "passthrough"
  )
  port map (
    i_clk     => tb_clk,
    i_rst     => tb_rst,
    i_data    => reg_slices(3).i_data,
    i_valid   => reg_slices(3).i_valid,
    o_ready   => reg_slices(3).o_ready,
    o_data    => reg_slices(3).o_data,
    o_valid   => reg_slices(3).o_valid,
    i_ready   => reg_slices(3).i_ready
  );

end architecture tb;