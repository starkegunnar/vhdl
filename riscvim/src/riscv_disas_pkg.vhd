
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library lib_riscv;
use lib_riscv.riscv_pkg.all;
use lib_riscv.riscv_alu_pkg.all;

package riscv_disas_pkg is

  function f_inst2str(inst : std_logic_vector; pc : std_logic_vector) return line;
  function f_alu2str(alu_op : t_alu_opcode) return string;

end package riscv_disas_pkg;

package body riscv_disas_pkg is

  function f_reg2str(r : t_reg_addr) return string is
  begin
    case r is
    when C_GPR_ZERO =>  return "zero";
    when C_GPR_RA =>    return "ra";
    when C_GPR_SP =>    return "sp";
    when C_GPR_GP =>    return "gp";
    when C_GPR_TP =>    return "tp";
    when C_GPR_T0 =>    return "t0";
    when C_GPR_T1 =>    return "t1";
    when C_GPR_T2 =>    return "t2";
    when C_GPR_FP =>    return "fp";
    when C_GPR_S1 =>    return "s1";
    when C_GPR_A0 =>    return "a0";
    when C_GPR_A1 =>    return "a1";
    when C_GPR_A2 =>    return "a2";
    when C_GPR_A3 =>    return "a3";
    when C_GPR_A4 =>    return "a4";
    when C_GPR_A5 =>    return "a5";
    when C_GPR_A6 =>    return "a6";
    when C_GPR_A7 =>    return "a7";
    when C_GPR_S2 =>    return "s2";
    when C_GPR_S3 =>    return "s3";
    when C_GPR_S4 =>    return "s4";
    when C_GPR_S5 =>    return "s5";
    when C_GPR_S6 =>    return "s6";
    when C_GPR_S7 =>    return "s7";
    when C_GPR_S8 =>    return "s8";
    when C_GPR_S9 =>    return "s9";
    when C_GPR_S10 =>   return "s10";
    when C_GPR_S11 =>   return "s11";
    when C_GPR_T3 =>    return "t3";
    when C_GPR_T4 =>    return "t4";
    when C_GPR_T5 =>    return "t5";
    when C_GPR_T6 =>    return "t6";
    when others =>      return "xxx";
    end case;
  end function;

  function f_jalr2str(f3 : t_f3) return string is
  begin
    case f3 is
    when C_F3_I_JALR => return "jalr";
    when others =>      return "xxx";
    end case;
  end function;

  function f_load2str(f3 : t_f3) return string is
  begin
    case f3 is
    when C_F3_I_LB =>   return "lb";
    when C_F3_I_LH =>   return "lh";
    when C_F3_I_LW =>   return "lw";
    when C_F3_I_LBU =>  return "lbu";
    when C_F3_I_LHU =>  return "lhu";
    when others =>      return "xxx";
    end case;
  end function;

  function f_opimm2str(f3 : t_f3; f12 : t_f12) return string is
  begin
    case f3 is
    when C_F3_I_ADDI =>   return "addi";
    when C_F3_I_SLLI =>
      case? f12 is
      when C_F12_CLZ =>                 return "clz";
      when C_F12_CTZ =>                 return "ctz";
      when C_F12_CPOP =>                return "cpop";
      when C_F12_SEXTB =>               return "sext.b";
      when C_F12_SEXTH =>               return "sext.h";
      when C_F7_BCLR_BEXT & "-----" =>  return "bclri";
      when C_F7_BINV & "-----" =>       return "binvi";
      when C_F7_BSET & "-----" =>       return "bseti";
      when C_F7_BASE & "-----" =>       return "slli";
      when others =>                    return "xxx";
      end case?;
    when C_F3_I_SLTI =>   return "slti";
    when C_F3_I_SLTIU =>  return "sltiu";
    when C_F3_I_SRLI =>
      case? f12 is
      when C_F12_ORC =>                 return "orc.b";
      when C_F12_REV8 =>                return "rev8";
      when C_F7_ROL_ROR & "-----" =>    return "rori";
      when C_F7_BCLR_BEXT & "-----" =>  return "bexti";
      when C_F7_BASE & "-----" =>       return "srli";
      when C_F7_SUB & "-----" =>        return "srai";
      when others =>                    return "xxx";
      end case?;
    when C_F3_I_XORI =>   return "xori";
    when C_F3_I_ORI =>    return "ori";
    when C_F3_I_ANDI =>   return "andi";
    when others =>        return "xxx";
    end case;
  end function;

  function f_fence2str(f3 : t_f3) return string is
  begin
    case f3 is
    when C_F3_I_FENCE =>  return "fence";
    when C_F3_I_FENCEI => return "fence.i";
    when others =>        return "xxx";
    end case;
  end function;

  function f_sys_csr2str(f3 : t_f3) return string is
  begin
    case f3 is
    when C_F3_I_CSRRW =>  return "csrrw";
    when C_F3_I_CSRRS =>  return "csrrs";
    when C_F3_I_CSRRC =>  return "csrrc";
    when C_F3_I_CSRRWI => return "csrrwi";
    when C_F3_I_CSRRSI => return "csrrsi";
    when C_F3_I_CSRRCI => return "csrrci";
    when others =>        return "xxx";
    end case;
  end function;

  function f_sys_priv2str(f3 : t_f3; f12 : t_f12) return string is
  begin
    case f3 is
    when C_F3_I_PRIV =>
      case f12 is
      when C_F12_ECALL =>   return "ecall";
      when C_F12_EBREAK =>  return "ebreak";
      when C_F12_SRET =>    return "sret";
      when C_F12_MRET =>    return "mret";
      when C_F12_DRET =>    return "dret";
      when C_F12_WFI =>     return "wfi";
      when others =>        return "xxx";
      end case;
    when others =>        return "xxx";
    end case;
  end function;

  function f_branch2str(f3 : t_f3) return string is
  begin
    case f3 is
    when C_F3_B_BEQ =>  return "beq";
    when C_F3_B_BNE =>  return "bne";
    when C_F3_B_BLT =>  return "blt";
    when C_F3_B_BGE =>  return "bge";
    when C_F3_B_BLTU => return "bltu";
    when C_F3_B_BGEU => return "bgeu";
    when others =>      return "xxx";
    end case;
  end function;

  function f_store2str(f3 : t_f3) return string is
  begin
    case f3 is
    when C_F3_S_SB => return "sb";
    when C_F3_S_SH => return "sh";
    when C_F3_S_SW => return "sw";
    when others =>    return "xxx";
    end case;
  end function;

  function f_opreg2str(f3 : t_f3; f7 : t_f7; f12 : t_f12) return string is
  begin
    case f3 is
    when C_F3_R_ADD =>
      case f7 is
      when C_F7_BASE =>   return "add";
      when C_F7_SUB =>    return "sub";
      when C_F7_MULDIV => return "mul";
      when others =>      return "xxx";
      end case;
    when C_F3_R_SLL =>
      case f7 is
      when C_F7_BASE =>         return "sll";
      when C_F7_BCLR_BEXT =>    return "bclr";
      when C_F7_BINV =>         return "binv";
      when C_F7_BSET =>         return "bset";
      when C_F7_MINMAX_CLMUL => return "clmul";
      when C_F7_ROL_ROR =>      return "rol";
      when C_F7_MULDIV =>       return "mulh";
      when others =>
        case f12 is
        when C_F12_CLZ =>   return "clz";
        when C_F12_CTZ =>   return "ctz";
        when C_F12_CPOP =>  return "cpop";
        when others =>      return "xxx";
        end case;
      end case;
    when C_F3_R_SLT =>
      case f7 is
      when C_F7_BASE =>         return "slt";
      when C_F7_MINMAX_CLMUL => return "clmulr";
      when C_F7_SHADD =>        return "sh1add";
      when C_F7_MULDIV =>       return "mulhsu";
      when others =>            return "xxx";
      end case;
    when C_F3_R_SLTU =>
      case f7 is
      when C_F7_BASE =>         return "sltu";
      when C_F7_MINMAX_CLMUL => return "clmulh";
      when C_F7_MULDIV =>       return "mulhu";
      when others =>            return "xxx";
      end case;
    when C_F3_R_XOR =>
      case f7 is
      when C_F7_BASE =>         return "xor";
      when C_F7_SUB =>          return "xnor";
      when C_F7_MINMAX_CLMUL => return "min";
      when C_F7_MULDIV =>       return "div";
      when C_F7_SHADD =>        return "sh2add";
      when others =>            return "xxx";
      end case;
    when C_F3_R_SRL =>
      case f7 is
      when C_F7_BASE =>         return "srl";
      when C_F7_SUB =>          return "sra";
      when C_F7_MINMAX_CLMUL => return "minu";
      when C_F7_ROL_ROR =>      return "ror";
      when C_F7_BCLR_BEXT =>    return "bext";
      when C_F7_MULDIV =>       return "divu";
      when C_F7_CZERO =>        return "czero.eqz";
      when others =>
        case f12 is
        when C_F12_ZEXTH => return "zext.h";
        when others =>      return "xxx";
        end case;
      end case;
    when C_F3_R_OR =>
      case f7 is
      when C_F7_BASE =>         return "or";
      when C_F7_SUB =>          return "orn";
      when C_F7_MINMAX_CLMUL => return "max";
      when C_F7_MULDIV =>       return "rem";
      when C_F7_SHADD =>        return "sh3add";
      when others =>            return "xxx";
      end case;
    when C_F3_R_AND =>
      case f7 is
      when C_F7_BASE =>         return "and";
      when C_F7_SUB =>          return "andn";
      when C_F7_MINMAX_CLMUL => return "maxu";
      when C_F7_MULDIV =>       return "remu";
      when C_F7_CZERO =>        return "czero.nez";
      when others =>            return "xxx";
      end case;
    when others => return "xxx";
    end case;
  end function;

  function f_amo2str(f5 : t_f5) return string is
  begin
    case f5 is
    when C_F5_S_LR =>       return "lr.w";
    when C_F5_S_SC =>       return "sc.w";
    when C_F5_S_AMOSWAP =>  return "amoswap.w";
    when C_F5_S_AMOADD =>   return "amoadd.w";
    when C_F5_S_AMOXOR =>   return "amoxor.w";
    when C_F5_S_AMOAND =>   return "amoand.w";
    when C_F5_S_AMOOR =>    return "amoor.w";
    when C_F5_S_AMOMIN =>   return "amomin.w";
    when C_F5_S_AMOMAX =>   return "amomax.w";
    when C_F5_S_AMOMINU =>  return "amominu.w";
    when C_F5_S_AMOMAXU =>  return "amomaxu.w";
    when others =>          return "xxx";
    end case;
  end function;

  function f_csr2str(csr : t_csr_addr) return string is
  begin
    case csr is
    when C_CSR_UCYCLE => return "ucycle";
    when C_CSR_UTIME => return "utime";
    when C_CSR_UINSTRET => return "uinstret";
    when C_CSR_HPMCOUNTER3 => return "hpmcounter3";
    when C_CSR_HPMCOUNTER4 => return "hpmcounter4";
    when C_CSR_HPMCOUNTER5 => return "hpmcounter5";
    when C_CSR_HPMCOUNTER6 => return "hpmcounter6";
    when C_CSR_HPMCOUNTER7 => return "hpmcounter7";
    when C_CSR_HPMCOUNTER8 => return "hpmcounter8";
    when C_CSR_HPMCOUNTER9 => return "hpmcounter9";
    when C_CSR_HPMCOUNTER10 => return "hpmcounter10";
    when C_CSR_HPMCOUNTER11 => return "hpmcounter11";
    when C_CSR_HPMCOUNTER12 => return "hpmcounter12";
    when C_CSR_HPMCOUNTER13 => return "hpmcounter13";
    when C_CSR_HPMCOUNTER14 => return "hpmcounter14";
    when C_CSR_HPMCOUNTER15 => return "hpmcounter15";
    when C_CSR_HPMCOUNTER16 => return "hpmcounter16";
    when C_CSR_HPMCOUNTER17 => return "hpmcounter17";
    when C_CSR_HPMCOUNTER18 => return "hpmcounter18";
    when C_CSR_HPMCOUNTER19 => return "hpmcounter19";
    when C_CSR_HPMCOUNTER20 => return "hpmcounter20";
    when C_CSR_HPMCOUNTER21 => return "hpmcounter21";
    when C_CSR_HPMCOUNTER22 => return "hpmcounter22";
    when C_CSR_HPMCOUNTER23 => return "hpmcounter23";
    when C_CSR_HPMCOUNTER24 => return "hpmcounter24";
    when C_CSR_HPMCOUNTER25 => return "hpmcounter25";
    when C_CSR_HPMCOUNTER26 => return "hpmcounter26";
    when C_CSR_HPMCOUNTER27 => return "hpmcounter27";
    when C_CSR_HPMCOUNTER28 => return "hpmcounter28";
    when C_CSR_HPMCOUNTER29 => return "hpmcounter29";
    when C_CSR_HPMCOUNTER30 => return "hpmcounter30";
    when C_CSR_HPMCOUNTER31 => return "hpmcounter31";
    when C_CSR_UTIMEH => return "utimeh";
    when C_CSR_UCYCLEH => return "ucycleh";
    when C_CSR_UINSTRETH => return "uinstreth";
    when C_CSR_HPMCOUNTER3H => return "hpmcounter3h";
    when C_CSR_HPMCOUNTER4H => return "hpmcounter4h";
    when C_CSR_HPMCOUNTER5H => return "hpmcounter5h";
    when C_CSR_HPMCOUNTER6H => return "hpmcounter6h";
    when C_CSR_HPMCOUNTER7H => return "hpmcounter7h";
    when C_CSR_HPMCOUNTER8H => return "hpmcounter8h";
    when C_CSR_HPMCOUNTER9H => return "hpmcounter9h";
    when C_CSR_HPMCOUNTER10H => return "hpmcounter10h";
    when C_CSR_HPMCOUNTER11H => return "hpmcounter11h";
    when C_CSR_HPMCOUNTER12H => return "hpmcounter12h";
    when C_CSR_HPMCOUNTER13H => return "hpmcounter13h";
    when C_CSR_HPMCOUNTER14H => return "hpmcounter14h";
    when C_CSR_HPMCOUNTER15H => return "hpmcounter15h";
    when C_CSR_HPMCOUNTER16H => return "hpmcounter16h";
    when C_CSR_HPMCOUNTER17H => return "hpmcounter17h";
    when C_CSR_HPMCOUNTER18H => return "hpmcounter18h";
    when C_CSR_HPMCOUNTER19H => return "hpmcounter19h";
    when C_CSR_HPMCOUNTER20H => return "hpmcounter20h";
    when C_CSR_HPMCOUNTER21H => return "hpmcounter21h";
    when C_CSR_HPMCOUNTER22H => return "hpmcounter22h";
    when C_CSR_HPMCOUNTER23H => return "hpmcounter23h";
    when C_CSR_HPMCOUNTER24H => return "hpmcounter24h";
    when C_CSR_HPMCOUNTER25H => return "hpmcounter25h";
    when C_CSR_HPMCOUNTER26H => return "hpmcounter26h";
    when C_CSR_HPMCOUNTER27H => return "hpmcounter27h";
    when C_CSR_HPMCOUNTER28H => return "hpmcounter28h";
    when C_CSR_HPMCOUNTER29H => return "hpmcounter29h";
    when C_CSR_HPMCOUNTER30H => return "hpmcounter30h";
    when C_CSR_HPMCOUNTER31H => return "hpmcounter31h";
    when C_CSR_MARCHID => return "marchid";
    when C_CSR_MIMPID => return "mimpid";
    when C_CSR_MHARTID => return "mhartid";
    when C_CSR_MCONFIGPTR => return "mconfigptr";
    when C_CSR_MSTATUS => return "mstatus";
    when C_CSR_MISA => return "misa";
    when C_CSR_MEDELEG => return "medeleg";
    when C_CSR_MIDELEG => return "mideleg";
    when C_CSR_MIE => return "mie";
    when C_CSR_MTVEC => return "mtvec";
    when C_CSR_MCOUNTEREN => return "mcounteren";
    when C_CSR_MSTATUSH => return "mstatush";
    when C_CSR_MCOUNTINHIBIT => return "mcountinhibit";
    when C_CSR_MHPMEVENT3 => return "mhpmevent3";
    when C_CSR_MHPMEVENT4 => return "mhpmevent4";
    when C_CSR_MHPMEVENT5 => return "mhpmevent5";
    when C_CSR_MHPMEVENT6 => return "mhpmevent6";
    when C_CSR_MHPMEVENT7 => return "mhpmevent7";
    when C_CSR_MHPMEVENT8 => return "mhpmevent8";
    when C_CSR_MHPMEVENT9 => return "mhpmevent9";
    when C_CSR_MHPMEVENT10 => return "mhpmevent10";
    when C_CSR_MHPMEVENT11 => return "mhpmevent11";
    when C_CSR_MHPMEVENT12 => return "mhpmevent12";
    when C_CSR_MHPMEVENT13 => return "mhpmevent13";
    when C_CSR_MHPMEVENT14 => return "mhpmevent14";
    when C_CSR_MHPMEVENT15 => return "mhpmevent15";
    when C_CSR_MHPMEVENT16 => return "mhpmevent16";
    when C_CSR_MHPMEVENT17 => return "mhpmevent17";
    when C_CSR_MHPMEVENT18 => return "mhpmevent18";
    when C_CSR_MHPMEVENT19 => return "mhpmevent19";
    when C_CSR_MHPMEVENT20 => return "mhpmevent20";
    when C_CSR_MHPMEVENT21 => return "mhpmevent21";
    when C_CSR_MHPMEVENT22 => return "mhpmevent22";
    when C_CSR_MHPMEVENT23 => return "mhpmevent23";
    when C_CSR_MHPMEVENT24 => return "mhpmevent24";
    when C_CSR_MHPMEVENT25 => return "mhpmevent25";
    when C_CSR_MHPMEVENT26 => return "mhpmevent26";
    when C_CSR_MHPMEVENT27 => return "mhpmevent27";
    when C_CSR_MHPMEVENT28 => return "mhpmevent28";
    when C_CSR_MHPMEVENT29 => return "mhpmevent29";
    when C_CSR_MHPMEVENT30 => return "mhpmevent30";
    when C_CSR_MHPMEVENT31 => return "mhpmevent31";
    when C_CSR_MSCRATCH => return "mscratch";
    when C_CSR_MEPC => return "mepc";
    when C_CSR_MCAUSE => return "mcause";
    when C_CSR_MTVAL => return "mtval";
    when C_CSR_MIP => return "mip";
    when C_CSR_MTINST => return "mtinst";
    when C_CSR_MTVAL2 => return "mtval2";
    when C_CSR_MENVCFG => return "menvcfg";
    when C_CSR_MENVCFGH => return "menvcfgh";
    when C_CSR_MSECCFG => return "mseccfg";
    when C_CSR_MSECCFGH => return "mseccfgh";
    when C_CSR_PMPCFG0 => return "pmpcfg0";
    when C_CSR_PMPCFG1 => return "pmpcfg1";
    when C_CSR_PMPCFG2 => return "pmpcfg2";
    when C_CSR_PMPCFG3 => return "pmpcfg3";
    when C_CSR_PMPCFG4 => return "pmpcfg4";
    when C_CSR_PMPCFG5 => return "pmpcfg5";
    when C_CSR_PMPCFG6 => return "pmpcfg6";
    when C_CSR_PMPCFG7 => return "pmpcfg7";
    when C_CSR_PMPCFG8 => return "pmpcfg8";
    when C_CSR_PMPCFG9 => return "pmpcfg9";
    when C_CSR_PMPCFG10 => return "pmpcfg10";
    when C_CSR_PMPCFG11 => return "pmpcfg11";
    when C_CSR_PMPCFG12 => return "pmpcfg12";
    when C_CSR_PMPCFG13 => return "pmpcfg13";
    when C_CSR_PMPCFG14 => return "pmpcfg14";
    when C_CSR_PMPCFG15 => return "pmpcfg15";
    when C_CSR_PMPADDR0 => return "pmpaddr0";
    when C_CSR_PMPADDR1 => return "pmpaddr1";
    when C_CSR_PMPADDR2 => return "pmpaddr2";
    when C_CSR_PMPADDR3 => return "pmpaddr3";
    when C_CSR_PMPADDR4 => return "pmpaddr4";
    when C_CSR_PMPADDR5 => return "pmpaddr5";
    when C_CSR_PMPADDR6 => return "pmpaddr6";
    when C_CSR_PMPADDR7 => return "pmpaddr7";
    when C_CSR_PMPADDR8 => return "pmpaddr8";
    when C_CSR_PMPADDR9 => return "pmpaddr9";
    when C_CSR_PMPADDR10 => return "pmpaddr10";
    when C_CSR_PMPADDR11 => return "pmpaddr11";
    when C_CSR_PMPADDR12 => return "pmpaddr12";
    when C_CSR_PMPADDR13 => return "pmpaddr13";
    when C_CSR_PMPADDR14 => return "pmpaddr14";
    when C_CSR_PMPADDR15 => return "pmpaddr15";
    when C_CSR_PMPADDR16 => return "pmpaddr16";
    when C_CSR_PMPADDR17 => return "pmpaddr17";
    when C_CSR_PMPADDR18 => return "pmpaddr18";
    when C_CSR_PMPADDR19 => return "pmpaddr19";
    when C_CSR_PMPADDR20 => return "pmpaddr20";
    when C_CSR_PMPADDR21 => return "pmpaddr21";
    when C_CSR_PMPADDR22 => return "pmpaddr22";
    when C_CSR_PMPADDR23 => return "pmpaddr23";
    when C_CSR_PMPADDR24 => return "pmpaddr24";
    when C_CSR_PMPADDR25 => return "pmpaddr25";
    when C_CSR_PMPADDR26 => return "pmpaddr26";
    when C_CSR_PMPADDR27 => return "pmpaddr27";
    when C_CSR_PMPADDR28 => return "pmpaddr28";
    when C_CSR_PMPADDR29 => return "pmpaddr29";
    when C_CSR_PMPADDR30 => return "pmpaddr30";
    when C_CSR_PMPADDR31 => return "pmpaddr31";
    when C_CSR_PMPADDR32 => return "pmpaddr32";
    when C_CSR_PMPADDR33 => return "pmpaddr33";
    when C_CSR_PMPADDR34 => return "pmpaddr34";
    when C_CSR_PMPADDR35 => return "pmpaddr35";
    when C_CSR_PMPADDR36 => return "pmpaddr36";
    when C_CSR_PMPADDR37 => return "pmpaddr37";
    when C_CSR_PMPADDR38 => return "pmpaddr38";
    when C_CSR_PMPADDR39 => return "pmpaddr39";
    when C_CSR_PMPADDR40 => return "pmpaddr40";
    when C_CSR_PMPADDR41 => return "pmpaddr41";
    when C_CSR_PMPADDR42 => return "pmpaddr42";
    when C_CSR_PMPADDR43 => return "pmpaddr43";
    when C_CSR_PMPADDR44 => return "pmpaddr44";
    when C_CSR_PMPADDR45 => return "pmpaddr45";
    when C_CSR_PMPADDR46 => return "pmpaddr46";
    when C_CSR_PMPADDR47 => return "pmpaddr47";
    when C_CSR_PMPADDR48 => return "pmpaddr48";
    when C_CSR_PMPADDR49 => return "pmpaddr49";
    when C_CSR_PMPADDR50 => return "pmpaddr50";
    when C_CSR_PMPADDR51 => return "pmpaddr51";
    when C_CSR_PMPADDR52 => return "pmpaddr52";
    when C_CSR_PMPADDR53 => return "pmpaddr53";
    when C_CSR_PMPADDR54 => return "pmpaddr54";
    when C_CSR_PMPADDR55 => return "pmpaddr55";
    when C_CSR_PMPADDR56 => return "pmpaddr56";
    when C_CSR_PMPADDR57 => return "pmpaddr57";
    when C_CSR_PMPADDR58 => return "pmpaddr58";
    when C_CSR_PMPADDR59 => return "pmpaddr59";
    when C_CSR_PMPADDR60 => return "pmpaddr60";
    when C_CSR_PMPADDR61 => return "pmpaddr61";
    when C_CSR_PMPADDR62 => return "pmpaddr62";
    when C_CSR_PMPADDR63 => return "pmpaddr63";
    when C_CSR_MCYCLE => return "mcycle";
    when C_CSR_MINSTRET => return "minstret";
    when C_CSR_MHPMCOUNTER3 => return "mhpmcounter3";
    when C_CSR_MHPMCOUNTER4 => return "mhpmcounter4";
    when C_CSR_MHPMCOUNTER5 => return "mhpmcounter5";
    when C_CSR_MHPMCOUNTER6 => return "mhpmcounter6";
    when C_CSR_MHPMCOUNTER7 => return "mhpmcounter7";
    when C_CSR_MHPMCOUNTER8 => return "mhpmcounter8";
    when C_CSR_MHPMCOUNTER9 => return "mhpmcounter9";
    when C_CSR_MHPMCOUNTER10 => return "mhpmcounter10";
    when C_CSR_MHPMCOUNTER11 => return "mhpmcounter11";
    when C_CSR_MHPMCOUNTER12 => return "mhpmcounter12";
    when C_CSR_MHPMCOUNTER13 => return "mhpmcounter13";
    when C_CSR_MHPMCOUNTER14 => return "mhpmcounter14";
    when C_CSR_MHPMCOUNTER15 => return "mhpmcounter15";
    when C_CSR_MHPMCOUNTER16 => return "mhpmcounter16";
    when C_CSR_MHPMCOUNTER17 => return "mhpmcounter17";
    when C_CSR_MHPMCOUNTER18 => return "mhpmcounter18";
    when C_CSR_MHPMCOUNTER19 => return "mhpmcounter19";
    when C_CSR_MHPMCOUNTER20 => return "mhpmcounter20";
    when C_CSR_MHPMCOUNTER21 => return "mhpmcounter21";
    when C_CSR_MHPMCOUNTER22 => return "mhpmcounter22";
    when C_CSR_MHPMCOUNTER23 => return "mhpmcounter23";
    when C_CSR_MHPMCOUNTER24 => return "mhpmcounter24";
    when C_CSR_MHPMCOUNTER25 => return "mhpmcounter25";
    when C_CSR_MHPMCOUNTER26 => return "mhpmcounter26";
    when C_CSR_MHPMCOUNTER27 => return "mhpmcounter27";
    when C_CSR_MHPMCOUNTER28 => return "mhpmcounter28";
    when C_CSR_MHPMCOUNTER29 => return "mhpmcounter29";
    when C_CSR_MHPMCOUNTER30 => return "mhpmcounter30";
    when C_CSR_MHPMCOUNTER31 => return "mhpmcounter31";
    when C_CSR_MCYCLEH => return "mcycleh";
    when C_CSR_MINSTRETH => return "minstreth";
    when C_CSR_MHPMCOUNTER3H => return "mhpmcounter3h";
    when C_CSR_MHPMCOUNTER4H => return "mhpmcounter4h";
    when C_CSR_MHPMCOUNTER5H => return "mhpmcounter5h";
    when C_CSR_MHPMCOUNTER6H => return "mhpmcounter6h";
    when C_CSR_MHPMCOUNTER7H => return "mhpmcounter7h";
    when C_CSR_MHPMCOUNTER8H => return "mhpmcounter8h";
    when C_CSR_MHPMCOUNTER9H => return "mhpmcounter9h";
    when C_CSR_MHPMCOUNTER10H => return "mhpmcounter10h";
    when C_CSR_MHPMCOUNTER11H => return "mhpmcounter11h";
    when C_CSR_MHPMCOUNTER12H => return "mhpmcounter12h";
    when C_CSR_MHPMCOUNTER13H => return "mhpmcounter13h";
    when C_CSR_MHPMCOUNTER14H => return "mhpmcounter14h";
    when C_CSR_MHPMCOUNTER15H => return "mhpmcounter15h";
    when C_CSR_MHPMCOUNTER16H => return "mhpmcounter16h";
    when C_CSR_MHPMCOUNTER17H => return "mhpmcounter17h";
    when C_CSR_MHPMCOUNTER18H => return "mhpmcounter18h";
    when C_CSR_MHPMCOUNTER19H => return "mhpmcounter19h";
    when C_CSR_MHPMCOUNTER20H => return "mhpmcounter20h";
    when C_CSR_MHPMCOUNTER21H => return "mhpmcounter21h";
    when C_CSR_MHPMCOUNTER22H => return "mhpmcounter22h";
    when C_CSR_MHPMCOUNTER23H => return "mhpmcounter23h";
    when C_CSR_MHPMCOUNTER24H => return "mhpmcounter24h";
    when C_CSR_MHPMCOUNTER25H => return "mhpmcounter25h";
    when C_CSR_MHPMCOUNTER26H => return "mhpmcounter26h";
    when C_CSR_MHPMCOUNTER27H => return "mhpmcounter27h";
    when C_CSR_MHPMCOUNTER28H => return "mhpmcounter28h";
    when C_CSR_MHPMCOUNTER29H => return "mhpmcounter29h";
    when C_CSR_MHPMCOUNTER30H => return "mhpmcounter30h";
    when C_CSR_MHPMCOUNTER31H => return "mhpmcounter31h";
    when C_CSR_TSELECT => return "tselect";
    when C_CSR_TDATA1 => return "tdata1";
    when C_CSR_TDATA2 => return "tdata2";
    when C_CSR_TDATA3 => return "tdata3";
    when C_CSR_MCONTEXT => return "mcontext";
    when C_CSR_DCSR => return "dcsr";
    when C_CSR_DPC => return "dpc";
    when C_CSR_DSCRATCH0 => return "dscratch0";
    when C_CSR_DSCRATCH1 => return "dscratch1";
    when others => return "unknown";
    end case;
  end function;

  function f_inst2str(inst : std_logic_vector; pc : std_logic_vector) return line is
    variable l    : line;
    variable op   : t_opcode := f_opcode(inst);
    variable f3   : t_f3 := f_f3(inst);
    variable f5   : t_f5 := f_f5(inst);
    variable f7   : t_f7 := f_f7(inst);
    variable f12  : t_f12 := f_f12(inst);
    variable rd   : t_reg_addr := f_rd(inst);
    variable rs1  : t_reg_addr := f_rs1(inst);
    variable rs2  : t_reg_addr := f_rs2(inst);
    variable csr  : t_csr_addr := f_csr_addr(inst);
    variable imm  : std_logic_vector(C_XLEN-1 downto 0) := f_imm(inst);
    variable t    : std_logic_vector(C_XLEN-1 downto 0);
    variable i    : integer := to_integer(signed(imm));
  begin
    case op is
    when C_OP_LUI =>
      write(l, "lui "&f_reg2str(rd)&", "&to_string(to_integer(unsigned(imm))));
    when C_OP_AUIPC =>
      t := std_logic_vector(unsigned(pc) + unsigned(imm));
      write(l, "auipc "&f_reg2str(rd)&", "&to_hstring(t));
    when C_OP_JAL =>
      t := std_logic_vector(unsigned(pc) + unsigned(imm));
      write(l, "jal "&f_reg2str(rd)&", "&to_hstring(t));
    when C_OP_BRANCH =>
      case f3 is
      when C_F3_B_BEQ | C_F3_B_BNE | C_F3_B_BLT | C_F3_B_BGE | C_F3_B_BLTU | C_F3_B_BGEU =>
        t := std_logic_vector(unsigned(pc) + unsigned(imm));
        write(l, f_branch2str(f3)&" "&f_reg2str(rs1)&", "&f_reg2str(rs2)&", "&to_hstring(t));
      when others =>
        write(l, string'("Unknown instruction"));
      end case;
    when C_OP_JALR =>
      if f3 = C_F3_I_JALR then
        write(l, "jalr "&f_reg2str(rd)&", "&to_hstring(imm)&"("&f_reg2str(rs1)&")");
      else
        write(l, string'("Unknown instruction"));
      end if;
    when C_OP_LOAD =>
      case f3 is
      when C_F3_I_LB | C_F3_I_LH | C_F3_I_LW | C_F3_I_LBU | C_F3_I_LHU =>
        write(l, f_load2str(f3)&" "&f_reg2str(rd)&", "&to_string(i)&"("&f_reg2str(rs1)&")");
      when others =>
        write(l, string'("Unknown instruction"));
      end case;
    when C_OP_IMM =>
      write(l, f_opimm2str(f3, f12)&" "&f_reg2str(rd)&", "&f_reg2str(rs1)&", "&to_string(i));
    when C_OP_FENCE =>
      write(l, f_fence2str(f3));
    when C_OP_SYSTEM =>
      if f3 = C_F3_I_PRIV then
        write(l, f_sys_priv2str(f3, f12));
      else
        case f3 is
        when C_F3_I_CSRRW | C_F3_I_CSRRS | C_F3_I_CSRRC =>
          write(l, f_sys_csr2str(f3)&" "&f_reg2str(rd)&", "&f_csr2str(csr)&", "&f_reg2str(rs1));
        when C_F3_I_CSRRWI | C_F3_I_CSRRSI | C_F3_I_CSRRCI =>
          write(l, f_sys_csr2str(f3)&" "&f_reg2str(rd)&", "&f_csr2str(csr)&", "&to_string(i));
        when others =>
          write(l, string'("Unknown instruction"));
        end case;
      end if;
    when C_OP_STORE =>
      case f3 is
      when C_F3_S_SB | C_F3_S_SH | C_F3_S_SW  =>
        write(l, f_store2str(f3)&" "&f_reg2str(rs2)&", "&to_string(i)&"("&f_reg2str(rs1)&")");
      when others =>
        write(l, string'("Unknown instruction"));
      end case;
    when C_OP_REG =>
      write(l, f_opreg2str(f3, f7, f12)&" "&f_reg2str(rd)&", "&f_reg2str(rs1)&", "&f_reg2str(rs2));
    when C_OP_AMO =>
      case f5 is
      when C_F5_S_LR | C_F5_S_SC =>
        write(l, f_amo2str(f5)&" "&f_reg2str(rd)&", "&f_reg2str(rs2)&", ("&f_reg2str(rs1)&")");
      when others =>
        write(l, string'("Unknown instruction"));
      end case;
    when others =>
      write(l, string'("Unknown instruction"));
    end case;
    return l;
  end function;

  function f_alu2str(alu_op : t_alu_opcode) return string is
  begin
    case f_alu_op2slv(alu_op) is
    when f_alu_op2slv(C_ALU_ADD)        => return "ADD";
    when f_alu_op2slv(C_ALU_EQ)         => return "EQ";
    when f_alu_op2slv(C_ALU_SUB)        => return "SUB";
    when f_alu_op2slv(C_ALU_SLT)        => return "SLT";
    when f_alu_op2slv(C_ALU_SLTU)       => return "SLTU";
    when f_alu_op2slv(C_ALU_SH1ADD)     => return "SH1ADD";
    when f_alu_op2slv(C_ALU_SH2ADD)     => return "SH2ADD";
    when f_alu_op2slv(C_ALU_SH3ADD)     => return "SH3ADD";
    when f_alu_op2slv(C_ALU_MIN)        => return "MIN";
    when f_alu_op2slv(C_ALU_MINU)       => return "MINU";
    when f_alu_op2slv(C_ALU_MAX)        => return "MAX";
    when f_alu_op2slv(C_ALU_MAXU)       => return "MAXU";
    when f_alu_op2slv(C_ALU_XOR)        => return "XOR";
    when f_alu_op2slv(C_ALU_OR)         => return "OR";
    when f_alu_op2slv(C_ALU_AND)        => return "AND";
    when f_alu_op2slv(C_ALU_XNOR)       => return "XNOR";
    when f_alu_op2slv(C_ALU_ORN)        => return "ORN";
    when f_alu_op2slv(C_ALU_ANDN)       => return "ANDN";
    when f_alu_op2slv(C_ALU_ORC)        => return "ORC";
    when f_alu_op2slv(C_ALU_CZERO_EQZ)  => return "CZERO_EQZ";
    when f_alu_op2slv(C_ALU_CZERO_NEZ)  => return "CZERO_NEZ";
    when f_alu_op2slv(C_ALU_ZEXTH)      => return "ZEXT.H";
    when f_alu_op2slv(C_ALU_SEXTB)      => return "SEXT.B";
    when f_alu_op2slv(C_ALU_SEXTH)      => return "SEXT.H";
    when f_alu_op2slv(C_ALU_SLL)        => return "SLL";
    when f_alu_op2slv(C_ALU_SRL)        => return "SRL";
    when f_alu_op2slv(C_ALU_SRA)        => return "SRA";
    when f_alu_op2slv(C_ALU_ROL)        => return "ROL";
    when f_alu_op2slv(C_ALU_ROR)        => return "ROR";
    when f_alu_op2slv(C_ALU_BCLR)       => return "BCLR";
    when f_alu_op2slv(C_ALU_BEXT)       => return "BEXT";
    when f_alu_op2slv(C_ALU_BINV)       => return "BINV";
    when f_alu_op2slv(C_ALU_BSET)       => return "BSET";
    when f_alu_op2slv(C_ALU_MOVB)       => return "MOVB";
    when f_alu_op2slv(C_ALU_CLZ)        => return "CLZ";
    when f_alu_op2slv(C_ALU_CTZ)        => return "CTZ";
    when f_alu_op2slv(C_ALU_CPOP)       => return "CPOP";
    when f_alu_op2slv(C_ALU_REV8)       => return "REV8";
    when f_alu_op2slv(C_ALU_CLMUL)      => return "CLMUL";
    when f_alu_op2slv(C_ALU_CLMULH)     => return "CLMULH";
    when f_alu_op2slv(C_ALU_CLMULR)     => return "CLMULR";
    when others                         => return "xxx";
    end case;
  end function;

end package body riscv_disas_pkg;