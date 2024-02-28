--! @defgroup   COMMON_PKG common package
--!
--! @brief      This file implements common package.
--!
--! @author     Martin Caous George
--! @date       2023
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library lib_common;
use lib_common.common_pkg.all;
use lib_common.random_2008.all;

--! Common package
--!
package generic_stream_tb_pkg is

  generic (
    type t_data
  );

  procedure pr_write_stream(
    signal clk      : in    std_logic;
    signal m_data   : out   t_data;
    signal m_valid  : out   std_logic;
    signal m_ready  : in    std_logic;
    data            : in    t_data;
    timeout         : in    time;
    rate            : in    real := 1.0
  );

  procedure pr_read_stream(
    signal clk      : in    std_logic;
    signal s_data   : in    t_data;
    signal s_valid  : in    std_logic;
    signal s_ready  : out   std_logic;
    data            : out   t_data;
    timeout         : in    time;
    rate            : in    real := 1.0
  );

end package generic_stream_tb_pkg;

package body generic_stream_tb_pkg is

  procedure pr_write_stream(
    signal clk      : in    std_logic;
    signal m_data   : out   t_data;
    signal m_valid  : out   std_logic;
    signal m_ready  : in    std_logic;
    data            : in    t_data;
    timeout         : in    time;
    rate            : in    real := 1.0
  ) is
    variable v_timeout  : time;
  begin
    v_timeout := now + timeout;
    m_data  <= data;
    m_valid <= '0';
    while random > rate loop
      wait until rising_edge(clk);
      assert now < v_timeout report "pr_write_stream timeout" severity failure;
    end loop;
    v_timeout := now + timeout;
    m_valid <= '1';
    wait until rising_edge(clk);
    while m_valid /= '1' or m_ready /= '1' loop
      wait until rising_edge(clk);
      assert now < v_timeout report "pr_write_stream timeout" severity failure;
    end loop;
    m_valid <= '0';
  end procedure pr_write_stream;

  procedure pr_read_stream(
    signal clk      : in    std_logic;
    signal s_data   : in    t_data;
    signal s_valid  : in    std_logic;
    signal s_ready  : out   std_logic;
    data            : out   t_data;
    timeout         : in    time;
    rate            : in    real := 1.0
  ) is
    variable v_timeout  : time;
  begin
    v_timeout := now + timeout;
    s_ready <= '0';
    while random > rate loop
      wait until rising_edge(clk);
      assert now < v_timeout report "pr_read_stream timeout" severity failure;
    end loop;
    v_timeout := now + timeout;
    s_ready <= '1';
    wait until rising_edge(clk);
    while s_ready /= '1' or s_valid /= '1' loop
      wait until rising_edge(clk);
      assert now < v_timeout report "pr_read_stream timeout" severity failure;
    end loop;
    data    := s_data;
    s_ready <= '0';
  end procedure pr_read_stream;

end package body generic_stream_tb_pkg;