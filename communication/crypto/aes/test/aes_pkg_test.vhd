library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_aes;
use lib_aes.aes_pkg.all;

entity aes_pkg_test is
end entity aes_pkg_test;

architecture tb of aes_pkg_test is

  type t_blk_array is array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);

  signal sbox, sbox_inverse : t_sbox;
  signal shift_in, shift_out : t_aes_blk;
  signal mix_in, mix_out : t_aes_blk;

begin

  sbox <= f_init_sbox;
  sbox_inverse <= f_inverse_sbox(sbox);

  b_gen : for i in 0 to 15 generate
    shift_in(i mod 4, i/4) <= std_logic_vector(to_unsigned(i+1,8));
  end generate b_gen;

  shift_out <= f_shift_rows(shift_in);

  mix_in <= ((x"63",x"f2",x"01",x"c6"),(x"47", x"0a", x"01", x"c6"),(x"a2", x"22", x"01", x"c6"),(x"f0", x"5c", x"01", x"c6"));

  mix_out <= f_gmix_columns(mix_in);
end architecture tb;