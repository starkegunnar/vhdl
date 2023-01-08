--! @defgroup   RV32_CORE_RTL RV32 core rtl
--!
--! @brief      This file implements RV32 core rtl.
--!
--! @author     Martin
--! @date       2022
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_riscv;
use lib_riscv.rv32i_pkg.all;

entity rv32_core is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;

    ce      : out std_logic;
    pc      : out std_logic_vector(t_xlen_range);
    inst    : in  std_logic_vector(t_xlen_range);

    daddr   : out std_logic_vector(t_xlen_range);
    ren     : out std_logic;
    rvalid  : in  std_logic;
    rdata   : in  std_logic_vector(t_xlen_range);
    wen     : out std_logic;
    wdata   : out std_logic_vector(t_xlen_range)
  );
end entity rv32_core;

architecture rtl of rv32_core is

  signal pc_ce, pc_stall, pc_valid : std_logic := '0';  -- Program counter
  signal if_ce, if_stall, if_valid : std_logic := '0';  -- Intruction fetch
  signal id_ce, id_stall, id_valid : std_logic := '0';  -- Intruction decode
  signal ex_ce, ex_stall, ex_valid : std_logic := '0';  -- Execute
  signal ma_ce, ma_stall, ma_valid : std_logic := '0';  -- Memory access
  signal wb_ce, wb_stall, wb_valid : std_logic := '0';  -- Writeback

  signal clr    : std_logic := '0';
  signal stall  : std_logic_vector(3 downto 0) := (others => '0');

  signal pc_if          : std_logic_vector(t_xlen_range);

  signal id2ex          : t_idecode2execute;
  --signal execute        : t_execute;
  signal ex2mem         : t_execute2mem;
  signal mem2wb         : t_mem2writeback;
  signal r1, r2         : std_logic_vector(t_xlen_range);
  signal pc_r, pc_set   : std_logic_vector(t_xlen_range);
  signal br_take        : std_logic;
  signal op1, op2       : std_logic_vector(t_xlen_range);
  signal epc_set        : std_logic;
  signal epc            : std_logic_vector(t_xlen_range);
  signal jump           : std_logic;

  signal regs_hazard    : std_logic;
  signal alu_en, br_en, muldiv_en, csr_en   : std_logic;
  signal muldiv_busy, csr_busy              : std_logic;
  signal alu_valid, br_valid, muldiv_valid, csr_valid : std_logic;
  signal alu_res, muldiv_res, csr_res       : std_logic_vector(t_xlen_range);

  signal ex_res         : std_logic_vector(t_xlen_range);
  signal mem_busy       : std_logic;
  signal wb_data        : std_logic_vector(t_xlen_range);

  signal r1_used        : std_logic;
  signal r2_used        : std_logic;
  signal r1_ex_hazard, r1_mem_hazard, r1_wb_hazard : std_logic;
  signal r2_ex_hazard, r2_mem_hazard, r2_wb_hazard : std_logic;
  signal r1_fwd_sel     : std_logic_vector(1 downto 0);
  signal r2_fwd_sel     : std_logic_vector(1 downto 0);

