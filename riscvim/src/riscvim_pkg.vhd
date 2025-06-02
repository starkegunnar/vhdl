--! @defgroup   riscvim_pkg rv 32 i package
--!
--! @brief      This file implements rv 32 i package.
--!
--! @author     Martin
--! @date       2022
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--! RISC V functions and types package
--!
package riscvim_pkg is

  --! Register width (and number of registers)
  --!
  constant c_x_w            : natural := 32;
  --! Highest index of register
  --!
  constant c_xhi            : natural := c_x_w - 1;
  --! Lowest index of register
  --!
  constant c_xlo            : natural := 0;
  --! Register range
  --!
  subtype t_x_range is natural range c_xhi downto c_xlo;

  subtype t_wordx is std_logic_vector(t_x_range);
  subtype t_swordx is signed(t_x_range);
  subtype t_uwordx is unsigned(t_x_range);
  subtype t_wordx1 is std_logic_vector(c_x_w downto 0);

  type t_wordx_array is array(natural range <>) of t_wordx;

  --! Double register width
  --!
  constant c_2x_w            : natural := 2*c_x_w;
  --! Highest index of double register
  --!
  constant c_2xhi            : natural := c_2x_w - 1;
  --! Lowest index of double register
  --!
  constant c_2xlo            : natural := 0;
  --! Double register range
  --!
  subtype t_2x_range is natural range c_2x_w-1 downto c_2xlo;

  subtype t_dwordx is std_logic_vector(t_2x_range);
  subtype t_dwordx1 is std_logic_vector(c_2x_w downto 0);
  subtype t_dswordx is signed(t_2x_range);
  subtype t_duwordx is unsigned(t_2x_range);

  --! Half register width
  --!
  constant c_hx_w            : natural := c_x_w / 2;
  --! Highest index of half register
  --!
  constant c_hxhi            : natural := c_hx_w - 1;
  --! Lowest index of half register
  --!
  constant c_hxlo            : natural := 0;
  --! Half register range
  --!
  subtype t_hx_range is natural range c_hx_w-1 downto c_hxlo;
  subtype t_hx_hi_range is natural range c_x_w-1 downto c_hx_w;
  subtype t_hx_lo_range is natural range c_hx_w-1 downto c_hxlo;

  subtype t_hwordx is std_logic_vector(t_hx_range);
  subtype t_hwordx1 is std_logic_vector(c_hx_w downto 0);

  type t_hwordx_array is array(natural range <>) of t_hwordx;

  --! Byte register width
  --!
  constant c_bx_w            : natural := c_x_w / 4;
  --! Highest index of half register
  --!
  constant c_bxhi            : natural := c_bx_w - 1;
  --! Lowest index of byte register
  --!
  constant c_bxlo            : natural := 0;
  --! Byte register range
  --!
  subtype t_bx_range is natural range c_bx_w-1 downto c_bxlo;
  subtype t_bx3_range is natural range 4*c_bx_w-1 downto 3*c_bx_w;
  subtype t_bx2_range is natural range 3*c_bx_w-1 downto 2*c_bx_w;
  subtype t_bx1_range is natural range 2*c_bx_w-1 downto c_bx_w;
  subtype t_bx0_range is natural range c_bx_w-1 downto 0;

  subtype t_bytex is std_logic_vector(t_hx_range);
  subtype t_bytex1 is std_logic_vector(c_hx_w downto 0);

  type t_bytex_array is array(natural range <>) of t_bytex;


  --! Width of register select
  --!
  constant c_rfaddr_w       : natural := 5;
  constant c_rfaddr_hi      : natural := 4;
  constant c_rfaddr_lo      : natural := 0;
  subtype t_rfaddr_range is natural range c_rfaddr_hi downto c_rfaddr_lo;
  subtype t_rfaddr is std_logic_vector(t_rfaddr_range);
  constant c_rfaddr_x0      : t_rfaddr := (others => '0');

  constant c_f7_w           : natural := 7;
  constant c_f7_hi          : natural := 6;
  constant c_f7_lo          : natural := 0;
  subtype t_f7_range is natural range c_f7_hi downto c_f7_lo;
  constant c_f7_inst_hi     : natural := 31;
  constant c_f7_inst_lo     : natural := 25;
  subtype t_f7_inst_range is natural range c_f7_inst_hi downto c_f7_inst_lo;
  subtype t_f7 is std_logic_vector(t_f7_range);

  constant c_f5_w           : natural := 5;
  constant c_f5_hi          : natural := 4;
  constant c_f5_lo          : natural := 0;
  subtype t_f5_range is natural range c_f5_hi downto c_f5_lo;
  constant c_f5_inst_hi     : natural := 31;
  constant c_f5_inst_lo     : natural := 27;
  subtype t_f5_inst_range is natural range c_f5_inst_hi downto c_f5_inst_lo;
  subtype t_f5 is std_logic_vector(t_f5_range);

  constant c_f12_w          : natural := 12;
  constant c_f12_hi         : natural := 11;
  constant c_f12_lo         : natural := 0;
  subtype t_f12_range is natural range c_f12_hi downto c_f12_lo;
  constant c_f12_inst_hi    : natural := 31;
  constant c_f12_inst_lo    : natural := 20;
  subtype t_f12_inst_range is natural range c_f12_inst_hi downto c_f12_inst_lo;
  subtype t_f12 is std_logic_vector(t_f12_range);

  constant c_rs2_hi         : natural := 24;
  constant c_rs2_lo         : natural := 20;
  subtype t_rs2_range is natural range c_rs2_hi downto c_rs2_lo;

  constant c_rs1_hi         : natural := 19;
  constant c_rs1_lo         : natural := 15;
  subtype t_rs1_range is natural range c_rs1_hi downto c_rs1_lo;

  constant c_f3_w           : natural := 3;
  constant c_f3_hi          : natural := 2;
  constant c_f3_lo          : natural := 0;
  subtype t_f3_range is natural range c_f3_hi downto c_f3_lo;
  constant c_f3_inst_hi     : natural := 14;
  constant c_f3_inst_lo     : natural := 12;
  subtype t_f3_inst_range is natural range c_f3_inst_hi downto c_f3_inst_lo;
  subtype t_f3 is std_logic_vector(t_f3_range);

  constant c_rd_hi          : natural := 11;
  constant c_rd_lo          : natural := 7;
  subtype t_rd_range is natural range c_rd_hi downto c_rd_lo;

  constant c_opcode_w       : natural := 7;
  constant c_opcode_hi      : natural := 6;
  constant c_opcode_lo      : natural := 0;
  subtype t_opcode_range is natural range c_opcode_hi downto c_opcode_lo;
  constant c_opcode_inst_hi : natural := 6;
  constant c_opcode_inst_lo : natural := 0;
  subtype t_opcode_inst_range is natural range c_opcode_inst_hi downto c_opcode_inst_lo;
  subtype t_opcode is std_logic_vector(t_opcode_range);

  constant c_csr_addr_w       : natural := 12;
  constant c_csr_addr_hi      : natural := 11;
  constant c_csr_addr_lo      : natural := 0;
  subtype t_csr_addr_range is natural range c_csr_addr_hi downto c_csr_addr_lo;
  subtype t_csr_access_range is natural range c_csr_addr_hi downto c_csr_addr_hi - 1;
  subtype t_csr_priv_range is natural range c_csr_addr_hi - 2 downto c_csr_addr_hi - 3;
  constant c_csr_addr_inst_hi : natural := 31;
  constant c_csr_addr_inst_lo : natural := 20;
  subtype t_csr_addr_inst_range is natural range c_csr_addr_inst_hi downto c_csr_addr_inst_lo;

  constant c_csr_op_w         : natural := 2;
  constant c_csr_op_hi        : natural := 1;
  constant c_csr_op_lo        : natural := 0;
  subtype t_csr_op_range is natural range c_csr_op_hi downto c_csr_op_lo;


  -- RV32I base instruction set                                                 Type  PC  IMM R2 R1  RS EX       OP  OPA OPB OPC
  constant c_opcode_lui     : std_logic_vector(t_opcode_range) := "0110111";  --  U         X        ALU         MOV 0   IMM -
  constant c_opcode_auipc   : std_logic_vector(t_opcode_range) := "0010111";  --  U    X    X        ALU         ADD PC  IMM -
  constant c_opcode_jal     : std_logic_vector(t_opcode_range) := "1101111";  --  J    X    X        PC next     ADD PC  IMM -
  constant c_opcode_branch  : std_logic_vector(t_opcode_range) := "1100011";  --  B    X    X  X  X  -           ADD R1  R2
  constant c_opcode_jalr    : std_logic_vector(t_opcode_range) := "1100111";  --  I    X    X     X  PC next     ADD R1  IMM -
  constant c_opcode_load    : std_logic_vector(t_opcode_range) := "0000011";  --  I         X     X  LSU         ADD R1  IMM -
  constant c_opcode_op_imm  : std_logic_vector(t_opcode_range) := "0010011";  --  I         X     X  ALU         ANY R1  IMM -
  constant c_opcode_fence   : std_logic_vector(t_opcode_range) := "0001111";  --  I         ?     ?  ?           ?   ?   ?   -
  constant c_opcode_system  : std_logic_vector(t_opcode_range) := "1110011";  --  I         X     X  CSR         CSR R1  IMM -
  constant c_opcode_store   : std_logic_vector(t_opcode_range) := "0100011";  --  S         X  X  X  LSU         -   R1  IMM R2
  constant c_opcode_op      : std_logic_vector(t_opcode_range) := "0110011";  --  R            X  X  MULDIV      ANY R1  R2  -

  -- RV32A extension
  constant c_opcode_amo     : std_logic_vector(t_opcode_range) := "0101111";  --  S         X  X  X  LSU         -   R1  IMM R2

  -- RV32C compressed instruction set
  constant c_opcode_c0      : std_logic_vector(1 downto 0) := "00";
  constant c_opcode_c1      : std_logic_vector(1 downto 0) := "01";
  constant c_opcode_c2      : std_logic_vector(1 downto 0) := "10";

  -- FUNCT3 flags
  --
  constant c_f3_jalr            : t_f3 := "000";

  constant c_f3_br_beq          : t_f3 := "000";
  constant c_f3_br_bne          : t_f3 := "001";
  constant c_f3_br_blt          : t_f3 := "100";
  constant c_f3_br_bge          : t_f3 := "101";
  constant c_f3_br_bltu         : t_f3 := "110";
  constant c_f3_br_bgeu         : t_f3 := "111";

  constant c_f3_ld_lb           : t_f3 := "000";
  constant c_f3_ld_lh           : t_f3 := "001";
  constant c_f3_ld_lw           : t_f3 := "010";
  constant c_f3_ld_lbu          : t_f3 := "100";
  constant c_f3_ld_lhu          : t_f3 := "101";

  constant c_f3_st_sb           : t_f3 := "000";
  constant c_f3_st_sh           : t_f3 := "001";
  constant c_f3_st_sw           : t_f3 := "010";

  constant c_f3_a_amow          : t_f3 := "010";

  constant c_f3_op_add          : t_f3 := "000";
  constant c_f3_op_sub          : t_f3 := "000";
  constant c_f3_op_slt          : t_f3 := "010";
  constant c_f3_op_sltu         : t_f3 := "011";
  constant c_f3_op_sll          : t_f3 := "001";
  constant c_f3_op_srl          : t_f3 := "101";
  constant c_f3_op_sra          : t_f3 := "101";
  constant c_f3_op_xor          : t_f3 := "100";
  constant c_f3_op_or           : t_f3 := "110";
  constant c_f3_op_and          : t_f3 := "111";

  constant c_f3_op_b_andn       : t_f3 := "111";  -- andn
  constant c_f3_op_b_orn        : t_f3 := "110";  -- orn
  constant c_f3_op_b_xnor       : t_f3 := "100";  -- xnor
  constant c_f3_op_b_bclr       : t_f3 := "001";  -- andn
  constant c_f3_op_b_bext       : t_f3 := "101";  -- srl and 1
  constant c_f3_op_b_binv       : t_f3 := "001";  -- xor
  constant c_f3_op_b_bset       : t_f3 := "001";  -- or
  --constant c_f3_op_b_clmul      : t_f3 := "001";  -- N/A
  --constant c_f3_op_b_clmulr     : t_f3 := "010";  -- N/A
  --constant c_f3_op_b_clmulh     : t_f3 := "011";  -- N/A
  constant c_f3_op_b_min        : t_f3 := "100";  -- slt(u)
  constant c_f3_op_b_minu       : t_f3 := "101";  -- slt(u)
  constant c_f3_op_b_max        : t_f3 := "110";  -- slt(u)
  constant c_f3_op_b_maxu       : t_f3 := "111";  -- slt(u)
  constant c_f3_op_b_cpop       : t_f3 := "001";  -- count leading zeros
  constant c_f3_op_b_clz        : t_f3 := "001";  -- count leading zeros
  constant c_f3_op_b_ctz        : t_f3 := "001";  -- count trailing zeros
  --constant c_f3_op_b_pack       : t_f3 := "100";  -- N/A
  --constant c_f3_op_b_packh      : t_f3 := "111";  -- N/A
  constant c_f3_op_b_rev        : t_f3 := "101";
  constant c_f3_op_b_rol        : t_f3 := "001";  -- rotate left
  constant c_f3_op_b_ror        : t_f3 := "101";  -- rotate right
  constant c_f3_op_b_sext       : t_f3 := "001";
  constant c_f3_op_b_sh1add     : t_f3 := "010";  -- add
  constant c_f3_op_b_sh2add     : t_f3 := "100";  -- add
  constant c_f3_op_b_sh3add     : t_f3 := "110";  -- add
  constant c_f3_op_b_zext       : t_f3 := "100";
  constant c_f3_op_b_orc        : t_f3 := "101";

  constant c_f3_op_m_mul        : t_f3 := "000";
  constant c_f3_op_m_mulh       : t_f3 := "001";
  constant c_f3_op_m_mulhsu     : t_f3 := "010";
  constant c_f3_op_m_mulhu      : t_f3 := "011";
  constant c_f3_op_m_div        : t_f3 := "100";
  constant c_f3_op_m_divu       : t_f3 := "101";
  constant c_f3_op_m_rem        : t_f3 := "110";
  constant c_f3_op_m_remu       : t_f3 := "111";

  constant c_f3_op_czero_eqz    : t_f3 := "101";
  constant c_f3_op_czero_nez    : t_f3 := "111";

  constant c_f3_miscmem_fence   : t_f3 := "000";
  constant c_f3_miscmem_fencei  : t_f3 := "001";

  constant c_f3_system_ecall    : t_f3 := "000";
  constant c_f3_system_ebreak   : t_f3 := "000";
  constant c_f3_system_csrrw    : t_f3 := "001";
  constant c_f3_system_csrrs    : t_f3 := "010";
  constant c_f3_system_csrrc    : t_f3 := "011";
  constant c_f3_system_csrrwi   : t_f3 := "101";
  constant c_f3_system_csrrsi   : t_f3 := "110";
  constant c_f3_system_csrrci   : t_f3 := "111";
  constant c_f3_system_sret     : t_f3 := "000";
  constant c_f3_system_mret     : t_f3 := "000";
  constant c_f3_system_wfi      : t_f3 := "000";

  constant c_f5_a_lr            : t_f5 := "00010";
  constant c_f5_a_sc            : t_f5 := "00011";
  constant c_f5_a_amoswap       : t_f5 := "00001";
  constant c_f5_a_amoadd        : t_f5 := "00000";
  constant c_f5_a_amoxor        : t_f5 := "00100";
  constant c_f5_a_amoand        : t_f5 := "01100";
  constant c_f5_a_amoor         : t_f5 := "01000";
  constant c_f5_a_amomin        : t_f5 := "10000";
  constant c_f5_a_amomax        : t_f5 := "10100";
  constant c_f5_a_amominu       : t_f5 := "11000";
  constant c_f5_a_amomaxu       : t_f5 := "11100";

  constant c_f7_null            : t_f7 := "0000000";
  constant c_f7_sext_or_sub     : t_f7 := "0100000";
  constant c_f7_b_bclr_bext     : t_f7 := "0100100";
  constant c_f7_b_binv          : t_f7 := "0110100";
  constant c_f7_b_bset          : t_f7 := "0010100";
  constant c_f7_b_minmax_clmul  : t_f7 := "0000101";
  constant c_f7_b_pack          : t_f7 := "0000100";
  constant c_f7_b_rol_ror       : t_f7 := "0110000";
  constant c_f7_b_shadd         : t_f7 := "0010000";
  constant c_f7_m_muldiv        : t_f7 := "0000001";
  constant c_f7_czero           : t_f7 := "0000111";

  constant c_f12_system_ecall   : t_f12 := x"000";
  constant c_f12_system_ebreak  : t_f12 := x"001";
  constant c_f12_system_sret    : t_f12 := x"102";
  constant c_f12_system_mret    : t_f12 := x"302";
  constant c_f12_system_dret    : t_f12 := x"7b2";
  constant c_f12_system_wfi     : t_f12 := x"105";

  constant c_f12_b_clz          : t_f12 := x"600";
  constant c_f12_b_ctz          : t_f12 := x"601";
  constant c_f12_b_cpop         : t_f12 := x"602";
  constant c_f12_b_orc          : t_f12 := x"287";
  constant c_f12_b_rev          : t_f12 := x"698";
  constant c_f12_b_revb         : t_f12 := x"687";
  constant c_f12_b_sextb        : t_f12 := x"604";
  constant c_f12_b_sexth        : t_f12 := x"605";
  constant c_f12_b_zexth        : t_f12 := x"080";

  --
  --  Immediate indexes
  --

  constant c_immw           : natural := 12;
  constant c_immuj_w        : natural := 22;
  constant c_immi_hi        : natural := 31;
  constant c_immi_lo        : natural := 20;
  constant c_imms_11_5_hi   : natural := 31;
  constant c_imms_11_5_lo   : natural := 25;
  constant c_imms_4_0_hi    : natural := 11;
  constant c_imms_4_0_lo    : natural := 7;
  constant c_immb_12        : natural := 31;
  constant c_immb_11        : natural := 7;
  constant c_immb_10_5_hi   : natural := 30;
  constant c_immb_10_5_lo   : natural := 25;
  constant c_immb_4_1_hi    : natural := 11;
  constant c_immb_4_1_lo    : natural := 8;
  constant c_immu_31_12_hi  : natural := 31;
  constant c_immu_31_12_lo  : natural := 12;
  constant c_immj_20        : natural := 31;
  constant c_immj_10_1_hi   : natural := 30;
  constant c_immj_10_1_lo   : natural := 21;
  constant c_immj_11        : natural := 20;
  constant c_immj_19_12_hi  : natural := 19;
  constant c_immj_19_12_lo  : natural := 12;

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
  constant c_alu_exe_math   : t_alu_exe := "00";
  constant c_alu_exe_logic  : t_alu_exe := "01";
  constant c_alu_exe_shift  : t_alu_exe := "10";
  constant c_alu_exe_misc   : t_alu_exe := "11";

  -- Alu operations
  -- Math op(2) => negate op_b, op(1 downto 0) => result select, opx(2 downto 1) => shamt, opx(0) => sext
  constant c_alu_op_add     : t_alu_op := "000";
  constant c_alu_op_eq      : t_alu_op := "001";
  constant c_alu_op_sub     : t_alu_op := "100";
  constant c_alu_op_slt     : t_alu_op := "101";
  constant c_alu_op_min     : t_alu_op := "110";
  constant c_alu_op_max     : t_alu_op := "111";

  -- Math ALU opcodes
  constant c_alu_add        : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_add, opx => "000");
  constant c_alu_eq         : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_eq,  opx => "000");
  constant c_alu_sub        : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_sub, opx => "000");
  constant c_alu_slt        : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_slt, opx => "001");
  constant c_alu_sltu       : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_slt, opx => "000");
  constant c_alu_sh1add     : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_add, opx => "010");
  constant c_alu_sh2add     : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_add, opx => "100");
  constant c_alu_sh3add     : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_add, opx => "110");
  constant c_alu_min        : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_min, opx => "001");
  constant c_alu_minu       : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_min, opx => "000");
  constant c_alu_max        : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_max, opx => "001");
  constant c_alu_maxu       : t_alu_opcode := (exe => c_alu_exe_math, op => c_alu_op_max, opx => "000");

  -- Bitwise logic op(2) =>
  constant c_alu_op_xor     : t_alu_op := "000";
  constant c_alu_op_or      : t_alu_op := "001";
  constant c_alu_op_and     : t_alu_op := "011";
  constant c_alu_op_xnor    : t_alu_op := "100";
  constant c_alu_op_orn     : t_alu_op := "101";
  constant c_alu_op_andn    : t_alu_op := "111";

  -- Logic ALU opcodes
  constant c_alu_xor        : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_xor, opx => "000");
  constant c_alu_or         : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_or, opx => "000");
  constant c_alu_and        : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_and, opx => "000");
  constant c_alu_xnor       : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_xnor, opx => "000");
  constant c_alu_orn        : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_orn, opx => "000");
  constant c_alu_andn       : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_andn, opx => "000");
  constant c_alu_binv       : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_xor, opx => "001");
  constant c_alu_bset       : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_or, opx => "001");
  constant c_alu_bclr       : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_andn, opx => "001");
  constant c_alu_orc        : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_or, opx => "010");
  constant c_alu_czeroeqz   : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_and, opx => "011");
  constant c_alu_czeronez   : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_andn, opx => "011");
  constant c_alu_sextb      : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_xor, opx => "101");
  constant c_alu_zexth      : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_xor, opx => "110");
  constant c_alu_sexth      : t_alu_opcode := (exe => c_alu_exe_logic, op => c_alu_op_xor, opx => "111");

  -- Shifter
  constant c_alu_op_sll     : t_alu_op := "100";    -- 2 => negate op_b (shift left)
  constant c_alu_op_srl     : t_alu_op := "000";
  constant c_alu_op_rol     : t_alu_op := "101";    -- 2 => negate op_b (shift left)
  constant c_alu_op_ror     : t_alu_op := "001";
  constant c_alu_op_bext    : t_alu_op := "010";

  -- Shifter ALU opcodes
  constant c_alu_sll        : t_alu_opcode := (exe => c_alu_exe_shift, op => c_alu_op_sll, opx => "000");
  constant c_alu_srl        : t_alu_opcode := (exe => c_alu_exe_shift, op => c_alu_op_srl, opx => "000");
  constant c_alu_sra        : t_alu_opcode := (exe => c_alu_exe_shift, op => c_alu_op_srl, opx => "001");
  constant c_alu_rol        : t_alu_opcode := (exe => c_alu_exe_shift, op => c_alu_op_rol, opx => "000");
  constant c_alu_ror        : t_alu_opcode := (exe => c_alu_exe_shift, op => c_alu_op_ror, opx => "000");
  constant c_alu_bext       : t_alu_opcode := (exe => c_alu_exe_shift, op => c_alu_op_bext, opx => "000");

  -- Misc
  constant c_alu_op_mov     : t_alu_op := "000";
  constant c_alu_op_cbits   : t_alu_op := "001";  -- ctz, clz, cpop
  constant c_alu_op_rev     : t_alu_op := "010";  -- rev8, revb
  constant c_alu_op_clmul   : t_alu_op := "011";  -- clmul, clmulh, clmulr

  -- Misc ALU opcodes
  constant c_alu_mov        : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_mov, opx => "000");
  constant c_alu_clz        : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_cbits, opx => "000");
  constant c_alu_ctz        : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_cbits, opx => "001");
  constant c_alu_cpop       : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_cbits, opx => "010");
  constant c_alu_rev8       : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_rev, opx => "000");
  constant c_alu_revb       : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_rev, opx => "001");
  constant c_alu_clmul      : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_clmul, opx => "000");
  constant c_alu_clmulh     : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_clmul, opx => "001");
  constant c_alu_clmulr     : t_alu_opcode := (exe => c_alu_exe_misc, op => c_alu_op_clmul, opx => "010");

