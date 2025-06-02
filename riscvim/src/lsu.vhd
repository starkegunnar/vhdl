library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity lsu is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    id_valid    : in  std_logic;
    ex_ready    : out std_logic;
    ex_valid    : out std_logic;
    wb_ready    : in  std_logic;

    halt        : in  std_logic;
    kill        : in  std_logic;

    ctrl        : in  t_muldiv_ctrl;
    op_a        : in  t_wordx;
    op_b        : in  t_wordx;
    op_c        : in  t_wordx;

    res         : out t_wordx
  );
end entity lsu;

architecture rtl of lsu is

begin


end architecture rtl;
