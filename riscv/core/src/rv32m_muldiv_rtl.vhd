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
use ieee.std_logic_misc.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_riscv;
use lib_riscv.rv32i_pkg.all;

entity rv32m_muldiv is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    en      : in  std_logic;
    stall   : in  std_logic;

    aluop   : in  std_logic_vector(t_alu_op_range);
    op1     : in  std_logic_vector(t_xlen_range);
    op2     : in  std_logic_vector(t_xlen_range);

    valid   : out std_logic;
    busy    : out std_logic;
    res     : out std_logic_vector(t_xlen_range) := (others => '0')
  );
end entity rv32m_muldiv;

architecture rtl of rv32m_muldiv is

  signal mul_en       : std_logic;
  signal mul_valid    : std_logic;
  signal mul_busy     : std_logic;
  signal mul_opa_s    : std_logic;
  signal mul_opb_s    : std_logic;
  signal mul_sel      : std_logic;
  signal prod_comb    : signed(2*c_xlen - 1 downto 0);
  signal prod_resv    : signed(1 downto 0);
  signal uprod_comb   : unsigned(2*c_xlen + 1 downto 0);
  signal prod         : std_logic_vector(t_xlen_range);
  signal a            : unsigned(31 downto 0);
  signal b            : unsigned(31 downto 0);
  signal b_ext        : unsigned(32 downto 0);
  signal a_n          : unsigned(32 downto 0);
  signal b_n          : unsigned(32 downto 0);
  signal ah, al, bh, bl : unsigned(15 downto 0);
  signal ahbh         : unsigned(31 downto 0);
  signal ahbl         : unsigned(31 downto 0);
  signal albh         : unsigned(31 downto 0);
  signal albl         : unsigned(31 downto 0);
  signal ahbl_albh    : unsigned(32 downto 0);
  signal s            : unsigned(32 downto 0);
  signal prod_test    : unsigned(63 downto 0);
  signal sign_sel     : std_logic_vector(1 downto 0);
  signal valid_shift  : std_logic_vector(2 downto 0);
  signal prod_sel     : std_logic_vector(2 downto 0);

  signal div_en       : std_logic;
  signal div_signed   : std_logic;
  signal div_sel      : std_logic;
  signal div_busy     : std_logic;
  signal div_valid    : std_logic;
  signal div_res      : std_logic_vector(t_xlen_range);

begin

