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

entity rv32i_alu is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    en      : in  std_logic;
    stall   : in  std_logic;

    alu_op  : in  std_logic_vector(t_alu_op_range);
    op1     : in  std_logic_vector(t_xlen_range);
    op2     : in  std_logic_vector(t_xlen_range);

    valid   : out std_logic;
    busy    : out std_logic;
    res     : out std_logic_vector(t_xlen_range)
  );
end entity rv32i_alu;

architecture rtl of rv32i_alu is

  signal is_sub         : std_logic;
  signal is_sra         : std_logic;
  signal sub_res        : unsigned(t_xlen_range);
  signal c              : std_ulogic;
  signal v              : std_logic;
  signal n              : std_logic;
  signal shamt          : natural range 0 to c_xlen_hi;
  signal illegal_shamt  : std_logic;
  signal srl_res        : std_logic_vector(t_xlen_range);
  signal sll_res        : std_logic_vector(t_xlen_range);

begin

  busy <= '0'; -- All ops are single cycle

  (c, sub_res) <= ('0' & unsigned(op1)) - ('0' & unsigned(op2));
  n <= std_logic(sub_res(c_xlen_hi));
  v <= (n xor op1(c_xlen_hi)) and (op1(c_xlen_hi) xor op2(c_xlen_hi));

  shamt         <= to_integer(unsigned(op2(4 downto 0)));
  illegal_shamt <= op2(5);

  is_sub <= alu_op(alu_op'high);
  is_sra <= alu_op(alu_op'high);

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

  p_alu : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        case alu_op(alu_op'high - 1 downto 0) is
        when c_alu_op_sll(alu_op'high - 1 downto 0) =>
          -- Shift left logical
          res                         <= (others => '0');
          res(res'high downto shamt)  <= op1(op1'high - shamt downto 0);
        when c_alu_op_slt(alu_op'high - 1 downto 0) =>
          -- Set if less than
          res <= (res'high downto 1 => '0') & (n xor v);
        when c_alu_op_sltu(alu_op'high - 1 downto 0)=>
          -- Set if less than (unsigned)
          res <= (res'high downto 1 => '0') & (not c);
        when c_alu_op_xor(alu_op'high - 1 downto 0) =>
          -- XOR
          res <= op1 xor op2;
        when c_alu_op_srl(alu_op'high - 1 downto 0) =>
          -- Shift right (logical/arithmetic)
          res                             <= (others => is_sra and op1(op1'high));
          res(res'high - shamt downto 0)  <= op1(op1'high downto shamt);
        when c_alu_op_or(alu_op'high - 1 downto 0)  =>
          -- OR
          res <= op1 or op2;
        when c_alu_op_and(alu_op'high - 1 downto 0) =>
          -- AND
          res <= op1 and op2;
        when others =>
          -- Default add/sub
          if is_sub = '1' then
            res <= std_logic_vector(sub_res);
          else
            res <= std_logic_vector(unsigned(op1) + unsigned(op2));
          end if;
        end case;
      end if;
    end if;
  end process p_alu;

end architecture rtl;