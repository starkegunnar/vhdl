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
  type t_signed_array is array(natural range <>) of signed;
  --! Unconstrained array type of unsigned
  --!
  type t_unsigned_array is array(natural range <>) of unsigned;

  --! Register slice type
  --!
  type t_reg_slice_type is (
    e_reg_slice_full,
    e_reg_slice_fallthrough,
    e_reg_slice_srl,
    e_reg_slice_passthrough
  );

  --! RAM read mode
  --!
  type t_ram_mode is (
    e_ram_read_first,
    e_ram_write_first,
    e_ram_no_change
  );

  --!
  --! @brief      Get binary logarithm of value
  --!
  --! @param      n     The value
  --!
  --! @return     Binary logarithm
  --!
  function f_log2(n : integer) return integer;
  --!
  --! @brief      Get binary logarithm of value (non-zero result)
  --!
  --! @param      n     The value
  --!
  --! @return     Binary logarithm or 1 if result is less than 1
  --!
  function f_log2nz(n : integer) return integer;
  --!
  --! @brief      Check if value is power of two
  --!
  --! @param      n     Value to check
  --!
  --! @return     True if value is power of two, False otherwise
  --!
  function f_is_pow2(n : integer) return boolean;
  --!
  --! @brief      Get value rounded to next power of two
  --!
  --! @param      n     Value to get next power of two of
  --!
  --! @return     Value rounded to next power of two
  --!
  function f_ceil_pow2(n : integer) return integer;
  --!
  --! @brief      Get ceil of integer division
  --!
  --! @param      n     Dividend
  --! @param      m     Divisor
  --!
  --! @return     Division quotient rounded up
  --!
  function f_ceil_div(n, m : integer) return integer;
  --!
  --! @brief      Reverse order of elements
  --!
  --! @param      v       Input vector
  --! @param      size    Reverse block size
  --! @param      reverse Do reverse
  --!
  --! @return     Division quotient rounded up
  --!
  function f_reverse(v : std_logic_vector; size : positive := 1; reverse : boolean := true) return std_logic_vector;
  --!
  --! @brief      Convert binary to gray code
  --!
  --! @param      bin     Binary input
  --!
  --! @return     Gray code representation of binary input
  --!
  function f_bin2gray(bin : std_logic_vector) return std_logic_vector;
  function f_bin2gray(bin : unsigned) return unsigned;
  --!
  --! @brief      Convert gray code to binary
  --!
  --! @param      bin     Gray code input
  --!
  --! @return     Binary representation of gray input
  --!
  function f_gray2bin(gray : std_logic_vector) return std_logic_vector;
  function f_gray2bin(gray : unsigned) return unsigned;
  --!
  --! @brief      Count number of ones in vector
  --!
  --! @param      v       Vector to count ones in
  --!
  --! @return     Number of ones in vector v
  --!
  function f_count_ones(v : std_logic_vector) return natural;

  function f_onehot2bin(v : std_logic_vector; empty_value : integer := -1) return std_logic_vector;

  function f_lssb(v : std_logic_vector) return std_logic_vector;
  function f_mssb(v : std_logic_vector) return std_logic_vector;
  function f_lssb_index(v : std_logic_vector) return integer;
  function f_mssb_index(v : std_logic_vector) return integer;
  --!
  function f_cond(expr : boolean; a, b : std_logic) return std_logic;
  function f_cond(expr : boolean; a, b : std_logic_vector) return std_logic_vector;
  function f_cond(expr : boolean; a, b : unsigned) return unsigned;
  function f_cond(expr : boolean; a, b : signed) return signed;
  function f_cond(expr : boolean; a, b : integer) return integer;
  function f_cond(expr : boolean; a, b : real) return real;

  procedure pr_prio_enc(
    signal req        : in  std_logic_vector;
    signal gnt        : out std_logic_vector;
    signal gnt_index  : out std_logic_vector;
    signal gnt_valid  : out std_logic
  );

  procedure pr_lzc(
    signal din    : in  std_logic_vector;
    signal cnt    : out std_logic_vector;
    signal empty  : out std_logic
  );


end package common_pkg;