--  0 : MUL     : -000 : signed * signed, return low product
--  1 : MULH    : -001 : signed * signed, return high product
--  2 : MULHSU  : -010 : signed * unsigned, return high product
--  3 : MULHU   : -011 : unsigned * unsigned, return high product

  mul_en    <= en and not aluop(2);
  mul_opa_s <= aluop(1) nand aluop(0);
  mul_opb_s <= not aluop(1);
  mul_sel   <= '1' when aluop(1 downto 0) = "00" else '0';

  --(prod_resv, prod_comb) <= signed((mul_opa_s and op1(op1'high)) & op1) * signed((mul_opb_s and op2(op2'high)) & op2);

  -- a(31)           <= std_ulogic(not op1(op1'high)) when mul_opa_s = '1' else std_ulogic(op1(op1'high));
  -- a(30 downto 0)  <= unsigned(op1(30 downto 0));
  -- b(31)           <= std_ulogic(not op2(op2'high)) when mul_opb_s = '1' else std_ulogic(op2(op2'high));
  -- b(30 downto 0)  <= unsigned(op2(30 downto 0));

  -- b_ext <= '0' & b;
  -- b_n   <= unsigned(-signed(b_ext));
  -- a_n   <= x"8000_0000" - (('0' & a) + ('0' & b));

  -- s <= a_n when mul_opa_s = '1' and mul_opb_s = '1' else
  --      b_n when mul_opa_s = '1' and mul_opb_s = '0' else
  --      (others => '0');


  -- ahbh <= ah * bh;
  -- ahbl <= ah * bl;
  -- albh <= al * bh;
  -- albl <= al * bl;

  --ahbl_albh <= ('0' & ahbl_r) + ('0' & albh_r);

  -- (ah, al) <= a;
  -- (bh, bl) <= b;

  p_pipe_mul : process(clk)
    variable v_ah, v_al, v_bh, v_bl : unsigned(15 downto 0);
    variable v_ahbh : unsigned(31 downto 0);
    variable v_ahbl : unsigned(31 downto 0);
    variable v_albh : unsigned(31 downto 0);
    variable v_albl : unsigned(31 downto 0);
    variable v_b    : unsigned(32 downto 0);
  begin
    if rising_edge(clk) then
        valid_shift <= valid_shift(valid_shift'high - 1 downto 0) & mul_en;
        prod_sel    <= prod_sel(prod_sel'high - 1 downto 0) & mul_sel;
        sign_sel(1 downto 0) <= mul_opa_s & mul_opb_s;

        -- clk 0, register operands
        a <= unsigned(op1);
        if mul_opa_s = '1' then
          a(31) <= std_ulogic(not op1(op1'high));
        end if;
        b <= unsigned(op2);
        if mul_opb_s = '1' then
          b(31) <= std_ulogic(not op2(op2'high));
        end if;

        -- clk 1
        (v_ah, v_al) := a;
        (v_bh, v_bl) := b;
        -- First products
        v_ahbh := v_ah * v_bh;
        v_ahbl := v_ah * v_bl;
        v_albh := v_al * v_bh;
        v_albl := v_al * v_bl;
        ahbh      <= v_ahbh;
        ahbl      <= v_ahbl;
        albh      <= v_albh;
        albl      <= v_albl;
        ahbl_albh <= ('0' & v_ahbl) + ('0' & v_albh);

        case sign_sel is
        when "11" =>
          s <= x"8000_0000" - (('0' & a) + ('0' & b));
        when "10" =>
          v_b := '0' & b;
          s <= unsigned(-signed(v_b));
        when others =>
          s <= (others => '0');
        end case;

        -- clk 2
        -- Accumulate product
        prod_test(15 downto  0) <= albl(15 downto 0);
        prod_test(63 downto 16) <= (ahbh & x"0000") + ahbl_albh + albl(31 downto 16) + (s & "000" & x"000");

        if rst = '1' then
          valid_shift <= (others => '0');
        end if;
    end if;
  end process;

  mul_busy  <= or_reduce(valid_shift(1 downto 0));
  mul_valid <= valid_shift(valid_shift'high);
  prod <= std_logic_vector(prod_test(31 downto 0)) when prod_sel(prod_sel'high) = '1' else std_logic_vector(prod_test(63 downto 32));

--  p_mul : process(clk)
--  begin
--    if rising_edge(clk) then
--      if mul_en = '1' then
--        mul_valid <= '1';
--        if mul_sel = '1' then
--          prod <= std_logic_vector(prod_comb(31 downto 0));
--        else
--          prod <= std_logic_vector(prod_comb(63 downto 32));
--        end if;
--      elsif stall = '0' then
--        mul_valid <= '0';
--      end if;
--
--      if rst = '1' then
--        mul_valid <= '0';
--      end if;
--    end if;
--  end process p_mul;

--  4 : DIV     : -100 : signed / signed, return quotient
--  5 : DIVU    : -101 : unsigned / unsigned, return quotient
--  6 : REM     : -110 : signed / signed, return remainder
--  7 : REMU    : -111 : unsigned / unsigned, return remainder

  div_en     <= en and aluop(2);
  div_sel    <= aluop(1);
  div_signed <= not aluop(0);

  i_divider : entity lib_riscv.rv32m_div(rtl)
  port map (
    clk         => clk,
    rst         => rst,
    en          => div_en,
    stall       => stall,
    result_sel  => div_sel,
    signed_div  => div_signed,
    numerator   => op1,
    denominator => op2,
    busy        => div_busy,
    valid       => div_valid,
    result      => div_res
  );

  valid <= mul_valid or div_valid;
  busy  <= mul_busy or div_busy;
  res   <= div_res when div_valid = '1' else prod;

end architecture rtl;