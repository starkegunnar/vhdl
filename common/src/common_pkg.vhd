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

--! Common package
--!
package common_pkg is

  --! Unconstrained array type of std_logic_vector
  --!
  type t_slv_array is array(natural range <>) of std_logic_vector;
  --! Unconstrained array type of signed
  --!
  type t_sig_array is array(natural range <>) of signed;
  --! Unconstrained array type of unsigned
  --!
  type t_usig_array is array(natural range <>) of unsigned;
  --! Unconstrained array type of unsigned
  --!
  type t_int_array is array(natural range <>) of integer;
  --! Unconstrained array type of boolean
  --!
  type t_bool_array is array(natural range <>) of boolean;

  --!
  --! @brief      Get minumum of two values
  --!
  --! @param      l     Left
  --! @param      r     Right
  --!
  --! @return     Minimum value
  --!
  function fn_min(l, r : integer) return integer;
  --!
  --! @brief      Get minumum value in list of values
  --!
  --! @param      list  The list of values
  --!
  --! @return     Minimum value
  --!
  function fn_min(list : t_int_array) return integer;
  --!
  --! @brief      Get maximum of two values
  --!
  --! @param      l     Left
  --! @param      r     Right
  --!
  --! @return     Maximum value
  --!
  function fn_max(l, r : integer) return integer;
  --!
  --! @brief      Get maximum value in list of values
  --!
  --! @param      list  The list of values
  --!
  --! @return     Maximum value
  --!
  function fn_max(list : t_int_array) return integer;
  --!
  --! @brief      Get binary logarithm of value
  --!
  --! @param      n     The value
  --!
  --! @return     Binary logarithm
  --!
  function fn_log2(n : integer) return integer;
  --!
  --! @brief      Get binary logarithm of value (non-zero result)
  --!
  --! @param      n     The value
  --!
  --! @return     Binary logarithm or 1 if result is less than 1
  --!
  function fn_log2nz(n : integer) return integer;
  --!
  --! @brief      Get ceil of integer division
  --!
  --! @param      n     Dividend
  --! @param      m     Divisor
  --!
  --! @return     Division quotient rounded up
  --!
  function fn_ceil_div(n, m : integer) return integer;
  --!
  --! @brief      Reverse order of elements
  --!
  --! @param      reverse Do reverse
  --! @param      v       Input vector
  --! @param      size    Reverse block size
  --!
  --! @return     Division quotient rounded up
  --!
  function fn_reverse(reverse boolean; v : std_logic_vector; size : positive) return std_logic_vector;
  --!
  --! @brief      Convert binary to gray code
  --!
  --! @param      bin     Binary input
  --!
  --! @return     Gray code representation of binary input
  --!
  function fn_bin2gray(bin : std_logic_vector) return std_logic_vector;
  --!
  --! @brief      Convert gray code to binary
  --!
  --! @param      bin     Gray code input
  --!
  --! @return     Binary representation of gray input
  --!
  function fn_gray2bin(gray : std_logic_vector) return std_logic_vector;

end package common_pkg;

package body common_pkg is

  function fn_min(l, r : integer) return integer is
  begin
    if l < r then
      return l;
    else
      return r;
    end if;
  end function fn_min;

  function fn_min(list : t_int_array) return integer is
    variable v_min : integer;
  begin
    v_min := list(0);
    for i in 1 to list'high loop
      if list(i) < v_min then
        v_min := list(i);
      end if;
    end loop;
    return v_min;
  end function fn_min;

  function fn_max(l, r : integer) return integer is
  begin
    if l < r then
      return r;
    else
      return l;
    end if;
  end function fn_max;

  function fn_max(list : t_int_array) return integer is
    variable v_max : integer;
  begin
    v_max := list(0);
    for i in 1 to list'high loop
      if v_max < list(i) then
        v_max := list(i);
      end if;
    end loop;
    return v_max;
  end function fn_max;

  function fn_log2(n : integer) return integer is
  begin
    return integer(ceil(log2(real(n))));
  end function fn_log2;

  function fn_log2nz(n : integer) return integer is
  begin
    return fn_max(1, fn_log2(n));
  end function fn_log2nz;

  function fn_ceil_div(n, m : integer) return integer is
  begin
    return integer(ceil(real(n)/real(m)));
  end function fn_ceil_div;

  function fn_reverse(reverse boolean; v : std_logic_vector; size : natural) return std_logic_vector is
    constant c_l : natural := v'length;
    constant c_n : natural := c_l/size;
    variable v_v : std_logic_vector(v'length-1 downto 0);
    variable v_r : std_logic_vector(v'length-1 downto 0);
  begin
    assert c_l mod size = 0 and (c_l = size or (c_l/size mod 2 = 0)) report "fn_reverse: invalid input";
    v_v := v;
    if reverse then
      for i in 0 to c_n-1 loop
        v_r((i+1)*size-1 downto i*size) := v_v(c_l-i*size-1 downto c_l-(i+1)*size);
      end loop;
    else
      v_r := v_v;
    end if;
    return v_r;
  end function fn_reverse;

  function fn_bin2gray(bin : std_logic_vector) return std_logic_vector is
  begin
    return bin xor ('0' & bin(bin'high downto bin'low+1));
  end function fn_bin2gray;

  function fn_gray2bin(gray : std_logic_vector) return std_logic_vector is
    variable v_bin  : std_logic_vector(gray'high+1 downto gray'low);
  begin
    v_bin(v_bin'high) := '0';
    for i in gray'high downto gray'low loop
      v_bin(i) := v_bin(i + 1) xor gray(i);
    end loop;
    return v_bin(gray'range);
  end function fn_gray2bin;

end package body common_pkg;