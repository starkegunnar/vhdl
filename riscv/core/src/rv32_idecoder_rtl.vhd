--! @defgroup   RV32_IDECODER_RTL RISCV 32 instruction decoder rtl
--!
--! @brief      This file implements RTL RISCV 32 instruction decoder rtl.
--!
--! @author     Martin
--! @date       2022
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

-- library lib_common;
-- use lib_common.common_pkg.all;

library lib_riscv;
use lib_riscv.rv32i_pkg.all;

entity rv32_idecoder is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    en        : in  std_logic;
    stall     : in  std_logic;

    inst      : in  std_logic_vector(t_xlen_range); -- Instruction

    valid     : out std_logic;                          -- Instruction is valid
    opcode    : out t_opcode;
    alu_op    : out std_logic_vector(t_alu_op_range);   -- ALU operation code
    op1_sel   : out std_logic;       -- '1' PC,  '0' R1
    op2_sel   : out std_logic;       -- '1' IMM, '0' R2
    imm       : out std_logic_vector(t_xlen_range);     -- Immediate
    jal       : out std_logic;                          -- JAL(R)
    br_op     : out std_logic_vector(t_f3_range);       -- Branch compare operation
    br_en     : out std_logic;                          -- Branch enable
    ecall     : out std_logic;                          --
    ebreak    : out std_logic;                          --
    mret      : out std_logic;                          -- Return from machine privilege
    csr_op    : out std_logic_vector(t_f3_range);       -- CSR operation
    csr_addr  : out std_logic_vector(t_csr_addr_range); -- CSR operation address
    csr_we    : out std_logic;                          -- CSR operation write enable
    ex_sel    : out std_logic_vector(1 downto 0);       -- MULDIV "11", CSR "10", IMM "01", ALU "00"
    mem_read  : out std_logic;                          -- Instruction requires read memory access
    mem_write : out std_logic;                          -- Instruction requires write memory access
    wb        : out std_logic;                          -- Instruction requires writeback
    wb_sel    : out std_logic;                          -- MEM '1', Execute result '0'
    rd        : out std_logic_vector(t_rsel_range);     -- Destination register select
    ill_inst  : out std_logic
  );
end entity rv32_idecoder;

architecture rtl of rv32_idecoder is

  signal valid_op     : std_logic;
  signal opcode_comb  : t_opcode;