--
--  MUL/DIV OPERATION CODES
--

  type t_muldiv_ctrl is record
    mode  : std_logic;
    signa : std_logic;
    signb : std_logic;
  end record;

  constant c_muldiv_none    : t_muldiv_ctrl := (mode => '0', signa => '0', signb => '0');
  constant c_muldiv_mul     : t_muldiv_ctrl := (mode => '0', signa => '1', signb => '1');
  constant c_muldiv_mulh    : t_muldiv_ctrl := (mode => '1', signa => '1', signb => '1');
  constant c_muldiv_mulhsu  : t_muldiv_ctrl := (mode => '1', signa => '1', signb => '0');
  constant c_muldiv_mulhu   : t_muldiv_ctrl := (mode => '1', signa => '0', signb => '0');
  constant c_muldiv_div     : t_muldiv_ctrl := (mode => '0', signa => '1', signb => '1');
  constant c_muldiv_divu    : t_muldiv_ctrl := (mode => '0', signa => '0', signb => '0');
  constant c_muldiv_rem     : t_muldiv_ctrl := (mode => '1', signa => '1', signb => '1');
  constant c_muldiv_remu    : t_muldiv_ctrl := (mode => '1', signa => '0', signb => '0');

--
--  BRANCH OPERATION CODES
--
  subtype t_br_opcode is std_logic_vector(1 downto 0);

  constant c_br_op_eq : t_br_opcode := "00";
  constant c_br_op_ne : t_br_opcode := "01";
  constant c_br_op_lt : t_br_opcode := "10";
  constant c_br_op_ge : t_br_opcode := "11";

--
--  CONTROL & STATUS REGISTER (CSR)
--

  -- CSR OP f3(1:0)
  subtype t_csr_op is std_logic_vector(t_csr_op_range);

  constant c_csr_op_r       : std_logic_vector(t_csr_op_range) := "00";
  constant c_csr_op_rw      : std_logic_vector(t_csr_op_range) := "01";
  constant c_csr_op_rs      : std_logic_vector(t_csr_op_range) := "10";
  constant c_csr_op_rc      : std_logic_vector(t_csr_op_range) := "11";

  constant c_csr_read_only  : std_logic_vector(t_csr_access_range) := "11";

