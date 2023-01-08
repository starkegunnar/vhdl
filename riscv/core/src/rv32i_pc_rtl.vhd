--! @defgroup   RV32I_PC_RTL rv 32 i pc rtl
--!
--! @brief      This file implements rv 32 i pc rtl.
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

entity rv32i_pc is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    en    : in  std_logic;
    set   : in  std_logic_vector;
    pci   : in  std_logic_vector(t_xlen_range);
    pc    : out std_logic_vector(t_xlen_range)
  );
end entity rv32i_pc;

