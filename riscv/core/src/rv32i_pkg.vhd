--! @defgroup   RV32I_PKG rv 32 i package
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

library lib_common;
use lib_common.common_pkg.all;

--! RISC V functions and types package
--!
package rv32i_pkg is

  --! Register width (and number of registers)
  --!
  constant c_xlen           : natural := 32;
  --! Highest index of register
  --!
  constant c_xlen_hi        : natural := c_xlen - 1;
  --! Lowest index of register
  --!
  constant c_xlen_lo        : natural := 0;
  --! Register range
  --!
  subtype t_xlen_range is natural range c_xlen_hi downto c_xlen_lo;
  --! Double register range
  --!
  subtype t_2xlen_range is natural range 2*c_xlen-1 downto c_xlen_lo;
  --! Width of register select
  --!
  constant c_rsel_w         : natural := 5;
  constant c_rsel_hi        : natural := 4;
  constant c_rsel_lo        : natural := 0;
  subtype t_rsel_range is natural range c_rsel_hi downto c_rsel_lo;

  constant c_f7_w           : natural := 7;
  constant c_f7_hi          : natural := 6;
  constant c_f7_lo          : natural := 0;
  subtype t_f7_range is natural range c_f7_hi downto c_f7_lo;
  constant c_f7_inst_hi     : natural := 31;
  constant c_f7_inst_lo     : natural := 25;
  subtype t_f7_inst_range is natural range c_f7_inst_hi downto c_f7_inst_lo;

  constant c_f12_w          : natural := 12;
  constant c_f12_hi         : natural := 11;
  constant c_f12_lo         : natural := 0;
  subtype t_f12_range is natural range c_f12_hi downto c_f12_lo;
  constant c_f12_inst_hi    : natural := 31;
  constant c_f12_inst_lo    : natural := 20;
  subtype t_f12_inst_range is natural range c_f12_inst_hi downto c_f12_inst_lo;

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

  constant c_rd_hi          : natural := 11;
  constant c_rd_lo          : natural := 7;
  subtype t_rd_range is natural range c_rd_hi downto c_rd_lo;

  constant c_opcode_w       : natural := 5;
  constant c_opcode_hi      : natural := 4;
  constant c_opcode_lo      : natural := 0;
  subtype t_opcode_range is natural range c_opcode_hi downto c_opcode_lo;
  constant c_opcode_inst_hi : natural := 6;
  constant c_opcode_inst_lo : natural := 2;
  subtype t_opcode_inst_range is natural range c_opcode_inst_hi downto c_opcode_inst_lo;
  constant c_opcode_valid_hi : natural := 1;
  constant c_opcode_valid_lo : natural := 0;
  subtype t_opcode_valid_range is natural range c_opcode_valid_hi downto c_opcode_valid_lo;

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

  constant c_inst_valid_w   : natural := 2;
  constant c_inst_valid_hi  : natural := 1;
  constant c_inst_valid_lo  : natural := 0;

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

  constant c_inst_valid     : std_logic_vector(c_inst_valid_w - 1 downto 0) := "11";

  -- RV32I base instruction set                                                 Type  PC  IMM R2  R1  RS          OP  OP1 OP2
  constant c_opcode_lui     : std_logic_vector(t_opcode_range) := "01101";  --  U           X         ALU         MOV 0   IMM
  constant c_opcode_auipc   : std_logic_vector(t_opcode_range) := "00101";  --  U      X    X         ALU         ADD PC  IMM
  constant c_opcode_jal     : std_logic_vector(t_opcode_range) := "11011";  --  J      X    X         PC next     ADD PC  IMM
  constant c_opcode_branch  : std_logic_vector(t_opcode_range) := "11000";  --  B      X    X  X   X  -           ADD PC  IMM
  constant c_opcode_jalr    : std_logic_vector(t_opcode_range) := "11001";  --  I      X    X      X  PC next     ADD R1  IMM
  constant c_opcode_load    : std_logic_vector(t_opcode_range) := "00000";  --  I           X      X  MEM         ADD R1  IMM
  constant c_opcode_op_imm  : std_logic_vector(t_opcode_range) := "00100";  --  I           X      X  ALU         ANY R1  IMM
  constant c_opcode_fence   : std_logic_vector(t_opcode_range) := "00011";  --  I           ?      ?  ?           ?   ?   ?
  constant c_opcode_system  : std_logic_vector(t_opcode_range) := "11100";  --  I           X      X  CSR         CSR R1  IMM
  constant c_opcode_store   : std_logic_vector(t_opcode_range) := "01000";  --  S           X  X   X  -           ADD R1  R2
  constant c_opcode_op      : std_logic_vector(t_opcode_range) := "01100";  --  R              X   X  ALU/MULDIV  ANY R1  R2
  type t_opcode is (
    op_lui,
    op_jal,
    op_jalr,
    op_auipc,
    op_branch,
    op_load,
    op_store,
    op_op_imm,
    op_op,
    op_fence,
    op_system,
    op_unsupported
  );

  -- M extension
  constant c_opcode_mext    : std_logic_vector(t_opcode_range) := "01100";

  -- FUNCT3 flags
  --
  constant c_f3_jalr        : std_logic_vector(t_f3_range) := "000";

  constant c_f3_branch_beq  : std_logic_vector(t_f3_range) := "000";
  constant c_f3_branch_bne  : std_logic_vector(t_f3_range) := "001";
  constant c_f3_branch_blt  : std_logic_vector(t_f3_range) := "100";
  constant c_f3_branch_bge  : std_logic_vector(t_f3_range) := "101";
  constant c_f3_branch_bltu : std_logic_vector(t_f3_range) := "110";
  constant c_f3_branch_bgeu : std_logic_vector(t_f3_range) := "111";

  constant c_f3_load_lb     : std_logic_vector(t_f3_range) := "000";
  constant c_f3_load_lh     : std_logic_vector(t_f3_range) := "001";
  constant c_f3_load_lw     : std_logic_vector(t_f3_range) := "010";
  constant c_f3_load_lbu    : std_logic_vector(t_f3_range) := "100";
  constant c_f3_load_lhu    : std_logic_vector(t_f3_range) := "101";

  constant c_f3_store_sb    : std_logic_vector(t_f3_range) := "000";
  constant c_f3_store_sh    : std_logic_vector(t_f3_range) := "001";
  constant c_f3_store_sw    : std_logic_vector(t_f3_range) := "010";

  constant c_f3_opimm_addi  : std_logic_vector(t_f3_range) := "000";
  constant c_f3_opimm_slli  : std_logic_vector(t_f3_range) := "001";
  constant c_f3_opimm_slti  : std_logic_vector(t_f3_range) := "010";
  constant c_f3_opimm_sltiu : std_logic_vector(t_f3_range) := "011";
  constant c_f3_opimm_xori  : std_logic_vector(t_f3_range) := "100";
  constant c_f3_opimm_srli  : std_logic_vector(t_f3_range) := "101";
  constant c_f3_opimm_srai  : std_logic_vector(t_f3_range) := "101";
  constant c_f3_opimm_ori   : std_logic_vector(t_f3_range) := "110";
  constant c_f3_opimm_andi  : std_logic_vector(t_f3_range) := "111";

  constant c_f3_op_add      : std_logic_vector(t_f3_range) := "000";
  constant c_f3_op_sub      : std_logic_vector(t_f3_range) := "000";
  constant c_f3_op_sll      : std_logic_vector(t_f3_range) := "001";
  constant c_f3_op_slt      : std_logic_vector(t_f3_range) := "010";
  constant c_f3_op_sltu     : std_logic_vector(t_f3_range) := "011";
  constant c_f3_op_xor      : std_logic_vector(t_f3_range) := "100";
  constant c_f3_op_srl      : std_logic_vector(t_f3_range) := "101";
  constant c_f3_op_sra      : std_logic_vector(t_f3_range) := "101";
  constant c_f3_op_or       : std_logic_vector(t_f3_range) := "110";
  constant c_f3_op_and      : std_logic_vector(t_f3_range) := "111";

  constant c_f3_op_m_mul    : std_logic_vector(t_f3_range) := "000";
  constant c_f3_op_m_mulh   : std_logic_vector(t_f3_range) := "001";
  constant c_f3_op_m_mulhsu : std_logic_vector(t_f3_range) := "010";
  constant c_f3_op_m_mulhu  : std_logic_vector(t_f3_range) := "011";
  constant c_f3_op_m_div    : std_logic_vector(t_f3_range) := "100";
  constant c_f3_op_m_divu   : std_logic_vector(t_f3_range) := "101";
  constant c_f3_op_m_rem    : std_logic_vector(t_f3_range) := "110";
  constant c_f3_op_m_remu   : std_logic_vector(t_f3_range) := "111";

  constant c_f3_miscmem_fence   : std_logic_vector(t_f3_range) := "000";
  constant c_f3_miscmem_fencei  : std_logic_vector(t_f3_range) := "001";

  constant c_f3_system_ecall  : std_logic_vector(t_f3_range) := "000";
  constant c_f3_system_ebreak : std_logic_vector(t_f3_range) := "000";
  constant c_f3_system_csrrw  : std_logic_vector(t_f3_range) := "001";
  constant c_f3_system_csrrs  : std_logic_vector(t_f3_range) := "010";
  constant c_f3_system_csrrc  : std_logic_vector(t_f3_range) := "011";
  constant c_f3_system_csrrwi : std_logic_vector(t_f3_range) := "101";
  constant c_f3_system_csrrsi : std_logic_vector(t_f3_range) := "110";
  constant c_f3_system_csrrci : std_logic_vector(t_f3_range) := "111";
  constant c_f3_system_sret   : std_logic_vector(t_f3_range) := "000";
  constant c_f3_system_mret   : std_logic_vector(t_f3_range) := "000";
  constant c_f3_system_wfi    : std_logic_vector(t_f3_range) := "000";

  constant c_f7_sub_add_n_bit   : natural := 5;
  constant c_f7_sra_srl_n_bit   : natural := 5;

  constant c_f12_system_ecall   : std_logic_vector(t_f12_range) := x"000";
  constant c_f12_system_ebreak  : std_logic_vector(t_f12_range) := x"001";
  constant c_f12_system_sret    : std_logic_vector(t_f12_range) := x"102";
  constant c_f12_system_mret    : std_logic_vector(t_f12_range) := x"302";
  constant c_f12_system_wfi     : std_logic_vector(t_f12_range) := x"105";

