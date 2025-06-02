
library ieee;
use ieee.std_logic_1164.all;

package riscv_pkg is

  constant C_XLEN : natural := 32;
  subtype t_wordx is std_logic_vector(C_XLEN-1 downto 0);

  -- Extension configuration

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

  -- Registers

  subtype t_reg_addr is std_logic_vector(4 downto 0);

  -- Register   ABI name  Description
  ----------------------------------------------------------------
  -- x0         zero      Hard-wired zero
  -- x1         ra        Return address                    Caller
  -- x2         sp        Stack pointer                     Callee
  -- x3         gp        Global pointer
  -- x4         tp        Thread pointer
  -- x5–7       t0–2      Temporaries                       Caller
  -- x8         s0/fp     Saved register/frame pointer      Callee
  -- x9         s1        Saved register                    Callee
  -- x10–11     a0–1      Function arguments/return values  Caller
  -- x12–17     a2–7      Function arguments                Caller
  -- x18–27     s2–11     Saved registers                   Callee
  -- x28–31     t3–6      Temporaries                       Caller
  constant C_GPR_ZERO : t_reg_addr := "00000";
  constant C_GPR_RA   : t_reg_addr := "00001";
  constant C_GPR_SP   : t_reg_addr := "00010";
  constant C_GPR_GP   : t_reg_addr := "00011";
  constant C_GPR_TP   : t_reg_addr := "00100";
  constant C_GPR_T0   : t_reg_addr := "00101";
  constant C_GPR_T1   : t_reg_addr := "00110";
  constant C_GPR_T2   : t_reg_addr := "00111";
  constant C_GPR_FP   : t_reg_addr := "01000";
  constant C_GPR_S1   : t_reg_addr := "01001";
  constant C_GPR_A0   : t_reg_addr := "01010";
  constant C_GPR_A1   : t_reg_addr := "01011";
  constant C_GPR_A2   : t_reg_addr := "01100";
  constant C_GPR_A3   : t_reg_addr := "01101";
  constant C_GPR_A4   : t_reg_addr := "01110";
  constant C_GPR_A5   : t_reg_addr := "01111";
  constant C_GPR_A6   : t_reg_addr := "10000";
  constant C_GPR_A7   : t_reg_addr := "10001";
  constant C_GPR_S2   : t_reg_addr := "10010";
  constant C_GPR_S3   : t_reg_addr := "10011";
  constant C_GPR_S4   : t_reg_addr := "10100";
  constant C_GPR_S5   : t_reg_addr := "10101";
  constant C_GPR_S6   : t_reg_addr := "10110";
  constant C_GPR_S7   : t_reg_addr := "10111";
  constant C_GPR_S8   : t_reg_addr := "11000";
  constant C_GPR_S9   : t_reg_addr := "11001";
  constant C_GPR_S10  : t_reg_addr := "11010";
  constant C_GPR_S11  : t_reg_addr := "11011";
  constant C_GPR_T3   : t_reg_addr := "11100";
  constant C_GPR_T4   : t_reg_addr := "11101";
  constant C_GPR_T5   : t_reg_addr := "11110";
  constant C_GPR_T6   : t_reg_addr := "11111";

  -- Opcodes

  subtype t_opcode is std_logic_vector(6 downto 0);

  -- I

  constant C_OP_LUI     : t_opcode := "0110111";  -- U
  constant C_OP_AUIPC   : t_opcode := "0010111";  -- U
  constant C_OP_JAL     : t_opcode := "1101111";  -- J
  constant C_OP_BRANCH  : t_opcode := "1100011";  -- B
  constant C_OP_JALR    : t_opcode := "1100111";  -- I
  constant C_OP_LOAD    : t_opcode := "0000011";  -- I
  constant C_OP_IMM     : t_opcode := "0010011";  -- I
  constant C_OP_FENCE   : t_opcode := "0001111";  -- I
  constant C_OP_SYSTEM  : t_opcode := "1110011";  -- I
  constant C_OP_STORE   : t_opcode := "0100011";  -- S
  constant C_OP_REG     : t_opcode := "0110011";  -- R

  -- A

  constant C_OP_AMO     : t_opcode := "0101111";  -- S

  -- FUNCT3

  subtype t_f3 is std_logic_vector(2 downto 0);

  -- I

  -- JALR
  constant C_F3_I_JALR      : t_f3 := "000";

  -- Load
  constant C_F3_I_LB        : t_f3 := "000";
  constant C_F3_I_LH        : t_f3 := "001";
  constant C_F3_I_LW        : t_f3 := "010";
  constant C_F3_I_LBU       : t_f3 := "100";
  constant C_F3_I_LHU       : t_f3 := "101";

  -- OP Imm
  constant C_F3_I_ADDI      : t_f3 := "000";
  constant C_F3_I_SLLI      : t_f3 := "001";
  constant C_F3_I_SLTI      : t_f3 := "010";
  constant C_F3_I_SLTIU     : t_f3 := "011";
  constant C_F3_I_SRLI      : t_f3 := "101";
  constant C_F3_I_SRAI      : t_f3 := "101";
  constant C_F3_I_XORI      : t_f3 := "100";
  constant C_F3_I_ORI       : t_f3 := "110";
  constant C_F3_I_ANDI      : t_f3 := "111";

  -- OP Imm (Zbb)
  constant C_F3_I_RORI      : t_f3 := "101";
  constant C_F3_I_BCLZ      : t_f3 := "001";
  constant C_F3_I_BCTZ      : t_f3 := "001";
  constant C_F3_I_BCPOP     : t_f3 := "001";
  constant C_F3_I_ORCB      : t_f3 := "001";
  constant C_F3_I_REV8      : t_f3 := "101";
  constant C_F3_I_SEXTB     : t_f3 := "001";
  constant C_F3_I_SEXTH     : t_f3 := "001";

  -- OP Imm (Zbs)
  constant C_F3_I_BCLRI     : t_f3 := "001";
  constant C_F3_I_BEXTI     : t_f3 := "101";
  constant C_F3_I_BINVI     : t_f3 := "001";
  constant C_F3_I_BSETI     : t_f3 := "001";

  -- Fence
  constant C_F3_I_FENCE     : t_f3 := "000";
  constant C_F3_I_FENCEI    : t_f3 := "001";

  -- System
  constant C_F3_I_PRIV      : t_f3 := "000";
  constant C_F3_I_CSRRW     : t_f3 := "001";
  constant C_F3_I_CSRRS     : t_f3 := "010";
  constant C_F3_I_CSRRC     : t_f3 := "011";
  constant C_F3_I_CSRRWI    : t_f3 := "101";
  constant C_F3_I_CSRRSI    : t_f3 := "110";
  constant C_F3_I_CSRRCI    : t_f3 := "111";

  -- B

  -- Branch
  constant C_F3_B_BEQ       : t_f3 := "000";
  constant C_F3_B_BNE       : t_f3 := "001";
  constant C_F3_B_BLT       : t_f3 := "100";
  constant C_F3_B_BGE       : t_f3 := "101";
  constant C_F3_B_BLTU      : t_f3 := "110";
  constant C_F3_B_BGEU      : t_f3 := "111";

  -- S

  -- Store
  constant C_F3_S_SB        : t_f3 := "000";
  constant C_F3_S_SH        : t_f3 := "001";
  constant C_F3_S_SW        : t_f3 := "010";

  -- AMO
  constant C_F3_S_AMOW      : t_f3 := "010";

  -- R

  -- OP Reg
  constant C_F3_R_ADD       : t_f3 := "000";
  constant C_F3_R_SUB       : t_f3 := "000";
  constant C_F3_R_SLL       : t_f3 := "001";
  constant C_F3_R_SLT       : t_f3 := "010";
  constant C_F3_R_SLTU      : t_f3 := "011";
  constant C_F3_R_XOR       : t_f3 := "100";
  constant C_F3_R_SRL       : t_f3 := "101";
  constant C_F3_R_SRA       : t_f3 := "101";
  constant C_F3_R_OR        : t_f3 := "110";
  constant C_F3_R_AND       : t_f3 := "111";

  -- OP Reg (M, Zmmul)
  constant C_F3_R_MUL       : t_f3 := "000";
  constant C_F3_R_MULH      : t_f3 := "001";
  constant C_F3_R_MULHSU    : t_f3 := "010";
  constant C_F3_R_MULHU     : t_f3 := "011";
  constant C_F3_R_DIV       : t_f3 := "100";
  constant C_F3_R_DIVU      : t_f3 := "101";
  constant C_F3_R_REM       : t_f3 := "110";
  constant C_F3_R_REMU      : t_f3 := "111";

  -- OP Reg (Zba)
  constant C_F3_R_SH1ADD    : t_f3 := "010";
  constant C_F3_R_SH2ADD    : t_f3 := "100";
  constant C_F3_R_SH3ADD    : t_f3 := "110";

  -- OP Reg (Zbb)
  constant C_F3_R_XNOR      : t_f3 := "100";
  constant C_F3_R_ORN       : t_f3 := "110";
  constant C_F3_R_ANDN      : t_f3 := "111";
  constant C_F3_R_BCLZ      : t_f3 := "001";
  constant C_F3_R_BCTZ      : t_f3 := "001";
  constant C_F3_R_BCPOP     : t_f3 := "001";
  constant C_F3_R_MAX       : t_f3 := "110";
  constant C_F3_R_MAXU      : t_f3 := "111";
  constant C_F3_R_MIN       : t_f3 := "100";
  constant C_F3_R_MINU      : t_f3 := "101";
  constant C_F3_R_ROL       : t_f3 := "001";
  constant C_F3_R_ROR       : t_f3 := "101";
  constant C_F3_R_ZEXT      : t_f3 := "101";

  -- OP Reg (Zbc)
  constant C_F3_R_CLMUL     : t_f3 := "001";
  constant C_F3_R_CLMULR    : t_f3 := "010";
  constant C_F3_R_CLMULH    : t_f3 := "011";

  -- OP Reg (Zbs)
  constant C_F3_R_BCLR      : t_f3 := "001";
  constant C_F3_R_BEXT      : t_f3 := "101";
  constant C_F3_R_BINV      : t_f3 := "001";
  constant C_F3_R_BSET      : t_f3 := "001";

  -- OP Reg (Zicond)
  constant C_F3_R_CZERO_EQZ : t_f3 := "101";
  constant C_F3_R_CZERO_NEZ : t_f3 := "111";

  -- FUNCT5

  subtype t_f5 is std_logic_vector(4 downto 0);

  -- OP AMO (Zalrsc)
  constant C_F5_S_LR        : t_f5 := "00010";
  constant C_F5_S_SC        : t_f5 := "00011";

  -- OP AMO (Zaamo)
  constant C_F5_S_AMOSWAP   : t_f5 := "00001";
  constant C_F5_S_AMOADD    : t_f5 := "00000";
  constant C_F5_S_AMOXOR    : t_f5 := "00100";
  constant C_F5_S_AMOAND    : t_f5 := "01100";
  constant C_F5_S_AMOOR     : t_f5 := "01000";
  constant C_F5_S_AMOMIN    : t_f5 := "10000";
  constant C_F5_S_AMOMAX    : t_f5 := "10100";
  constant C_F5_S_AMOMINU   : t_f5 := "11000";
  constant C_F5_S_AMOMAXU   : t_f5 := "11100";

  -- FUNCT7

  subtype t_f7 is std_logic_vector(6 downto 0);

  constant C_F7_BASE          : t_f7 := "0000000";
  constant C_F7_SUB           : t_f7 := "0100000";
  constant C_F7_BCLR_BEXT     : t_f7 := "0100100";
  constant C_F7_BINV          : t_f7 := "0110100";
  constant C_F7_BSET          : t_f7 := "0010100";
  constant C_F7_MINMAX_CLMUL  : t_f7 := "0000101";
  constant C_F7_ROL_ROR       : t_f7 := "0110000";
  constant C_F7_SHADD         : t_f7 := "0010000";
  constant C_F7_MULDIV        : t_f7 := "0000001";
  constant C_F7_CZERO         : t_f7 := "0000111";

  -- FUNCT12

  subtype t_f12 is std_logic_vector(11 downto 0);

  -- OP System
  constant C_F12_ECALL  : t_f12 := x"000";
  constant C_F12_EBREAK : t_f12 := x"001";
  constant C_F12_SRET   : t_f12 := x"102";
  constant C_F12_MRET   : t_f12 := x"302";
  constant C_F12_DRET   : t_f12 := x"7b2";
  constant C_F12_WFI    : t_f12 := x"105";

  -- OP Imm
  constant C_F12_ORC    : t_f12 := x"287";
  constant C_F12_REV8   : t_f12 := x"698";
  constant C_F12_SEXTB  : t_f12 := x"604";
  constant C_F12_SEXTH  : t_f12 := x"605";

  -- OP Imm/Reg
  constant C_F12_CLZ    : t_f12 := x"600";
  constant C_F12_CTZ    : t_f12 := x"601";
  constant C_F12_CPOP   : t_f12 := x"602";

  -- OP Reg
  constant C_F12_ZEXTH  : t_f12 := x"080";

  -- Privilege modes

  subtype t_priv_mode is std_logic_vector(1 downto 0);

  constant C_PRIV_M : t_priv_mode := "11";
  constant C_PRIV_S : t_priv_mode := "01";
  constant C_PRIV_U : t_priv_mode := "00";

  -- Control and Status Registers

  subtype t_csr_addr is std_logic_vector(11 downto 0);

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

  constant C_CSR_UCYCLE          : t_csr_addr := x"C00";
  constant C_CSR_UTIME           : t_csr_addr := x"C01";
  constant C_CSR_UINSTRET        : t_csr_addr := x"C02";
  constant C_CSR_HPMCOUNTER3     : t_csr_addr := x"C03";
  constant C_CSR_HPMCOUNTER4     : t_csr_addr := x"C04";
  constant C_CSR_HPMCOUNTER5     : t_csr_addr := x"C05";
  constant C_CSR_HPMCOUNTER6     : t_csr_addr := x"C06";
  constant C_CSR_HPMCOUNTER7     : t_csr_addr := x"C07";
  constant C_CSR_HPMCOUNTER8     : t_csr_addr := x"C08";
  constant C_CSR_HPMCOUNTER9     : t_csr_addr := x"C09";
  constant C_CSR_HPMCOUNTER10    : t_csr_addr := x"C0A";
  constant C_CSR_HPMCOUNTER11    : t_csr_addr := x"C0B";
  constant C_CSR_HPMCOUNTER12    : t_csr_addr := x"C0C";
  constant C_CSR_HPMCOUNTER13    : t_csr_addr := x"C0D";
  constant C_CSR_HPMCOUNTER14    : t_csr_addr := x"C0E";
  constant C_CSR_HPMCOUNTER15    : t_csr_addr := x"C0F";
  constant C_CSR_HPMCOUNTER16    : t_csr_addr := x"C10";
  constant C_CSR_HPMCOUNTER17    : t_csr_addr := x"C11";
  constant C_CSR_HPMCOUNTER18    : t_csr_addr := x"C12";
  constant C_CSR_HPMCOUNTER19    : t_csr_addr := x"C13";
  constant C_CSR_HPMCOUNTER20    : t_csr_addr := x"C14";
  constant C_CSR_HPMCOUNTER21    : t_csr_addr := x"C15";
  constant C_CSR_HPMCOUNTER22    : t_csr_addr := x"C16";
  constant C_CSR_HPMCOUNTER23    : t_csr_addr := x"C17";
  constant C_CSR_HPMCOUNTER24    : t_csr_addr := x"C18";
  constant C_CSR_HPMCOUNTER25    : t_csr_addr := x"C19";
  constant C_CSR_HPMCOUNTER26    : t_csr_addr := x"C1A";
  constant C_CSR_HPMCOUNTER27    : t_csr_addr := x"C1B";
  constant C_CSR_HPMCOUNTER28    : t_csr_addr := x"C1C";
  constant C_CSR_HPMCOUNTER29    : t_csr_addr := x"C1D";
  constant C_CSR_HPMCOUNTER30    : t_csr_addr := x"C1E";
  constant C_CSR_HPMCOUNTER31    : t_csr_addr := x"C1F";
  constant C_CSR_UTIMEH          : t_csr_addr := x"C81";
  constant C_CSR_UCYCLEH         : t_csr_addr := x"C80";
  constant C_CSR_UINSTRETH       : t_csr_addr := x"C82";
  constant C_CSR_HPMCOUNTER3H    : t_csr_addr := x"C83";
  constant C_CSR_HPMCOUNTER4H    : t_csr_addr := x"C84";
  constant C_CSR_HPMCOUNTER5H    : t_csr_addr := x"C85";
  constant C_CSR_HPMCOUNTER6H    : t_csr_addr := x"C86";
  constant C_CSR_HPMCOUNTER7H    : t_csr_addr := x"C87";
  constant C_CSR_HPMCOUNTER8H    : t_csr_addr := x"C88";
  constant C_CSR_HPMCOUNTER9H    : t_csr_addr := x"C89";
  constant C_CSR_HPMCOUNTER10H   : t_csr_addr := x"C8A";
  constant C_CSR_HPMCOUNTER11H   : t_csr_addr := x"C8B";
  constant C_CSR_HPMCOUNTER12H   : t_csr_addr := x"C8C";
  constant C_CSR_HPMCOUNTER13H   : t_csr_addr := x"C8D";
  constant C_CSR_HPMCOUNTER14H   : t_csr_addr := x"C8E";
  constant C_CSR_HPMCOUNTER15H   : t_csr_addr := x"C8F";
  constant C_CSR_HPMCOUNTER16H   : t_csr_addr := x"C90";
  constant C_CSR_HPMCOUNTER17H   : t_csr_addr := x"C91";
  constant C_CSR_HPMCOUNTER18H   : t_csr_addr := x"C92";
  constant C_CSR_HPMCOUNTER19H   : t_csr_addr := x"C93";
  constant C_CSR_HPMCOUNTER20H   : t_csr_addr := x"C94";
  constant C_CSR_HPMCOUNTER21H   : t_csr_addr := x"C95";
  constant C_CSR_HPMCOUNTER22H   : t_csr_addr := x"C96";
  constant C_CSR_HPMCOUNTER23H   : t_csr_addr := x"C97";
  constant C_CSR_HPMCOUNTER24H   : t_csr_addr := x"C98";
  constant C_CSR_HPMCOUNTER25H   : t_csr_addr := x"C99";
  constant C_CSR_HPMCOUNTER26H   : t_csr_addr := x"C9A";
  constant C_CSR_HPMCOUNTER27H   : t_csr_addr := x"C9B";
  constant C_CSR_HPMCOUNTER28H   : t_csr_addr := x"C9C";
  constant C_CSR_HPMCOUNTER29H   : t_csr_addr := x"C9D";
  constant C_CSR_HPMCOUNTER30H   : t_csr_addr := x"C9E";
  constant C_CSR_HPMCOUNTER31H   : t_csr_addr := x"C9F";

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

  constant C_CSR_MVENDORID       : t_csr_addr := x"F11";
  constant C_CSR_MARCHID         : t_csr_addr := x"F12";
  constant C_CSR_MIMPID          : t_csr_addr := x"F13";
  constant C_CSR_MHARTID         : t_csr_addr := x"F14";
  constant C_CSR_MCONFIGPTR      : t_csr_addr := x"F15";
  constant C_CSR_MSTATUS         : t_csr_addr := x"300";
  constant C_CSR_MISA            : t_csr_addr := x"301";
  constant C_CSR_MEDELEG         : t_csr_addr := x"302";
  constant C_CSR_MIDELEG         : t_csr_addr := x"303";
  constant C_CSR_MIE             : t_csr_addr := x"304";
  constant C_CSR_MTVEC           : t_csr_addr := x"305";
  constant C_CSR_MCOUNTEREN      : t_csr_addr := x"306";
  constant C_CSR_MSTATUSH        : t_csr_addr := x"310";
  constant C_CSR_MCOUNTINHIBIT   : t_csr_addr := x"320";
  constant C_CSR_MHPMEVENT3      : t_csr_addr := x"323";
  constant C_CSR_MHPMEVENT4      : t_csr_addr := x"324";
  constant C_CSR_MHPMEVENT5      : t_csr_addr := x"325";
  constant C_CSR_MHPMEVENT6      : t_csr_addr := x"326";
  constant C_CSR_MHPMEVENT7      : t_csr_addr := x"327";
  constant C_CSR_MHPMEVENT8      : t_csr_addr := x"328";
  constant C_CSR_MHPMEVENT9      : t_csr_addr := x"329";
  constant C_CSR_MHPMEVENT10     : t_csr_addr := x"32A";
  constant C_CSR_MHPMEVENT11     : t_csr_addr := x"32B";
  constant C_CSR_MHPMEVENT12     : t_csr_addr := x"32C";
  constant C_CSR_MHPMEVENT13     : t_csr_addr := x"32D";
  constant C_CSR_MHPMEVENT14     : t_csr_addr := x"32E";
  constant C_CSR_MHPMEVENT15     : t_csr_addr := x"32F";
  constant C_CSR_MHPMEVENT16     : t_csr_addr := x"330";
  constant C_CSR_MHPMEVENT17     : t_csr_addr := x"331";
  constant C_CSR_MHPMEVENT18     : t_csr_addr := x"332";
  constant C_CSR_MHPMEVENT19     : t_csr_addr := x"333";
  constant C_CSR_MHPMEVENT20     : t_csr_addr := x"334";
  constant C_CSR_MHPMEVENT21     : t_csr_addr := x"335";
  constant C_CSR_MHPMEVENT22     : t_csr_addr := x"336";
  constant C_CSR_MHPMEVENT23     : t_csr_addr := x"337";
  constant C_CSR_MHPMEVENT24     : t_csr_addr := x"338";
  constant C_CSR_MHPMEVENT25     : t_csr_addr := x"339";
  constant C_CSR_MHPMEVENT26     : t_csr_addr := x"33A";
  constant C_CSR_MHPMEVENT27     : t_csr_addr := x"33B";
  constant C_CSR_MHPMEVENT28     : t_csr_addr := x"33C";
  constant C_CSR_MHPMEVENT29     : t_csr_addr := x"33D";
  constant C_CSR_MHPMEVENT30     : t_csr_addr := x"33E";
  constant C_CSR_MHPMEVENT31     : t_csr_addr := x"33F";
  constant C_CSR_MSCRATCH        : t_csr_addr := x"340";
  constant C_CSR_MEPC            : t_csr_addr := x"341";
  constant C_CSR_MCAUSE          : t_csr_addr := x"342";
  constant C_CSR_MTVAL           : t_csr_addr := x"343";
  constant C_CSR_MIP             : t_csr_addr := x"344";
  constant C_CSR_MTINST          : t_csr_addr := x"34A";
  constant C_CSR_MTVAL2          : t_csr_addr := x"34B";
  constant C_CSR_MENVCFG         : t_csr_addr := x"30A";
  constant C_CSR_MENVCFGH        : t_csr_addr := x"31A";
  constant C_CSR_MSECCFG         : t_csr_addr := x"747";
  constant C_CSR_MSECCFGH        : t_csr_addr := x"757";
  constant C_CSR_PMPCFG0         : t_csr_addr := x"3A0";
  constant C_CSR_PMPCFG1         : t_csr_addr := x"3A1";
  constant C_CSR_PMPCFG2         : t_csr_addr := x"3A2";
  constant C_CSR_PMPCFG3         : t_csr_addr := x"3A3";
  constant C_CSR_PMPCFG4         : t_csr_addr := x"3A4";
  constant C_CSR_PMPCFG5         : t_csr_addr := x"3A5";
  constant C_CSR_PMPCFG6         : t_csr_addr := x"3A6";
  constant C_CSR_PMPCFG7         : t_csr_addr := x"3A7";
  constant C_CSR_PMPCFG8         : t_csr_addr := x"3A8";
  constant C_CSR_PMPCFG9         : t_csr_addr := x"3A9";
  constant C_CSR_PMPCFG10        : t_csr_addr := x"3AA";
  constant C_CSR_PMPCFG11        : t_csr_addr := x"3AB";
  constant C_CSR_PMPCFG12        : t_csr_addr := x"3AC";
  constant C_CSR_PMPCFG13        : t_csr_addr := x"3AD";
  constant C_CSR_PMPCFG14        : t_csr_addr := x"3AE";
  constant C_CSR_PMPCFG15        : t_csr_addr := x"3AF";
  constant C_CSR_PMPADDR0        : t_csr_addr := x"3B0";
  constant C_CSR_PMPADDR1        : t_csr_addr := x"3B1";
  constant C_CSR_PMPADDR2        : t_csr_addr := x"3B2";
  constant C_CSR_PMPADDR3        : t_csr_addr := x"3B3";
  constant C_CSR_PMPADDR4        : t_csr_addr := x"3B4";
  constant C_CSR_PMPADDR5        : t_csr_addr := x"3B5";
  constant C_CSR_PMPADDR6        : t_csr_addr := x"3B6";
  constant C_CSR_PMPADDR7        : t_csr_addr := x"3B7";
  constant C_CSR_PMPADDR8        : t_csr_addr := x"3B8";
  constant C_CSR_PMPADDR9        : t_csr_addr := x"3B9";
  constant C_CSR_PMPADDR10       : t_csr_addr := x"3BA";
  constant C_CSR_PMPADDR11       : t_csr_addr := x"3BB";
  constant C_CSR_PMPADDR12       : t_csr_addr := x"3BC";
  constant C_CSR_PMPADDR13       : t_csr_addr := x"3BD";
  constant C_CSR_PMPADDR14       : t_csr_addr := x"3BE";
  constant C_CSR_PMPADDR15       : t_csr_addr := x"3BF";
  constant C_CSR_PMPADDR16       : t_csr_addr := x"3C0";
  constant C_CSR_PMPADDR17       : t_csr_addr := x"3C1";
  constant C_CSR_PMPADDR18       : t_csr_addr := x"3C2";
  constant C_CSR_PMPADDR19       : t_csr_addr := x"3C3";
  constant C_CSR_PMPADDR20       : t_csr_addr := x"3C4";
  constant C_CSR_PMPADDR21       : t_csr_addr := x"3C5";
  constant C_CSR_PMPADDR22       : t_csr_addr := x"3C6";
  constant C_CSR_PMPADDR23       : t_csr_addr := x"3C7";
  constant C_CSR_PMPADDR24       : t_csr_addr := x"3C8";
  constant C_CSR_PMPADDR25       : t_csr_addr := x"3C9";
  constant C_CSR_PMPADDR26       : t_csr_addr := x"3CA";
  constant C_CSR_PMPADDR27       : t_csr_addr := x"3CB";
  constant C_CSR_PMPADDR28       : t_csr_addr := x"3CC";
  constant C_CSR_PMPADDR29       : t_csr_addr := x"3CD";
  constant C_CSR_PMPADDR30       : t_csr_addr := x"3CE";
  constant C_CSR_PMPADDR31       : t_csr_addr := x"3CF";
  constant C_CSR_PMPADDR32       : t_csr_addr := x"3D0";
  constant C_CSR_PMPADDR33       : t_csr_addr := x"3D1";
  constant C_CSR_PMPADDR34       : t_csr_addr := x"3D2";
  constant C_CSR_PMPADDR35       : t_csr_addr := x"3D3";
  constant C_CSR_PMPADDR36       : t_csr_addr := x"3D4";
  constant C_CSR_PMPADDR37       : t_csr_addr := x"3D5";
  constant C_CSR_PMPADDR38       : t_csr_addr := x"3D6";
  constant C_CSR_PMPADDR39       : t_csr_addr := x"3D7";
  constant C_CSR_PMPADDR40       : t_csr_addr := x"3D8";
  constant C_CSR_PMPADDR41       : t_csr_addr := x"3D9";
  constant C_CSR_PMPADDR42       : t_csr_addr := x"3DA";
  constant C_CSR_PMPADDR43       : t_csr_addr := x"3DB";
  constant C_CSR_PMPADDR44       : t_csr_addr := x"3DC";
  constant C_CSR_PMPADDR45       : t_csr_addr := x"3DD";
  constant C_CSR_PMPADDR46       : t_csr_addr := x"3DE";
  constant C_CSR_PMPADDR47       : t_csr_addr := x"3DF";
  constant C_CSR_PMPADDR48       : t_csr_addr := x"3E0";
  constant C_CSR_PMPADDR49       : t_csr_addr := x"3E1";
  constant C_CSR_PMPADDR50       : t_csr_addr := x"3E2";
  constant C_CSR_PMPADDR51       : t_csr_addr := x"3E3";
  constant C_CSR_PMPADDR52       : t_csr_addr := x"3E4";
  constant C_CSR_PMPADDR53       : t_csr_addr := x"3E5";
  constant C_CSR_PMPADDR54       : t_csr_addr := x"3E6";
  constant C_CSR_PMPADDR55       : t_csr_addr := x"3E7";
  constant C_CSR_PMPADDR56       : t_csr_addr := x"3E8";
  constant C_CSR_PMPADDR57       : t_csr_addr := x"3E9";
  constant C_CSR_PMPADDR58       : t_csr_addr := x"3EA";
  constant C_CSR_PMPADDR59       : t_csr_addr := x"3EB";
  constant C_CSR_PMPADDR60       : t_csr_addr := x"3EC";
  constant C_CSR_PMPADDR61       : t_csr_addr := x"3ED";
  constant C_CSR_PMPADDR62       : t_csr_addr := x"3EE";
  constant C_CSR_PMPADDR63       : t_csr_addr := x"3EF";
  constant C_CSR_MCYCLE          : t_csr_addr := x"B00";
  constant C_CSR_MINSTRET        : t_csr_addr := x"B02";
  constant C_CSR_MHPMCOUNTER3    : t_csr_addr := x"B03";
  constant C_CSR_MHPMCOUNTER4    : t_csr_addr := x"B04";
  constant C_CSR_MHPMCOUNTER5    : t_csr_addr := x"B05";
  constant C_CSR_MHPMCOUNTER6    : t_csr_addr := x"B06";
  constant C_CSR_MHPMCOUNTER7    : t_csr_addr := x"B07";
  constant C_CSR_MHPMCOUNTER8    : t_csr_addr := x"B08";
  constant C_CSR_MHPMCOUNTER9    : t_csr_addr := x"B09";
  constant C_CSR_MHPMCOUNTER10   : t_csr_addr := x"B0A";
  constant C_CSR_MHPMCOUNTER11   : t_csr_addr := x"B0B";
  constant C_CSR_MHPMCOUNTER12   : t_csr_addr := x"B0C";
  constant C_CSR_MHPMCOUNTER13   : t_csr_addr := x"B0D";
  constant C_CSR_MHPMCOUNTER14   : t_csr_addr := x"B0E";
  constant C_CSR_MHPMCOUNTER15   : t_csr_addr := x"B0F";
  constant C_CSR_MHPMCOUNTER16   : t_csr_addr := x"B10";
  constant C_CSR_MHPMCOUNTER17   : t_csr_addr := x"B11";
  constant C_CSR_MHPMCOUNTER18   : t_csr_addr := x"B12";
  constant C_CSR_MHPMCOUNTER19   : t_csr_addr := x"B13";
  constant C_CSR_MHPMCOUNTER20   : t_csr_addr := x"B14";
  constant C_CSR_MHPMCOUNTER21   : t_csr_addr := x"B15";
  constant C_CSR_MHPMCOUNTER22   : t_csr_addr := x"B16";
  constant C_CSR_MHPMCOUNTER23   : t_csr_addr := x"B17";
  constant C_CSR_MHPMCOUNTER24   : t_csr_addr := x"B18";
  constant C_CSR_MHPMCOUNTER25   : t_csr_addr := x"B19";
  constant C_CSR_MHPMCOUNTER26   : t_csr_addr := x"B1A";
  constant C_CSR_MHPMCOUNTER27   : t_csr_addr := x"B1B";
  constant C_CSR_MHPMCOUNTER28   : t_csr_addr := x"B1C";
  constant C_CSR_MHPMCOUNTER29   : t_csr_addr := x"B1D";
  constant C_CSR_MHPMCOUNTER30   : t_csr_addr := x"B1E";
  constant C_CSR_MHPMCOUNTER31   : t_csr_addr := x"B1F";
  constant C_CSR_MCYCLEH         : t_csr_addr := x"B80";
  constant C_CSR_MINSTRETH       : t_csr_addr := x"B82";
  constant C_CSR_MHPMCOUNTER3H   : t_csr_addr := x"B83";
  constant C_CSR_MHPMCOUNTER4H   : t_csr_addr := x"B84";
  constant C_CSR_MHPMCOUNTER5H   : t_csr_addr := x"B85";
  constant C_CSR_MHPMCOUNTER6H   : t_csr_addr := x"B86";
  constant C_CSR_MHPMCOUNTER7H   : t_csr_addr := x"B87";
  constant C_CSR_MHPMCOUNTER8H   : t_csr_addr := x"B88";
  constant C_CSR_MHPMCOUNTER9H   : t_csr_addr := x"B89";
  constant C_CSR_MHPMCOUNTER10H  : t_csr_addr := x"B8A";
  constant C_CSR_MHPMCOUNTER11H  : t_csr_addr := x"B8B";
  constant C_CSR_MHPMCOUNTER12H  : t_csr_addr := x"B8C";
  constant C_CSR_MHPMCOUNTER13H  : t_csr_addr := x"B8D";
  constant C_CSR_MHPMCOUNTER14H  : t_csr_addr := x"B8E";
  constant C_CSR_MHPMCOUNTER15H  : t_csr_addr := x"B8F";
  constant C_CSR_MHPMCOUNTER16H  : t_csr_addr := x"B90";
  constant C_CSR_MHPMCOUNTER17H  : t_csr_addr := x"B91";
  constant C_CSR_MHPMCOUNTER18H  : t_csr_addr := x"B92";
  constant C_CSR_MHPMCOUNTER19H  : t_csr_addr := x"B93";
  constant C_CSR_MHPMCOUNTER20H  : t_csr_addr := x"B94";
  constant C_CSR_MHPMCOUNTER21H  : t_csr_addr := x"B95";
  constant C_CSR_MHPMCOUNTER22H  : t_csr_addr := x"B96";
  constant C_CSR_MHPMCOUNTER23H  : t_csr_addr := x"B97";
  constant C_CSR_MHPMCOUNTER24H  : t_csr_addr := x"B98";
  constant C_CSR_MHPMCOUNTER25H  : t_csr_addr := x"B99";
  constant C_CSR_MHPMCOUNTER26H  : t_csr_addr := x"B9A";
  constant C_CSR_MHPMCOUNTER27H  : t_csr_addr := x"B9B";
  constant C_CSR_MHPMCOUNTER28H  : t_csr_addr := x"B9C";
  constant C_CSR_MHPMCOUNTER29H  : t_csr_addr := x"B9D";
  constant C_CSR_MHPMCOUNTER30H  : t_csr_addr := x"B9E";
  constant C_CSR_MHPMCOUNTER31H  : t_csr_addr := x"B9F";
  constant C_CSR_TSELECT         : t_csr_addr := x"7A0";
  constant C_CSR_TDATA1          : t_csr_addr := x"7A1";
  constant C_CSR_TDATA2          : t_csr_addr := x"7A2";
  constant C_CSR_TDATA3          : t_csr_addr := x"7A3";
  constant C_CSR_MCONTEXT        : t_csr_addr := x"7A8";
  constant C_CSR_DCSR            : t_csr_addr := x"7B0";
  constant C_CSR_DPC             : t_csr_addr := x"7B1";
  constant C_CSR_DSCRATCH0       : t_csr_addr := x"7B2";
  constant C_CSR_DSCRATCH1       : t_csr_addr := x"7B3";

  -- Functions

  function f_opcode(inst : std_logic_vector) return t_opcode;
  function f_rd(inst : std_logic_vector) return t_reg_addr;
  function f_rs1(inst : std_logic_vector) return t_reg_addr;
  function f_rs2(inst : std_logic_vector) return t_reg_addr;
  function f_f3(inst : std_logic_vector) return t_f3;
  function f_f5(inst : std_logic_vector) return t_f5;
  function f_f7(inst : std_logic_vector) return t_f7;
  function f_f12(inst : std_logic_vector) return t_f12;
  function f_csr_addr(inst : std_logic_vector) return t_csr_addr;

  function f_imm(inst : std_logic_vector) return std_logic_vector;

  function f_pc_incr(compressed : std_logic) return std_logic_vector;

