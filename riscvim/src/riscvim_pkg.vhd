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
  constant c_xlen           : natural := 32;
  --! Highest index of register
  --!
  constant c_xhi            : natural := c_xlen - 1;
  --! Lowest index of register
  --!
  constant c_xlo            : natural := 0;
  --! Register range
  --!
  subtype t_xlen_range is natural range c_xhi downto c_xlo;
  --! Double register range
  --!
  subtype t_2xlen_range is natural range 2*c_xlen-1 downto c_xlo;
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

  constant c_opcode_w       : natural := 7;
  constant c_opcode_hi      : natural := 6;
  constant c_opcode_lo      : natural := 0;
  subtype t_opcode_range is natural range c_opcode_hi downto c_opcode_lo;
  constant c_opcode_inst_hi : natural := 6;
  constant c_opcode_inst_lo : natural := 0;
  subtype t_opcode_inst_range is natural range c_opcode_inst_hi downto c_opcode_inst_lo;

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


  -- RV32I base instruction set                                                 Type  PC  IMM R2 R1  RS EX          OP  OPA OPA OPC
  constant c_opcode_lui     : std_logic_vector(t_opcode_range) := "0110111";  --  U           X         ALU         MOV 0   IMM -
  constant c_opcode_auipc   : std_logic_vector(t_opcode_range) := "0010111";  --  U      X    X         ALU         ADD PC  IMM -
  constant c_opcode_jal     : std_logic_vector(t_opcode_range) := "1101111";  --  J      X    X         PC next     ADD PC  IMM -
  constant c_opcode_branch  : std_logic_vector(t_opcode_range) := "1100011";  --  B      X    X  X   X  -           ADD R1  R2  PC+IMM
  constant c_opcode_jalr    : std_logic_vector(t_opcode_range) := "1100111";  --  I      X    X      X  PC next     ADD R1  IMM -
  constant c_opcode_load    : std_logic_vector(t_opcode_range) := "0000011";  --  I           X      X  LSU         ADD R1  IMM -
  constant c_opcode_op_imm  : std_logic_vector(t_opcode_range) := "0010011";  --  I           X      X  ALU         ANY R1  IMM -
  constant c_opcode_fence   : std_logic_vector(t_opcode_range) := "0001111";  --  I           ?      ?  ?           ?   ?   ?   -
  constant c_opcode_system  : std_logic_vector(t_opcode_range) := "1110011";  --  I           X      X  CSR         CSR R1  IMM -
  constant c_opcode_store   : std_logic_vector(t_opcode_range) := "0100011";  --  S           X  X   X  LSU         ADD R1  IMM R2
  constant c_opcode_op      : std_logic_vector(t_opcode_range) := "0110011";  --  R              X   X  MULDIV      ANY R1  R2  -

  -- RV32C compressed instruction set
  constant c_opcode_c0      : std_logic_vector(1 downto 0) := "00";
  constant c_opcode_c1      : std_logic_vector(1 downto 0) := "01";
  constant c_opcode_c2      : std_logic_vector(1 downto 0) := "10";

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
  constant c_f3_op_sub      : std_logic_vector(t_f3_range) := "000";  -- Negate OpB
  constant c_f3_op_sll      : std_logic_vector(t_f3_range) := "001";  -- Bit-reverse OpA and result
  constant c_f3_op_slt      : std_logic_vector(t_f3_range) := "010";  -- Signed compare
  constant c_f3_op_sltu     : std_logic_vector(t_f3_range) := "011";  -- Unsigned compare
  constant c_f3_op_xor      : std_logic_vector(t_f3_range) := "100";
  constant c_f3_op_srl      : std_logic_vector(t_f3_range) := "101";
  constant c_f3_op_sra      : std_logic_vector(t_f3_range) := "101";  -- Sign extend shift
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

--
--  ALU OPERATION CODES
--
  subtype t_alu_op_range is natural range 4 downto 0;

  -- Addition
  constant c_alu_op_add         : std_logic_vector(t_alu_op_range) := "00000";
  constant c_alu_op_sub         : std_logic_vector(t_alu_op_range) := "01000";  -- 3 => negate op_b
  -- Bitwise
  constant c_alu_op_xor         : std_logic_vector(t_alu_op_range) := "00100";
  constant c_alu_op_or          : std_logic_vector(t_alu_op_range) := "00110";
  constant c_alu_op_and         : std_logic_vector(t_alu_op_range) := "00111";
  -- Shifter
  constant c_alu_op_sll         : std_logic_vector(t_alu_op_range) := "00001";  -- 2 => bit reverse when '0'
  constant c_alu_op_srl         : std_logic_vector(t_alu_op_range) := "00101";
  constant c_alu_op_sra         : std_logic_vector(t_alu_op_range) := "01101";  -- 3 => sign extend
  -- Compare
  constant c_alu_op_eq          : std_logic_vector(t_alu_op_range) := "10000";  -- 4 => cmp
  constant c_alu_op_ne          : std_logic_vector(t_alu_op_range) := "10001";  -- 4 => cmp
  constant c_alu_op_slt         : std_logic_vector(t_alu_op_range) := "11010";  -- 4 => cmp, 3 => sign extend
  constant c_alu_op_sltu        : std_logic_vector(t_alu_op_range) := "10011";  -- 4 => cmp
  constant c_alu_op_lt          : std_logic_vector(t_alu_op_range) := "11100";  -- 4 => cmp, 3 => sign extend
  constant c_alu_op_ge          : std_logic_vector(t_alu_op_range) := "11101";  -- 4 => cmp, 3 => sign extend
  constant c_alu_op_ltu         : std_logic_vector(t_alu_op_range) := "10110";  -- 4 => cmp
  constant c_alu_op_geu         : std_logic_vector(t_alu_op_range) := "10111";  -- 4 => cmp

  --
  --  MUL/DIV OPERATION CODES
  --
  constant c_mul_op_mul         : std_logic := '0';
  constant c_mul_op_mulh        : std_logic := '1';
  constant c_div_op_div         : std_logic := '0';
  constant c_div_op_rem         : std_logic := '1';

--
--  CONTROL & STATUS REGISTER (CSR)
--

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

--
--  FUNCTIONS
--

  function f_log2(n : positive) return natural;
  function f_log2nz(n : positive) return natural;
  function f_ceil_div(n : natural; d : positive) return natural;
  function f_reverse(v : std_logic_vector; size : positive := 1; reverse : boolean := true) return std_logic_vector;

end package riscvim_pkg;

package body riscvim_pkg is

  function f_log2(n : positive) return natural is
  begin
    return integer(ceil(log2(real(n))));
  end function f_log2;

  function f_log2nz(n : positive) return natural is
  begin
    return maximum(1, f_log2(n));
  end function f_log2nz;

  function f_ceil_div(n, m : integer) return natural is
  begin
    return integer(ceil(real(n)/real(m)));
  end function f_ceil_div;

  function f_reverse(reverse : boolean; v : std_logic_vector; size : natural) return std_logic_vector is
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

end package body riscvim_pkg;