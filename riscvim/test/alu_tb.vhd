library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library lib_riscv;
use lib_riscv.riscv_pkg.all;
use lib_riscv.riscv_utils_pkg.all;
use lib_riscv.riscv_alu_pkg.all;
use lib_riscv.riscv_disas_pkg.all;

entity alu_tb is
end entity alu_tb;

architecture tb of alu_tb is

  constant c_cfg : t_riscv_isa_config := (others => true);

  type t_alu_ops is array(natural range <>) of t_alu_opcode;

  constant c_alu_math_ops : t_alu_ops := (
    c_alu_add,
    c_alu_sub,
    c_alu_slt,
    c_alu_sltu,
    c_alu_sh1add,
    c_alu_sh2add,
    c_alu_sh3add,
    c_alu_min,
    c_alu_minu,
    c_alu_max,
    c_alu_maxu
  );

  constant c_alu_logic_ops : t_alu_ops := (
    c_alu_xor,
    c_alu_or,
    c_alu_and,
    c_alu_xnor,
    c_alu_orn,
    c_alu_andn,
    c_alu_orc,
    c_alu_czero_eqz,
    c_alu_czero_nez,
    c_alu_sextb,
    c_alu_zexth,
    c_alu_sexth
  );

  constant c_alu_shift_ops : t_alu_ops := (
    c_alu_sll,
    c_alu_srl,
    c_alu_sra,
    c_alu_rol,
    c_alu_ror,
    c_alu_bclr,
    c_alu_bext,
    c_alu_binv,
    c_alu_bset
  );

  constant c_alu_misc_ops : t_alu_ops := (
    c_alu_movb,
    c_alu_clz,
    c_alu_ctz,
    c_alu_cpop,
    c_alu_rev8
  );

  signal alu_op : t_alu_opcode := ("00", "000", "000");
  signal op_a   : std_logic_vector(C_XLEN-1 downto 0) := x"80008084";
  signal op_b   : std_logic_vector(C_XLEN-1 downto 0) := x"00000006";
  signal result : t_alu_result;

begin

  result <= f_alu(c_cfg, alu_op, op_a, op_b);

  p_test : process
    variable l : line;
  begin

    for i in 0 to c_alu_math_ops'high loop
      alu_op <= c_alu_math_ops(i);
      wait for 1 ns;
      write(l, f_alu2str(alu_op));
      writeline(output, l);
      for j in 0 to 1 loop
        op_a <= not op_a;
        wait for 100 ns;
      end loop;
    end loop;

    for i in 0 to c_alu_logic_ops'high loop
      alu_op <= c_alu_logic_ops(i);
      wait for 1 ns;
      write(l, f_alu2str(alu_op));
      writeline(output, l);
      for j in 0 to 1 loop
        op_a <= not op_a;
        wait for 100 ns;
      end loop;
    end loop;

    for i in 0 to c_alu_shift_ops'high loop
      alu_op <= c_alu_shift_ops(i);
      wait for 1 ns;
      write(l, f_alu2str(alu_op));
      writeline(output, l);
      for j in 1 to 31 loop
        op_b <= std_logic_vector(to_unsigned(j,C_XLEN));
        wait for 100 ns;
      end loop;
    end loop;

    op_b    <= x"00000006";

    for i in 0 to c_alu_misc_ops'high loop
      alu_op <= c_alu_misc_ops(i);
      wait for 1 ns;
      write(l, f_alu2str(alu_op));
      writeline(output, l);
      for j in 0 to 3 loop
        op_a <= std_logic_vector(rotate_left(unsigned(op_a),C_XLEN/4));
        wait for 100 ns;
      end loop;
      wait for 100 ns;
    end loop;
  end process;

end architecture tb;