end package riscv_pkg;

package body riscv_pkg is

  function f_opcode(inst : std_logic_vector) return t_opcode is
    variable v : t_opcode := inst(6 downto 0);
  begin
    return v;
  end function;

  function f_rd(inst : std_logic_vector) return t_reg_addr is
    variable v : t_reg_addr := inst(11 downto 7);
  begin
    return v;
  end function;

  function f_rs1(inst : std_logic_vector) return t_reg_addr is
    variable v : t_reg_addr := inst(19 downto 15);
  begin
    return v;
  end function;

  function f_rs2(inst : std_logic_vector) return t_reg_addr is
    variable v : t_reg_addr := inst(24 downto 20);
  begin
    return v;
  end function;

  function f_f3(inst : std_logic_vector) return t_f3 is
    variable v : t_f3 := inst(14 downto 12);
  begin
    return v;
  end function;

  function f_f5(inst : std_logic_vector) return t_f5 is
    variable v : t_f5 := inst(31 downto 27);
  begin
    return v;
  end function;

  function f_f7(inst : std_logic_vector) return t_f7 is
    variable v : t_f7 := inst(31 downto 25);
  begin
    return v;
  end function;

  function f_f12(inst : std_logic_vector) return t_f12 is
    variable v : t_f12 := inst(31 downto 20);
  begin
    return v;
  end function;

  function f_csr_addr(inst : std_logic_vector) return t_csr_addr is
    variable v : t_csr_addr := inst(31 downto 20);
  begin
    return v;
  end function;

  function f_imm_i(inst : std_logic_vector) return std_logic_vector is
    variable v : std_logic_vector(C_XLEN-1 downto 0);
  begin
    v(31 downto 11) := (others => inst(31));
    v(10 downto 0)  := inst(30 downto 20);
    return v;
  end function;

  function f_imm_s(inst : std_logic_vector) return std_logic_vector is
    variable v : std_logic_vector(C_XLEN-1 downto 0);
  begin
    v(31 downto 11) := (others => inst(31));
    v(10 downto 5)  := inst(30 downto 25);
    v(4 downto 0)   := inst(11 downto 7);
    return v;
  end function;

  function f_imm_u(inst : std_logic_vector) return std_logic_vector is
    variable v : std_logic_vector(C_XLEN-1 downto 0);
  begin
    v(31 downto 12) := inst(31 downto 12);
    v(11 downto 0)  := (others => '0');
    return v;
  end function;

  function f_imm_b(inst : std_logic_vector) return std_logic_vector is
    variable v : std_logic_vector(C_XLEN-1 downto 0);
  begin
    v(31 downto 12) := (others => inst(31));
    v(11)           := inst(7);
    v(10 downto 5)  := inst(30 downto 25);
    v(4 downto 1)   := inst(11 downto 8);
    v(0)            := '0';
    return v;
  end function;

  function f_imm_j(inst : std_logic_vector) return std_logic_vector is
    variable v : std_logic_vector(C_XLEN-1 downto 0);
  begin
    v(31 downto 20) := (others => inst(31));
    v(19 downto 12) := inst(19 downto 12);
    v(11)           := inst(20);
    v(10 downto 1)  := inst(30 downto 21);
    v(0)            := '0';
    return v;
  end function;

  function f_imm_csr(inst : std_logic_vector) return std_logic_vector is
    variable v : std_logic_vector(C_XLEN-1 downto 0);
  begin
    v(31 downto 5)  := (others => '0');
    v(4 downto 0)   := inst(19 downto 15);
    return v;
  end function;

  function f_imm(inst : std_logic_vector) return std_logic_vector is
    variable v : std_logic_vector(C_XLEN-1 downto 0);
  begin
    case f_opcode(inst) is
    when C_OP_LUI | C_OP_AUIPC =>
      v := f_imm_u(inst);
    when C_OP_JAL =>
      v := f_imm_j(inst);
    when C_OP_BRANCH =>
      v := f_imm_b(inst);
    when C_OP_STORE | C_OP_AMO =>
      v := f_imm_s(inst);
    when C_OP_SYSTEM =>
      v := f_imm_csr(inst);
    when others =>
      v := f_imm_i(inst);
    end case;
    return v;
  end function;

  function f_pc_incr(compressed : std_logic) return std_logic_vector is
    variable v : std_logic_vector(C_XLEN-1 downto 0) := (others => '0');
  begin
    v(2) := not compressed;
    v(1) := compressed;
    return v;
  end function;

end package body riscv_pkg;