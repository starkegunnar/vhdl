library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;
use lib_riscvim.random_2008.all;

entity div_tb is
end entity div_tb;

architecture tb of div_tb is

  constant c_ndiv : natural := 4;

  type t_div is record
    valid     : std_logic;
    ready     : std_logic;
    ctrl      : t_div_ctrl;
    op_a      : t_wordx;
    op_b      : t_wordx;
    res       : t_wordx;
    res_valid : std_logic;
  end record;

  type t_div_array is array(natural range <>) of t_div;

  type t_div_generics is record
    radix4      : boolean;
    fast_shift  : boolean;
  end record;

  type t_div_generics_array is array(natural range <>) of t_div_generics;

  constant c_div_generics : t_div_generics_array(0 to c_ndiv-1) := (
    (radix4 => false, fast_shift => false),
    (radix4 => false, fast_shift => true),
    (radix4 => true,  fast_shift => false),
    (radix4 => true,  fast_shift => true)
  );

  type t_stim is record
    a : t_wordx;
    b : t_wordx;
  end record;

  type t_stim_array is array(natural range <>) of t_stim;

  function f_stim_init(n : natural) return t_stim_array is
    variable v : t_stim_array(0 to n-1);
  begin
    v(0).a := random(32);
    v(0).a := random(32);
    v(0).b := (others => '0');
    v(1).a := x"80000000";
    v(1).b := x"ffffffff";
    v(2).a := x"00000000";
    v(2).b := x"00000002";
    v(3).a := x"00000055";
    v(3).b := x"00000056";
    for i in 4 to 9 loop
      v(i).a := x"0000" & random(16);
      v(i).b := x"0000" & "00" & random(14);
    end loop;
    for i in 10 to 15 loop
      v(i).a := random(32);
      v(i).b := random(32);
    end loop;
    return v;
  end function;

  constant c_stim : t_stim_array(0 to 15) := f_stim_init(16);

  signal clk  : std_logic := '1';
  signal rst  : std_logic := '1';
  signal div  : t_div_array(0 to 5);
  signal stim : t_stim_array(0 to 15);

begin

  clk <= not clk after 5 ns;
  rst <= '0' after 40 ns;

  b_div : for i in 0 to c_ndiv-1 generate

    i_div : entity lib_riscvim.div
    generic map (
      g_radix4      => c_div_generics(i).radix4,
      g_fast_shift  => c_div_generics(i).fast_shift
    )
    port map (
      clk       => clk,
      rst       => rst,
      valid     => div(i).valid,
      ready     => div(i).ready,
      halt      => '0',
      ctrl      => div(i).ctrl,
      op_a      => div(i).op_a,
      op_b      => div(i).op_b,
      res_valid => div(i).res_valid,
      res       => div(i).res
    );

    p_test : process
    begin
      div(i).valid      <= '0';
      div(i).ctrl.drem  <= '0';
      div(i).ctrl.signx <= '0';
      div(i).op_a       <= (others => '0');
      div(i).op_b       <= (others => '0');
      wait until rising_edge(clk);
      wait until rst = '0';
      wait until rising_edge(clk);

      for j in 0 to 15 loop
        div(i).op_a   <= c_stim(j).a;
        div(i).op_b   <= c_stim(j).b;
        div(i).valid  <= '1';

        while div(i).ready = '1' loop
          wait until rising_edge(clk);
        end loop;
        div(i).valid  <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk) and div(i).res_valid = '1';
      end loop;

      div(i).ctrl.signx <= '1';
      wait until rising_edge(clk);

      for j in 0 to 15 loop
        div(i).op_a   <= c_stim(j).a;
        div(i).op_b   <= c_stim(j).b;
        div(i).valid  <= '1';

        while div(i).ready = '1' loop
          wait until rising_edge(clk);
        end loop;
        div(i).valid  <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk) and div(i).res_valid = '1';
      end loop;


      wait;
    end process;

  end generate b_div;

end architecture;