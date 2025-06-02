
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscv;
use lib_riscv.riscv_pkg.all;
use lib_riscv.riscv_utils_pkg.all;

package riscv_alu_pkg is

--
--  ALU OPERATION CODES
--

  subtype t_alu_exe is std_logic_vector(1 downto 0);
  subtype t_alu_op is std_logic_vector(2 downto 0);
  subtype t_alu_opx is std_logic_vector(2 downto 0);

  type t_alu_opcode is record
    exe : t_alu_exe;
    op  : t_alu_op;
    opx : t_alu_opx;
  end record;

  type t_alu_result is record
    res : t_wordx;
    cmp : std_logic;
  end record;

  -- ALU execution select
  constant C_ALU_EXE_MATH   : t_alu_exe := "00";
  constant C_ALU_EXE_LOGIC  : t_alu_exe := "01";
  constant C_ALU_EXE_SHIFT  : t_alu_exe := "10";
  constant C_ALU_EXE_MISC   : t_alu_exe := "11";

  -- Alu operations
  -- Math op(2) => negate op_b, op(1 downto 0) => result select, opx(2 downto 1) => shamt, opx(0) => signed
  constant C_ALU_OP_ADD     : t_alu_op := "000";
  constant C_ALU_OP_EQ      : t_alu_op := "001";
  constant C_ALU_OP_SUB     : t_alu_op := "100"; -- [2] => negate op_b for subtraction
  constant C_ALU_OP_SLT     : t_alu_op := "101"; -- [2] => negate op_b for subtraction
  constant C_ALU_OP_MIN     : t_alu_op := "110"; -- [2] => negate op_b for subtraction
  constant C_ALU_OP_MAX     : t_alu_op := "111"; -- [2] => negate op_b for subtraction

  -- Math ALU opcodes
  constant C_ALU_ADD        : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_ADD, opx => "000");
  constant C_ALU_EQ         : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_EQ,  opx => "000");
  constant C_ALU_SUB        : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_SUB, opx => "000");
  constant C_ALU_SLT        : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_SLT, opx => "001");
  constant C_ALU_SLTU       : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_SLT, opx => "000");
  constant C_ALU_SH1ADD     : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_ADD, opx => "010");
  constant C_ALU_SH2ADD     : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_ADD, opx => "100");
  constant C_ALU_SH3ADD     : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_ADD, opx => "110");
  constant C_ALU_MIN        : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_MIN, opx => "001");
  constant C_ALU_MINU       : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_MIN, opx => "000");
  constant C_ALU_MAX        : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_MAX, opx => "001");
  constant C_ALU_MAXU       : t_alu_opcode := (exe => C_ALU_EXE_MATH, op => C_ALU_OP_MAX, opx => "000");

  -- Bitwise logic op(2) => negate op_b
  constant C_ALU_OP_XOR     : t_alu_op := "000";
  constant C_ALU_OP_OR      : t_alu_op := "001";
  constant C_ALU_OP_AND     : t_alu_op := "011";
  constant C_ALU_OP_XNOR    : t_alu_op := "100"; -- [2] => negate op_b
  constant C_ALU_OP_ORN     : t_alu_op := "101"; -- [2] => negate op_b
  constant C_ALU_OP_ANDN    : t_alu_op := "111"; -- [2] => negate op_b

  -- Logic ALU opcodes
  constant C_ALU_XOR        : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_XOR,  opx => "000");
  constant C_ALU_OR         : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_OR,   opx => "000");
  constant C_ALU_AND        : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_AND,  opx => "000");
  constant C_ALU_XNOR       : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_XNOR, opx => "000");
  constant C_ALU_ORN        : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_ORN,  opx => "000");
  constant C_ALU_ANDN       : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_ANDN, opx => "000");
  constant C_ALU_CZERO_EQZ  : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_AND,  opx => "001");
  constant C_ALU_CZERO_NEZ  : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_ANDN, opx => "001");
  constant C_ALU_SEXTB      : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_XNOR, opx => "010");
  constant C_ALU_ORC        : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_OR,   opx => "011");
  constant C_ALU_ZEXTH      : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_XOR,  opx => "011");
  constant C_ALU_SEXTH      : t_alu_opcode := (exe => C_ALU_EXE_LOGIC, op => C_ALU_OP_XNOR, opx => "011");

  -- Shifter
  constant C_ALU_OP_SLL     : t_alu_op := "100"; -- [2] => Shift left
  constant C_ALU_OP_SRL     : t_alu_op := "000";
  constant C_ALU_OP_ROL     : t_alu_op := "101"; -- [2] => Shift left, [0] => Rotate
  constant C_ALU_OP_ROR     : t_alu_op := "001"; -- [0] => Rotate
  constant C_ALU_OP_SLB     : t_alu_op := "110"; -- [2] => Shift left, [1] => Single bit op
  constant C_ALU_OP_BEXT    : t_alu_op := "010"; -- [1] => Single bit op

  -- Shifter ALU opcodes
  constant C_ALU_SLL        : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_SLL,  opx => "000");
  constant C_ALU_SRL        : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_SRL,  opx => "000");
  constant C_ALU_SRA        : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_SRL,  opx => "001");
  constant C_ALU_ROL        : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_ROL,  opx => "000");
  constant C_ALU_ROR        : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_ROR,  opx => "000");
  constant C_ALU_BCLR       : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_SLB,  opx => "110");
  constant C_ALU_BEXT       : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_BEXT, opx => "000");
  constant C_ALU_BINV       : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_SLB,  opx => "010");
  constant C_ALU_BSET       : t_alu_opcode := (exe => C_ALU_EXE_SHIFT, op => C_ALU_OP_SLB,  opx => "100");

  -- Misc
  constant C_ALU_OP_MOVB    : t_alu_op := "000";  -- mov op_b
  constant C_ALU_OP_CBITS   : t_alu_op := "001";  -- ctz, clz, cpop
  constant C_ALU_OP_REV     : t_alu_op := "010";  -- rev8
  constant C_ALU_OP_CLMUL   : t_alu_op := "011";  -- clmul, clmulh, clmulr

  -- Misc ALU opcodes
  constant C_ALU_MOVB       : t_alu_opcode := (exe => C_ALU_EXE_MISC, op => C_ALU_OP_MOVB,  opx => "000");
  constant C_ALU_CLZ        : t_alu_opcode := (exe => C_ALU_EXE_MISC, op => C_ALU_OP_CBITS, opx => "000");
  constant C_ALU_CTZ        : t_alu_opcode := (exe => C_ALU_EXE_MISC, op => C_ALU_OP_CBITS, opx => "001");
  constant C_ALU_CPOP       : t_alu_opcode := (exe => C_ALU_EXE_MISC, op => C_ALU_OP_CBITS, opx => "010");
  constant C_ALU_REV8       : t_alu_opcode := (exe => C_ALU_EXE_MISC, op => C_ALU_OP_REV,   opx => "000");
  constant C_ALU_CLMUL      : t_alu_opcode := (exe => C_ALU_EXE_MISC, op => C_ALU_OP_CLMUL, opx => "000");
  constant C_ALU_CLMULH     : t_alu_opcode := (exe => C_ALU_EXE_MISC, op => C_ALU_OP_CLMUL, opx => "011");
  constant C_ALU_CLMULR     : t_alu_opcode := (exe => C_ALU_EXE_MISC, op => C_ALU_OP_CLMUL, opx => "001");

