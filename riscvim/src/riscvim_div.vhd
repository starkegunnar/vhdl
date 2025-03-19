library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity riscvim_div is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    id_valid    : in  std_logic;
    div_rem     : in  std_logic;
    div_signed  : in  std_logic;
    op_a        : in  std_logic_vector(t_xlen_range);
    op_b        : in  std_logic_vector(t_xlen_range);

    halt        : in  std_logic;

    ex_valid    : out std_logic;
    ex_ready    : out std_logic;
    wb_ready    : in  std_logic;
    res         : out std_logic_vector(t_xlen_range) := (others => '0')
  );
end entity riscvim_div;

architecture rtl of rv32m_div is

  type t_div_state is (d_idle, d_divide, d_finish);

  signal state      : t_div_state := d_idle;
  signal state_next : t_div_state := d_idle;

  signal op_a_neg   : std_logic;
  signal op_b_neg   : std_logic;
  signal op_a_abs   : unsigned(t_xlen_range);
  signal op_b_abs   : unsigned(t_xlen_range);

  signal init       : std_logic;

  signal n          : unsigned(t_xlen_range); -- numerator
  signal d          : unsigned(t_xlen_range); -- dividend
  signal q          : unsigned(t_xlen_range); -- quotient
  signal r          : unsigned(t_xlen_range); -- remainder

  signal n_shift    : unsigned(t_xlen_range);
  signal r_shift    : unsigned(t_xlen_range);
  signal q_bit      : std_ulogic;
  signal q_shift    : unsigned(t_xlen_range);
  signal r_diff     : unsigned(t_xlen_range);
  signal n_next     : unsigned(t_xlen_range);
  signal d_next     : unsigned(t_xlen_range);
  signal q_next     : unsigned(t_xlen_range);
  signal r_next     : unsigned(t_xlen_range);

  signal div_en     : std_logic;

  signal count      : unsigned(f_log2(c_xlen)-1 downto 0);
  signal count_zero : std_logic;

  signal res_neg    : std_logic;
  signal res_comb   : unsigned(t_xlen_range);

  -- synthesis translate_off
  signal div_test  : signed(c_xlen downto 0);
  signal rem_test  : signed(c_xlen downto 0);
  -- synthesis translate_on

begin

  op_a_neg <= div_signed and op_a(c_xhi);
  op_b_neg <= div_signed and op_b(c_xhi);
  op_a_abs <= unsigned(-signed(op_a)) when op_a_neg = '1' else unsigned(op_a);
  op_b_abs <= unsigned(-signed(op_b)) when op_b_neg = '1' else unsigned(op_b);

  n_shift <= n(c_xhi-1 downto 0) & '0';
  r_shift <= r(c_xhi-1 downto 0) & n(c_xhi);

  -- Calulate r >= d
  (q_bit, r_diff) <= ('0' & r_shift) - d;

  q_shift <= q(c_xhi-1 downto 0) & not q_bit;

  n_next <= op_a_abs when init = '1' else n_shift;
  d_next <= op_b_abs when init = '1' else d;
  q_next <= (others => '0') when init = '1' else q_shift;
  r_next <= (others => '0') when init = '1' else r_diff when q_bit = '0' else r_shift;

  count_zero <= '1' when count = 0 else '0';

  p_state_comb : process(all)
  begin
    state_next  <= state;

    ex_valid    <= '0';
    ex_ready    <= '0';

    init        <= '0';

    div_en      <= '1';

    case state is
    when d_idle =>
      init        <= '1';
      state_next  <= d_divide;
    when d_divide =>
      if count_zero = '1' then
        state_next <= d_finish;
      end if;
    when d_finish =>
      ex_valid    <= '1';

      div_en      <= '0';
      if wb_ready = '1' then
        ex_ready    <= '1';
        state_next  <= d_idle;
      end if;
    end case;
  end process;

  p_res_neg : process(clk)
  begin
    if rising_edge(clk) then
      if init = '1' then
        res_neg <= div_signed and ((op_a_neg and div_rem) or ((op_a_neg xor op_b_neg) and or op_b));
      end if;
    end if;
  end process;

  p_count : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count <= (others => '0');
      elsif id_valid = '1' and halt = '0' then
        if init = '1' then
          count <= to_unsigned(c_xhi, count'length);
        elsif count_zero = '0' then
          count <= count - 1;
        end if;
      end if;
    end if;
  end process;

  p_regs : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= d_idle;
      elsif id_valid = '1' and halt = '0' then
        state <= state_next;
        if div_en = '1' then
          n <= n_next;
          d <= d_next;
          q <= q_next;
          r <= r_next;
        end if;
      end if;
    end if;
  end process;

  res_comb <= r when div_rem = '1' else q;

  res <= std_logic_vector(-signed(res_comb)) when res_neg = '1' else std_logic_vector(res_comb);

  -- synthesis translate_off
  div_test <= signed((sign_a and op_a(c_xhi)) & op_a) / signed((sign_b and op_b(c_xhi)) & op_b);
  -- synthesis translate_on

end architecture rtl;
