library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity riscvim_alu is
  port (
    alu_op    : in  std_logic_vector(t_alu_op_range);
    op_a      : in  std_logic_vector(t_xlen_range);
    op_b      : in  std_logic_vector(t_xlen_range);

    res       : out std_logic_vector(t_xlen_range) := (others => '0');
    cmp_res   : out std_logic
  );
end entity;

architecture rtl of riscvim_alu is

  signal adder_op_b : unsigned(t_xlen_range);
  signal adder_res  : std_logic_vector(t_xlen_range);

  signal shift_op_a : signed(c_xlen downto 0);
  signal shift_res  : std_logic_vector(c_xlen-1 downto 0);

  signal cmp_eq     : std_logic;
  signal cmp_lt     : std_logic;

begin

  -- Adder
  -- alu_op(3) => negate op_b
  adder_op_b  <= unsigned(-signed(op_b)) when alu_op(3) = '1' else unsigned(op_b);
  adder_res   <= std_logic_vector(unsigned(op_a) + adder_op_b);

  -- Shifter
  -- alu_op(2) => bit reverse when '0'
  -- alu_op(3) => sign extend
  shift_op_a  <= signed((op_a(c_xhi) and alu_op(3)) & f_reverse(op_a, 1, (alu_op(2) = '0')));
  shift_res   <= std_logic_vector(resize(shift_right(shift_op_a, to_integer(unsigned(op_b(4 downto 0)))), c_xlen));

  -- Compare
  -- alu_op(3) => sign extend
  cmp_eq <= '1' when op_a = op_b else '0';
  cmp_lt <= '1' when signed((op_a(c_xhi) and alu_op(3)) & op_a) < signed((op_b(c_xhi) and alu_op(3)) & op_b) else '0';
  p_cmp : process(all)
  begin
    cmp_res <= '0';
    case alu_op(2 downto 0) is
    when c_alu_op_eq(2 downto 0) =>
      cmp_res <= cmp_eq;
    when c_alu_op_ne(2 downto 0) =>
      cmp_res <= not cmp_eq;
    when c_alu_op_slt(2 downto 0) | c_alu_op_lt(2 downto 0) | c_alu_op_sltu(2 downto 0) | c_alu_op_ltu(2 downto 0) =>
      cmp_res <= cmp_lt;
    when c_alu_op_ge(2 downto 0) | c_alu_op_geu(2 downto 0) =>
      cmp_res <= not cmp_lt;
    when others =>
    end case;
  end process;

  -- Result mux
  p_res : process(all)
  begin
    res <= (others => '0');
    case alu_op is
    when c_alu_op_add | c_alu_op_sub =>
      res <= adder_res;
    when c_alu_op_xor =>
      res <= op_a xor op_b;
    when c_alu_op_or =>
      res <= op_a or op_b;
    when c_alu_op_and =>
      res <= op_a and op_b;
    when c_alu_op_sll | c_alu_op_srl | c_alu_op_sra =>
      res <= f_reverse(shift_res, 1, (alu_op(2) = '0'));
    when c_alu_op_slt | c_alu_op_sltu =>
      res <= 31Ux"0" & cmp_res;
    when others =>
    end case;
  end process;

end architecture;