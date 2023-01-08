--! @defgroup   RV32I_ALU_TB RV2I ALU testbench
--!
--! @brief      This file implements RV32I ALU testbench.
--!
--! @author     Martin
--! @date       2022
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_riscv;
use lib_riscv.rv32i_pkg.all;

entity rv32_core_tb is
end entity rv32_core_tb;

architecture sim of rv32_core_tb is

  constant c_instr_mem_bytes  : natural := 2**14;
  constant c_clk_period       : time := 10 ns;
  constant c_rst_period       : time := 20 ns;

  type t_int_file is file of integer;

  --"/home/martin/projects/riscv/target/share/riscv-tests/isa/rv32ui-p-simple"

  impure function fn_fill_instr return t_slv_array is
    file obj_file   : t_int_file;
    variable v_res  : t_slv_array(0 to (c_instr_mem_bytes / 4)-1)(t_xlen_range) := (others => (others => '0'));
    variable v_word : integer;
    variable v_i    : natural := 0;
  begin
    file_open(obj_file, "../test/stimuli/rv32ui-p-add");
    while v_i < v_res'length and not endfile(obj_file) loop
      read(obj_file, v_word);
      v_res(v_i) := std_logic_vector(to_unsigned(v_word, c_xlen));
      v_i := v_i + 1;
    end loop;
    file_close(obj_file);
    return v_res;
  end function;

  signal instr_mem  : t_slv_array(0 to (c_instr_mem_bytes / 4)-1)(t_xlen_range) := (others => (others => '0')); -- 16 kB
  signal data_mem   : t_slv_array(0 to (c_instr_mem_bytes / 4)-1)(t_xlen_range) := (others => (others => '0')); -- 16 kB

  signal done     : boolean := false;
  signal clk      : std_logic := '1';
  signal rst      : std_logic := '1';
  signal rst_cnt  : natural := 5;
  signal pc       : std_logic_vector(t_xlen_range) := (others => '0');
  signal instr    : std_logic_vector(t_xlen_range) := (others => '0');
  signal ce       : std_logic := '0';
  signal pc_out   : std_logic_vector(t_xlen_range) := (others => '0');
  signal daddr    : std_logic_vector(t_xlen_range) := (others => '0');
  signal ren      : std_logic := '0';
  signal rvalid   : std_logic := '0';
  signal rdata    : std_logic_vector(t_xlen_range) := (others => '0');
  signal wen      : std_logic := '0';
  signal wdata    : std_logic_vector(t_xlen_range) := (others => '0');

begin

  done <= true after 10 us;
  clk <= '0' when done else not clk after c_clk_period / 2;
  p_rst : process(clk)
  begin
    if rising_edge(clk) then
      if 0 < rst_cnt then
        rst_cnt <= rst_cnt - 1;
      else
        rst <= '0';
      end if;
    end if;
  end process;

  p_fill : process
  begin
    instr_mem <= fn_fill_instr;
    wait;
  end process;

  p_instr : process(clk)
  begin
    if rising_edge(clk) then
      if ce = '1' then
        instr   <= instr_mem(to_integer(unsigned(pc(13 downto 2))));
      end if;
    end if;
  end process;

  i_dut : entity lib_riscv.rv32_core(rtl)
  port map (
    clk     => clk,
    rst     => rst,
    -- Instruction mem
    ce      => ce,
    pc      => pc,
    inst    => instr,
    -- Data mem
    daddr   => daddr,
    ren     => ren,
    rvalid  => rvalid,
    rdata   => rdata,
    wen     => wen,
    wdata   => wdata
  );

end architecture sim;
