--! @defgroup   COMMON_PKG common package
--!
--! @brief      This file implements common package.
--!
--! @author     Martin Caous George
--! @date       2022
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
package common_tb_pkg is

  procedure pr_write_stream(
      generic (
        type t_data;
      )
      parameter (
      signal i_clk    : in    std_logic;
      signal o_data   : out   t_data;
      signal o_valid  : inout std_logic;
      signal i_ready  : in    std_logic;
      i_data          : in    t_data;
      i_timeout       : in    time;
      i_rate          : in    real := 1.0
      );
  );

  procedure pr_read_stream(
    generic (
      type t_data;
    )
    parameter (
      signal i_clk    : in    std_logic;
      signal i_data   : in    t_data;
      signal i_valid  : in    std_logic;
      signal o_ready  : inout std_logic;
      o_data          : out   t_data;
      i_timeout       : in    time;
      i_rate          : in    real := 1.0
    );
  );

end package common_tb_pkg;

package body common_tb_pkg is

  procedure pr_write_stream(
    generic (
      type t_data;
    )
    parameter (
      signal clk      : in    std_logic;
      signal m_data   : out   t_data;
      signal m_valid  : inout std_logic;
      signal m_ready  : in    std_logic;
      data            : in    t_data;
      timeout         : in    time;
      rate            : in    real := 1.0
    );
  ) is
    variable v_timeout  : time;
  begin
    v_timeout := now + timeout;
    m_data  <= i_data;
    m_valid <= '0';
    while random > rate loop
      wait until rising_edge(clk);
      assert now < v_timeout report "pcdr_write_stream timeout" severity failure;
    end loop;
    v_timeout := now + timeout;
    m_valid <= '1';
    wait until rising_edge(clk);
    while m_valid = '0' or m_ready = '0' loop
      wait until rising_edge(clk);
      assert now < v_timeout report "pcdr_write_stream timeout" severity failure;
    end loop;
    m_valid <= '0';
  end procedure pcdr_write_stream;

  procedure pr_read_stream(
    generic (
      type t_data;
    )
    parameter (
    signal clk      : in    std_logic;
    signal s_data   : in    t_data;
    signal s_valid  : in    std_logic;
    signal s_ready  : inout std_logic;
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
      assert now < v_timeout report "pcdr_read_stream timeout" severity failure;
    end loop;
    v_timeout := now + timeout;
    s_ready <= '1';
    wait until rising_edge(clk);
    while s_ready = '0' or s_valid = '0' loop
      wait until rising_edge(clk);
      assert now < v_timeout report "pcdr_read_stream timeout" severity failure;
    end loop;
    s_data  := data;
    s_ready <= '0';
  end procedure pcdr_read_stream;

end package body common_tb_pkg;