-- RV32I ALU OPS
--  N : NAME    : CODE :
--  0 : ADD     : 0000 :
--  1 : SLL     : 0001 :
--  2 : SLT     : 0010 :
--  3 : SLTU    : 0011 :
--  4 : XOR     : 0100 :
--  5 : SRL     : 0101 :
--  6 : OR      : 0110 :
--  7 : AND     : 0111 :
--  8 : SUB     : 1000 :
--  9 : SRA     : 1101 :
--
-- RV32M MULDIV OPS
--  N : NAME    : CODE :
--  0 : MUL     : -000 :
--  1 : MULH    : -001 :
--  2 : MULHSU  : -010 :
--  3 : MULHU   : -011 :
--  4 : DIV     : -100 :
--  5 : DIVU    : -101 :
--  6 : REM     : -110 :
--  7 : REMU    : -111 :
  constant c_alu_op_w       : natural := 4;
  constant c_alu_op_hi      : natural := 3;
  constant c_alu_op_lo      : natural := 0;
  subtype t_alu_op_range is natural range c_alu_op_hi downto c_alu_op_lo;
  -- RV32I (f7[0] = '0') f7[5]:f3
  constant c_alu_op_add     : std_logic_vector(t_alu_op_range) := "0000";
  constant c_alu_op_sub     : std_logic_vector(t_alu_op_range) := "1000";
  constant c_alu_op_sll     : std_logic_vector(t_alu_op_range) := "0001";
  constant c_alu_op_slt     : std_logic_vector(t_alu_op_range) := "0010";
  constant c_alu_op_sltu    : std_logic_vector(t_alu_op_range) := "0011";
  constant c_alu_op_xor     : std_logic_vector(t_alu_op_range) := "0100";
  constant c_alu_op_srl     : std_logic_vector(t_alu_op_range) := "0101";
  constant c_alu_op_sra     : std_logic_vector(t_alu_op_range) := "1101";
  constant c_alu_op_or      : std_logic_vector(t_alu_op_range) := "0110";
  constant c_alu_op_and     : std_logic_vector(t_alu_op_range) := "0111";
  -- RV32M (f7[0] = '1') f7[5]:f3
  constant c_alu_op_mul     : std_logic_vector(t_alu_op_range) := "0000";
  constant c_alu_op_mulh    : std_logic_vector(t_alu_op_range) := "0001";
  constant c_alu_op_mulhsu  : std_logic_vector(t_alu_op_range) := "0010";
  constant c_alu_op_mulhu   : std_logic_vector(t_alu_op_range) := "0011";
  constant c_alu_op_div     : std_logic_vector(t_alu_op_range) := "0100";
  constant c_alu_op_divu    : std_logic_vector(t_alu_op_range) := "0101";
  constant c_alu_op_rem     : std_logic_vector(t_alu_op_range) := "0110";
  constant c_alu_op_remu    : std_logic_vector(t_alu_op_range) := "0111";

  -- Execute stage selection
  constant c_ex_sel_w       : natural := 2;
  constant c_ex_sel_hi      : natural := 1;
  constant c_ex_sel_lo      : natural := 0;
  subtype t_ex_sel_range is natural range c_ex_sel_hi downto c_ex_sel_lo;
  constant c_ex_sel_alu     : std_logic_vector(t_ex_sel_range) := "00";
  constant c_ex_sel_imm     : std_logic_vector(t_ex_sel_range) := "01";
  constant c_ex_sel_csr     : std_logic_vector(t_ex_sel_range) := "10";
  constant c_ex_sel_muldiv  : std_logic_vector(t_ex_sel_range) := "11";


  -- CSR OP f3(1:0)
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

  constant c_csr_addr_ucycle      : std_logic_vector(t_csr_addr_range) := x"C00";
  constant c_csr_addr_ucycleh     : std_logic_vector(t_csr_addr_range) := x"C80";
  constant c_csr_addr_utime       : std_logic_vector(t_csr_addr_range) := x"C01";
  constant c_csr_addr_utimeh      : std_logic_vector(t_csr_addr_range) := x"C81";
  constant c_csr_addr_uinstret    : std_logic_vector(t_csr_addr_range) := x"C02";
  constant c_csr_addr_uinstreth   : std_logic_vector(t_csr_addr_range) := x"C82";

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

  constant c_csr_addr_mvendorid     : std_logic_vector(t_csr_addr_range) := x"F11";
  constant c_csr_addr_marchid       : std_logic_vector(t_csr_addr_range) := x"F12";
  constant c_csr_addr_mimpid        : std_logic_vector(t_csr_addr_range) := x"F13";
  constant c_csr_addr_mhartid       : std_logic_vector(t_csr_addr_range) := x"F14";
  constant c_csr_addr_mconfigptr    : std_logic_vector(t_csr_addr_range) := x"F15";
  constant c_csr_addr_mstatus       : std_logic_vector(t_csr_addr_range) := x"300";
  constant c_csr_addr_mstatush      : std_logic_vector(t_csr_addr_range) := x"310";
  constant c_csr_addr_misa          : std_logic_vector(t_csr_addr_range) := x"301";
  constant c_csr_addr_medeleg       : std_logic_vector(t_csr_addr_range) := x"302";
  constant c_csr_addr_mideleg       : std_logic_vector(t_csr_addr_range) := x"303";
  constant c_csr_addr_mie           : std_logic_vector(t_csr_addr_range) := x"304";
  constant c_csr_addr_mtvec         : std_logic_vector(t_csr_addr_range) := x"305";
  constant c_csr_addr_mcounteren    : std_logic_vector(t_csr_addr_range) := x"306";
  constant c_csr_addr_mscratch      : std_logic_vector(t_csr_addr_range) := x"340";
  constant c_csr_addr_mepc          : std_logic_vector(t_csr_addr_range) := x"341";
  constant c_csr_addr_mcause        : std_logic_vector(t_csr_addr_range) := x"342";
  constant c_csr_addr_mtval         : std_logic_vector(t_csr_addr_range) := x"343";
  constant c_csr_addr_mip           : std_logic_vector(t_csr_addr_range) := x"344";
  constant c_csr_addr_mtinst        : std_logic_vector(t_csr_addr_range) := x"34A";
  constant c_csr_addr_mcycle        : std_logic_vector(t_csr_addr_range) := x"B00";
  constant c_csr_addr_mcycleh       : std_logic_vector(t_csr_addr_range) := x"B80";
  constant c_csr_addr_minstret      : std_logic_vector(t_csr_addr_range) := x"B02";
  constant c_csr_addr_minstreth     : std_logic_vector(t_csr_addr_range) := x"B82";
  constant c_csr_addr_mcountinhibit : std_logic_vector(t_csr_addr_range) := x"320";

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
--  0         16–23           Reserved
--  0         24–31           Designated for custom use
--  0         32–47           Reserved
--  0         48–63           Designated for custom use
--  0         ≥64             Reserved
  constant c_excp_inst_addr_misalign      : std_logic_vector(t_xlen_range) := x"00000000";
  constant c_excp_inst_access_fault       : std_logic_vector(t_xlen_range) := x"00000001";
  constant c_excp_inst_illegal            : std_logic_vector(t_xlen_range) := x"00000002";
  constant c_excp_inst_breakpoint         : std_logic_vector(t_xlen_range) := x"00000003";
  constant c_excp_load_addr_misalign      : std_logic_vector(t_xlen_range) := x"00000004";
  constant c_excp_load_access_fault       : std_logic_vector(t_xlen_range) := x"00000005";
  constant c_excp_store_amo_addr_misalign : std_logic_vector(t_xlen_range) := x"00000006";
  constant c_excp_store_amo_access_fault  : std_logic_vector(t_xlen_range) := x"00000007";
  constant c_excp_ecall_from_user         : std_logic_vector(t_xlen_range) := x"00000008";
  constant c_excp_ecall_from_supervisor   : std_logic_vector(t_xlen_range) := x"00000009";
  -- reserved                                                                 x"0000000A"
  constant c_excp_ecall_from_machine      : std_logic_vector(t_xlen_range) := x"0000000B";
  constant c_excp_inst_page_fault         : std_logic_vector(t_xlen_range) := x"0000000C";
  constant c_excp_load_page_fault         : std_logic_vector(t_xlen_range) := x"0000000D";
  -- reserved                                                                 x"0000000E"
  constant c_excp_store_amo_page_fault    : std_logic_vector(t_xlen_range) := x"0000000F";
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
--  1         12–15           Reserved
--  1         ≥16             Designated for platform use
  -- reserved user                                                            x"80000000"
  constant c_excp_sw_int_supervisor       : std_logic_vector(t_xlen_range) := x"80000001";
  -- reserved hypervisor                                                      x"80000002"
  constant c_excp_sw_int_machine          : std_logic_vector(t_xlen_range) := x"80000003";
  -- reserved user                                                            x"80000004"
  constant c_excp_tim_int_supervisor      : std_logic_vector(t_xlen_range) := x"80000005";
  -- reserved hypervisor                                                      x"80000006"
  constant c_excp_tim_int_machine         : std_logic_vector(t_xlen_range) := x"80000007";
  -- reserved user                                                            x"80000008"
  constant c_excp_ext_int_supervisor      : std_logic_vector(t_xlen_range) := x"80000009";
  -- reserved hypervisor                                                      x"8000000A"
  constant c_excp_ext_int_machine         : std_logic_vector(t_xlen_range) := x"8000000B";


  type t_ifetch2idecode is record
    instr   : std_logic_vector(t_xlen_range);
    pc      : std_logic_vector(t_xlen_range);
    pc_next : std_logic_vector(t_xlen_range);
  end record;

  type t_idecode2execute is record
    valid     : std_logic;
    opcode    : t_opcode;
    pc        : std_logic_vector(t_xlen_range);
    alu_op    : std_logic_vector(t_alu_op_range);
    op1_sel   : std_logic;                        -- r1, pc
    op2_sel   : std_logic;                        -- r2, imm
    jal       : std_logic;                        -- Jump enable
    br_op     : std_logic_vector(t_f3_range);     -- Branch compare operation
    br_en     : std_logic;                        -- Branch enable
    ecall     : std_logic;
    ebreak    : std_logic;
    mret      : std_logic;
    csr_op    : std_logic_vector(t_f3_range);
    csr_addr  : std_logic_vector(t_csr_addr_range);
    csr_we    : std_logic;
    rs1       : std_logic_vector(t_rsel_range);
    rs2       : std_logic_vector(t_rsel_range);
    ex_sel    : std_logic_vector(1 downto 0);     -- IMM, ALU, CSR or MULDIV
    r1        : std_logic_vector(t_xlen_range);   -- r1
    r2        : std_logic_vector(t_xlen_range);   -- r2
    imm       : std_logic_vector(t_xlen_range);
    mem_read  : std_logic;
    mem_write : std_logic;
    wb        : std_logic;
    wb_sel    : std_logic; -- MEM or EX result
    rd        : std_logic_vector(t_rsel_range);
  end record;

  type t_execute2mem is record
    valid     : std_logic;
    opcode    : t_opcode;
    pc        : std_logic_vector(t_xlen_range);
    pc_next   : std_logic_vector(t_xlen_range);
    jal       : std_logic;                        -- Jump enable
    r2        : std_logic_vector(t_xlen_range);
    imm       : std_logic_vector(t_xlen_range);
    ex_sel    : std_logic_vector(1 downto 0);     -- ALU, CSR or MULDIV
    ecall     : std_logic;
    ebreak    : std_logic;
    mret      : std_logic;
    mem_read  : std_logic;
    mem_write : std_logic;
    wb        : std_logic;
    wb_sel    : std_logic;
    rd        : std_logic_vector(t_rsel_range);
  end record;

  type t_mem2writeback is record
    opcode    : t_opcode;
    ex_res    : std_logic_vector(t_xlen_range);
    wb        : std_logic;
    wb_sel    : std_logic;
    rd        : std_logic_vector(t_rsel_range);
  end record;

  type t_rv32i_r_type is record
    funct7  : std_logic_vector(c_f7_w - 1 downto 0);
    rs2     : std_logic_vector(c_rsel_w - 1 downto 0);
    rs1     : std_logic_vector(c_rsel_w - 1 downto 0);
    funct3  : std_logic_vector(c_f3_w - 1 downto 0);
    rd      : std_logic_vector(c_rsel_w - 1 downto 0);
    opcode  : std_logic_vector(c_opcode_w - 1 downto 0);
    valid   : std_logic_vector(c_inst_valid_w - 1 downto 0);
  end record t_rv32i_r_type;

end package rv32i_pkg;

package body rv32i_pkg is

end package body rv32i_pkg;