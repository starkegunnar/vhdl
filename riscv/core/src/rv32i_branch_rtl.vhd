--! @defgroup   RV32I_ALU_RTL RV32I alu rtl
--!
--! @brief      This file implements RV32I alu rtl.
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

entity rv32i_branch is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    en      : in  std_logic;
    stall   : in  std_logic;

    br_op   : in  std_logic_vector(t_f3_range);
    r1      : in  std_logic_vector(t_xlen_range);
    r2      : in  std_logic_vector(t_xlen_range);

    valid   : out std_logic;
    busy    : out std_logic;
    brtake  : out std_logic
  );
end entity rv32i_branch;

architecture rtl of rv32i_branch is

  signal cmp  : unsigned(t_xlen_range);
  signal c    : std_ulogic;
  signal v    : std_logic;
  signal n    : std_logic;
  signal lt   : std_logic;
  signal eq   : std_logic;
  signal ltu  : std_logic;

begin

  (c, cmp) <= ('0' & unsigned(r1)) - ('0' & unsigned(r2));

  n   <= std_logic(cmp(c_xlen_hi));
  v   <= (n xor r1(c_xlen_hi)) and (r1(c_xlen_hi) xor r2(c_xlen_hi));
  lt  <= n xor v;
  eq  <= '1' when cmp = 0 else '0';
  ltu <= std_logic(c);

  busy <= '0';

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

  p_compare : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        case br_op is
        when c_f3_branch_beq  => brtake <= eq;
        when c_f3_branch_bne  => brtake <= not eq;
        when c_f3_branch_blt  => brtake <= lt;
        when c_f3_branch_bge  => brtake <= not lt;
        when c_f3_branch_bltu => brtake <= ltu;
        when c_f3_branch_bgeu => brtake <= not ltu;
        when others           => brtake <= '0';
        end case;
      end if;
    end if;
  end process p_compare;

end architecture rtl;