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

entity rv32m_mul is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;

    id_valid  : in  std_logic;
    mulh      : in  std_logic_vector(t_alu_op_range);
    sign_a    : in  std_logic;
    sign_b    : in  std_logic;
    op_a      : in  std_logic_vector(t_xlen_range);
    op_b      : in  std_logic_vector(t_xlen_range);

    halt      : in  std_logic;

    ex_valid  : out std_logic;
    ex_ready  : out std_logic;
    wb_ready  : in  std_logic;
    res       : out std_logic_vector(t_xlen_range) := (others => '0')
  );
end entity rv32m_mul;

architecture rtl of rv32m_mul is

  type t_mul_state is (m_albl, m_ahbl, m_albh, m_ahbh);

  signal state      : t_mul_state := m_albl;
  signal state_next : t_mul_state := m_albl;

  signal mul_sign   : std_logic_vector(1 downto 0);
  signal mul_sel    : std_logic_vector(1 downto 0);
  signal mul_op_a   : signed(c_xlen/2 downto 0);
  signal mul_op_b   : signed(c_xlen/2 downto 0);

  signal shamt      : unsigned(4 downto 0);

  signal mul_prod   : signed(c_xlen+1 downto 0);
  signal mul_shift  : signed(c_xlen+1 downto 0);
  signal mac_next   : signed(c_xlen+1 downto 0);
  signal mac        : signed(c_xlen+1 downto 0);

begin

  mul_op_a(c_xlen/2-1 downto 0) <= signed(op_a(c_xlen-1 downto c_xlen/2)) when mul_sel(0) = '1' else signed(op_a(c_xlen/2-1 downto 0));
  mul_op_a(c_xlen/2)            <= mul_sign(0) and mul_op_a(c_xlen/2-1);
  mul_op_b(c_xlen/2-1 downto 0) <= signed(op_b(c_xlen-1 downto c_xlen/2)) when mul_sel(1) = '1' else signed(op_b(c_xlen/2-1 downto 0));
  mul_op_b(c_xlen/2)            <= mul_sign(1) and mul_op_b(c_xlen/2-1);

  mul_prod <= mul_op_a * mul_op_b;
  mul_shift <= shift_left(mul_prod, to_integer(shamt)) when mulh = '1' else shift_right(mul_prod, to_integer(shamt));

  p_mul_comb : process(all)
  begin
    state_next  <= state;
    mac_next    <= mul_shift + mac;
    ex_valid    <= '0';
    ex_ready    <= '0';

    case state is
    when m_albl =>
      shamt <= "10000";
      if mulh = '1' then
        mul_sel   <= "00";
        mul_sign  <= "00";
      else
        mul_sel   <= "11";
        mul_sign  <= sign_b & sign_a;
      end if;
      state_next <= m_ahbl;
    when m_ahbl =>
      shamt       <= "00000";
      mul_sel     <= "01";
      mul_sign    <= '0' & sign_a;
      state_next  <= m_albh;
    when m_albh =>
      shamt       <= "10000";
      mul_sel     <= "10";
      mul_sign    <= sign_b & '0';
      state_next  <= m_ahbh;
    when m_ahbh =>
      shamt <= "00000";
      if mulh = '1' then
        mul_sel   <= "11";
        mul_sign  <= sign_b & sign_a;
      else
        mul_sel   <= "00";
        mul_sign  <= "00";
      end if;
      ex_valid <= '1';
      if wb_ready = '1' then
        ex_ready    <= '1';
        state_next  <= m_albl;
        mac_next    <= (others => '0');
      end if;
    end case;

    if halt = '1' then
      ex_valid  <= '0';
      ex_ready  <= '0';
    end if;
  end process;

  p_mul_sync : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        mac   <= (others => '0');
        state <= m_albl;
      elsif id_valid = '1' and halt = '0' then
        mac   <= mac_next;
        state <= state_next;
      end if;
    end if;
  end process;

  res <= std_logic_vector(mul_acc(c_xlen-1 downto 0));

end architecture rtl;