package body common_pkg is

  function f_log2(n : integer) return integer is
  begin
    return integer(ceil(log2(real(n))));
  end function f_log2;

  function f_log2nz(n : integer) return integer is
  begin
    return maximum(1, f_log2(n));
  end function f_log2nz;

  function f_is_pow2(n : integer) return boolean is
  begin
    return 2**f_log2(n) = n;
  end function f_is_pow2;

  function f_ceil_pow2(n : integer) return integer is
  begin
    return 2**f_log2(n);
  end function f_ceil_pow2;

  function f_ceil_div(n, m : integer) return integer is
  begin
    return integer(ceil(real(n)/real(m)));
  end function f_ceil_div;

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
  end function f_reverse;

  function f_bin2gray(bin : std_logic_vector) return std_logic_vector is
  begin
    return bin xor ('0' & bin(bin'high downto bin'low+1));
  end function f_bin2gray;

  function f_bin2gray(bin : unsigned) return unsigned is
  begin
    return bin xor ('0' & bin(bin'high downto bin'low+1));
  end function f_bin2gray;

  function f_gray2bin(gray : std_logic_vector) return std_logic_vector is
    variable v_bin  : std_logic_vector(gray'high+1 downto gray'low);
  begin
    v_bin(v_bin'high) := '0';
    for i in gray'high downto gray'low loop
      v_bin(i) := v_bin(i + 1) xor gray(i);
    end loop;
    return v_bin(gray'range);
  end function f_gray2bin;

  function f_gray2bin(gray : unsigned) return unsigned is
    variable v_bin  : unsigned(gray'high+1 downto gray'low);
  begin
    v_bin(v_bin'high) := '0';
    for i in gray'high downto gray'low loop
      v_bin(i) := v_bin(i + 1) xor gray(i);
    end loop;
    return v_bin(gray'range);
  end function f_gray2bin;

  function f_count_ones(v : std_logic_vector) return natural is
    variable v_ones : natural range 0 to v'length := 0;
  begin
    for i in v'range loop
      if v(i) = '1' then
        v_ones := v_ones + 1;
      end if;
    end loop;
    return v_ones;
  end function f_count_ones;

  function f_onehot2bin(v : std_logic_vector; empty_value : integer := -1) return std_logic_vector is
    variable v_r : unsigned(f_log2nz(maximum(v'high, empty_value)+1)-1 downto 0);
  begin
    if empty_value > 0 and v = (v'range => '0') then
      v_r := to_unsigned(empty_value, v_r'length);
    else
      if f_count_ones(v) /= 1 and (empty_value < 0 or f_count_ones(v) > 1) then
        report "f_onehot2bin: invalid input vector, not onehot" severity warning;
      end if;
      for i in v'range loop
        if v(i) = '1' then
          v_r := v_r + to_unsigned(i, v_r'length);
        end if;
      end loop;
    end if;
    return std_logic_vector(v_r);
  end function f_onehot2bin;

  function f_lssb(v : std_logic_vector) return std_logic_vector is
  begin
    return v and std_logic_vector(-signed(v));
  end function f_lssb;

  function f_mssb(v : std_logic_vector) return std_logic_vector is
  begin
    return f_reverse(f_lssb(f_reverse(v)));
  end function f_mssb;

  function f_lssb_index(v : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(f_onehot2bin(f_lssb(v))));
  end function f_lssb_index;

  function f_mssb_index(v : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(f_onehot2bin(f_mssb(v))));
  end function f_mssb_index;


  function f_cond(expr : boolean; a, b : std_logic) return std_logic is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function f_cond;

  function f_cond(expr : boolean; a, b : std_logic_vector) return std_logic_vector is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function f_cond;

  function f_cond(expr : boolean; a, b : unsigned) return unsigned is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function f_cond;

  function f_cond(expr : boolean; a, b : signed) return signed is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function f_cond;

  function f_cond(expr : boolean; a, b : integer) return integer is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function f_cond;

  function f_cond(expr : boolean; a, b : real) return real is
  begin
    if expr then
      return a;
    else
      return b;
    end if;
  end function f_cond;

  procedure pr_prio_enc(
    signal req        : in  std_logic_vector;
    signal gnt        : out std_logic_vector;
    signal gnt_index  : out std_logic_vector;
    signal gnt_valid  : out std_logic
  ) is
    constant c_lvls : natural := f_log2(req'length);
    type t_node is record
      r : std_logic;
      g : std_logic;
      i : std_logic_vector(f_log2nz(req'length)-1 downto 0);
      s : std_logic;
    end record;
    type t_nodes is array(0 to 2**c_lvls-2) of t_node;
    variable curr   : natural;
    variable prev   : natural;
    variable nodes  : t_nodes;
  begin
    if req'length > 1 then
      l_tree_down : for i in c_lvls-1 downto 0 loop
        l_leaf_down : for j in 2**i-1 downto 0 loop
          curr := 2**i-1+j;
          prev := 2**(i+1)+2*j-1;
          if i = c_lvls-1 then
            if 2*j < req'length-1 then
              nodes(curr).r     := or req(2*j+1 downto 2*j);
              nodes(curr).s     := not req(2*j);
              nodes(curr).i(0)  := not req(2*j);
            elsif 2*j = req'length-1 then
              nodes(curr).r     := req(2*j);
              nodes(curr).s     := '0';
              nodes(curr).i(0)  := '0';
            else
              nodes(curr).r     := '0';
              nodes(curr).s     := '0';
              nodes(curr).i(0)  := '0';
            end if;
          else
            nodes(curr).r := nodes(prev+1).r or nodes(prev).r;
            nodes(curr).s := not nodes(prev).r;
            if nodes(curr).s = '1' then
              nodes(curr).i(c_lvls-i-1 downto 0) := '1' & nodes(prev+1).i(c_lvls-i-2 downto 0);
            else
              nodes(curr).i(c_lvls-i-1 downto 0) := '0' & nodes(prev).i(c_lvls-i-2 downto 0);
            end if;
          end if;
        end loop;
      end loop;

      gnt_valid <= nodes(0).r;
      gnt_index <= nodes(0).i;

      nodes(0).g := '1';

      l_tree_up : for i in 0 to c_lvls-1 loop
        l_leaf_up : for j in 0 to 2**i-1 loop
          curr := 2**i-1+j;
          prev := 2**(i+1)+2*j-1;
          if i = c_lvls-1 then
            if 2*j < req'length-1 then
              gnt(2*j+1)  <= nodes(curr).g and nodes(curr).s;
              gnt(2*j)    <= nodes(curr).g and not nodes(curr).s;
            elsif 2*j = req'length-1 then
              gnt(2*j)    <= nodes(curr).g;
            end if;
          else
            nodes(prev+1).g := nodes(curr).g and nodes(curr).s;
            nodes(prev).g   := nodes(curr).g and not nodes(curr).s;
          end if;
        end loop;
      end loop;
    else
      gnt       <= req;
      gnt_index <= "0";
      gnt_valid <= req(0);
    end if;
  end procedure;

  procedure pr_lzc(
    signal din    : in  std_logic_vector;
    signal cnt    : out std_logic_vector;
    signal empty  : out std_logic
  ) is
    constant c_levels   : natural := f_log2(din'length);
    variable cnt_nodes  : t_slv_array(2**c_levels-1 downto 0)(c_levels-1 downto 0) := (others => (others => '0'));
    variable sel_nodes  : std_logic_vector(2**c_levels-1 downto 0) := (others => '0');
    variable idx_nodes  : t_slv_array(din'length-1 downto 0)(c_levels-1 downto 0);
  begin
    assert cnt'length = c_levels
      report "pr_lzc: invalid cnt width "&integer'image(cnt'length)&", expected "&integer'image(c_levels)
      severity failure;
    if c_levels = 0 then
      cnt   <= not din;
      empty <= not din(0);
    else
      for i in idx_nodes'range loop
        idx_nodes(i) := std_logic_vector(to_unsigned(i,cnt'length));
      end loop;
      for i in c_levels-1 downto 0 loop
        for j in 2**i-1 downto 0 loop
          if i = c_levels-1 then
            if 2*j < din'length-1 then
              sel_nodes(2**i-1+j) := din(2*j) or din(2*j+1);
              if din(2*j) = '1' then
                cnt_nodes(2**i-1+j) := idx_nodes(2*j);
              else
                cnt_nodes(2**i-1+j) := idx_nodes(2*j+1);
              end if;
            elsif 2*j = din'length-1 then
              sel_nodes(2**i-1+j) := din(2*j);
              cnt_nodes(2**i-1+j) := idx_nodes(2*j);
            end if;
          else
            sel_nodes(2**i-1+j) := sel_nodes(2**(i+1)+2*j-1) or sel_nodes(2**(i+1)+2*j);
            if sel_nodes(2**(i+1)+2*j-1) = '1' then
              cnt_nodes(2**i-1+j) := cnt_nodes(2**(i+1)+2*j-1);
            else
              cnt_nodes(2**i-1+j) := cnt_nodes(2**(i+1)+2*j);
            end if;
          end if;
        end loop;
      end loop;

      cnt   <= cnt_nodes(0);
      empty <= nor(din);
    end if;
  end procedure;

end package body common_pkg;