begin

  pc <= pc_r;

  pc_stall  <= '0';
  pc_ce     <= not if_stall;

  jump <= alu_valid and ((br_valid and br_take) or ex2mem.jal);

  clr <= epc_set or jump;

  p_pc : process(clk)
  begin
    if rising_edge(clk) then
      if pc_ce = '1' or jump = '1' or epc_set = '1' then
        pc_valid  <= '1';
      elsif if_ce = '1' then
        pc_valid  <= '0';
      end if;
      if epc_set = '1' then
        pc_r <= epc;
      elsif jump = '1' then
        pc_r <= alu_res;
      elsif pc_ce = '1' and pc_valid = '1' then
        pc_r <= std_logic_vector(unsigned(pc_r) + 4);
      end if;
      if rst = '1' then
        pc_valid  <= '0';
        pc_r      <= (others => '0');
      end if;
    end if;
  end process;

  if_stall  <= (if_valid and id_stall);
  if_ce     <= pc_valid and not if_stall;
  ce        <= if_ce;

  p_if : process(clk)
  begin
    if rising_edge(clk) then
      if if_ce = '1' then
        if_valid <= '1';
      elsif id_ce = '1' then
        if_valid <= '0';
      end if;

      if if_ce = '1' then
        pc_if <= pc_r;
      end if;

      if rst = '1' or clr = '1' then
        if_valid <= '0';
      end if;
    end if;
  end process;

  id_ce     <= if_valid and not id_stall;
  id_stall  <= (id_valid and ex_stall) or (if_valid and regs_hazard);
  --id_valid  <= id2ex.valid;

  i_decode : entity lib_riscv.rv32_idecoder(rtl)
  port map (
    clk       => clk,
    rst       => rst or clr,
    en        => id_ce,
    stall     => id_stall,
    inst      => inst,
    valid     => id2ex.valid,
    opcode    => id2ex.opcode,
    alu_op    => id2ex.alu_op,
    op1_sel   => id2ex.op1_sel,
    op2_sel   => id2ex.op2_sel,
    imm       => id2ex.imm,
    jal       => id2ex.jal,
    br_op     => id2ex.br_op,
    br_en     => id2ex.br_en,
    ecall     => id2ex.ecall,
    ebreak    => id2ex.ebreak,
    mret      => id2ex.mret,
    csr_op    => id2ex.csr_op,
    csr_addr  => id2ex.csr_addr,
    csr_we    => id2ex.csr_we,
    ex_sel    => id2ex.ex_sel,
    mem_read  => id2ex.mem_read,
    mem_write => id2ex.mem_write,
    wb        => id2ex.wb,
    wb_sel    => id2ex.wb_sel,
    rd        => id2ex.rd,
    ill_inst  => open
  );

  i_registers : entity lib_riscv.rv32i_register_file(rtl)
  port map (
    clk     => clk,
    en      => id_ce,
    rs1     => inst(t_rs1_range),
    rs2     => inst(t_rs2_range),
    rd      => mem2wb.rd,
    we      => mem2wb.wb and ma_valid,
    wd      => wb_data,
    r1      => r1,
    r2      => r2
  );

  p_regs_used : process(all)
  begin
    case inst(t_opcode_inst_range) is
    when c_opcode_lui =>
      r1_used <= '0';
      r2_used <= '0';
    when c_opcode_auipc =>
      r1_used <= '0';
      r2_used <= '0';
    when c_opcode_jal =>
      r1_used <= '0';
      r2_used <= '0';
    when c_opcode_branch =>
      r1_used <= '1';
      r2_used <= '1';
    when c_opcode_jalr =>
      r1_used <= '1';
      r2_used <= '0';
    when c_opcode_load =>
      r1_used <= '1';
      r2_used <= '0';
    when c_opcode_op_imm =>
      r1_used <= '1';
      r2_used <= '0';
    when c_opcode_fence =>
      r1_used <= '0';
      r2_used <= '0';
    when c_opcode_system =>
      r1_used <= '1';
      r2_used <= '0';
    when c_opcode_store =>
      r1_used <= '1';
      r2_used <= '1';
    when c_opcode_op =>
      r1_used <= '1';
      r2_used <= '1';
    when others =>
      r1_used <= '0';
      r2_used <= '0';
    end case;
  end process;

  r1_ex_hazard  <= r1_used when (id_valid and id2ex.wb ) = '1' and inst(t_rs1_range) = id2ex.rd else '0';
  r1_mem_hazard <= r1_used when (ex_valid and ex2mem.wb) = '1' and inst(t_rs1_range) = ex2mem.rd else '0';
  r1_wb_hazard  <= r1_used when (ma_valid and mem2wb.wb) = '1' and inst(t_rs1_range) = mem2wb.rd else '0';
  r2_ex_hazard  <= r2_used when (id_valid and id2ex.wb ) = '1' and inst(t_rs2_range) = id2ex.rd else '0';
  r2_mem_hazard <= r2_used when (ex_valid and ex2mem.wb) = '1' and inst(t_rs2_range) = ex2mem.rd else '0';
  r2_wb_hazard  <= r2_used when (ma_valid and mem2wb.wb) = '1' and inst(t_rs2_range) = mem2wb.rd else '0';

  r1_fwd_sel <= r1_mem_hazard & r1_wb_hazard;
  r2_fwd_sel <= r2_mem_hazard & r2_wb_hazard;

  regs_hazard <= r1_ex_hazard or r2_ex_hazard or ((r1_mem_hazard or r2_mem_hazard) and ex2mem.mem_read);

  p_id_valid : process(clk)
  begin
    if rising_edge(clk) then
      if id_ce = '1' then
        id_valid <= '1';
      elsif ex_ce = '1' then
        id_valid <= '0';
      end if;

      if rst = '1' or clr = '1' then
        id_valid    <= '0';
      end if;
    end if;
  end process;

  p_pc_id : process(clk)
  begin
    if rising_edge(clk) then
      if id_ce = '1' then
        id2ex.pc  <= pc_if;
        id2ex.rs1 <= inst(t_rs1_range);
        id2ex.rs2 <= inst(t_rs2_range);
        id2ex.r1  <= r1;
        id2ex.r2  <= r2;
        if r1_mem_hazard = '1' then
          id2ex.r1  <= ex_res;
        elsif r1_wb_hazard = '1' then
          id2ex.r1  <= wb_data;
        end if;
        if r2_mem_hazard = '1' then
          id2ex.r2  <= ex_res;
        elsif r2_wb_hazard = '1' then
          id2ex.r2  <= wb_data;
        end if;
      end if;
    end if;
  end process;

  ex_stall  <= (ex_valid and ma_stall) or (id_valid and (muldiv_busy or csr_busy));
  ex_ce     <= id_valid and not ex_stall;

  alu_en    <= ex_ce                  when id2ex.ex_sel = c_ex_sel_alu    else
               ex_ce                  when id2ex.ex_sel = c_ex_sel_imm    else
               '0';
  br_en     <= ex_ce and id2ex.br_en  when id2ex.ex_sel = c_ex_sel_alu    else '0';
  csr_en    <= ex_ce                  when id2ex.ex_sel = c_ex_sel_csr    else '0';
  muldiv_en <= ex_ce                  when id2ex.ex_sel = c_ex_sel_muldiv else '0';

  -- Operator select (TODO: hazard detection and forwarding)
  -- Move to separate pipe stage?
  op1 <= id2ex.pc   when id2ex.op1_sel = '1' else
         id2ex.r1;
  op2 <= id2ex.imm  when id2ex.op2_sel = '1' else
         id2ex.r2;

  i_alu : entity lib_riscv.rv32i_alu(rtl)
  port map (
    clk     => clk,
    rst     => rst or clr,
    en      => alu_en,
    stall   => ex_stall,
    alu_op  => id2ex.alu_op,
    op1     => op1,
    op2     => op2,
    valid   => alu_valid,
    busy    => open,
    res     => alu_res
  );

  i_branch_compare : entity lib_riscv.rv32i_branch(rtl)
  port map (
    clk     => clk,
    rst     => rst or clr,
    en      => br_en,
    stall   => ex_stall,
    br_op   => id2ex.br_op,
    r1      => id2ex.r1,
    r2      => id2ex.r2,
    valid   => br_valid,
    busy    => open,
    brtake  => br_take
  );

  i_csr : entity lib_riscv.rv32i_csr(rtl)
  port map (
    clk       => clk,
    rst       => rst,
    clr       => clr,
    en        => csr_en,
    stall     => ex_stall,
    csr_op    => id2ex.csr_op,
    csr_addr  => id2ex.csr_addr,
    csr_re    => id2ex.wb,
    csr_we    => id2ex.csr_we,
    r1        => id2ex.r1,
    imm       => id2ex.imm,
    instret   => ex_ce,
    pc        => ex2mem.pc,
    epc_set   => epc_set,
    epc       => epc,
    excp_inst_breakpoint          => open,
    excp_inst_page_fault          => open,
    excp_inst_access_fault        => open,
    excp_inst_illegal             => open,
    excp_inst_addr_misalign       => open,
    excp_ecall                    => id2ex.ecall,
    excp_env_breakpoint           => id2ex.ebreak,
    excp_load_breakpoint          => open,
    excp_store_amo_breakpoint     => open,
    excp_load_addr_misalign       => open,
    excp_store_amo_addr_misalign  => open,
    excp_load_page_fault          => open,
    excp_store_amo_page_fault     => open,
    excp_load_access_fault        => open,
    excp_store_amo_access_fault   => open,
    excp_ext_int                  => open,
    mret                          => id2ex.mret,
    valid     => csr_valid,
    busy      => csr_busy,
    res       => csr_res
  );

  i_muldiv : entity lib_riscv.rv32m_muldiv(rtl)
  port map (
    clk     => clk,
    rst     => rst or clr,
    en      => muldiv_en,
    stall   => ex_stall,
    aluop   => id2ex.alu_op,
    op1     => id2ex.r1,
    op2     => id2ex.r2,
    valid   => muldiv_valid,
    busy    => muldiv_busy,
    res     => muldiv_res
  );

  p_ex : process(clk)
  begin
    if rising_edge(clk) then
      if ex_ce = '1' then
        ex2mem.opcode     <= id2ex.opcode;
        ex2mem.pc         <= id2ex.pc;
        ex2mem.pc_next    <= pc_if;
        ex2mem.jal        <= id2ex.jal;
        ex2mem.r2         <= id2ex.r2;
        ex2mem.imm        <= id2ex.imm;
        ex2mem.ex_sel     <= id2ex.ex_sel;
        ex2mem.mem_read   <= id2ex.mem_read;
        ex2mem.mem_write  <= id2ex.mem_write;
        ex2mem.wb         <= id2ex.wb;
        ex2mem.wb_sel     <= id2ex.wb_sel;
        ex2mem.rd         <= id2ex.rd;
      end if;
    end if;
  end process;

  ex_valid  <= alu_valid or csr_valid or muldiv_valid;

  ma_ce     <= ex_valid and not ma_stall;
  ma_stall  <= ex_valid and mem_busy;

  daddr   <= alu_res;
  ren     <= ex2mem.mem_read;
  wen     <= ex2mem.mem_write;
  wdata   <= ex2mem.r2;

  ex_res <= ex2mem.imm      when ex2mem.ex_sel = c_ex_sel_imm else
            csr_res         when ex2mem.ex_sel = c_ex_sel_csr else
            muldiv_res      when ex2mem.ex_sel = c_ex_sel_muldiv else
            ex2mem.pc_next  when ex2mem.ex_sel = c_ex_sel_alu and ex2mem.jal = '1' else
            alu_res;

  p_ma : process(clk)
  begin
    if rising_edge(clk) then
      ma_valid <= '0';
      if ma_ce = '1' then
        if ex2mem.mem_read = '1' and mem_busy = '0' then
          mem_busy <= '1';
        else
          ma_valid <= '1';
        end if;
        mem2wb.opcode <= ex2mem.opcode;
        mem2wb.ex_res <= ex_res;
        mem2wb.wb     <= ex2mem.wb;
        mem2wb.wb_sel <= ex2mem.wb_sel;
        mem2wb.rd     <= ex2mem.rd;
      elsif mem_busy = '1' then
        ma_valid <= '1';
        mem_busy <= '0';
      end if;

      if rst = '1' then
        ma_valid  <= '0';
        mem_busy  <= '0';
      end if;
    end if;
  end process;

  wb_data <= rdata when mem2wb.wb_sel = '1' else mem2wb.ex_res;

end architecture rtl;
