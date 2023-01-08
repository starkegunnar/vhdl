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

end package body common_pkg;