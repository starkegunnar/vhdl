library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_cdc;
library lib_bus_components;
library lib_common;
use lib_common.random_2008.all;
use lib_bus_components.axis_pkg.all;

entity cdc_bus_tb is
end entity cdc_bus_tb;

architecture tb of cdc_bus_tb is

  type t_all_done is array (0 to 0) of boolean;
  type t_reg_slice is record
    s_data  : std_logic_vector(7 downto 0);
    s_valid : std_logic;
    s_ready : std_logic;
    m_data  : std_logic_vector(7 downto 0);
    m_valid : std_logic;
    m_ready : std_logic;
  end record;
  type t_reg_slices is array (0 to 0) of t_reg_slice;
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

  signal tb_s_clk : std_logic := '0';
  signal tb_m_clk : std_logic := '0';
  signal tb_rst   : std_logic := '1';

  signal all_done : t_all_done := (others => false);

  signal reg_slices : t_reg_slices;
  signal test_data : t_slv_array;

begin

  tb_s_clk <= '0' when all_done = (all_done'low to all_done'high => true) else not tb_s_clk after c_clk_period / 2;
  tb_m_clk <= '0' when all_done = (all_done'low to all_done'high => true) else not tb_m_clk after c_clk_period / 3;
  tb_rst <= '1' when all_done = (all_done'low to all_done'high => true) else '0' after 3 * c_clk_period;

  test_data <= fn_fill_test_data;

  b_gen_ctrl : for i in 0 to 3 generate

  p_write : process
    variable v_data : std_logic_vector(7 downto 0);
  begin
    reg_slices(i).s_data  <= (others => '0');
    reg_slices(i).s_valid <= '0';

    wait until tb_rst = '0';
    wait until rising_edge(tb_s_clk);

    for j in test_data'range loop
      v_data := test_data(j);
      pcdr_write(
        tb_s_clk,
        reg_slices(i).s_data,
        reg_slices(i).s_valid,
        reg_slices(i).s_ready,
        v_data,
        100 * c_clk_period,
        0.7);
    end loop;

    wait;
  end process;

  p_read : process
    variable v_data : std_logic_vector(7 downto 0);
  begin
    reg_slices(i).m_ready <= '0';

    wait until tb_rst = '0';
    wait until rising_edge(tb_m_clk);

    for j in test_data'range loop
      pcdr_read(
        tb_m_clk,
        reg_slices(i).m_data,
        reg_slices(i).m_valid,
        reg_slices(i).m_ready,
        v_data,
        100 * c_clk_period,
        0.7);
      assert v_data = test_data(j) report "Read data mismatch, expected " & to_hstring(test_data(j)) & " got " & to_hstring(v_data) severity warning;
    end loop;

    all_done(i) <= true;
    wait until rising_edge(tb_m_clk);

    wait;
  end process;

  end generate b_gen_ctrl;

  i_dut : entity lib_cdc.cdc_bus(rtl)
  generic map (
    g_data_width  => 8,
  )
  port map (
    src_clk   => tb_s_clk,
    src_rst   => tb_rst,
    src_data  => reg_slices(0).s_data,
    src_valid => reg_slices(0).s_valid,
    src_ready => reg_slices(0).s_ready,
    dst_clk   => tb_m_clk,
    dst_rst   => tb_rst,
    dst_data  => reg_slices(0).m_data,
    dst_valid => reg_slices(0).m_valid,
    dst_ready => reg_slices(0).m_ready
  );


end architecture tb;