-- Number Privilege Name Description
--
-- Unprivileged Floating-Point CSRs
--
-- 0x001 |  URW | fflags Floating-Point Accrued Exceptions.
-- 0x002 |  URW | frm Floating-Point Dynamic Rounding Mode.
-- 0x003 |  URW | fcsr Floating-Point Control and Status Register (frm + fflags).
--
-- Unprivileged Counter/Timers
--
-- 0xC00 |  URO | cycle Cycle counter for RDCYCLE instruction.
-- 0xC01 |  URO | time Timer for RDTIME instruction.
-- 0xC02 |  URO | instret Instructions-retired counter for RDINSTRET instruction.
-- 0xC03 |  URO | hpmcounter3 Performance-monitoring counter.
-- 0xC04 |  URO | hpmcounter4 Performance-monitoring counter.
-- .
-- .
-- .
-- 0xC1F |  URO | hpmcounter31 Performance-monitoring counter.
-- 0xC80 |  URO | cycleh Upper 32 bits of cycle, RV32 only.
-- 0xC81 |  URO | timeh Upper 32 bits of time, RV32 only.
-- 0xC82 |  URO | instreth Upper 32 bits of instret, RV32 only.
-- 0xC83 |  URO | hpmcounter3h Upper 32 bits of hpmcounter3, RV32 only.
-- 0xC84 |  URO | hpmcounter4h Upper 32 bits of hpmcounter4, RV32 only.
-- .
-- .
-- .
-- 0xC9F |  URO | hpmcounter31h Upper 32 bits of hpmcounter31, RV32 only

  constant c_csr_addr_ucycle          : std_logic_vector(t_csr_addr_range) := x"C00";
  constant c_csr_addr_utime           : std_logic_vector(t_csr_addr_range) := x"C01";
  constant c_csr_addr_uinstret        : std_logic_vector(t_csr_addr_range) := x"C02";
  constant c_csr_addr_hpmcounter3     : std_logic_vector(t_csr_addr_range) := x"C03";
  constant c_csr_addr_hpmcounter4     : std_logic_vector(t_csr_addr_range) := x"C04";
  constant c_csr_addr_hpmcounter5     : std_logic_vector(t_csr_addr_range) := x"C05";
  constant c_csr_addr_hpmcounter6     : std_logic_vector(t_csr_addr_range) := x"C06";
  constant c_csr_addr_hpmcounter7     : std_logic_vector(t_csr_addr_range) := x"C07";
  constant c_csr_addr_hpmcounter8     : std_logic_vector(t_csr_addr_range) := x"C08";
  constant c_csr_addr_hpmcounter9     : std_logic_vector(t_csr_addr_range) := x"C09";
  constant c_csr_addr_hpmcounter10    : std_logic_vector(t_csr_addr_range) := x"C0A";
  constant c_csr_addr_hpmcounter11    : std_logic_vector(t_csr_addr_range) := x"C0B";
  constant c_csr_addr_hpmcounter12    : std_logic_vector(t_csr_addr_range) := x"C0C";
  constant c_csr_addr_hpmcounter13    : std_logic_vector(t_csr_addr_range) := x"C0D";
  constant c_csr_addr_hpmcounter14    : std_logic_vector(t_csr_addr_range) := x"C0E";
  constant c_csr_addr_hpmcounter15    : std_logic_vector(t_csr_addr_range) := x"C0F";
  constant c_csr_addr_hpmcounter16    : std_logic_vector(t_csr_addr_range) := x"C10";
  constant c_csr_addr_hpmcounter17    : std_logic_vector(t_csr_addr_range) := x"C11";
  constant c_csr_addr_hpmcounter18    : std_logic_vector(t_csr_addr_range) := x"C12";
  constant c_csr_addr_hpmcounter19    : std_logic_vector(t_csr_addr_range) := x"C13";
  constant c_csr_addr_hpmcounter20    : std_logic_vector(t_csr_addr_range) := x"C14";
  constant c_csr_addr_hpmcounter21    : std_logic_vector(t_csr_addr_range) := x"C15";
  constant c_csr_addr_hpmcounter22    : std_logic_vector(t_csr_addr_range) := x"C16";
  constant c_csr_addr_hpmcounter23    : std_logic_vector(t_csr_addr_range) := x"C17";
  constant c_csr_addr_hpmcounter24    : std_logic_vector(t_csr_addr_range) := x"C18";
  constant c_csr_addr_hpmcounter25    : std_logic_vector(t_csr_addr_range) := x"C19";
  constant c_csr_addr_hpmcounter26    : std_logic_vector(t_csr_addr_range) := x"C1A";
  constant c_csr_addr_hpmcounter27    : std_logic_vector(t_csr_addr_range) := x"C1B";
  constant c_csr_addr_hpmcounter28    : std_logic_vector(t_csr_addr_range) := x"C1C";
  constant c_csr_addr_hpmcounter29    : std_logic_vector(t_csr_addr_range) := x"C1D";
  constant c_csr_addr_hpmcounter30    : std_logic_vector(t_csr_addr_range) := x"C1E";
  constant c_csr_addr_hpmcounter31    : std_logic_vector(t_csr_addr_range) := x"C1F";
  constant c_csr_addr_utimeh          : std_logic_vector(t_csr_addr_range) := x"C81";
  constant c_csr_addr_ucycleh         : std_logic_vector(t_csr_addr_range) := x"C80";
  constant c_csr_addr_uinstreth       : std_logic_vector(t_csr_addr_range) := x"C82";
  constant c_csr_addr_hpmcounter3h    : std_logic_vector(t_csr_addr_range) := x"C83";
  constant c_csr_addr_hpmcounter4h    : std_logic_vector(t_csr_addr_range) := x"C84";
  constant c_csr_addr_hpmcounter5h    : std_logic_vector(t_csr_addr_range) := x"C85";
  constant c_csr_addr_hpmcounter6h    : std_logic_vector(t_csr_addr_range) := x"C86";
  constant c_csr_addr_hpmcounter7h    : std_logic_vector(t_csr_addr_range) := x"C87";
  constant c_csr_addr_hpmcounter8h    : std_logic_vector(t_csr_addr_range) := x"C88";
  constant c_csr_addr_hpmcounter9h    : std_logic_vector(t_csr_addr_range) := x"C89";
  constant c_csr_addr_hpmcounter10h   : std_logic_vector(t_csr_addr_range) := x"C8A";
  constant c_csr_addr_hpmcounter11h   : std_logic_vector(t_csr_addr_range) := x"C8B";
  constant c_csr_addr_hpmcounter12h   : std_logic_vector(t_csr_addr_range) := x"C8C";
  constant c_csr_addr_hpmcounter13h   : std_logic_vector(t_csr_addr_range) := x"C8D";
  constant c_csr_addr_hpmcounter14h   : std_logic_vector(t_csr_addr_range) := x"C8E";
  constant c_csr_addr_hpmcounter15h   : std_logic_vector(t_csr_addr_range) := x"C8F";
  constant c_csr_addr_hpmcounter16h   : std_logic_vector(t_csr_addr_range) := x"C90";
  constant c_csr_addr_hpmcounter17h   : std_logic_vector(t_csr_addr_range) := x"C91";
  constant c_csr_addr_hpmcounter18h   : std_logic_vector(t_csr_addr_range) := x"C92";
  constant c_csr_addr_hpmcounter19h   : std_logic_vector(t_csr_addr_range) := x"C93";
  constant c_csr_addr_hpmcounter20h   : std_logic_vector(t_csr_addr_range) := x"C94";
  constant c_csr_addr_hpmcounter21h   : std_logic_vector(t_csr_addr_range) := x"C95";
  constant c_csr_addr_hpmcounter22h   : std_logic_vector(t_csr_addr_range) := x"C96";
  constant c_csr_addr_hpmcounter23h   : std_logic_vector(t_csr_addr_range) := x"C97";
  constant c_csr_addr_hpmcounter24h   : std_logic_vector(t_csr_addr_range) := x"C98";
  constant c_csr_addr_hpmcounter25h   : std_logic_vector(t_csr_addr_range) := x"C99";
  constant c_csr_addr_hpmcounter26h   : std_logic_vector(t_csr_addr_range) := x"C9A";
  constant c_csr_addr_hpmcounter27h   : std_logic_vector(t_csr_addr_range) := x"C9B";
  constant c_csr_addr_hpmcounter28h   : std_logic_vector(t_csr_addr_range) := x"C9C";
  constant c_csr_addr_hpmcounter29h   : std_logic_vector(t_csr_addr_range) := x"C9D";
  constant c_csr_addr_hpmcounter30h   : std_logic_vector(t_csr_addr_range) := x"C9E";
  constant c_csr_addr_hpmcounter31h   : std_logic_vector(t_csr_addr_range) := x"C9F";

