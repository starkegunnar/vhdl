--! @defgroup   RV32_REGISTER_FILE_RTL rv 32 register file rtl
--!
--! @brief      This file implements rv 32 register file rtl.
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

entity rv32i_register_file is
  port (
    clk   : in  std_logic;
    en    : in  std_logic;                      -- Register read enable
    rs1   : in  std_logic_vector(t_rsel_range); -- Register select 1
    rs2   : in  std_logic_vector(t_rsel_range); -- Register select 2
    rd    : in  std_logic_vector(t_rsel_range); -- Register destination
    we    : in  std_logic;                      -- Write enable destination
    wd    : in  std_logic_vector(t_xlen_range); -- Write data
    r1    : out std_logic_vector(t_xlen_range); -- Register 1 data
    r2    : out std_logic_vector(t_xlen_range)  -- Register 2 data
  );
end entity rv32i_register_file;

architecture rtl of rv32i_register_file is

  signal xregs : t_slv_array(t_xlen_range)(t_xlen_range) := (others => (others => '0'));

begin

  p_regs : process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        xregs(to_integer(unsigned(rd))) <= wd;
      end if;
    end if ;
  end process;

  r1 <= xregs(to_integer(unsigned(rs1)));
  r2 <= xregs(to_integer(unsigned(rs2)));

end architecture rtl;