library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity div is
  generic (
    g_radix4      : boolean := false;
    g_fast_shift  : boolean := false
  );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    valid       : in  std_logic;
    ready       : out std_logic;
    halt        : in  std_logic;
    kill        : in  std_logic;

    ctrl        : in  t_muldiv_ctrl;
    op_a        : in  t_wordx;
    op_b        : in  t_wordx;

    res_valid   : out std_logic;
    res_ready   : in  std_logic;
    res         : out t_wordx
  );
end entity div;

architecture rtl of div is

  type t_div_state is (div_idle, div_shifting, div_running, div_stopping);

  type t_div_reg is record
    state         : t_div_state;
    mode          : std_logic;
    dividend      : t_uwordx;
    divisor_pre   : t_uwordx;
    divisor       : t_uwordx;
    quotient      : t_uwordx;
    quotient_mask : t_uwordx;
    res_inv       : std_ulogic;
    result        : t_wordx;
    valid         : std_logic;
    ready         : std_logic;
  end record;

  signal r, rn : t_div_reg;

  -- pragma translate_off
  signal div_test  : t_wordx;
  signal rem_test  : t_wordx;
  -- pragma translate_on

begin

  p_comb : process(all)
    variable v            : t_div_reg;
    variable signx        : std_logic;
    variable neg_a        : std_ulogic;
    variable neg_b        : std_ulogic;
    variable op_a_abs     : t_uwordx;
    variable op_b_abs     : t_uwordx;
    variable clz_a        : std_logic_vector(4 downto 0);
    variable clz_b        : std_logic_vector(4 downto 0);
    variable shamt        : unsigned(4 downto 0);
    variable shamt_cout   : std_ulogic;
    variable div_zero     : std_logic;
    variable rem_zero     : std_logic;
    variable sub_x3       : unsigned(c_x_w downto 0);
    variable sub_x3_cout  : std_ulogic;
    variable sub_x2       : unsigned(c_x_w downto 0);
    variable sub_x2_cout  : std_ulogic;
    variable sub_x1       : unsigned(c_x_w-1 downto 0);
    variable sub_x1_cout  : std_ulogic;
    variable result       : t_uwordx;
  begin
    -- Default values
    v := r;

    -- Both operands are either signed or unsigned
    signx := ctrl.signa;

    -- Signed op with negative values
    neg_a := signx and op_a(op_a'high);
    neg_b := signx and op_b(op_b'high);

    op_a_abs := unsigned(neg_a xor op_a) + neg_a;
    op_b_abs := unsigned(neg_b xor op_b) + neg_b;

    -- Division by zero
    div_zero := nor op_b;

    -- Zero remainder
    rem_zero := nor r.dividend;

    -- Shift amount
    clz_a := f_alu_misc_clz(std_logic_vector(r.dividend));
    clz_b := f_alu_misc_clz(std_logic_vector(r.divisor_pre));
    if g_fast_shift then
      (shamt_cout, shamt) := unsigned('0' & clz_b) - unsigned(clz_a);
      if g_radix4 then
        shamt(0) := '0';
      end if;
    else
      shamt_cout  := '0';
      shamt       := (others => '0');
    end if;

    (sub_x1_cout, sub_x1) := ('0' & r.dividend) - r.divisor;
    (sub_x2_cout, sub_x2) := ("00" & r.dividend) - (r.divisor & '0');
    (sub_x3_cout, sub_x3) := ("00" & r.dividend) - ((r.divisor & '0') + r.divisor);

    case r.state is
    when div_idle =>
      v.mode      := ctrl.mode;
      v.res_inv   := signx and ((op_a(op_a'high) and ctrl.mode) or ((op_a(op_a'high) xor op_b(op_b'high)) and not div_zero));
      v.dividend  := op_a_abs;
      v.quotient  := (others => div_zero);
      if not g_fast_shift then
        v.divisor       := op_b_abs;
        v.quotient_mask := to_unsigned(1, v.quotient_mask'length);
      else
        v.divisor_pre := op_b_abs;
      end if;
      if r.valid = '1' and res_ready = '1' then
        v.valid := '0';
      end if;
      if valid = '1' and (r.valid = '0' or res_ready = '1') then
        v.ready := '0';
        v.valid := '0';
        if div_zero = '1' then
          v.state := div_stopping;
        else
          v.state := div_shifting;
        end if;
      end if;

    when div_shifting =>
      if g_fast_shift then
        v.divisor       := shift_left(r.divisor_pre, to_integer(shamt));
        v.quotient_mask := (others => '0');
        v.quotient_mask(to_integer(shamt)) := '1';
        if shamt_cout = '1' then
          v.state := div_stopping;
        else
          v.state := div_running;
        end if;
      else
        if g_radix4 and sub_x3_cout = '0' and sub_x2_cout = '0' and sub_x1_cout = '0' and
           r.divisor(r.divisor'high downto r.divisor'high-1) = "00" then
          v.divisor       := shift_left(r.divisor, 2);
          v.quotient_mask := shift_left(r.quotient_mask, 2);
        elsif not g_radix4 and sub_x1_cout = '0' and r.divisor(r.divisor'high) = '0' then
          v.divisor       := shift_left(r.divisor, 1);
          v.quotient_mask := shift_left(r.quotient_mask, 1);
        else
          v.state := div_running;
        end if;
      end if;

    when div_running =>
      if g_radix4 and sub_x3_cout = '0' then
        v.dividend := sub_x3(v.dividend'range);
        v.quotient := r.quotient or r.quotient_mask(r.quotient_mask'high-1 downto 0) & '0' or r.quotient_mask;
      elsif g_radix4 and sub_x2_cout = '0' then
        v.dividend := sub_x2(v.dividend'range);
        v.quotient := r.quotient or r.quotient_mask(r.quotient_mask'high-1 downto 0) & '0';
      elsif sub_x1_cout = '0' then
        v.dividend := sub_x1(v.dividend'range);
        v.quotient := r.quotient or r.quotient_mask;
      end if;
      v.divisor       := shift_right(r.divisor, 1+g_radix4);
      v.quotient_mask := shift_right(r.quotient_mask, 1+g_radix4);

      if r.quotient_mask(0) = '1' or rem_zero = '1' then
        v.state := div_stopping;
      end if;

    when div_stopping =>
      if r.mode = '1' then
        result := r.dividend;
      else
        result := r.quotient;
      end if;
      v.result  := std_logic_vector((r.res_inv xor result) + r.res_inv);
      v.ready   := '1';
      v.valid   := '1';
      v.state   := div_idle;

    when others =>
    end case;

    if rst = '1' or kill = '1' then
      v.state   := div_idle;
      v.ready   := '1';
      v.valid   := '0';
    end if;

    ready     <= r.ready;
    res_valid <= r.valid;
    res       <= r.result;

    rn <= v;
  end process;

  p_reg : process(clk)
  begin
    if rising_edge(clk) then
      r <= rn;
    end if;
  end process;

  -- pragma translate_off
  p_test : process(clk)
  begin
    if rising_edge(clk) then
      if valid = '1' and ready = '1' then
        if unsigned(op_b) = 0 then
          div_test <= (others => '1');
          rem_test <= op_a;
        elsif ctrl.signa = '1' then
          div_test <= std_logic_vector(signed(op_a) / signed(op_b));
          rem_test <= std_logic_vector(signed(op_a) rem signed(op_b));
        else
          div_test <= std_logic_vector(unsigned(op_a) / unsigned(op_b));
          rem_test <= std_logic_vector(unsigned(op_a) rem unsigned(op_b));
        end if;
      end if;
    end if;
  end process;
      -- pragma translate_on

end architecture rtl;