-- Number Privilege Name Description
--
-- Machine Information Registers
--
-- 0xF11 |  MRO | mvendorid Vendor ID.
-- 0xF12 |  MRO | marchid Architecture ID.
-- 0xF13 |  MRO | mimpid Implementation ID.
-- 0xF14 |  MRO | mhartid Hardware thread ID.
-- 0xF15 |  MRO | mconfigptr Pointer to configuration data structure.
--
-- Machine Trap Setup
-- 0x300 |  MRW | mstatus Machine status register.
-- 0x301 |  MRW | misa ISA and extensions
-- 0x302 |  MRW | medeleg Machine exception delegation register.
-- 0x303 |  MRW | mideleg Machine interrupt delegation register.
-- 0x304 |  MRW | mie Machine interrupt-enable register.
-- 0x305 |  MRW | mtvec Machine trap-handler base address.
-- 0x306 |  MRW | mcounteren Machine counter enable.
-- 0x310 |  MRW | mstatush Additional machine status register, RV32 only.
--
-- Machine Trap Handling
--
-- 0x340 |  MRW | mscratch Scratch register for machine trap handlers.
-- 0x341 |  MRW | mepc Machine exception program counter.
-- 0x342 |  MRW | mcause Machine trap cause.
-- 0x343 |  MRW | mtval Machine bad address or instruction.
-- 0x344 |  MRW | mip Machine interrupt pending.
-- 0x34A |  MRW | mtinst Machine trap instruction (transformed).
-- 0x34B |  MRW | mtval2 Machine bad guest physical address.
--
-- Machine Configuration
--
-- 0x30A |  MRW | menvcfg Machine environment configuration register.
-- 0x31A |  MRW | menvcfgh Additional machine env. conf. register, RV32 only.
-- 0x747 |  MRW | mseccfg Machine security configuration register.
-- 0x757 |  MRW | mseccfgh Additional machine security conf. register, RV32 only.
--
-- Machine Memory Protection
--
-- 0x3A0 |  MRW | pmpcfg0 Physical memory protection configuration.
-- 0x3A1 |  MRW | pmpcfg1 Physical memory protection configuration, RV32 only.
-- 0x3A2 |  MRW | pmpcfg2 Physical memory protection configuration.
-- 0x3A3 |  MRW | pmpcfg3 Physical memory protection configuration, RV32 only.
-- .
-- .
-- .
-- 0x3AE |  MRW | pmpcfg14 Physical memory protection configuration.
-- 0x3AF |  MRW | pmpcfg15 Physical memory protection configuration, RV32 only.
-- 0x3B0 |  MRW | pmpaddr0 Physical memory protection address register.
-- 0x3B1 |  MRW | pmpaddr1 Physical memory protection address register.
-- .
-- .
-- .
-- 0x3EF |  MRW | pmpaddr63 Physical memory protection address register.
--
-- Number Privilege Name Description
--
-- Machine Counter/Timers
--
-- 0xB00 |  MRW | mcycle Machine cycle counter.
-- 0xB02 |  MRW | minstret Machine instructions-retired counter.
-- 0xB03 |  MRW | mhpmcounter3 Machine performance-monitoring counter.
-- 0xB04 |  MRW | mhpmcounter4 Machine performance-monitoring counter.
-- .
-- .
-- .
-- 0xB1F |  MRW | mhpmcounter31 Machine performance-monitoring counter.
-- 0xB80 |  MRW | mcycleh Upper 32 bits of mcycle, RV32 only.
-- 0xB82 |  MRW | minstreth Upper 32 bits of minstret, RV32 only.
-- 0xB83 |  MRW | mhpmcounter3h Upper 32 bits of mhpmcounter3, RV32 only.
-- 0xB84 |  MRW | mhpmcounter4h Upper 32 bits of mhpmcounter4, RV32 only.
-- .
-- .
-- .
-- 0xB9F |  MRW | mhpmcounter31h Upper 32 bits of mhpmcounter31, RV32 only.
--
-- Machine Counter Setup
--
-- 0x320 |  MRW | mcountinhibit Machine counter-inhibit register.
-- 0x323 |  MRW | mhpmevent3 Machine performance-monitoring event selector.
-- 0x324 |  MRW | mhpmevent4 Machine performance-monitoring event selector.
-- .
-- .
-- .
-- 0x33F |  MRW | mhpmevent31 Machine performance-monitoring event selector.
--
-- Debug/Trace Registers (shared with Debug Mode)
--
-- 0x7A0 |  MRW | tselect Debug/Trace trigger register select.
-- 0x7A1 |  MRW | tdata1 First Debug/Trace trigger data register.
-- 0x7A2 |  MRW | tdata2 Second Debug/Trace trigger data register.
-- 0x7A3 |  MRW | tdata3 Third Debug/Trace trigger data register.
-- 0x7A8 |  MRW | mcontext Machine-mode context register.
--
-- Debug Mode Registers
--
-- 0x7B0 |  DRW | dcsr Debug control and status register.
-- 0x7B1 |  DRW | dpc Debug PC.
-- 0x7B2 |  DRW | dscratch0 Debug scratch register 0.
-- 0x7B3 |  DRW | dscratch1 Debug scratch register 1.

  constant c_csr_addr_mvendorid       : std_logic_vector(t_csr_addr_range) := x"F11";
  constant c_csr_addr_marchid         : std_logic_vector(t_csr_addr_range) := x"F12";
  constant c_csr_addr_mimpid          : std_logic_vector(t_csr_addr_range) := x"F13";
  constant c_csr_addr_mhartid         : std_logic_vector(t_csr_addr_range) := x"F14";
  constant c_csr_addr_mconfigptr      : std_logic_vector(t_csr_addr_range) := x"F15";
  constant c_csr_addr_mstatus         : std_logic_vector(t_csr_addr_range) := x"300";
  constant c_csr_addr_misa            : std_logic_vector(t_csr_addr_range) := x"301";
  constant c_csr_addr_medeleg         : std_logic_vector(t_csr_addr_range) := x"302";
  constant c_csr_addr_mideleg         : std_logic_vector(t_csr_addr_range) := x"303";
  constant c_csr_addr_mie             : std_logic_vector(t_csr_addr_range) := x"304";
  constant c_csr_addr_mtvec           : std_logic_vector(t_csr_addr_range) := x"305";
  constant c_csr_addr_mcounteren      : std_logic_vector(t_csr_addr_range) := x"306";
  constant c_csr_addr_mstatush        : std_logic_vector(t_csr_addr_range) := x"310";
  constant c_csr_addr_mcountinhibit   : std_logic_vector(t_csr_addr_range) := x"320";
  constant c_csr_addr_mhpmevent3      : std_logic_vector(t_csr_addr_range) := x"323";
  constant c_csr_addr_mhpmevent4      : std_logic_vector(t_csr_addr_range) := x"324";
  constant c_csr_addr_mhpmevent5      : std_logic_vector(t_csr_addr_range) := x"325";
  constant c_csr_addr_mhpmevent6      : std_logic_vector(t_csr_addr_range) := x"326";
  constant c_csr_addr_mhpmevent7      : std_logic_vector(t_csr_addr_range) := x"327";
  constant c_csr_addr_mhpmevent8      : std_logic_vector(t_csr_addr_range) := x"328";
  constant c_csr_addr_mhpmevent9      : std_logic_vector(t_csr_addr_range) := x"329";
  constant c_csr_addr_mhpmevent10     : std_logic_vector(t_csr_addr_range) := x"32A";
  constant c_csr_addr_mhpmevent11     : std_logic_vector(t_csr_addr_range) := x"32B";
  constant c_csr_addr_mhpmevent12     : std_logic_vector(t_csr_addr_range) := x"32C";
  constant c_csr_addr_mhpmevent13     : std_logic_vector(t_csr_addr_range) := x"32D";
  constant c_csr_addr_mhpmevent14     : std_logic_vector(t_csr_addr_range) := x"32E";
  constant c_csr_addr_mhpmevent15     : std_logic_vector(t_csr_addr_range) := x"32F";
  constant c_csr_addr_mhpmevent16     : std_logic_vector(t_csr_addr_range) := x"330";
  constant c_csr_addr_mhpmevent17     : std_logic_vector(t_csr_addr_range) := x"331";
  constant c_csr_addr_mhpmevent18     : std_logic_vector(t_csr_addr_range) := x"332";
  constant c_csr_addr_mhpmevent19     : std_logic_vector(t_csr_addr_range) := x"333";
  constant c_csr_addr_mhpmevent20     : std_logic_vector(t_csr_addr_range) := x"334";
  constant c_csr_addr_mhpmevent21     : std_logic_vector(t_csr_addr_range) := x"335";
  constant c_csr_addr_mhpmevent22     : std_logic_vector(t_csr_addr_range) := x"336";
  constant c_csr_addr_mhpmevent23     : std_logic_vector(t_csr_addr_range) := x"337";
  constant c_csr_addr_mhpmevent24     : std_logic_vector(t_csr_addr_range) := x"338";
  constant c_csr_addr_mhpmevent25     : std_logic_vector(t_csr_addr_range) := x"339";
  constant c_csr_addr_mhpmevent26     : std_logic_vector(t_csr_addr_range) := x"33A";
  constant c_csr_addr_mhpmevent27     : std_logic_vector(t_csr_addr_range) := x"33B";
  constant c_csr_addr_mhpmevent28     : std_logic_vector(t_csr_addr_range) := x"33C";
  constant c_csr_addr_mhpmevent29     : std_logic_vector(t_csr_addr_range) := x"33D";
  constant c_csr_addr_mhpmevent30     : std_logic_vector(t_csr_addr_range) := x"33E";
  constant c_csr_addr_mhpmevent31     : std_logic_vector(t_csr_addr_range) := x"33F";
  constant c_csr_addr_mscratch        : std_logic_vector(t_csr_addr_range) := x"340";
  constant c_csr_addr_mepc            : std_logic_vector(t_csr_addr_range) := x"341";
  constant c_csr_addr_mcause          : std_logic_vector(t_csr_addr_range) := x"342";
  constant c_csr_addr_mtval           : std_logic_vector(t_csr_addr_range) := x"343";
  constant c_csr_addr_mip             : std_logic_vector(t_csr_addr_range) := x"344";
  constant c_csr_addr_mtinst          : std_logic_vector(t_csr_addr_range) := x"34A";
  constant c_csr_addr_mtval2          : std_logic_vector(t_csr_addr_range) := x"34B";
  constant c_csr_addr_menvcfg         : std_logic_vector(t_csr_addr_range) := x"30A";
  constant c_csr_addr_menvcfgh        : std_logic_vector(t_csr_addr_range) := x"31A";
  constant c_csr_addr_mseccfg         : std_logic_vector(t_csr_addr_range) := x"747";
  constant c_csr_addr_mseccfgh        : std_logic_vector(t_csr_addr_range) := x"757";
  constant c_csr_addr_pmpcfg0         : std_logic_vector(t_csr_addr_range) := x"3A0";
  constant c_csr_addr_pmpcfg1         : std_logic_vector(t_csr_addr_range) := x"3A1";
  constant c_csr_addr_pmpcfg2         : std_logic_vector(t_csr_addr_range) := x"3A2";
  constant c_csr_addr_pmpcfg3         : std_logic_vector(t_csr_addr_range) := x"3A3";
  constant c_csr_addr_pmpcfg4         : std_logic_vector(t_csr_addr_range) := x"3A4";
  constant c_csr_addr_pmpcfg5         : std_logic_vector(t_csr_addr_range) := x"3A5";
  constant c_csr_addr_pmpcfg6         : std_logic_vector(t_csr_addr_range) := x"3A6";
  constant c_csr_addr_pmpcfg7         : std_logic_vector(t_csr_addr_range) := x"3A7";
  constant c_csr_addr_pmpcfg8         : std_logic_vector(t_csr_addr_range) := x"3A8";
  constant c_csr_addr_pmpcfg9         : std_logic_vector(t_csr_addr_range) := x"3A9";
  constant c_csr_addr_pmpcfg10        : std_logic_vector(t_csr_addr_range) := x"3AA";
  constant c_csr_addr_pmpcfg11        : std_logic_vector(t_csr_addr_range) := x"3AB";
  constant c_csr_addr_pmpcfg12        : std_logic_vector(t_csr_addr_range) := x"3AC";
  constant c_csr_addr_pmpcfg13        : std_logic_vector(t_csr_addr_range) := x"3AD";
  constant c_csr_addr_pmpcfg14        : std_logic_vector(t_csr_addr_range) := x"3AE";
  constant c_csr_addr_pmpcfg15        : std_logic_vector(t_csr_addr_range) := x"3AF";
  constant c_csr_addr_pmpaddr0        : std_logic_vector(t_csr_addr_range) := x"3B0";
  constant c_csr_addr_pmpaddr1        : std_logic_vector(t_csr_addr_range) := x"3B1";
  constant c_csr_addr_pmpaddr2        : std_logic_vector(t_csr_addr_range) := x"3B2";
  constant c_csr_addr_pmpaddr3        : std_logic_vector(t_csr_addr_range) := x"3B3";
  constant c_csr_addr_pmpaddr4        : std_logic_vector(t_csr_addr_range) := x"3B4";
  constant c_csr_addr_pmpaddr5        : std_logic_vector(t_csr_addr_range) := x"3B5";
  constant c_csr_addr_pmpaddr6        : std_logic_vector(t_csr_addr_range) := x"3B6";
  constant c_csr_addr_pmpaddr7        : std_logic_vector(t_csr_addr_range) := x"3B7";
  constant c_csr_addr_pmpaddr8        : std_logic_vector(t_csr_addr_range) := x"3B8";
  constant c_csr_addr_pmpaddr9        : std_logic_vector(t_csr_addr_range) := x"3B9";
  constant c_csr_addr_pmpaddr10       : std_logic_vector(t_csr_addr_range) := x"3BA";
  constant c_csr_addr_pmpaddr11       : std_logic_vector(t_csr_addr_range) := x"3BB";
  constant c_csr_addr_pmpaddr12       : std_logic_vector(t_csr_addr_range) := x"3BC";
  constant c_csr_addr_pmpaddr13       : std_logic_vector(t_csr_addr_range) := x"3BD";
  constant c_csr_addr_pmpaddr14       : std_logic_vector(t_csr_addr_range) := x"3BE";
  constant c_csr_addr_pmpaddr15       : std_logic_vector(t_csr_addr_range) := x"3BF";
  constant c_csr_addr_pmpaddr16       : std_logic_vector(t_csr_addr_range) := x"3C0";
  constant c_csr_addr_pmpaddr17       : std_logic_vector(t_csr_addr_range) := x"3C1";
  constant c_csr_addr_pmpaddr18       : std_logic_vector(t_csr_addr_range) := x"3C2";
  constant c_csr_addr_pmpaddr19       : std_logic_vector(t_csr_addr_range) := x"3C3";
  constant c_csr_addr_pmpaddr20       : std_logic_vector(t_csr_addr_range) := x"3C4";
  constant c_csr_addr_pmpaddr21       : std_logic_vector(t_csr_addr_range) := x"3C5";
  constant c_csr_addr_pmpaddr22       : std_logic_vector(t_csr_addr_range) := x"3C6";
  constant c_csr_addr_pmpaddr23       : std_logic_vector(t_csr_addr_range) := x"3C7";
  constant c_csr_addr_pmpaddr24       : std_logic_vector(t_csr_addr_range) := x"3C8";
  constant c_csr_addr_pmpaddr25       : std_logic_vector(t_csr_addr_range) := x"3C9";
  constant c_csr_addr_pmpaddr26       : std_logic_vector(t_csr_addr_range) := x"3CA";
  constant c_csr_addr_pmpaddr27       : std_logic_vector(t_csr_addr_range) := x"3CB";
  constant c_csr_addr_pmpaddr28       : std_logic_vector(t_csr_addr_range) := x"3CC";
  constant c_csr_addr_pmpaddr29       : std_logic_vector(t_csr_addr_range) := x"3CD";
  constant c_csr_addr_pmpaddr30       : std_logic_vector(t_csr_addr_range) := x"3CE";
  constant c_csr_addr_pmpaddr31       : std_logic_vector(t_csr_addr_range) := x"3CF";
  constant c_csr_addr_pmpaddr32       : std_logic_vector(t_csr_addr_range) := x"3D0";
  constant c_csr_addr_pmpaddr33       : std_logic_vector(t_csr_addr_range) := x"3D1";
  constant c_csr_addr_pmpaddr34       : std_logic_vector(t_csr_addr_range) := x"3D2";
  constant c_csr_addr_pmpaddr35       : std_logic_vector(t_csr_addr_range) := x"3D3";
  constant c_csr_addr_pmpaddr36       : std_logic_vector(t_csr_addr_range) := x"3D4";
  constant c_csr_addr_pmpaddr37       : std_logic_vector(t_csr_addr_range) := x"3D5";
  constant c_csr_addr_pmpaddr38       : std_logic_vector(t_csr_addr_range) := x"3D6";
  constant c_csr_addr_pmpaddr39       : std_logic_vector(t_csr_addr_range) := x"3D7";
  constant c_csr_addr_pmpaddr40       : std_logic_vector(t_csr_addr_range) := x"3D8";
  constant c_csr_addr_pmpaddr41       : std_logic_vector(t_csr_addr_range) := x"3D9";
  constant c_csr_addr_pmpaddr42       : std_logic_vector(t_csr_addr_range) := x"3DA";
  constant c_csr_addr_pmpaddr43       : std_logic_vector(t_csr_addr_range) := x"3DB";
  constant c_csr_addr_pmpaddr44       : std_logic_vector(t_csr_addr_range) := x"3DC";
  constant c_csr_addr_pmpaddr45       : std_logic_vector(t_csr_addr_range) := x"3DD";
  constant c_csr_addr_pmpaddr46       : std_logic_vector(t_csr_addr_range) := x"3DE";
  constant c_csr_addr_pmpaddr47       : std_logic_vector(t_csr_addr_range) := x"3DF";
  constant c_csr_addr_pmpaddr48       : std_logic_vector(t_csr_addr_range) := x"3E0";
  constant c_csr_addr_pmpaddr49       : std_logic_vector(t_csr_addr_range) := x"3E1";
  constant c_csr_addr_pmpaddr50       : std_logic_vector(t_csr_addr_range) := x"3E2";
  constant c_csr_addr_pmpaddr51       : std_logic_vector(t_csr_addr_range) := x"3E3";
  constant c_csr_addr_pmpaddr52       : std_logic_vector(t_csr_addr_range) := x"3E4";
  constant c_csr_addr_pmpaddr53       : std_logic_vector(t_csr_addr_range) := x"3E5";
  constant c_csr_addr_pmpaddr54       : std_logic_vector(t_csr_addr_range) := x"3E6";
  constant c_csr_addr_pmpaddr55       : std_logic_vector(t_csr_addr_range) := x"3E7";
  constant c_csr_addr_pmpaddr56       : std_logic_vector(t_csr_addr_range) := x"3E8";
  constant c_csr_addr_pmpaddr57       : std_logic_vector(t_csr_addr_range) := x"3E9";
  constant c_csr_addr_pmpaddr58       : std_logic_vector(t_csr_addr_range) := x"3EA";
  constant c_csr_addr_pmpaddr59       : std_logic_vector(t_csr_addr_range) := x"3EB";
  constant c_csr_addr_pmpaddr60       : std_logic_vector(t_csr_addr_range) := x"3EC";
  constant c_csr_addr_pmpaddr61       : std_logic_vector(t_csr_addr_range) := x"3ED";
  constant c_csr_addr_pmpaddr62       : std_logic_vector(t_csr_addr_range) := x"3EE";
  constant c_csr_addr_pmpaddr63       : std_logic_vector(t_csr_addr_range) := x"3EF";
  constant c_csr_addr_mcycle          : std_logic_vector(t_csr_addr_range) := x"B00";
  constant c_csr_addr_minstret        : std_logic_vector(t_csr_addr_range) := x"B02";
  constant c_csr_addr_mhpmcounter3    : std_logic_vector(t_csr_addr_range) := x"B03";
  constant c_csr_addr_mhpmcounter4    : std_logic_vector(t_csr_addr_range) := x"B04";
  constant c_csr_addr_mhpmcounter5    : std_logic_vector(t_csr_addr_range) := x"B05";
  constant c_csr_addr_mhpmcounter6    : std_logic_vector(t_csr_addr_range) := x"B06";
  constant c_csr_addr_mhpmcounter7    : std_logic_vector(t_csr_addr_range) := x"B07";
  constant c_csr_addr_mhpmcounter8    : std_logic_vector(t_csr_addr_range) := x"B08";
  constant c_csr_addr_mhpmcounter9    : std_logic_vector(t_csr_addr_range) := x"B09";
  constant c_csr_addr_mhpmcounter10   : std_logic_vector(t_csr_addr_range) := x"B0A";
  constant c_csr_addr_mhpmcounter11   : std_logic_vector(t_csr_addr_range) := x"B0B";
  constant c_csr_addr_mhpmcounter12   : std_logic_vector(t_csr_addr_range) := x"B0C";
  constant c_csr_addr_mhpmcounter13   : std_logic_vector(t_csr_addr_range) := x"B0D";
  constant c_csr_addr_mhpmcounter14   : std_logic_vector(t_csr_addr_range) := x"B0E";
  constant c_csr_addr_mhpmcounter15   : std_logic_vector(t_csr_addr_range) := x"B0F";
  constant c_csr_addr_mhpmcounter16   : std_logic_vector(t_csr_addr_range) := x"B10";
  constant c_csr_addr_mhpmcounter17   : std_logic_vector(t_csr_addr_range) := x"B11";
  constant c_csr_addr_mhpmcounter18   : std_logic_vector(t_csr_addr_range) := x"B12";
  constant c_csr_addr_mhpmcounter19   : std_logic_vector(t_csr_addr_range) := x"B13";
  constant c_csr_addr_mhpmcounter20   : std_logic_vector(t_csr_addr_range) := x"B14";
  constant c_csr_addr_mhpmcounter21   : std_logic_vector(t_csr_addr_range) := x"B15";
  constant c_csr_addr_mhpmcounter22   : std_logic_vector(t_csr_addr_range) := x"B16";
  constant c_csr_addr_mhpmcounter23   : std_logic_vector(t_csr_addr_range) := x"B17";
  constant c_csr_addr_mhpmcounter24   : std_logic_vector(t_csr_addr_range) := x"B18";
  constant c_csr_addr_mhpmcounter25   : std_logic_vector(t_csr_addr_range) := x"B19";
  constant c_csr_addr_mhpmcounter26   : std_logic_vector(t_csr_addr_range) := x"B1A";
  constant c_csr_addr_mhpmcounter27   : std_logic_vector(t_csr_addr_range) := x"B1B";
  constant c_csr_addr_mhpmcounter28   : std_logic_vector(t_csr_addr_range) := x"B1C";
  constant c_csr_addr_mhpmcounter29   : std_logic_vector(t_csr_addr_range) := x"B1D";
  constant c_csr_addr_mhpmcounter30   : std_logic_vector(t_csr_addr_range) := x"B1E";
  constant c_csr_addr_mhpmcounter31   : std_logic_vector(t_csr_addr_range) := x"B1F";
  constant c_csr_addr_mcycleh         : std_logic_vector(t_csr_addr_range) := x"B80";
  constant c_csr_addr_minstreth       : std_logic_vector(t_csr_addr_range) := x"B82";
  constant c_csr_addr_mhpmcounter3h   : std_logic_vector(t_csr_addr_range) := x"B83";
  constant c_csr_addr_mhpmcounter4h   : std_logic_vector(t_csr_addr_range) := x"B84";
  constant c_csr_addr_mhpmcounter5h   : std_logic_vector(t_csr_addr_range) := x"B85";
  constant c_csr_addr_mhpmcounter6h   : std_logic_vector(t_csr_addr_range) := x"B86";
  constant c_csr_addr_mhpmcounter7h   : std_logic_vector(t_csr_addr_range) := x"B87";
  constant c_csr_addr_mhpmcounter8h   : std_logic_vector(t_csr_addr_range) := x"B88";
  constant c_csr_addr_mhpmcounter9h   : std_logic_vector(t_csr_addr_range) := x"B89";
  constant c_csr_addr_mhpmcounter10h  : std_logic_vector(t_csr_addr_range) := x"B8A";
  constant c_csr_addr_mhpmcounter11h  : std_logic_vector(t_csr_addr_range) := x"B8B";
  constant c_csr_addr_mhpmcounter12h  : std_logic_vector(t_csr_addr_range) := x"B8C";
  constant c_csr_addr_mhpmcounter13h  : std_logic_vector(t_csr_addr_range) := x"B8D";
  constant c_csr_addr_mhpmcounter14h  : std_logic_vector(t_csr_addr_range) := x"B8E";
  constant c_csr_addr_mhpmcounter15h  : std_logic_vector(t_csr_addr_range) := x"B8F";
  constant c_csr_addr_mhpmcounter16h  : std_logic_vector(t_csr_addr_range) := x"B90";
  constant c_csr_addr_mhpmcounter17h  : std_logic_vector(t_csr_addr_range) := x"B91";
  constant c_csr_addr_mhpmcounter18h  : std_logic_vector(t_csr_addr_range) := x"B92";
  constant c_csr_addr_mhpmcounter19h  : std_logic_vector(t_csr_addr_range) := x"B93";
  constant c_csr_addr_mhpmcounter20h  : std_logic_vector(t_csr_addr_range) := x"B94";
  constant c_csr_addr_mhpmcounter21h  : std_logic_vector(t_csr_addr_range) := x"B95";
  constant c_csr_addr_mhpmcounter22h  : std_logic_vector(t_csr_addr_range) := x"B96";
  constant c_csr_addr_mhpmcounter23h  : std_logic_vector(t_csr_addr_range) := x"B97";
  constant c_csr_addr_mhpmcounter24h  : std_logic_vector(t_csr_addr_range) := x"B98";
  constant c_csr_addr_mhpmcounter25h  : std_logic_vector(t_csr_addr_range) := x"B99";
  constant c_csr_addr_mhpmcounter26h  : std_logic_vector(t_csr_addr_range) := x"B9A";
  constant c_csr_addr_mhpmcounter27h  : std_logic_vector(t_csr_addr_range) := x"B9B";
  constant c_csr_addr_mhpmcounter28h  : std_logic_vector(t_csr_addr_range) := x"B9C";
  constant c_csr_addr_mhpmcounter29h  : std_logic_vector(t_csr_addr_range) := x"B9D";
  constant c_csr_addr_mhpmcounter30h  : std_logic_vector(t_csr_addr_range) := x"B9E";
  constant c_csr_addr_mhpmcounter31h  : std_logic_vector(t_csr_addr_range) := x"B9F";
  constant c_csr_addr_tselect         : std_logic_vector(t_csr_addr_range) := x"7A0";
  constant c_csr_addr_tdata1          : std_logic_vector(t_csr_addr_range) := x"7A1";
  constant c_csr_addr_tdata2          : std_logic_vector(t_csr_addr_range) := x"7A2";
  constant c_csr_addr_tdata3          : std_logic_vector(t_csr_addr_range) := x"7A3";
  constant c_csr_addr_mcontext        : std_logic_vector(t_csr_addr_range) := x"7A8";
  constant c_csr_addr_dcsr            : std_logic_vector(t_csr_addr_range) := x"7B0";
  constant c_csr_addr_dpc             : std_logic_vector(t_csr_addr_range) := x"7B1";
  constant c_csr_addr_dscratch0       : std_logic_vector(t_csr_addr_range) := x"7B2";
  constant c_csr_addr_dscratch1       : std_logic_vector(t_csr_addr_range) := x"7B3";

