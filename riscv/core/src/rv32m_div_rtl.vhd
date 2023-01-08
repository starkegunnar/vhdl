--! @defgroup   RV32M_DIV_RTL RV32M div rtl
--!
--! @brief      This file implements RV32M div rtl.
--!
--! @author     Martin
--! @date       2022
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_riscv;
use lib_riscv.rv32i_pkg.all;

entity rv32m_div is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    en          : in  std_logic;
    stall       : in  std_logic;
    -- Control
    result_sel  : in  std_logic;
    signed_div  : in  std_logic;
    numerator   : in  std_logic_vector(t_xlen_range);
    denominator : in  std_logic_vector(t_xlen_range);

    busy        : out std_logic;
    valid       : out std_logic;
    result      : out std_logic_vector(t_xlen_range)
  );
end entity ; -- rv32m_div

architecture rtl of rv32m_div is

  constant c_numerator_ovfl   : std_logic_vector(t_xlen_range) := '1' & (numerator'high - 1 downto 0 => '0');
  constant c_denominator_ovfl : std_logic_vector(t_xlen_range) := (others => '1');

  signal n          : unsigned(t_xlen_range);
  signal r          : unsigned(t_xlen_range);
  signal divisor    : unsigned(t_xlen_range);
  signal q          : unsigned(t_xlen_range);
  signal pre_sign   : std_logic;
  signal busy_r     : std_logic;
  signal sign_r     : std_ulogic;
  signal nbit       : unsigned(t_rsel_range);
  signal last       : std_logic;
  signal zero       : std_logic;
  signal ovfl       : std_logic;
  signal c          : std_ulogic;
  signal diff       : unsigned(t_xlen_range);
  signal sel_r      : std_logic;

begin

  (c, diff) <= ('0' & r(r'high -1 downto 0) & n(n'high)) - ('0' & divisor);

  p_busy_r : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        busy_r <= '1';
      elsif last = '1' or zero = '1' or ovfl = '1' then
        busy_r <= '0';
      end if;

      if rst = '1' then
        busy_r <= '0';
      end if;
    end if;
  end process;

  p_busy : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        busy <= '1';
      elsif (last = '1' and sign_r = '0') or zero = '1' or ovfl = '1' then
        busy <= '0';
      elsif busy_r = '0' then
        busy <= '0';
      end if;

      if rst = '1' then
        busy <= '0';
      end if;
    end if;
  end process;

  p_valid : process(clk)
  begin
    if rising_edge(clk) then
      if busy_r = '1' and (zero = '1' or ovfl = '1') then
        valid <= '1';
      elsif busy_r = '1' then
        if last = '1' then
          valid <= not sign_r;
        end if;
      elsif sign_r = '1' then
        valid <= '1';
      elsif stall = '0' then
        valid <= '0';
      end if;

      if rst = '1' then
        valid <= '0';
      end if;
    end if;
  end process;

  p_zero : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' and busy_r = '0' then
        if unsigned(denominator) = 0 then
          zero <= '1';
        else
          zero <= '0';
        end if;
      end if;
    end if;
  end process;

  p_ovfl : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' and busy_r = '0' then
        if signed_div = '1' and numerator = c_numerator_ovfl and denominator = c_denominator_ovfl then
          ovfl <= '1';
        else
          ovfl <= '0';
        end if;
      end if;
    end if;
  end process;

  p_nbit : process(clk)
  begin
    if rising_edge(clk) then
      nbit <= (others => '0');
      if busy_r = '1' and pre_sign = '0' then
        nbit <= nbit + 1;
      end if;

      if rst = '1' then
        nbit <= (others => '0');
      end if;
    end if;
  end process;

  p_last : process(clk)
  begin
    if rising_edge(clk) then
      last <= '0';
      if busy_r = '1' and nbit = c_xlen_hi - 1 then
        last <= '1';
      end if;

      if rst = '1' then
        last <= '0';
      end if;
    end if;
  end process;

  p_presign : process(clk)
  begin
    if rising_edge(clk) then
      pre_sign <= en and not busy_r and signed_div and (numerator(numerator'high) or denominator(denominator'high));
      if rst = '1' then
        pre_sign <= '0';
      end if;
    end if;
  end process;

  p_dividend : process(clk)
  begin
    if rising_edge(clk) then
      if pre_sign = '1' then
        if n(n'high) = '1' then
          n <= unsigned(-signed(n));
        end if;
      elsif busy_r = '1' then
        n <= n(n'high - 1 downto 0) & '0';
      elsif busy_r = '0' and en = '1' then
        n <= unsigned(numerator);
      end if;
    end if;
  end process;

  p_divisor : process(clk)
  begin
    if rising_edge(clk) then
      if busy_r = '1' and pre_sign = '1' then
        if divisor(divisor'high) = '1' then
          divisor <= unsigned(-signed(divisor));
        end if;
      elsif busy_r = '0' and en = '1' then
        divisor <= unsigned(denominator);
      end if;
      if rst = '1' then
        divisor <= (others => '0');
      end if;
    end if;
  end process;

  p_sign_r : process(clk)
  begin
    if rising_edge(clk) then
      sign_r <= '0';
      if pre_sign = '1' then
        sign_r <= n(n'high) xor divisor(denominator'high);
      elsif busy_r = '1' then
        sign_r <= sign_r and not zero and not ovfl;
      end if;

      if rst = '1' then
        sign_r <= '0';
      end if;
    end if;
  end process;

  p_r : process(clk)
  begin
    if rising_edge(clk) then
      if busy_r = '1' then
        if zero = '1' then
          r <= n;
        elsif ovfl = '1' then
          r <= (others => '0');
        elsif pre_sign = '0' then
          if c = '0' then
            r <= diff;
          else
            r <= r(r'high - 1 downto 0) & n(n'high);
          end if;
        end if;
      elsif sign_r = '1' then
        r <= unsigned(-signed(r));
      elsif en = '1' then
        r <= (others => '0');
      end if;

      if rst = '1' then
        r <= (others => '0');
      end if;
    end if;
  end process;

  p_q : process(clk)
  begin
    if rising_edge(clk) then
      if busy_r = '1' then
        if zero = '1' then
          q <= (others => '1');
        elsif ovfl = '1' then
          q <= '1' & (q'high - 1 downto 0 => '0');
        else
          q <= q(q'high - 1 downto 0) & not c;
        end if;
      elsif sign_r = '1' then
        q <= unsigned(-signed(q));
      end if;

      if rst = '1' then
        q <= (others => '0');
      end if;
    end if;
  end process;

  p_sel : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' and busy_r = '0' then
        sel_r <= result_sel;
      end if;

      if rst = '1' then
        sel_r <= '0';
      end if;
    end if;
  end process;

  result <= std_logic_vector(r) when sel_r else std_logic_vector(q);

end architecture rtl;