begin

  p_valid : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        valid <= '1';
      elsif stall = '0' then
        valid <= '0';
      end if;

      if rst = '1' then
        valid <= '0';
      end if;
    end if;
  end process;

  p_opcode_comb : process(clk)
  begin
    case inst(t_opcode_inst_range) is
    when c_opcode_lui =>
      opcode_comb <= op_lui;
    when c_opcode_jal =>
      opcode_comb <= op_jal;
    when c_opcode_jalr =>
      opcode_comb <= op_jalr;
    when c_opcode_auipc =>
      opcode_comb <= op_auipc;
    when c_opcode_branch =>
      opcode_comb <= op_branch;
    when c_opcode_load =>
      opcode_comb <= op_load;
    when c_opcode_store =>
      opcode_comb <= op_store;
    when c_opcode_op_imm =>
      opcode_comb <= op_op_imm;
    when c_opcode_op =>
      opcode_comb <= op_op;
    when c_opcode_fence =>
      opcode_comb <= op_fence;
    when c_opcode_system =>
      opcode_comb <= op_system;
    when others =>
      opcode_comb <= op_unsupported;
    end case;
  end process;

  p_opcode : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        opcode <= opcode_comb;
      end if;
    end if;
  end process;

  -- Illegal instruction
  p_ill_inst : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        ill_inst <= '0';
        if inst(4 downto 2) = "111" or inst(1 downto 0) /= "11" then
          -- 32-bit instructions are illegal if inst[4:2]  = "111"
          -- 32-bit instructions are illegal if inst[1:0] /= "11"
          -- We do not support 16-bit instructions at this point
          ill_inst <= '1';
        else
          case inst(t_opcode_inst_range) is
          when c_opcode_lui =>
          when c_opcode_jal =>
          when c_opcode_jalr =>
          when c_opcode_auipc =>
          when c_opcode_branch =>
          when c_opcode_load =>
          when c_opcode_store =>
          when c_opcode_op_imm =>
          when c_opcode_op =>
          when c_opcode_fence =>
          when c_opcode_system =>
          when others =>
            -- Unsupported instruction
            ill_inst <= '1';
          end case;
        end if;
      end if;
    end if;
  end process;

  -- Jump and link (register)
  p_jal : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        jal <= '0';
        if inst(t_opcode_inst_range) = c_opcode_jal or inst(t_opcode_inst_range) = c_opcode_jalr then
          jal <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Branch control
  p_branch : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        br_op <= inst(t_f3_inst_range);
        br_en <= '0';
        if inst(t_opcode_inst_range) = c_opcode_branch then
          br_en <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Execute stage select
  -- ALU, MULDIV, CSR, IMM
  p_ex_sel : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        -- Default, ALU op
        ex_sel <= (others => '0');
        case inst(t_opcode_inst_range) is
        when c_opcode_lui =>
          -- MOV imm op
          ex_sel <= c_ex_sel_imm;
        when c_opcode_op =>
          if inst(c_f7_inst_lo) = '1' then
            -- MULDIV op
            ex_sel <= c_ex_sel_muldiv;
          end if;
        when c_opcode_system =>
            -- CSR op
          ex_sel <= c_ex_sel_csr;
        when others =>
        end case;
      end if;
    end if;
  end process;

  p_alu_op : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        alu_op <= c_alu_op_add;
        case inst(t_opcode_inst_range) is
        when c_opcode_op_imm =>
          if inst(t_f3_inst_range) = c_f3_opimm_srai then
            alu_op <= inst(c_f7_inst_hi - 1) & inst(t_f3_inst_range);
          else
            alu_op <= '0' & inst(t_f3_inst_range);
          end if;
        when c_opcode_op =>
          alu_op <= inst(c_f7_inst_hi - 1) & inst(t_f3_inst_range);
        when others =>
        end case;
      end if;
    end if;
  end process;

  p_imm : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        case inst(t_opcode_inst_range) is
        when c_opcode_lui | c_opcode_auipc =>
          -- U-type instruction
          imm <= inst(c_immu_31_12_hi downto c_immu_31_12_lo) & (c_immu_31_12_lo - 1 downto 0 => '0');
        when c_opcode_jal =>
          -- J-type instruction
          imm <= std_logic_vector(resize(signed(inst(c_immj_20) & inst(c_immj_19_12_hi downto c_immj_19_12_lo) & inst(c_immj_11) & inst(c_immj_10_1_hi downto c_immj_10_1_lo) & '0'), imm'length));
        when c_opcode_branch =>
          -- B-type instruction
          imm <= std_logic_vector(resize(signed(inst(c_immb_12) & inst(c_immb_11) & inst(c_immb_10_5_hi downto c_immb_10_5_lo) & inst(c_immb_4_1_hi downto c_immb_4_1_lo) & '0'), imm'length));
        when c_opcode_store =>
          -- S-type instruction
          imm <= std_logic_vector(resize(signed(inst(c_imms_11_5_hi downto c_imms_11_5_lo) & inst(c_imms_4_0_hi downto c_imms_4_0_lo)), imm'length));
        when c_opcode_system =>
          imm <= std_logic_vector(resize(unsigned(inst(t_rs1_range)), c_xlen));
        when others =>
          -- I-type instruction
          imm <= std_logic_vector(resize(signed(inst(c_immi_hi downto c_immi_lo)), imm'length));
        end case;
      end if;
    end if;
  end process;

  -- Execution stage operator select
  p_op_sel : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        -- "10" PC, "01" Imm, "00" Rx
        case inst(t_opcode_inst_range) is
        when c_opcode_jal | c_opcode_branch | c_opcode_auipc =>
          -- op pc imm
          op1_sel <= '1';
          op2_sel <= '1';
        when c_opcode_op =>
          -- op r1 r2
          op1_sel <= '0';
          op2_sel <= '0';
        when others =>
          -- op r1 imm
          op1_sel <= '0';
          op2_sel <= '1';
        end case;
      end if;
    end if;
  end process;

  p_sys : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        ecall   <= '0';
        ebreak  <= '0';
        mret    <= '0';
        if inst(t_opcode_inst_range) = c_opcode_system and or_reduce(inst(t_f3_inst_range)) = '0' then
          case inst(t_f12_inst_range) is
          when c_f12_system_ecall =>
            ecall <= '1';
          when c_f12_system_ebreak =>
            ebreak <= '1';
          when c_f12_system_mret =>
            mret <= '1';
          when others =>
          end case;
        end if;
      end if;
    end if;
  end process;

  p_csr : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        csr_we    <= '1';
        csr_addr  <= inst(t_csr_addr_inst_range);
        csr_op    <= inst(t_f3_inst_range);
        if or_reduce(inst(t_rs1_range)) = '0' then
          csr_we <= not inst(c_f3_inst_hi - 1);
        end if;
      end if;
    end if;
  end process;

  -- Memory access
  p_mem_access : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        mem_read  <= '0';
        mem_write <= '0';
        if inst(t_opcode_inst_range) = c_opcode_load then
          mem_read  <= '1';
        elsif inst(t_opcode_inst_range) = c_opcode_store then
          mem_write <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Write back select
  p_wb : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        wb <= '1';
        if or_reduce(inst(t_rd_range)) = '0' then
          -- Never write back if register address (rd) is zero
          wb <= '0';
        else
          case inst(t_opcode_inst_range) is
          when c_opcode_branch | c_opcode_store | c_opcode_fence =>
            wb <= '0';
          when c_opcode_system =>
            if or_reduce(inst(t_f3_inst_range)) = '0' then
              wb <= '0';
            end if;
          when others =>
          end case;
        end if;
      end if;
    end if;
  end process;

  -- MEM "100", "011" MULDIV, "010" PC_NEXT, "001" CSR, "000" ALU
  p_wb_sel : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        wb_sel <= '0';
        if inst(t_opcode_inst_range) = c_opcode_load then
          wb_sel <= '1';
        end if;
      end if;
    end if;
  end process;

  p_rd : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        rd <= inst(t_rd_range);
      end if;
    end if;
  end process;

end architecture rtl;