--  Interrupt Exception Code  Description
--  0         0               Instruction address misaligned
--  0         1               Instruction access fault
--  0         2               Illegal instruction
--  0         3               Breakpoint
--  0         4               Load address misaligned
--  0         5               Load access fault
--  0         6               Store/AMO address misaligned
--  0         7               Store/AMO access fault
--  0         8               Environment call from U-mode
--  0         9               Environment call from S-mode
--  0         10              Reserved
--  0         11              Environment call from M-mode
--  0         12              Instruction page fault
--  0         13              Load page fault
--  0         14              Reserved
--  0         15              Store/AMO page fault
--  0         16-23           Reserved
--  0         24-31           Designated for custom use
--  0         32-47           Reserved
--  0         48-63           Designated for custom use
--  0         ≥64             Reserved
  constant c_excp_inst_addr_misalign      : t_wordx := x"00000000";
  constant c_excp_inst_access_fault       : t_wordx := x"00000001";
  constant c_excp_inst_illegal            : t_wordx := x"00000002";
  constant c_excp_inst_breakpoint         : t_wordx := x"00000003";
  constant c_excp_load_addr_misalign      : t_wordx := x"00000004";
  constant c_excp_load_access_fault       : t_wordx := x"00000005";
  constant c_excp_store_amo_addr_misalign : t_wordx := x"00000006";
  constant c_excp_store_amo_access_fault  : t_wordx := x"00000007";
  constant c_excp_ecall_from_user         : t_wordx := x"00000008";
  constant c_excp_ecall_from_supervisor   : t_wordx := x"00000009";
  -- reserved                                                                 x"0000000A"
  constant c_excp_ecall_from_machine      : t_wordx := x"0000000B";
  constant c_excp_inst_page_fault         : t_wordx := x"0000000C";
  constant c_excp_load_page_fault         : t_wordx := x"0000000D";
  -- reserved                                                                 x"0000000E"
  constant c_excp_store_amo_page_fault    : t_wordx := x"0000000F";
--  Interrupt Exception Code  Description
--  1         0               Reserved
--  1         1               Supervisor software interrupt
--  1         2               Reserved
--  1         3               Machine software interrupt
--  1         4               Reserved
--  1         5               Supervisor timer interrupt
--  1         6               Reserved
--  1         7               Machine timer interrupt
--  1         8               Reserved
--  1         9               Supervisor external interrupt
--  1         10              Reserved
--  1         11              Machine external interrupt
--  1         12-15           Reserved
--  1         ≥16             Designated for platform use
  -- reserved user                                                            x"80000000"
  constant c_excp_sw_int_supervisor       : t_wordx := x"80000001";
  -- reserved hypervisor                                                      x"80000002"
  constant c_excp_sw_int_machine          : t_wordx := x"80000003";
  -- reserved user                                                            x"80000004"
  constant c_excp_tim_int_supervisor      : t_wordx := x"80000005";
  -- reserved hypervisor                                                      x"80000006"
  constant c_excp_tim_int_machine         : t_wordx := x"80000007";
  -- reserved user                                                            x"80000008"
  constant c_excp_ext_int_supervisor      : t_wordx := x"80000009";
  -- reserved hypervisor                                                      x"8000000A"
  constant c_excp_ext_int_machine         : t_wordx := x"8000000B";

  subtype t_priv_lvl is std_logic_vector(1 downto 0);

  constant c_priv_lvl_m : t_priv_lvl := "11";
  constant c_priv_lvl_h : t_priv_lvl := "10";
  constant c_priv_lvl_s : t_priv_lvl := "01";
  constant c_priv_lvl_u : t_priv_lvl := "00";

--
--  TYPES
--

type t_riscv_isa_extensions is (
  A,      -- Extension for Atomic Instructions
  B,      -- Extension for Bit Manipulation
  C,      -- Extension for Compressed Instructions
  M,      -- Extension for Integer Multiplication and Division
  U,      -- Extension for User privilege level
  Zalrsc, -- Extension for Load-Reserved/Store-Conditional Instructions
  Zaamo,  -- Extension for Atomic Memory Operations
  Zba,    -- Extension for Address generation
  Zbb,    -- Extension for Basic bit-manipulation
  Zbc,    -- Extension for Carry-less multiplication
  Zbs,    -- Extension for Single-bit instructions
  Zbkb,   -- Extension for Bit-manipulation for Cryptography
  Zbkc,   -- Extension for Carry-less multiplication for Cryptography
  Zbkx,   -- Extension for Crossbar permutations
  Zca,    -- Extension for Code-size saving instructions
  Zcb,    -- Extension for Code-size saving instructions
  Zcmp,   -- Extension for Code-size saving push/pop instructions
  Zcmt,   -- Extension for Code-size saving table jump instructions
  Zce,    -- Extension including Zca, Zcb, Zcmp and Zcmt
  Zmmul,  -- Extension for multiplication (M without division)
  Zicntr, -- Extension for Base Counters and Timers
  Zicond, -- Extension for Integer Conditional Operations
  Zihpm,  -- Extension for Hardware Performance Counters
  Smpmp   -- Extension for PMP Enhancements for memory access and execution prevention in Machine mode
);

type t_riscv_isa_config is array(t_riscv_isa_extensions) of boolean;

type t_reg_fw_select is (reg_rf, reg_ex, reg_wb);

type t_op_a_select is (op_a_rs1, op_a_pc, op_a_csr);

type t_imm_b_select is (imm_b_i, imm_b_s, imm_b_u, imm_b_csr, imm_b_pc_incr);

type t_op_b_select is (op_b_rs2, op_b_imm);

type t_op_c_select is (op_c_rs2, op_c_brt);

type t_jmp_select is (jmp_jal, jmp_br, jmp_jalr);

type t_ex_select is (ex_alu, ex_csr, ex_mul, ex_div);

type t_wb_select is (wb_ex, wb_mem);

type t_bus_prot is record
  priviledged : std_logic;
  non_secure  : std_logic;
  instruction : std_logic;
end record;

type t_bus_mem is record
  bufferable  : std_logic;
  cacheable   : std_logic;
end record;

type t_bus_req is record
  addr        : t_wordx;
  data        : t_wordx;
  we          : std_logic;
  prot        : t_bus_prot;
  memtype     : t_bus_mem;
  exclusive   : std_logic;
  dbg         : std_logic;
end record;

constant c_bus_resp_okay    : std_logic_vector(1 downto 0) := "00";
constant c_bus_resp_exokay  : std_logic_vector(1 downto 0) := "01";
constant c_bus_resp_slverr  : std_logic_vector(1 downto 0) := "10";
constant c_bus_resp_decerr  : std_logic_vector(1 downto 0) := "11";

type t_bus_resp is record
  data        : t_wordx;
  resp        : std_logic_vector(1 downto 0);
end record;

type t_if_ctrl is record
  pc_set      : std_logic;
  pc          : t_wordx;
  flush       : std_logic;
end record;

type t_if_id_reg is record
  pc          : t_wordx;
  inst        : t_wordx;
  compressed  : std_logic;
  illegal     : std_logic;
  seq_begin   : std_logic;
  seq_last    : std_logic;
end record;

type t_lsu_ctrl is record
  we   : std_logic;
  sz   : std_logic_vector(1 downto 0);
  sext : std_logic;
  amo  : std_logic_vector(5 downto 0);
end record;

constant c_lsu_ctrl_none : t_lsu_ctrl := (
  we => '0',
  sz => "00",
  sext => '0',
  amo => (others => '0')
);

type t_decoded_inst is record
  f3          : t_f3;
  rf_re       : std_logic_vector(1 downto 0);
  rf_we       : std_logic;
  imm_b_sel   : t_imm_b_select;
  op_a_sel    : t_op_a_select;
  op_b_sel    : t_op_b_select;
  op_c_sel    : t_op_c_select;
  jmp_sel     : t_jmp_select;
  ex_sel      : t_ex_select;
  wb_sel      : t_wb_select;
  alu_en      : std_logic;
  alu_op      : t_alu_opcode;
  mul_en      : std_logic;
  div_en      : std_logic;
  muldiv_ctrl : t_muldiv_ctrl;
  jal         : std_logic;
  br_en       : std_logic;
  csr_en      : std_logic;
  csr_op      : t_csr_op;
  lsu_en      : std_logic;
  lsu_ctrl    : t_lsu_ctrl;
  sys_en      : std_logic;
  sys_ecall   : std_logic;
  sys_ebreak  : std_logic;
  sys_mret    : std_logic;
  sys_dret    : std_logic;
  sys_fence   : std_logic;
  sys_fencei  : std_logic;
  sys_wfi     : std_logic;
  illegal     : std_logic;
end record;

constant c_decoded_inst_illegal : t_decoded_inst := (
  f3          => "000",
  rf_re       => "00",
  rf_we       => '0',
  imm_b_sel   => imm_b_i,
  op_a_sel    => op_a_rs1,
  op_b_sel    => op_b_rs2,
  op_c_sel    => op_c_rs2,
  ex_sel      => ex_alu,
  jmp_sel     => jmp_jal,
  wb_sel      => wb_ex,
  alu_en      => '0',
  alu_op      => c_alu_add,
  mul_en      => '0',
  div_en      => '0',
  muldiv_ctrl => c_muldiv_none,
  jal         => '0',
  br_en       => '0',
  csr_en      => '0',
  csr_op      => "00",
  lsu_en      => '0',
  lsu_ctrl    => c_lsu_ctrl_none,
  sys_en      => '0',
  sys_ecall   => '0',
  sys_ebreak  => '0',
  sys_mret    => '0',
  sys_dret    => '0',
  sys_fence   => '0',
  sys_fencei  => '0',
  sys_wfi     => '0',
  illegal     => '1'
);