--
--  MUL/DIV OPERATION CODES
--

  type t_muldiv_ctrl is record
    mode  : std_logic;
    signa : std_logic;
    signb : std_logic;
  end record;

  constant C_MULDIV_NONE    : t_muldiv_ctrl := (mode => '0', signa => '0', signb => '0');
  constant C_MULDIV_MUL     : t_muldiv_ctrl := (mode => '0', signa => '1', signb => '1');
  constant C_MULDIV_MULH    : t_muldiv_ctrl := (mode => '1', signa => '1', signb => '1');
  constant C_MULDIV_MULHSU  : t_muldiv_ctrl := (mode => '1', signa => '1', signb => '0');
  constant C_MULDIV_MULHU   : t_muldiv_ctrl := (mode => '1', signa => '0', signb => '0');
  constant C_MULDIV_DIV     : t_muldiv_ctrl := (mode => '0', signa => '1', signb => '1');
  constant C_MULDIV_DIVU    : t_muldiv_ctrl := (mode => '0', signa => '0', signb => '0');
  constant C_MULDIV_REM     : t_muldiv_ctrl := (mode => '1', signa => '1', signb => '1');
  constant C_MULDIV_REMU    : t_muldiv_ctrl := (mode => '1', signa => '0', signb => '0');

  function f_alu_op2slv(
    op : t_alu_opcode
  ) return std_logic_vector;

  function f_alu_misc_clz(
    op : std_logic_vector
  ) return std_logic_vector;

  function f_alu_misc_cpop(
    op : std_logic_vector
  ) return std_logic_vector;

  function f_alu(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_alu_result;

end package riscv_alu_pkg;

package body riscv_alu_pkg is

  function f_alu_op2slv(
    op : t_alu_opcode
  ) return std_logic_vector is
  begin
    return op.exe & op.op & op.opx;
  end function;

  function f_alu_math(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx is
    variable v_op_a     : unsigned(op_a'range);
    variable v_op_b     : unsigned(op_b'range);
    variable v_co       : std_logic;
    variable v_add_res  : t_wordx;
    variable v_tmp      : std_logic;
    variable v_op_a_sx  : std_logic;
    variable v_op_b_sx  : std_logic;
    variable v_eq       : std_logic;
    variable v_lt       : std_logic;
    variable v_res      : t_wordx := (others => '0');
  begin
    -- Math op(2) => negate op_b, op(1 downto 0) => result select, opx(2 downto 1) => shamt, opx(0) => sext
    -- op_add  "000"
    -- op_eq   "001"
    -- op_sub  "100"
    -- op_slt  "101"
    -- op_sltu "101"
    -- op_min  "110"
    -- op_minu "110"
    -- op_max  "111"
    -- op_maxu "111"
    -- Adder
    if cfg(Zba) then
      v_op_a := shift_left(unsigned(op_a), to_integer(unsigned(alu_op.opx(2 downto 1))));
    else
      v_op_a := unsigned(op_a);
    end if;
    v_op_b := unsigned((op_b xor alu_op.op(2))); -- Inverted if alu_op(2)
    (v_co, v_add_res, v_tmp) := std_logic_vector(('0' & v_op_a & '1') + (v_op_b & alu_op.op(2)));

    -- EQ
    v_eq := '0';
    if op_a = op_b then
      v_eq := '1';
    end if;

    -- SLT(U)
    v_op_a_sx := alu_op.opx(0) and op_a(C_XLEN-1);
    v_op_b_sx := alu_op.opx(0) and op_b(C_XLEN-1);
    v_lt      := v_op_a_sx xor not v_op_b_sx xor v_co;

    -- Result select
    if cfg(Zbb) and alu_op.op(1) = '1' then
      -- MIN(U)/MAX(U)
      if (v_lt xor alu_op.op(0)) = '1' then
        v_res := op_a;
      else
        v_res := op_b;
      end if;
    elsif alu_op.op(0) = '1' then
      -- EQ, SLT(U)
      if alu_op.op(2) = '1' then
        v_res(0) := v_lt;
      else
        v_res(0) := v_eq;
      end if;
    else
      -- ADD, SUB
      v_res := v_add_res;
    end if;

    return v_res;
  end function f_alu_math;

  function f_alu_shift(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx is
    variable shamt      : unsigned(4 downto 0);
    variable shift_in   : std_logic_vector(2*C_XLEN-1 downto 0) := (others => '0');
    variable shift_out  : std_logic_vector(C_XLEN-1 downto 0);
    variable res        : std_logic_vector(C_XLEN-1 downto 0);
  begin
    -- Negate shift amount on left shift
    shamt := unsigned(op_b(shamt'range) xor alu_op.op(2)) + std_ulogic(alu_op.op(2));

    -- Upper shift in
    if alu_op.op(2) = '1' or (cfg(Zbb) and alu_op.op(0) = '1') then
      -- Left shift or rotate
      if cfg(Zbs) and alu_op.op(2 downto 1) = "11" then
        -- BCLR, BINV, BSET
        shift_in(2*C_XLEN-1 downto C_XLEN) := x"0000_0001";
      else
        -- SLL, ROL, ROR
        shift_in(2*C_XLEN-1 downto C_XLEN) := op_a;
      end if;
    else
      -- Right shift
      -- SRL, SRA, BEXT
      shift_in(2*C_XLEN-1 downto C_XLEN) := (others => alu_op.opx(0) and op_a(C_XLEN-1));
    end if;

    -- Lower shift in
    if alu_op.op(2) = '0' or (cfg(Zbb) and alu_op.op(0) = '1') then
      -- Right shift or rotate
      -- SRL, SRA, ROL, ROR, BEXT
      shift_in(C_XLEN-1 downto 0) := op_a;
    end if;

    shift_out := std_logic_vector(shift_right(unsigned(shift_in), to_integer(shamt))(C_XLEN-1 downto 0));

    -- Result mux
    if cfg(Zbs) and alu_op.op(1) = '1' then
      case alu_op.opx(2 downto 1) is
      when "01"   => res := op_a xor shift_out;         -- BINV
      when "10"   => res := op_a  or shift_out;         -- BSET
      when "11"   => res := op_a and not shift_out;     -- BCLR
      when others => res := x"0000_0001" and shift_out; -- BEXT
      end case;
    else
      res := shift_out;
    end if;

    return res;
  end function f_alu_shift;

  function f_alu_logic(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx is
    variable v_op_b : t_wordx := op_b;
  begin
    if cfg(Zbb) or cfg(Zicond) then
      case alu_op.opx(1 downto 0) is
      when "00" =>
        if cfg(Zbb) then
          -- XNOR, ORN, ANDN
          v_op_b := op_b xor alu_op.op(2);
        end if;
      when "01" =>
        if cfg(Zicond) then
          -- Zicond EQZ, NEZ (AND/ANDN)
          -- alu_op.op(2) = '0' EQZ => op_b = 0 => others => '1'
          -- alu_op.op(2) = '1' NEZ => op_b = 0 => others => '0'
          v_op_b := (others => nor (op_b xor alu_op.op(2)));
        end if;
      when "10" =>
        if cfg(Zbb) then
          -- SEXT.B (XNOR)
          v_op_b(C_XLEN-1 downto C_XLEN/4) := op_a(C_XLEN-1 downto C_XLEN/4) xor op_a(C_XLEN/4-1);
        end if;
      when "11" =>
        if cfg(Zbb) then
          if alu_op(0) = '1' then
            -- ORC.B (OR)
            for i in 0 to 3 loop
              v_op_b((i+1)*(C_XLEN/4)-1 downto i*(C_XLEN/4)) := (others => or op_a((i+1)*(C_XLEN/4)-1 downto i*(C_XLEN/4)));
            end loop;
          else
            --ZEXT.H (XOR), SEXT.H (XNOR)
            v_op_b(C_XLEN/2-1 downto 0)      := (others => '0');
            v_op_b(C_XLEN-1 downto C_XLEN/2) := op_a(C_XLEN-1 downto C_XLEN/2) xor (op_a(C_XLEN/2-1) and alu_op.op(2));
          end if;
        end if;
      when others =>
      end case;
    end if;
    -- Bitwise op
    -- 00 xor: op_a xor op_b
    -- 01  or: (op_a xor op_b) or (op_a and op_b)
    -- 10 N/A: 0
    -- 11 and: op_a and op_b
    return ((op_a xor v_op_b) and not alu_op.op(1)) or (op_a and v_op_b and alu_op.op(0));
  end function f_alu_logic;

  function f_alu_misc_clz(
    op : std_logic_vector
  ) return std_logic_vector is
    constant c_h  : natural := op'length/2;
    variable v_op : std_logic_vector(op'length-1 downto 0) := op;
  begin
    if c_h = 1 then
      if or v_op(v_op'high downto c_h) = '1' then
        return "0";
      else
        return "1";
      end if;
    else
      if or v_op(v_op'high downto c_h) = '1' then
        return '0' & f_alu_misc_clz(v_op(v_op'high downto c_h));
      else
        return '1' & f_alu_misc_clz(v_op(c_h-1 downto 0));
      end if;
    end if;
  end function f_alu_misc_clz;

  function f_alu_misc_cpop(
    op : std_logic_vector
  ) return std_logic_vector is
    variable v_pop : unsigned(f_log2(op'length) downto 0) := (others => '0');
  begin
    for i in op'range loop
      v_pop := v_pop + std_ulogic(op(i));
    end loop;
    return std_logic_vector(v_pop);
  end function f_alu_misc_cpop;

  function f_alu_misc_clmul(
    op_a, op_b : std_logic_vector
  ) return std_logic_vector is
    variable v_op_a : std_logic_vector(op_a'length-1 downto 0) := op_a;
    variable v_op_b : std_logic_vector(op_b'length-1 downto 0) := op_b;
    variable v_res  : std_logic_vector(op_a'length-1 downto 0) := (others => '0');
  begin
    for i in 0 to v_res'length-1 loop
      for j in 0 to i loop
        v_res(i) := v_res(i) xor (v_op_a(i-j) and v_op_b(j));
      end loop;
    end loop;
    return v_res;
  end function;

  function f_alu_misc(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx is
    variable v_op_a   : t_wordx := f_reverse(op_a, 1, alu_op.opx(0) = '1');
    variable v_op_b   : t_wordx := f_reverse(op_b, 1, alu_op.opx(0) = '1');
    variable v_mov    : t_wordx := op_b;
    variable v_zero   : std_logic := nor op_a;
    variable v_cbits  : std_logic_vector(f_log2(op_a'length) downto 0) := (others => '0');
    variable v_rev    : t_wordx := (others => '0');
    variable v_clmul  : t_wordx := (others => '0');
    variable v_res    : t_wordx := (others => '0');
  begin
    if cfg(Zbb) then
      v_rev := f_reverse(op_a, (C_XLEN/4));
      if alu_op.opx(1) = '1' then
        v_cbits := f_alu_misc_cpop(op_a);
      else
        v_cbits := v_zero & (f_alu_misc_clz(v_op_a) and (not v_zero));
      end if;
    end if;

    if cfg(Zbc) then
      -- Reverse if CLMULR or CLMULH
      v_clmul := f_reverse(f_alu_misc_clmul(v_op_a, v_op_b), 1, alu_op.opx(0) = '1');
      -- Shift if CLMULH
      v_clmul := std_logic_vector(shift_right(unsigned(v_clmul), to_integer(unsigned(alu_op.opx(1 downto 1)))));
    end if;

    if cfg(Zbc) and alu_op.op(1 downto 0) = "11" then
      v_res := v_clmul;
    elsif cfg(Zbb) and alu_op.op(1) = '1' then
      v_res := v_rev;
    elsif cfg(Zbb) and alu_op.op(0) = '1' then
      v_res(v_cbits'range) := v_cbits;
    else
      v_res := v_mov;
    end if;

    return v_res;
  end function f_alu_misc;

  function f_alu(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_alu_result is
    variable v_math   : t_wordx := f_alu_math(cfg, alu_op, op_a, op_b);
    variable v_logic  : t_wordx := f_alu_logic(cfg, alu_op, op_a, op_b);
    variable v_shift  : t_wordx := f_alu_shift(cfg, alu_op, op_a, op_b);
    variable v_misc   : t_wordx := f_alu_misc(cfg, alu_op, op_a, op_b);
    variable v_alu    : t_alu_result;
  begin
    case alu_op.exe is
    when C_ALU_EXE_MATH   => v_alu.res := v_math;
    when C_ALU_EXE_LOGIC  => v_alu.res := v_logic;
    when C_ALU_EXE_SHIFT  => v_alu.res := v_shift;
    when C_ALU_EXE_MISC   => v_alu.res := v_misc;
    when others =>
    end case;

    v_alu.cmp := v_math(0);

    return v_alu;
  end function f_alu;

end package body riscv_alu_pkg;