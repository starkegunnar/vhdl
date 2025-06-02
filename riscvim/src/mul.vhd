library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity mul is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    op_valid    : in  std_logic;
    op_ready    : out std_logic;
    halt        : in  std_logic;
    kill        : in  std_logic;

    ctrl        : in  t_muldiv_ctrl;
    op_a        : in  t_wordx;
    op_b        : in  t_wordx;

    res_valid   : out std_logic;
    res_ready   : in  std_logic;
    res         : out t_wordx
  );
end entity mul;

architecture rtl of mul is

  type t_mul_state is (mul_mac0, mul_mac1, mul_mac2, mul_mac3);

  type t_mul_reg is record
    state : t_mul_state;
    mac   : signed(c_x_w+1 downto 0);
    valid : std_logic;
    ready : std_logic;
  end record;

  signal r, rn : t_mul_reg;

  -- pragma translate_off
  signal prod_test  : signed(c_2x_w+1 downto 0);
  signal prod_hi    : t_wordx;
  signal prod_lo    : t_wordx;
  -- pragma translate_on

begin

  p_comb : process(all)
    variable v            : t_mul_reg;
    variable op_hi        : std_logic_vector(1 downto 0);
    variable op_sign      : std_logic_vector(1 downto 0);
    variable mul_op_a     : signed(c_hx_w downto 0);
    variable mul_op_b     : signed(c_hx_w downto 0);
    variable shamt        : unsigned(4 downto 0);
    variable mul_prod     : signed(c_x_w+1 downto 0);
    variable valid        : std_logic;
    variable ready        : std_logic;
  begin
    -- Default values
    v := r;

    op_hi   := "00";
    op_sign := "00";

    shamt := "00000";

    valid := '0';
    ready := '0';

    -- MULH(S/U)
    -- albl
    -- ahbl + (albl >> 16)
    -- albh + (ahbl + (albl >> 16))
    -- ahbh + ((albh + (ahbl + (albl >> 16))) >> 16)

    -- MUL
    -- ahbl
    -- albh + ahbl
    -- albl + ((albh + ahbl) << 16)

    case r.state is
    when mul_mac0 =>
      if ctrl.mode = '1' then
        -- albl
        op_hi   := "00";
        op_sign := "00";
        v.state := mul_mac1;
      else
        -- ahbl
        op_hi   := "01";
        op_sign := '0' & ctrl.signa;
        v.state := mul_mac2;
      end if;
    when mul_mac1 =>
      -- ahbl
      op_hi   := "01";
      op_sign := '0' & ctrl.signa;
      shamt   := "10000";
      v.state := mul_mac2;
    when mul_mac2 =>
      -- albh
      op_hi   := "10";
      op_sign := ctrl.signb & '0';
      v.state := mul_mac3;
    when mul_mac3 =>
      shamt   := "10000";
      if ctrl.mode = '1' then
        -- ahbh
        op_hi   := "11";
        op_sign := ctrl.signb & ctrl.signa;
      else
        -- albl
        op_hi   := "00";
        op_sign := "00";
      end if;
      valid   := '1';
      if res_ready = '1' then
        ready   := '1';
        v.state := mul_mac0;
      end if;
    when others =>
    end case;

    if op_hi(0) = '1' then
      mul_op_a(t_hx_range) := signed(op_a(t_hx_hi_range));
    else
      mul_op_a(t_hx_range) := signed(op_a(t_hx_lo_range));
    end if;
    if op_hi(1) = '1' then
      mul_op_b(t_hx_range) := signed(op_b(t_hx_hi_range));
    else
      mul_op_b(t_hx_range) := signed(op_b(t_hx_lo_range));
    end if;
    mul_op_a(c_hx_w) := op_sign(0) and mul_op_a(c_hxhi);
    mul_op_b(c_hx_w) := op_sign(1) and mul_op_b(c_hxhi);

    mul_prod := mul_op_a * mul_op_b;

    if r.state = mul_mac3 then
      if res_ready = '1' then
        v.mac := (others => '0');
      end if;
    elsif ctrl.mode = '1' then
      v.mac := mul_prod + shift_right(r.mac, to_integer(shamt));
    else
      v.mac := mul_prod + shift_left(r.mac, to_integer(shamt));
    end if;

    if op_valid = '0' or kill = '1' then
      valid := '0';
      ready := '1';
    elsif halt = '1' then
      valid := '0';
      ready := '0';
    end if;

    if rst = '1' or kill = '1' then
      v.state := mul_mac0;
      v.mac   := (others => '0');
    end if;

    op_ready  <= ready;
    res_valid <= valid;
    res       <= std_logic_vector(v.mac(t_x_range));

    rn <= v;
  end process;

  p_reg : process(clk)
  begin
    if rising_edge(clk) then
      if (op_valid = '1' and halt = '0') or kill = '1' then
        r <= rn;
      end if;
    end if;
  end process;

  -- pragma translate_off
  prod_test <= signed((ctrl.signa and op_a(c_xhi)) & op_a) * signed((ctrl.signb and op_b(c_xhi)) & op_b);
  (prod_hi, prod_lo) <= std_logic_vector(prod_test(c_2x_w-1 downto 0));
  -- pragma translate_on

end architecture rtl;