--
--  FUNCTIONS
--

  function f_log2(n : positive) return natural;
  function f_log2nz(n : positive) return natural;
  function f_ceil_div(n : natural; d : positive) return natural;
  function f_reverse(v : std_logic_vector; size : positive := 1; reverse : boolean := true) return std_logic_vector;
  function f_bit(i : integer) return std_logic;
  function f_bit(b : boolean) return std_logic;
  function f_integer(b : boolean) return integer;
  function "+"(l : integer; r : boolean) return integer;
  function "-"(l : integer; r : boolean) return integer;
  function "*"(l : integer; r : boolean) return integer;

  function f_compressed(i : std_logic_vector) return boolean;

  function f_alu_math(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx;

  function f_alu_shift(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx;

  function f_alu_logic(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx;

  function f_alu_misc_clz(
    op : std_logic_vector
  ) return std_logic_vector;

  function f_alu_misc_cpop(
    op : std_logic_vector
  ) return std_logic_vector;

  function f_alu_misc(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx;

  function f_alu(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_alu_result;

  function f_jmp_target(
    jmp_sel : t_jmp_select;
    pc      : t_wordx;
    rs1     : t_wordx;
    imm_j   : t_wordx;
    imm_b   : t_wordx;
    imm_i   : t_wordx
  ) return t_wordx;

  function f_imm_i(i : t_wordx) return t_wordx;
  function f_imm_s(i : t_wordx) return t_wordx;
  function f_imm_u(i : t_wordx) return t_wordx;
  function f_imm_b(i : t_wordx) return t_wordx;
  function f_imm_j(i : t_wordx) return t_wordx;
  function f_imm_csr(i : t_wordx) return t_wordx;

  function f_opcode(i : t_wordx) return t_opcode;
  function f_rd(i : t_wordx) return t_rfaddr;
  function f_rs1(i : t_wordx) return t_rfaddr;
  function f_rs2(i : t_wordx) return t_rfaddr;
  function f_f3(i : t_wordx) return t_f3;
  function f_f5(i : t_wordx) return t_f5;
  function f_f7(i : t_wordx) return t_f7;
  function f_f12(i : t_wordx) return t_f12;

  /*function f_reg_select(
    sel   : t_reg_fw_select;
    r_rf  : t_wordx;
    r_ex  : t_wordx;
    r_mem : t_wordx;
    r_wb  : t_wordx
  ) return t_wordx;
*/
  function f_inst_decode(
    cfg   : t_riscv_isa_config;
    inst  : t_wordx
  ) return t_decoded_inst;
--
--  PROCEDURES
--

  procedure pr_extract_compressed(
    cfg           : t_riscv_isa_config;
    cinst         : in  t_wordx;
    inst          : out t_wordx;
    is_compressed : out std_logic;
    illegal       : out std_logic
  );

end package riscvim_pkg;

package body riscvim_pkg is

--
--  FUNCTIONS
--

  function f_log2(n : positive) return natural is
  begin
    return integer(ceil(log2(real(n))));
  end function f_log2;

  function f_log2nz(n : positive) return natural is
  begin
    return maximum(1, f_log2(n));
  end function f_log2nz;

  function f_ceil_div(n : natural; d : positive) return natural is
  begin
    return (n+d-1)/d;
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

  function f_bit(i : integer) return std_logic is
  begin
    if i /= 0 then return '1'; else return '0'; end if;
  end function f_bit;

  function f_bit(b : boolean) return std_logic is
  begin
    if b then return '1'; else return '0'; end if;
  end function f_bit;

  function f_integer(b : boolean) return integer is
  begin
    if b then return 1; else return 0; end if;
  end function f_integer;

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



  function f_compressed(i : std_logic_vector) return boolean is
  begin
    assert i'length >= 2 report "f_compressed: invalid arg" severity failure;
    return i(1 downto 0) /= "11";
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
    v_op_b := unsigned(op_b xor alu_op.op(2)); -- Invert op_b if alu_op(2)
    (v_co, v_add_res, v_tmp) := std_logic_vector(('0' & v_op_a & '1') + (v_op_b & alu_op.op(2)));

    -- EQ
    v_eq := '0';
    if op_a = op_b then
      v_eq := '1';
    end if;

    -- SLT(U)
    v_op_a_sx := alu_op.opx(0) and op_a(c_xhi);
    v_op_b_sx := alu_op.opx(0) and op_b(c_xhi);
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
    variable v_shamt    : unsigned(4 downto 0);
    variable v_shift_hi : t_wordx := (others => '0');
    variable v_shift_lo : t_wordx := (others => '0');
    variable v_shift    : t_dwordx;
    variable v_res      : t_wordx := (others => '0');
  begin
    -- Invert shift amount on left shift
    v_shamt := unsigned(op_b(v_shamt'range) xor alu_op.op(2));

    if cfg(Zbb) and alu_op.op(0) = '1' then
      -- Rotate
      if alu_op.op(2) = '1' then
        -- Left shift
        v_shift_hi := '0' & op_a(c_xhi downto 1);
        v_shift_lo := op_a(0) & op_a(c_xhi downto 1);
      else
        -- Right shift
        v_shift_hi := op_a;
        v_shift_lo := op_a;
      end if;
    else
      -- Normal shift
      if alu_op.op(2) = '1' then
        -- Left shift
        v_shift_hi := '0' & op_a(c_xhi downto 1);
        v_shift_lo := op_a(0) & (c_xhi-1 downto 0 => '0');
      else
        -- Right shift
        v_shift_hi := (others => (alu_op.opx(0)) and op_a(op_a'high));
        v_shift_lo := op_a;
      end if;
    end if;
    v_shift := v_shift_hi & v_shift_lo;
    v_shift := std_logic_vector(shift_right(unsigned(v_shift), to_integer(v_shamt)));

    if cfg(Zbs) and alu_op.op(1) = '1' then
      -- BEXT
      v_res(0)  := v_shift(0);
    else
      -- Shift or rotate
      v_res     := v_shift(t_x_range);
    end if;

    return v_res;
  end function f_alu_shift;

  function f_alu_logic(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx is
    variable v_op_b     : t_wordx := op_b;
    variable v_op_b_eqz : std_logic := nor op_b;
  begin
    if cfg(Zbb) or cfg(Zbs) or cfg(Zicond) then
      case alu_op.opx is
      when "000" =>
        if cfg(Zbb) then
          -- XNOR, ORN, ANDN
          v_op_b := op_b xor alu_op.op(2);
        end if;
      when "001" =>
        if cfg(Zbs) then
          -- BSET (OR), BCLR (ANDN), BINV (XOR)
          v_op_b := (others => alu_op.op(2));
          for i in 0 to c_x_w/c_bx_w-1 loop
            if i = to_integer(unsigned(op_b(4 downto 3))) then
              -- Set/clear bit at index
              v_op_b(c_bx_w*i+to_integer(unsigned(op_b(2 downto 0)))) := not alu_op.op(2);
            end if;
          end loop;
        end if;
      when "010" =>
        if cfg(Zbb) then
          -- ORC (OR)
          for i in 0 to c_x_w/c_bx_w-1 loop
            v_op_b((i+1)*c_bx_w-1 downto i*c_bx_w) := (others => or op_a((i+1)*c_bx_w-1 downto i*c_bx_w));
          end loop;
        end if;
      when "011" =>
        if cfg(Zicond) then
          -- Zicond EQZ, NEZ (AND/ANDN)
          -- alu_op.op(2) = '0' EQZ => op_b = 0 => others => '1'
          -- alu_op.op(2) = '1' NEZ => op_b = 0 => others => '0'
          v_op_b := (others => (v_op_b_eqz xor alu_op.op(2)));
        end if;
      when "101" | "110" | "111" =>
        if cfg(Zbb) then
          -- SEXTB, ZEXTH, SEXTH (XOR)
          v_op_b := (others => '0');
          if alu_op.opx(1) = '1' then
            v_op_b(c_xhi downto c_hx_w) := op_a(c_xhi downto c_hx_w) xor (op_a(c_hxhi) and alu_op.opx(0));
          else
            v_op_b(c_xhi downto c_bx_w) := op_a(c_xhi downto c_bx_w) xor op_a(c_bxhi);
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

  function f_alu_misc(
    cfg     : t_riscv_isa_config;
    alu_op  : t_alu_opcode;
    op_a    : t_wordx;
    op_b    : t_wordx
  ) return t_wordx is
    variable v_mov    : t_wordx := op_b;
    variable v_zero   : std_logic := nor op_a;
    variable v_cbits  : std_logic_vector(f_log2(op_a'length) downto 0) := (others => '0');
    variable v_rev    : t_wordx;
    variable v_res    : t_wordx := (others => '0');
  begin
    if cfg(Zbb) and alu_op.op(1) = '1' then
      if alu_op.opx(0) = '1' then
        for i in 0 to c_x_w/c_bx_w-1 loop
          v_rev((i+1)*c_bx_w-1 downto i*c_bx_w) := f_reverse(op_a((i+1)*c_bx_w-1 downto i*c_bx_w));
        end loop;
      else
        v_rev := f_reverse(op_a, c_bx_w);
      end if;
    elsif cfg(Zbb) and alu_op.op(0) = '1' then
      if alu_op.opx(1) = '1' then
        v_cbits := f_alu_misc_cpop(op_a);
      else
        v_cbits := v_zero & (f_alu_misc_clz(f_reverse(op_a, 1, alu_op.opx(0) = '1')) and (not v_zero));
      end if;
    end if;

    if cfg(Zbb) and alu_op.op(1) = '1' then
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
    when c_alu_exe_math   => v_alu.res := v_math;
    when c_alu_exe_logic  => v_alu.res := v_logic;
    when c_alu_exe_shift  => v_alu.res := v_shift;
    when c_alu_exe_misc   => v_alu.res := v_misc;
    when others =>
    end case;

    v_alu.cmp := v_math(0);

    return v_alu;
  end function f_alu;

  function f_jmp_target(
    jmp_sel : t_jmp_select;
    pc      : t_wordx;
    rs1     : t_wordx;
    imm_j   : t_wordx;
    imm_b   : t_wordx;
    imm_i   : t_wordx
  ) return t_wordx is
    variable v_a   : unsigned(t_x_range);
    variable v_b   : unsigned(t_x_range);
  begin
    case jmp_sel is
    when jmp_jal =>
      v_a := unsigned(pc);
      v_b := unsigned(imm_j);
    when jmp_br =>
      v_a := unsigned(pc);
      v_b := unsigned(imm_b);
    when jmp_jalr =>
      v_a := unsigned(rs1);
      v_b := unsigned(imm_i);
    when others =>
    end case;
    return std_logic_vector(v_a + v_b);
  end function f_jmp_target;

  function f_reg_fw_select(
    reg_sel : t_reg_fw_select;
    rf      : t_wordx;
    rex     : t_wordx;
    rwb     : t_wordx
  ) return t_wordx is
    variable v_r  : t_wordx;
  begin
    case reg_sel is
    when reg_ex =>
      v_r := rex;
    when reg_wb =>
      v_r := rwb;
    when others =>
      v_r := rf;
    end case;
    return v_r;
  end function f_reg_fw_select;

  function f_imm_b_select(
    imm_sel     : t_imm_b_select;
    imm_i       : t_wordx;
    imm_s       : t_wordx;
    imm_u       : t_wordx;
    imm_csr     : t_wordx;
    imm_pc_incr : t_wordx
  ) return t_wordx is
    variable v_imm : t_wordx;
  begin
    case imm_sel is
    when imm_b_s =>
      v_imm := imm_s;
    when imm_b_u =>
      v_imm := imm_u;
    when imm_b_csr =>
      v_imm := imm_csr;
    when imm_b_pc_incr =>
      v_imm := imm_pc_incr;
    when others =>
      v_imm := imm_i;
    end case;
    return v_imm;
  end function f_imm_b_select;

  function f_op_a_select(
    op_a_sel  : t_op_a_select;
    rs1       : t_wordx;
    pc        : t_wordx;
    imm_csr   : t_wordx
  ) return t_wordx is
    variable v_op_a : t_wordx;
  begin
    case op_a_sel is
    when op_a_pc =>
      v_op_a := pc;
    when op_a_csr =>
      v_op_a := imm_csr;
    when others =>
      v_op_a := rs1;
    end case;
    return v_op_a;
  end function f_op_a_select;

  function f_op_b_select(
    op_b_sel  : t_op_b_select;
    rs2       : t_wordx;
    imm       : t_wordx
  ) return t_wordx is
    variable v_op_b : t_wordx;
  begin
    case op_b_sel is
    when op_b_imm =>
      v_op_b := imm;
    when others =>
      v_op_b := rs2;
    end case;
    return v_op_b;
  end function f_op_b_select;

  function f_op_c_select(
    op_c_sel  : t_op_c_select;
    rs2       : t_wordx;
    brt       : t_wordx
  ) return t_wordx is
    variable v_op_c : t_wordx;
  begin
    case op_c_sel is
    when op_c_brt =>
      v_op_c := brt;
    when others =>
      v_op_c := rs2;
    end case;
    return v_op_c;
  end function f_op_c_select;

  function f_ex_select(
    ex_sel  : t_ex_select;
    alu     : t_wordx;
    csr     : t_wordx;
    mul     : t_wordx;
    div     : t_wordx
  ) return t_wordx is
    variable v_ex : t_wordx;
  begin
    case ex_sel is
    when ex_csr =>
      v_ex := csr;
    when ex_mul =>
      v_ex := mul;
    when ex_div =>
      v_ex := div;
    when others =>
      v_ex := alu;
    end case;
    return v_ex;
  end function f_ex_select;

  function f_wb_select(
    wb_sel  : t_wb_select;
    ex      : t_wordx;
    mem     : t_wordx
  ) return t_wordx is
    variable v_wb : t_wordx;
  begin
    case wb_sel is
    when wb_mem =>
      v_wb := ex;
    when others =>
      v_wb := mem;
    end case;
    return v_wb;
  end function f_wb_select;

  function f_inst_decode(
    cfg   : t_riscv_isa_config;
    inst : t_wordx
  ) return t_decoded_inst is
    variable v : t_decoded_inst := c_decoded_inst_illegal;
  begin
    v.f3      := f_f3(inst);
    v.illegal := '0';
    case f_opcode(inst) is
    when c_opcode_lui =>
      v.rf_we       := '1';
      v.imm_b_sel   := imm_b_u;
      v.op_b_sel    := op_b_imm;
      v.ex_sel      := ex_alu;
      v.wb_sel      := wb_ex;
      v.alu_en      := '1';
      v.alu_op      := c_alu_mov;


    when c_opcode_auipc =>
      v.rf_we       := '1';
      v.imm_b_sel   := imm_b_u;
      v.op_a_sel    := op_a_pc;
      v.op_b_sel    := op_b_imm;
      v.ex_sel      := ex_alu;
      v.wb_sel      := wb_ex;
      v.alu_en      := '1';
      v.alu_op      := c_alu_add;


    when c_opcode_jal =>
      v.rf_we       := '1';
      v.imm_b_sel   := imm_b_pc_incr;
      v.op_a_sel    := op_a_pc;
      v.op_b_sel    := op_b_imm;
      v.jmp_sel     := jmp_jal;
      v.ex_sel      := ex_alu;
      v.wb_sel      := wb_ex;
      v.alu_en      := '1';
      v.alu_op      := c_alu_add;


    when c_opcode_jalr =>
      if f_f3(inst) = "000" then
        v.rf_re(0)    := '1';
        v.rf_we       := '1';
        v.imm_b_sel   := imm_b_pc_incr;
        v.op_a_sel    := op_a_pc;
        v.op_b_sel    := op_b_imm;
        v.jmp_sel     := jmp_jalr;
        v.ex_sel      := ex_alu;
        v.wb_sel      := wb_ex;
        v.alu_en      := '1';
        v.alu_op      := c_alu_add;
      else
        v := c_decoded_inst_illegal;
      end if;


    when c_opcode_branch =>
      v.rf_re     := "11";
      v.imm_b_sel := imm_b_i;
      v.op_a_sel  := op_a_rs1;
      v.op_b_sel  := op_b_rs2;
      v.op_c_sel  := op_c_brt;
      v.jmp_sel   := jmp_br;
      v.br_en     := '1';
      if inst(c_f3_inst_hi) = '0' then
        v.alu_op := c_alu_eq;
      else
        v.alu_op := c_alu_sltu;
        v.alu_op.opx(0) := not inst(c_f3_inst_hi-1);
      end if;
      if f_f3(inst) = "010" or f_f3(inst) = "011" then
        v := c_decoded_inst_illegal;
      end if;


    when c_opcode_load =>
      v.rf_re(0)  := '1';
      v.rf_we     := '1';
      v.imm_b_sel := imm_b_s;
      v.op_a_sel  := op_a_rs1;
      v.op_b_sel  := op_b_imm;
      v.ex_sel    := ex_alu;
      v.wb_sel    := wb_mem;
      v.lsu_en    := '1';
      v.lsu_ctrl.we   := '0';
      v.lsu_ctrl.sz   := inst(c_f3_inst_hi-1 downto c_f3_inst_lo);
      v.lsu_ctrl.sext := not inst(c_f3_inst_hi);
      case f_f3(inst) is
      when "011" | "110" | "111" =>
        v := c_decoded_inst_illegal;
      when others =>
      end case;


    when c_opcode_store =>
      v.rf_re     := "11";
      v.imm_b_sel := imm_b_s;
      v.op_a_sel  := op_a_rs1;
      v.op_b_sel  := op_b_imm;
      v.op_c_sel  := op_c_rs2;
      v.lsu_en    := '1';
      v.lsu_ctrl.we   := '1';
      v.lsu_ctrl.sz   := inst(c_f3_inst_hi-1 downto c_f3_inst_lo);
      v.lsu_ctrl.sext := '0';
      if inst(c_f3_inst_hi) = '1' or inst(c_f3_inst_hi-1 downto c_f3_inst_lo) = "11" then
        v := c_decoded_inst_illegal;
      end if;


    when c_opcode_amo =>
      if f_f3(inst) = c_f3_a_amow then
        v.rf_re         := "11";
        v.rf_we         := '1';
        v.imm_b_sel     := imm_b_s;
        v.op_a_sel      := op_a_rs1;
        v.op_b_sel      := op_b_imm;
        v.op_c_sel      := op_c_rs2;
        v.ex_sel        := ex_alu;
        v.wb_sel        := wb_mem;
        v.lsu_ctrl.we   := '1';
        v.lsu_ctrl.sz   := "10";
        v.lsu_ctrl.sext := '0';
        v.lsu_ctrl.amo  := '1' & f_f5(inst);
        if f_f5(inst) = c_f5_a_lr then
          if f_rs2(inst) = c_rfaddr_x0 then
            v.rf_re(1)    := '0';
            v.lsu_ctrl.we := '0';
          else
            v := c_decoded_inst_illegal;
          end if;
        end if;
        if cfg(A) then
          case f_f5(inst) is
          when c_f5_a_lr =>
          when c_f5_a_sc =>
          when c_f5_a_amoswap =>
          when c_f5_a_amoadd =>
          when c_f5_a_amoxor =>
          when c_f5_a_amoand =>
          when c_f5_a_amoor =>
          when c_f5_a_amomin =>
          when c_f5_a_amomax =>
          when c_f5_a_amominu =>
          when c_f5_a_amomaxu =>
          when others =>
            v := c_decoded_inst_illegal;
          end case;
        elsif cfg(Zalrsc) then
          case f_f5(inst) is
          when c_f5_a_lr =>
          when c_f5_a_sc =>
          when others =>
            v := c_decoded_inst_illegal;
          end case;
        else
          v := c_decoded_inst_illegal;
        end if;
      else
        v := c_decoded_inst_illegal;
      end if;


    when c_opcode_op_imm =>
      v.rf_re(0)  := '1';
      v.rf_we     := '1';
      v.imm_b_sel := imm_b_i;
      v.op_a_sel  := op_a_rs1;
      v.op_b_sel  := op_b_imm;
      v.ex_sel    := ex_alu;
      v.wb_sel    := wb_ex;
      v.alu_en    := '1';
      case? (f_f12(inst) & f_f3(inst)) is
      when (c_f12_b_clz & c_f3_op_b_clz) =>
        if cfg(B) or cfg(Zbb) then
          v.alu_op := c_alu_clz;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f12_b_ctz & c_f3_op_b_ctz) =>
        if cfg(B) or cfg(Zbb) then
          v.alu_op := c_alu_ctz;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f12_b_cpop & c_f3_op_b_cpop) =>
        if cfg(B) or cfg(Zbb) then
          v.alu_op := c_alu_cpop;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f12_b_orc & c_f3_op_b_orc) =>
        if cfg(B) or cfg(Zbb) then
          v.alu_op := c_alu_cpop;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f12_b_rev & c_f3_op_b_rev) =>
        if cfg(B) or cfg(Zbb) then
          v.alu_op := c_alu_rev8;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f12_b_sextb & c_f3_op_b_sext) =>
        if cfg(B) or cfg(Zbb) then
          v.alu_op := c_alu_sextb;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f12_b_sexth & c_f3_op_b_sext) =>
        if cfg(B) or cfg(Zbb) then
          v.alu_op := c_alu_sexth;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f7_null & "-----" & c_f3_op_sll) =>
        v.alu_op := c_alu_sll;
      when (c_f7_null & "-----" & c_f3_op_srl) =>
        v.alu_op := c_alu_srl;
      when (c_f7_sext_or_sub & "-----" & c_f3_op_sra) =>
        v.alu_op := c_alu_sra;
      when (c_f7_b_rol_ror & "-----" & c_f3_op_b_ror) =>
        if cfg(B) or cfg(Zbb) then
          v.alu_op := c_alu_ror;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f7_b_bclr_bext & "-----" & c_f3_op_b_bclr) =>
        if cfg(B) or cfg(Zbs) then
          v.alu_op := c_alu_bclr;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f7_b_bclr_bext & "-----" & c_f3_op_b_bext) =>
        if cfg(B) or cfg(Zbs) then
          v.alu_op := c_alu_bext;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f7_b_binv & "-----" & c_f3_op_b_binv) =>
        if cfg(B) or cfg(Zbs) then
          v.alu_op := c_alu_binv;
        else
          v := c_decoded_inst_illegal;
        end if;
      when (c_f7_b_bset & "-----" & c_f3_op_b_bset) =>
        if cfg(B) or cfg(Zbs) then
          v.alu_op := c_alu_bset;
        else
          v := c_decoded_inst_illegal;
        end if;
      when ("------------" & c_f3_op_add) =>
        v.alu_op := c_alu_add;
      when ("------------" & c_f3_op_slt) =>
        v.alu_op := c_alu_slt;
      when ("------------" & c_f3_op_sltu) =>
      v.alu_op := c_alu_sltu;
      when ("------------" & c_f3_op_xor) =>
        v.alu_op := c_alu_xor;
      when ("------------" & c_f3_op_or) =>
        v.alu_op := c_alu_or;
      when ("------------" & c_f3_op_and) =>
        v.alu_op := c_alu_and;
      when others =>
        v := c_decoded_inst_illegal;
      end case?;


    when c_opcode_op =>
      v.rf_re     := "11";
      v.rf_we     := '1';
      v.op_a_sel  := op_a_rs1;
      v.op_b_sel  := op_b_rs2;
      v.wb_sel    := wb_ex;
      case f_f7(inst) is
      when c_f7_null =>
        case f_f3(inst) is
        when c_f3_op_add =>
          v.alu_op := c_alu_add;
        when c_f3_op_slt =>
          v.alu_op := c_alu_slt;
        when c_f3_op_sltu =>
          v.alu_op := c_alu_sltu;
        when c_f3_op_sll =>
          v.alu_op := c_alu_sll;
        when c_f3_op_srl =>
          v.alu_op := c_alu_srl;
        when c_f3_op_xor =>
          v.alu_op := c_alu_xor;
        when c_f3_op_or =>
          v.alu_op := c_alu_or;
        when c_f3_op_and =>
          v.alu_op := c_alu_and;
        when others =>
          v := c_decoded_inst_illegal;
        end case;
      when c_f7_sext_or_sub =>
        case f_f3(inst) is
        when c_f3_op_add =>
          v.alu_op := c_alu_sub;
        when c_f3_op_srl =>
          v.alu_op := c_alu_sra;
        when c_f3_op_xor =>
          if cfg(B) or cfg(Zbb) then
            v.alu_op := c_alu_xnor;
          else
            v := c_decoded_inst_illegal;
          end if;
        when c_f3_op_or =>
          if cfg(B) or cfg(Zbb) then
            v.alu_op := c_alu_orn;
          else
            v := c_decoded_inst_illegal;
          end if;
        when c_f3_op_and =>
          if cfg(B) or cfg(Zbb) then
            v.alu_op := c_alu_andn;
          else
            v := c_decoded_inst_illegal;
          end if;
        when others =>
          v := c_decoded_inst_illegal;
        end case;
      when c_f7_m_muldiv =>
        if inst(c_f3_inst_hi) = '1' then
          if cfg(M) then
            v.div_en            := '1';
            v.ex_sel            := ex_div;
            v.muldiv_ctrl.mode  := inst(c_f3_inst_hi-1);
            v.muldiv_ctrl.signa := not inst(c_f3_inst_lo);
            v.muldiv_ctrl.signb := not inst(c_f3_inst_lo);
          else
            v := c_decoded_inst_illegal;
          end if;
        else
          if cfg(M) or cfg(Zmmul) then
            v.mul_en := '1';
            v.ex_sel := ex_mul;
            case inst(c_f3_inst_hi-1 downto c_f3_inst_lo) is
            when c_f3_op_m_mul(1 downto 0) =>
              v.muldiv_ctrl := c_muldiv_mul;
            when c_f3_op_m_mulh(1 downto 0) =>
              v.muldiv_ctrl := c_muldiv_mulh;
            when c_f3_op_m_mulsu(1 downto 0) =>
              v.muldiv_ctrl := c_muldiv_mulhsu;
            when c_f3_op_m_mulu(1 downto 0) =>
              v.muldiv_ctrl := c_muldiv_mulhu;
            when others =>
            end case;
          else
            v := c_decoded_inst_illegal;
          end if;
        end if;
      when c_f7_b_shadd =>
        if cfg(B) or cfg(Zba) then
          case f_f3(inst) is
          when c_f3_op_b_sh1add =>
            v.alu_op := c_alu_sh1add;
          when c_f3_op_b_sh2add =>
            v.alu_op := c_alu_sh2add;
          when c_f3_op_b_sh3add =>
            v.alu_op := c_alu_sh3add;
          when others =>
            v := c_decoded_inst_illegal;
          end case;
        else
          v := c_decoded_inst_illegal;
        end if;
      when c_f7_b_minmax_clmul =>
        if (cfg(B) or cfg(Zbb)) and inst(c_f3_inst_hi) = '1' then
          case inst(c_f3_inst_hi-1 downto c_f3_inst_lo) is
          when c_f3_op_b_min(1 downto 0) =>
            v.alu_op := c_alu_min;
          when c_f3_op_b_minu(1 downto 0) =>
            v.alu_op := c_alu_minu;
          when c_f3_op_b_max(1 downto 0) =>
            v.alu_op := c_alu_max;
          when c_f3_op_b_maxu(1 downto 0) =>
            v.alu_op := c_alu_maxu;
          when others =>
            v := c_decoded_inst_illegal;
          end case;
        -- elsif (cfg(B) or cfg(Zbc)) and inst(c_f3_inst_hi) = '0'
        --   case inst(c_f3_inst_hi-1 downto c_f3_inst_lo) is
        --   when c_f3_op_b_clmul(1 downto 0) =>
        --   when c_f3_op_b_clmulr(1 downto 0) =>
        --   when c_f3_op_b_clmulh(1 downto 0) =>
        --   when others =>
        --     v := c_decoded_inst_illegal;
        --   end case;
        else
          v := c_decoded_inst_illegal;
        end if;
      when c_f7_b_rol_ror =>
        if cfg(B) or cfg(Zbb) then
          case f_f3(inst) is
          when c_f3_op_b_rol =>
            v.alu_op := c_alu_rol;
          when c_f3_op_b_ror =>
            v.alu_op := c_alu_ror;
          when others =>
            v := c_decoded_inst_illegal;
          end case;
        else
          v := c_decoded_inst_illegal;
        end if;
      when c_f7_b_bclr_bext =>
        if (cfg(B) or cfg(Zbb)) and f_f3(inst) = c_f3_op_b_bext then
          v.alu_op := c_alu_bext;
        else
          v := c_decoded_inst_illegal;
        end if;
      when c_f7_b_binv =>
        if (cfg(B) or cfg(Zbb)) and f_f3(inst) = c_f3_op_b_binv then
          v.alu_op := c_alu_binv;
        else
          v := c_decoded_inst_illegal;
        end if;
      when c_f7_b_bset =>
        if (cfg(B) or cfg(Zbb)) and f_f3(inst) = c_f3_op_b_bset then
          v.alu_op := c_alu_bset;
        else
          v := c_decoded_inst_illegal;
        end if;
      when c_f12_b_zexth(11 downto 5) =>
        if (cfg(B) or cfg(Zbb)) and f_rs2(inst) = "00000" and f_f3(inst) = c_f3_op_b_zext then
          v.alu_op := c_alu_zexth;
        else
          v := c_decoded_inst_illegal;
        end if;
      when c_f7_czero =>
        if cfg(Zicond) then
          case f_f3(inst) is
          when c_f3_op_czero_eqz =>
            v.alu_op := c_alu_czeroeqz;
          when c_f3_op_czero_nez =>
            v.alu_op := c_alu_czeronez;
          when others =>
            v := c_decoded_inst_illegal;
          end case;
        else
          v := c_decoded_inst_illegal;
        end if;
      when others =>
        v := c_decoded_inst_illegal;
      end case;


    when c_opcode_fence =>
      v.sys_en := '1';
      case f_f3(inst) is
      when c_f3_miscmem_fence =>
        v.sys_fence := '1';
      when c_f3_miscmem_fencei =>
        v.sys_fencei := '1';
      when others =>
        v := c_decoded_inst_illegal;
      end case;


    when c_opcode_system =>
      if f_f3(inst) = "000" then
        if f_rs1(inst) = c_rfaddr_x0 and f_rd(inst) = c_rfaddr_x0 then
          v.sys_en := '1';
          case f_f12(inst) is
          when c_f12_system_ecall =>
            v.sys_ecall := '1';
          when c_f12_system_ebreak =>
            v.sys_ebreak := '1';
          when c_f12_system_mret =>
            v.sys_mret := '1';
          when c_f12_system_dret =>
            v.sys_dret := '1';
          when c_f12_system_wfi =>
            v.sys_wfi := '1';
          when others =>
            v := c_decoded_inst_illegal;
          end case;
        else
          v := c_decoded_inst_illegal;
        end if;
      else
        v.rf_we   := '1';
        v.csr_en  := '1';
        if inst(c_f3_inst_hi) = '1' then
          v.op_a_sel := op_a_csr;
        else
          v.op_a_sel := op_a_rs1;
          v.rf_re(0) := '1';
        end if;
        v.op_b_sel  := op_b_imm;

        v.imm_b_sel := imm_b_i;

        v.ex_sel    := ex_csr;
        v.wb_sel    := wb_ex;

        case inst(c_f3_inst_hi-1 downto c_f3_inst_lo) is
        when c_csr_op_rw =>
          v.csr_op := c_csr_op_rw;
        when c_csr_op_rs =>
          if f_rs1(inst) = c_rfaddr_x0 then
            v.csr_op := c_csr_op_r;
          else
            v.csr_op := c_csr_op_rs;
          end if;
        when c_csr_op_rc =>
          if f_rs1(inst) = c_rfaddr_x0 then
            v.csr_op := c_csr_op_r;
          else
            v.csr_op := c_csr_op_rc;
          end if;
        when others =>
          v := c_decoded_inst_illegal;
        end case;
      end if;
    when others =>
      v.illegal := '1';
    end case;
    return v;
  end function;

  --
  --  PROCEDURES
  --

  procedure pr_extract_compressed(
    cfg           : in  t_riscv_isa_config;
    cinst         : in  t_wordx;
    inst          : out t_wordx;
    is_compressed : out std_logic;
    illegal       : out std_logic
  ) is
    variable v_inst       : t_wordx := (others => '0');
    variable v_compressed : std_logic := '1';
    variable v_illegal    : std_logic := '0';
  begin

    case cinst(1 downto 0) is
    when c_opcode_c0 => -- "00"
      case cinst(15 downto 13) is
      when "000" => -- C.ADDI4SPN
        v_inst := (
          31 downto 30  => '0',
          29 downto 26  => cinst(10 downto 7),
          25 downto 24  => cinst(12 downto 11),
          23            => cinst(5),
          22            => cinst(6),
          21 downto 20  => '0',
          19 downto 15  => "00010",
          14 downto 12  => c_f3_op_add,
          11 downto  7  => "01" & cinst(4 downto 2),
           6 downto  0  => c_opcode_op_imm
        );
        v_illegal := nor cinst(12 downto 5);
      when "010" => -- C.LW
        v_inst := (
          31 downto 27  => '0',
          26            => cinst(5),
          25 downto 23  => cinst(12 downto 10),
          22            => cinst(6),
          21 downto 20  => '0',
          19 downto 15  => "01" & cinst(9 downto 7),
          14 downto 12  => c_f3_ld_lw,
          11 downto  7  => "01" & cinst(4 downto 2),
           6 downto  0  => c_opcode_load
        );
      when "110" => -- C.SW
        v_inst := (
          31 downto 27  => '0',
          26            => cinst(5),
          25            => cinst(12),
          24 downto 20  => "01" & cinst(4 downto 2),
          19 downto 15  => "01" & cinst(9 downto 7),
          14 downto 12  => c_f3_st_sw,
          11 downto  7  => cinst(11 downto 10) & cinst(6) & "00",
           6 downto  0  => c_opcode_store
        );
      when others =>
        v_illegal := '1';
      end case;
    when c_opcode_c1 =>
      case cinst(15 downto 13) is
      when "000" => -- C.ADDI, C.NOP
        v_inst := (
          31 downto 25  => cinst(12),
          24 downto 20  => cinst(6 downto 2),
          19 downto 15  => cinst(11 downto 7),
          14 downto 12  => c_f3_op_add,
          11 downto  7  => cinst(11 downto 7),
           6 downto  0  => c_opcode_op_imm
        );
        v_illegal := nor cinst(12 downto 5);
      when "001" | "101" => -- C.JAL, C.J
        v_inst := (
          31            => cinst(12),
          30            => cinst(8),
          29 downto 28  => cinst(10 downto 9),
          27            => cinst(6),
          26            => cinst(7),
          25            => cinst(2),
          24            => cinst(11),
          23 downto 21  => cinst(5 downto 3),
          20 downto 12  => cinst(12),
          11 downto  7  => "0000" & not cinst(15),
           6 downto  0  => c_opcode_jal
        );
      when "010" => -- C.LI
        v_inst := (
          31 downto 25  => cinst(12),
          24 downto 20  => cinst(6 downto 2),
          19 downto 12  => '0',
          11 downto 7   => cinst(11 downto 7),
           6 downto  0  => c_opcode_op_imm
        );
      when "011" => -- C.LUI
        v_inst := (
          31 downto 17  => cinst(12),
          16 downto 12  => cinst(6 downto 2),
          11 downto  7  => cinst(11 downto 7),
           6 downto  0  => c_opcode_lui
        );
        if (cinst(12) & cinst(6 downto 2)) = 6x"00" then
          v_illegal := '1';
        elsif cinst(11 downto 7) = 5x"02" then
          -- C.ADDI16SP
          v_inst := (
            31 downto 29  => cinst(12),
            28 downto 27  => cinst(4 downto 3),
            26            => cinst(5),
            25            => cinst(2),
            24            => cinst(6),
            23 downto 20  => '0',
            19 downto 15  => "00010",
            14 downto 12  => c_f3_op_add,
            11 downto  7  => "00010",
             6 downto  0  => c_opcode_op_imm
          );
        end if;
      when "100" =>
        case cinst(11 downto 10) is
        when "00" | "01" => -- C.SRLI, C.SRAI
          v_inst := (
            31            => '0',
            30            => cinst(10),
            29 downto 25  => '0',
            24 downto 20  => cinst(6 downto 2),
            19 downto 15  => "01" & cinst(9 downto 7),
            14 downto 12  => c_f3_op_srl,
            11 downto  7  => "01" & cinst(9 downto 7),
             6 downto  0  => c_opcode_op_imm
          );
          v_illegal := cinst(12);
        when "10" => -- C.ANDI
          v_inst := (
            31 downto 25  => cinst(12),
            24 downto 20  => cinst(6 downto 2),
            19 downto 15  => "01" & cinst(9 downto 7),
            14 downto 12  => c_f3_op_and,
            11 downto  7  => "01"& cinst(9 downto 7),
             6 downto  0  => c_opcode_op_imm
          );
        when "11" =>
          case std_logic_vector'(cinst(12) & cinst(6 downto 5)) is
          when "000" => -- C.SUB
            v_inst := (
              31 downto 25  => c_f7_sext_or_sub,
              24 downto 20  => "01" & cinst(4 downto 2),
              19 downto 15  => "01" & cinst(9 downto 7),
              14 downto 12  => c_f3_op_xor,
              11 downto  7  => "01" & cinst(9 downto 7),
               6 downto  0  => c_opcode_op
            );
          when "001" => -- C.XOR
            v_inst := (
              31 downto 25  => c_f7_null,
              24 downto 20  => "01" & cinst(4 downto 2),
              19 downto 15  => "01" & cinst(9 downto 7),
              14 downto 12  => c_f3_op_xor,
              11 downto  7  => "01" & cinst(9 downto 7),
               6 downto  0  => c_opcode_op
            );
          when "010" => -- C.OR
            v_inst := (
              31 downto 25  => c_f7_null,
              24 downto 20  => "01" & cinst(4 downto 2),
              19 downto 15  => "01" & cinst(9 downto 7),
              14 downto 12  => c_f3_op_or,
              11 downto  7  => "01" & cinst(9 downto 7),
               6 downto  0  => c_opcode_op
            );
          when "011" => -- C.AND
            v_inst := (
              31 downto 25  => c_f7_null,
              24 downto 20  => "01" & cinst(4 downto 2),
              19 downto 15  => "01" & cinst(9 downto 7),
              14 downto 12  => c_f3_op_and,
              11 downto  7  => "01" & cinst(9 downto 7),
               6 downto  0  => c_opcode_op
            );
          when "110" =>
            if cfg(M) or cfg(Zmmul) then -- C.MUL
              v_inst := (
                31 downto 25  => c_f7_m_muldiv,
                24 downto 20  => "01" & cinst(4 downto 2),
                19 downto 15  => "01" & cinst(9 downto 7),
                14 downto 12  => c_f3_op_m_mul,
                11 downto  7  => "01" & cinst(9 downto 7),
                 6 downto  0  => c_opcode_op
              );
            else
              v_illegal := '1';
            end if;
          when "111" =>
            case cinst(4 downto 2) is
            when "000" => -- C.ZEXT.B -> ANDI 0xff
              v_inst := (
                31 downto 20  => x"0ff",
                19 downto 15  => "01" & cinst(9 downto 7),
                14 downto 12  => c_f3_op_and,
                11 downto  7  => "01" & cinst(9 downto 7),
                 6 downto  0  => c_opcode_op_imm
              );
            when "001" => -- C.SEXT.B -> SEXT.B
              if cfg(Zbb) then
                v_inst := (
                  31 downto 20  => c_f12_b_sextb,
                  19 downto 15  => "01" & cinst(9 downto 7),
                  14 downto 12  => c_f3_op_b_sext,
                  11 downto  7  => "01" & cinst(9 downto 7),
                   6 downto  0  => c_opcode_op_imm
                );
              else
                v_illegal := '1';
              end if;
            when "010" => -- C.ZEXT.H -> ZEXT.H
              if cfg(Zbb) then
                v_inst := (
                  31 downto 20  => c_f12_b_zexth,
                  19 downto 15  => "01" & cinst(9 downto 7),
                  14 downto 12  => c_f3_op_b_zext,
                  11 downto  7  => "01" & cinst(9 downto 7),
                   6 downto  0  => c_opcode_op_imm
                );
              else
                v_illegal := '1';
              end if;
            when "011" => -- C.SEXT.H -> SEXT.H
              if cfg(Zbb) then
                v_inst := (
                  31 downto 20  => c_f12_b_sexth,
                  19 downto 15  => "01" & cinst(9 downto 7),
                  14 downto 12  => c_f3_op_b_sext,
                  11 downto  7  => "01" & cinst(9 downto 7),
                   6 downto  0  => c_opcode_op_imm
                );
              else
                v_illegal := '1';
              end if;
            when "101" => --C.NOT -> XORI -1
              v_inst := (
                31 downto 20  => x"fff",
                19 downto 15  => "01" & cinst(9 downto 7),
                14 downto 12  => c_f3_op_xor,
                11 downto  7  => "01" & cinst(9 downto 7),
                 6 downto  0  => c_opcode_op_imm
              );
            when others =>
              v_illegal := '1';
            end case;
          when others =>
            v_illegal := '1';
          end case;
        when others =>
          v_illegal := '1';
        end case;
      when "110" | "111" => -- C.BEQZ, C.BNEZ
        v_inst := (
          31 downto 28  => cinst(12),
          27 downto 25  => cinst(6 downto 5) & cinst(2),
          24 downto 20  => '0',
          19 downto 15  => "01" & cinst(9 downto 7),
          14 downto 12  => "00" & cinst(13),
          11 downto  8  => cinst(11 downto 10) & cinst(4 downto 3),
           7            => cinst(12),
           6 downto  0  => c_opcode_branch
        );
      when others =>
        v_illegal := '1';
      end case;
    when c_opcode_c2 =>
      case cinst(15 downto 13) is
      when "000" => -- C.SLLI
        v_inst := (
          31 downto 25  => '0',
          24 downto 20  => cinst(6 downto 2),
          19 downto 15  => cinst(11 downto 7),
          14 downto 12  => c_f3_op_sll,
          11 downto  7  => cinst(11 downto 7),
           6 downto  0  => c_opcode_op_imm
        );
        v_illegal := cinst(12);
      when "010" => -- C.LWSP
        v_inst := (
          31 downto 28  => '0',
          27 downto 26  => cinst(3 downto 2),
          25            => cinst(12),
          24 downto 22  => cinst(6 downto 4),
          21 downto 20  => '0',
          19 downto 15  => "00010",
          14 downto 12  => c_f3_ld_lw,
          11 downto  7  => cinst(11 downto 7),
           6 downto  0  => c_opcode_load
        );
        v_illegal := nor cinst(11 downto 7);
      when "100" =>
        if cinst(12) = '0' then
          -- C.MV
          v_inst := (
            31 downto 25  => '0',
            24 downto 20  => cinst(6 downto 2),
            19 downto 15  => c_rfaddr_x0,
            14 downto 12  => c_f3_op_add,
            11 downto  7  => cinst(11 downto 7),
             6 downto  0  => c_opcode_op
          );
          if nor cinst(6 downto 2) then
            if cinst(11 downto 7) /= c_rfaddr_x0 then
              -- C.JR
              v_inst := (
                31 downto 20  => '0',
                19 downto 15  => cinst(11 downto 7),
                14 downto 12  => c_f3_jalr,
                11 downto  7  => '0',
                 6 downto  0  => c_opcode_jalr
              );
            else
              v_illegal := '1';
            end if;
          end if;
        else
          if nor cinst(6 downto 2) then
            if nor cinst(11 downto 7) then
              -- C.EBREAK
              v_inst := (
                31 downto 20  => c_f12_system_ebreak,
                19 downto 7   => '0',
                6  downto 0   => c_opcode_system
              );
            else
              -- C.JALR
              v_inst := (
                31 downto 20  => '0',
                19 downto 15  => cinst(11 downto 7),
                14 downto 12  => c_f3_jalr,
                11 downto  7  => "00001",
                 6 downto  0  => c_opcode_jalr
              );
            end if;
          else
            -- C.ADD
            v_inst := (
              31 downto 25  => c_f7_null,
              24 downto 20  => cinst(6 downto 2),
              19 downto 15  => cinst(11 downto 7),
              14 downto 12  => c_f3_op_add,
              11 downto  7  => cinst(11 downto 7),
               6 downto  0  => c_opcode_op
            );
          end if;
        end if;
      when "110" => -- C.SWSP
        v_inst := (
          31 downto 28  => '0',
          27 downto 26  => cinst(8 downto 7),
          25            => cinst(12),
          24 downto 20  => cinst(6 downto 2),
          19 downto 15  => "00010",
          14 downto 12  => c_f3_st_sw,
          11 downto  7  => cinst(11 downto 9) & "00",
           6 downto  0  => c_opcode_store
        );
      when others =>
        v_illegal := '1';
      end case;
    when others =>
      -- Not compressed
      v_inst       := cinst;
      v_compressed  := '1';
    end case;

    inst          := v_inst;
    is_compressed := v_compressed;
    illegal       := v_illegal;
  end procedure;

end package body riscvim_pkg;