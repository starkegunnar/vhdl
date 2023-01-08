library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library lib_common;
use lib_common.random_2008.all;

package axis_pkg is

  procedure pcdr_write(
    signal i_clk    : in    std_logic;
    signal o_data   : out   std_logic_vector;
    signal o_valid  : inout std_logic;
    signal i_ready  : in    std_logic;
    i_data          : in    std_logic_vector;
    i_timeout       : in    time;
    i_rate          : in    real := 1.0
  );

  procedure pcdr_read(
    signal i_clk    : in    std_logic;
    signal i_data   : in    std_logic_vector;
    signal i_valid  : in    std_logic;
    signal o_ready  : inout std_logic;
    o_data          : out   std_logic_vector;
    i_timeout       : in    time;
    i_rate          : in    real := 1.0
  );

end package axis_pkg;

package body axis_pkg is

  procedure pcdr_write(
    signal i_clk    : in    std_logic;
    signal o_data   : out   std_logic_vector;
    signal o_valid  : inout std_logic;
    signal i_ready  : in    std_logic;
    i_data          : in    std_logic_vector;
    i_timeout       : in    time;
    i_rate          : in    real := 1.0
  ) is
    variable v_timeout  : time;
  begin
    v_timeout := now + i_timeout;
    o_data  <= i_data;
    o_valid <= '0';
    while random > i_rate loop
      wait until rising_edge(i_clk);
      assert now < v_timeout report "pcdr_write timeout" severity failure;
    end loop;
    v_timeout := now + i_timeout;
    o_valid <= '1';
    wait until rising_edge(i_clk);
    while o_valid = '0' or i_ready = '0' loop
      wait until rising_edge(i_clk);
      assert now < v_timeout report "pcdr_write timeout" severity failure;
    end loop;
    o_valid <= '0';
  end procedure;

  procedure pcdr_read(
    signal i_clk    : in    std_logic;
    signal i_data   : in    std_logic_vector;
    signal i_valid  : in    std_logic;
    signal o_ready  : inout std_logic;
    o_data          : out   std_logic_vector;
    i_timeout       : in    time;
    i_rate          : in    real := 1.0
  ) is
    variable v_timeout  : time;
  begin
    v_timeout := now + i_timeout;
    o_ready <= '0';
    while random > i_rate loop
      wait until rising_edge(i_clk);
      assert now < v_timeout report "pcdr_read timeout" severity failure;
    end loop;
    v_timeout := now + i_timeout;
    o_ready <= '1';
    wait until rising_edge(i_clk);
    while o_ready = '0' or i_valid = '0' loop
      wait until rising_edge(i_clk);
      assert now < v_timeout report "pcdr_read timeout" severity failure;
    end loop;
    o_data  := i_data;
    o_ready <= '0';
  end procedure;

end package body axis_pkg;