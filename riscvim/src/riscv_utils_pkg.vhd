
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package riscv_utils_pkg is
  --
  --  TYPES
  --

  --! Unconstrained array type of std_logic_vector
  --!
  type t_slv_array is array(natural range <>) of std_logic_vector;
  --! Unconstrained array type of signed
  --!
  type t_signed_array is array(natural range <>) of signed;
  --! Unconstrained array type of unsigned
  --!
  type t_unsigned_array is array(natural range <>) of unsigned;

  --
  --  FUNCTIONS
  --
  function f_log2(n : positive) return natural;
  function f_log2nz(n : positive) return natural;
  function f_is_pow2(n : integer) return boolean;
  function f_ceil_pow2(n : integer) return integer;
  function f_ceil_div(n : natural; d : positive) return natural;
  function f_reverse(v : std_logic_vector; size : positive := 1; reverse : boolean := true) return std_logic_vector;
  function f_bit(i : integer) return std_logic;
  function f_bit(b : boolean) return std_logic;
  function f_integer(b : boolean) return integer;
  function "+"(l : integer; r : boolean) return integer;
  function "-"(l : integer; r : boolean) return integer;
  function "*"(l : integer; r : boolean) return integer;
  function f_cond(expr : boolean; a, b : std_logic) return std_logic;
  function f_cond(expr : boolean; a, b : std_logic_vector) return std_logic_vector;
  function f_cond(expr : boolean; a, b : unsigned) return unsigned;
  function f_cond(expr : boolean; a, b : signed) return signed;
  function f_cond(expr : boolean; a, b : integer) return integer;
  function f_cond(expr : boolean; a, b : real) return real;

end package riscv_utils_pkg;

package body riscv_utils_pkg is

  --
  --  FUNCTIONS
  --

  function f_log2(n : positive) return natural is
  begin
    return integer(ceil(log2(real(n))));
  end function;

  function f_log2nz(n : positive) return natural is
  begin
    return maximum(1, f_log2(n));
  end function;

  function f_is_pow2(n : integer) return boolean is
  begin
    return 2**f_log2(n) = n;
  end function;

  function f_ceil_pow2(n : integer) return integer is
  begin
    return 2**f_log2(n);
  end function;

  function f_ceil_div(n : natural; d : positive) return natural is
  begin
    return (n+d-1)/d;
  end function;

  function f_reverse(v : std_logic_vector; size : positive := 1; reverse : boolean := true) return std_logic_vector is
    constant c_l : natural := v'length;
    constant c_n : natural := c_l/size;
    variable v_v : std_logic_vector(v'length-1 downto 0);
    variable v_r : std_logic_vector(v'length-1 downto 0);
  begin
    assert c_l mod size = 0 and (c_l = size or (c_l/size mod 2 = 0)) report "f_reverse: invalid input";
    v_v := v;
    if reverse then
      for i in 0 to c_n-1 loop
        v_r((i+1)*size-1 downto i*size) := v_v(c_l-i*size-1 downto c_l-(i+1)*size);
      end loop;
    else
      v_r := v_v;
    end if;
    return v_r;
  end function;

  function f_bit(i : integer) return std_logic is
  begin
    if i /= 0 then return '1'; else return '0'; end if;
  end function;

  function f_bit(b : boolean) return std_logic is
  begin
    if b then return '1'; else return '0'; end if;
  end function;

  function f_integer(b : boolean) return integer is
  begin
    if b then return 1; else return 0; end if;
  end function;

  function "+"(l : integer; r : boolean) return integer is
  begin
    return l + f_integer(r);
  end function;

  function "-"(l : integer; r : boolean) return integer is
  begin
    return l - f_integer(r);
  end function;

  function "*"(l : integer; r : boolean) return integer is
  begin
    return l * f_integer(r);
  end function;

  function f_cond(expr : boolean; a, b : std_logic) return std_logic is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function;

  function f_cond(expr : boolean; a, b : std_logic_vector) return std_logic_vector is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function;

  function f_cond(expr : boolean; a, b : unsigned) return unsigned is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function;

  function f_cond(expr : boolean; a, b : signed) return signed is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function;

  function f_cond(expr : boolean; a, b : integer) return integer is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function;

  function f_cond(expr : boolean; a, b : real) return real is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function;

end package body riscv_utils_pkg;