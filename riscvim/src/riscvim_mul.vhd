library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity riscvim_mul is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;

    id_valid  : in  std_logic;
    mulh      : in  std_logic;
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
end entity riscvim_mul;

architecture rtl of riscvim_mul is

  type t_mul_state is (m_idle, m_mac_0, m_mac_1, m_mac_2);

  signal state      : t_mul_state := m_idle;
  signal state_next : t_mul_state := m_idle;

  signal mul_sign   : std_logic_vector(1 downto 0);
  signal mul_sel    : std_logic_vector(1 downto 0);
  signal mul_op_a   : signed(c_xlen/2 downto 0);
  signal mul_op_b   : signed(c_xlen/2 downto 0);

  signal shamt      : unsigned(4 downto 0);

  signal mul_prod   : signed(c_xlen+1 downto 0);
  signal mac_next   : signed(c_xlen+1 downto 0);
  signal mac        : signed(c_xlen+1 downto 0);
  signal mac_shift  : signed(c_xlen+1 downto 0);
  signal mac_res    : signed(c_xlen+1 downto 0);

  -- synthesis translate_off
  signal prod_test  : signed(2*(c_xlen+1)-1 downto 0);
  signal prod_hi    : std_logic_vector(c_xlen-1 downto 0);
  signal prod_lo    : std_logic_vector(c_xlen-1 downto 0);
  -- synthesis translate_on

begin

  -- Sign extend operands
  mul_op_a(c_xlen/2-1 downto 0) <= signed(op_a(c_xlen-1 downto c_xlen/2)) when mul_sel(0) = '1' else signed(op_a(c_xlen/2-1 downto 0));
  mul_op_a(c_xlen/2)            <= mul_sign(0) and mul_op_a(c_xlen/2-1);
  mul_op_b(c_xlen/2-1 downto 0) <= signed(op_b(c_xlen-1 downto c_xlen/2)) when mul_sel(1) = '1' else signed(op_b(c_xlen/2-1 downto 0));
  mul_op_b(c_xlen/2)            <= mul_sign(1) and mul_op_b(c_xlen/2-1);

  -- Do multiplication in parts
  mul_prod  <= mul_op_a * mul_op_b;
  mac_shift <= shift_right(mac, to_integer(shamt)) when mulh = '1' else shift_left(mac, to_integer(shamt));
  mac_res   <= mul_prod + mac_shift;

  -- MULH(S/U)
  -- albl
  -- ahbl + (albl >> 16)
  -- albh + (ahbl + (albl >> 16))
  -- ahbh + ((albh + (ahbl + (albl >> 16))) >> 16)

  -- MUL
  -- ahbl
  -- albh + ahbl
  -- albl + ((albh + ahbl) << 16)

  p_mul_comb : process(all)
  begin
    state_next  <= state;
    mac_next    <= mac;
    ex_valid    <= '0';
    ex_ready    <= '0';
    mul_sel     <= "00";
    mul_sign    <= "00";
    shamt       <= "00000";

    case state is
    when m_idle =>
      if mulh = '1' then
        -- albl
        state_next  <= m_mac_0;
      else
        -- ahbl
        mul_sel     <= "01";
        mul_sign    <= '0' & sign_a;
        state_next  <= m_mac_1;
      end if;
      mac_next    <= mac_res;
    when m_mac_0 =>
      -- ahbl
      shamt       <= "10000";
      mul_sel     <= "01";
      mul_sign    <= '0' & sign_a;
      mac_next    <= mac_res;
      state_next  <= m_mac_1;
    when m_mac_1 =>
      -- albh
      mul_sel     <= "10";
      mul_sign    <= sign_b & '0';
      mac_next    <= mac_res;
      state_next  <= m_mac_2;
    when m_mac_2 =>
      shamt <= "10000";
      if mulh = '1' then
        -- ahbh
        mul_sel   <= "11";
        mul_sign  <= sign_b & sign_a;
      else
        -- albl
      end if;
      ex_valid <= '1';
      if wb_ready = '1' then
        ex_ready    <= '1';
        state_next  <= m_idle;
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
        state <= m_idle;
      elsif id_valid = '1' and halt = '0' then
        mac   <= mac_next;
        state <= state_next;
      end if;
    end if;
  end process;

  res <= std_logic_vector(mac_res(c_xlen-1 downto 0));

  -- synthesis translate_off
  prod_test <= signed((sign_a and op_a(c_xhi)) & op_a) * signed((sign_b and op_b(c_xhi)) & op_b);
  (prod_hi, prod_lo) <= std_logic_vector(prod_test(2*c_xlen-1 downto 0));
  -- synthesis translate_on

end architecture rtl;
