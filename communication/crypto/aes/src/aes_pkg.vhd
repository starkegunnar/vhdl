--! @defgroup   AES_PKG aes package
--!
--! @brief      This file implements AES package.
--!
--! @author     Martin Caous George
--! @date       2025
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library lib_common;
use lib_common.common_pkg.all;

--! AES package
--!
package aes_pkg is

  -- AES block is column major indexed, ie:
  -- 0,0 : blk(7 downto 0),   0,1 : blk(39 downto 32), 0,2 : blk(71 downto 64), 0,3 : blk(103 downto 96),
  -- 1,0 : blk(15 downto 8),  1,1 : blk(47 downto 40), 1,2 : blk(79 downto 72), 1,3 : blk(111 downto 104),
  -- 2,0 : blk(23 downto 16), 2,1 : blk(55 downto 48), 2,2 : blk(87 downto 80), 2,3 : blk(119 downto 112),
  -- 3,0 : blk(31 downto 24), 3,1 : blk(63 downto 56), 3,2 : blk(95 downto 88), 3,3 : blk(127 downto 120)
  type t_aes_blk is array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);

  --function f_std2blk(std : std_logic_vector) return t_aes_blk;
  --function f_blk2std(blk : t_aes_blk) return std_logic_vector;

  function f_shift_rows(blk : t_aes_blk) return t_aes_blk;

  function f_gmix_columns(blk : t_aes_blk) return t_aes_blk;

  subtype t_sbox is t_slv_array(0 to 255)(7 downto 0);

  function f_init_sbox return t_sbox;
  function f_inverse_sbox(sbox : t_sbox) return t_sbox;

end package aes_pkg;

package body aes_pkg is

/*
  #define ROTL8(x,shift) ((uint8_t) ((x) << (shift)) | ((x) >> (8 - (shift))))

  void initialize_aes_sbox(uint8_t sbox[256]) {
  	uint8_t p = 1, q = 1;

  	// loop invariant: p * q == 1 in the Galois field
  	do {
  		// multiply p by 3
  		p = p ^ (p << 1) ^ (p & 0x80 ? 0x1B : 0);

  		// divide q by 3 (equals multiplication by 0xf6)
  		q ^= q << 1;
  		q ^= q << 2;
  		q ^= q << 4;
  		q ^= q & 0x80 ? 0x09 : 0;

  		// compute the affine transformation
  		uint8_t xformed = q ^ ROTL8(q, 1) ^ ROTL8(q, 2) ^ ROTL8(q, 3) ^ ROTL8(q, 4);

  		sbox[p] = xformed ^ 0x63;
  	} while (p != 1);

  	// 0 is a special case since it has no inverse
  	sbox[0] = 0x63;
  }
*/
  function f_init_sbox return t_sbox is
    variable v_p, v_q   : unsigned(7 downto 0) := x"01";
    variable v_tmp      : unsigned(7 downto 0);
    variable v_xformed  : unsigned(7 downto 0);
    variable v_sbox     : t_sbox;
  begin
    loop
      -- Multiply v_p by 3
      v_p := v_p xor shift_left(v_p, 1) xor (x"1B" and v_p(7));

      -- Divide v_q by 3 (equals multiplication by 0xf6)
      v_q := v_q xor shift_left(v_q, 1);
      v_q := v_q xor shift_left(v_q, 2);
      v_q := v_q xor shift_left(v_q, 4);
      v_q := v_q xor x"09" when (v_q and x"80") /= 0 else v_q xor x"00";

      -- Compute the affine transformation
      v_xformed := v_q xor rotate_left(v_q, 1) xor rotate_left(v_q, 2) xor rotate_left(v_q, 3) xor rotate_left(v_q, 4);

      v_sbox(to_integer(v_p)) := std_logic_vector(v_xformed xor x"63");

      exit when v_p = x"01";
    end loop;

    -- 0 is a special case since it has no inverse
    v_sbox(0) := x"63";

    return v_sbox;
  end function f_init_sbox;

  function f_inverse_sbox(sbox : t_sbox) return t_sbox is
    variable v_sbox_inv : t_sbox;
  begin
    for i in 0 to 255 loop
      v_sbox_inv(to_integer(unsigned(sbox(i)))) := std_logic_vector(to_unsigned(i,8));
    end loop;
    return v_sbox_inv;
  end function f_inverse_sbox;

  function f_shift_rows(blk : t_aes_blk) return t_aes_blk is
    variable v_blk : t_aes_blk;
  begin
    for c in 0 to 3 loop
      for r in 0 to 3 loop
        v_blk(r,c) := blk(r,(r+c) mod 4);
      end loop;
    end loop;
    return v_blk;
  end function f_shift_rows;

/*
  void gmix_column(unsigned char *r) {
    unsigned char a[4];
    unsigned char b[4];
    unsigned char c;
    unsigned char h;
    // The array 'a' is simply a copy of the input array 'r'
    // The array 'b' is each element of the array 'a' multiplied by 2
    // in Rijndael's Galois field
    // a[n] ^ b[n] is element n multiplied by 3 in Rijndael's Galois field
    for (c = 0; c < 4; c++) {
        a[c] = r[c];
        // h is set to 0x01 if the high bit of r[c] is set, 0x00 otherwise
        h = r[c] >> 7;    // logical right shift, thus shifting in zeros
        b[c] = r[c] << 1; // implicitly removes high bit because b[c] is an 8-bit char, so we xor by 0x1b and not 0x11b in the next line
        b[c] ^= h * 0x1B; // Rijndael's Galois field
    }
    r[0] = b[0] ^ a[3] ^ a[2] ^ b[1] ^ a[1]; // 2 * a0 + a3 + a2 + 3 * a1
    r[1] = b[1] ^ a[0] ^ a[3] ^ b[2] ^ a[2]; // 2 * a1 + a0 + a3 + 3 * a2
    r[2] = b[2] ^ a[1] ^ a[0] ^ b[3] ^ a[3]; // 2 * a2 + a1 + a0 + 3 * a3
    r[3] = b[3] ^ a[2] ^ a[1] ^ b[0] ^ a[0]; // 2 * a3 + a2 + a1 + 3 * a0
}
*/

  function f_gmix_columns(blk : t_aes_blk) return t_aes_blk is
    variable v_blk  : t_aes_blk;
    variable v_b    : t_slv_array(0 to 3)(7 downto 0);
  begin
    for c in 0 to 3 loop
      for r in 0 to 3 loop
        v_b(r) := blk(r,c)(6 downto 0) & '0';
        if blk(r,c)(7) = '1' then
          v_b(r) := v_b(r) xor x"1B";
        end if;
      end loop;
      v_blk(0,c) := v_b(0) xor blk(3,c) xor blk(2,c) xor v_b(1) xor blk(1,c);
      v_blk(1,c) := v_b(1) xor blk(0,c) xor blk(3,c) xor v_b(2) xor blk(2,c);
      v_blk(2,c) := v_b(2) xor blk(1,c) xor blk(0,c) xor v_b(3) xor blk(3,c);
      v_blk(3,c) := v_b(3) xor blk(2,c) xor blk(1,c) xor v_b(0) xor blk(0,c);
    end loop;
    return v_blk;
  end function f_gmix_columns;

end package body aes_pkg;