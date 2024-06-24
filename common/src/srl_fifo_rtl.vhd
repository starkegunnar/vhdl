library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity srl_fifo is
  generic (
    type t_data;
    g_depth         : positive := 4;
    g_bypass_empty  : boolean := true
  );
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst     : in  std_logic;
    -- Data and flow control
    s_data  : in  t_data;
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out t_data;
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity srl_fifo;

architecture rtl of srl_fifo is

  constant c_cw       : natural := fn_log2(g_depth)+1;

  type t_shreg is array(fn_ceil_pow2(g_depth)-1 downto 0) of t_data;

  signal we, re       : std_logic;
  signal shreg        : t_shreg;
  signal cnt          : std_logic_vector(c_cw-1 downto 0);
  signal cnt_p1       : std_logic_vector(c_cw-1 downto 0);
  signal addr         : std_logic_vector(c_cw-2 downto 0);
  signal empty        : std_logic;
  signal bypass       : std_logic;
  signal m_data_comb  : t_data;
  signal m_valid_comb : std_logic;
  signal m_ready_comb : std_logic;

begin

  bypass <= empty and m_ready_comb when g_bypass_empty else '0';

  we <= s_valid and s_ready and not bypass;
  re <= m_ready_comb and not empty;

  i_count : entity lib_common.up_down_counter(rtl)
  generic map (
    g_counter_width => c_cw,
    g_reset_value   => (others => '1')
  )
  port map (
    clk   => clk,
    rst   => rst,
    en    => '1',
    up    => we,
    down  => re,
    count => cnt
  );

  (empty, addr) <= cnt;

  i_count_p1 : entity lib_common.up_down_counter(rtl)
  generic map (
    g_counter_width => c_cw,
    g_reset_value   => std_logic_vector(to_unsigned(2*(c_cw-1), c_cw))
  )
  port map (
    clk   => clk,
    rst   => rst,
    en    => '1',
    up    => we,
    down  => re,
    count => cnt_p1
  );

  s_ready <= cnt_p1(c_cw-1);

  p_shreg : process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        shreg <= shreg(shreg'high-1 downto 0) & s_data;
      end if;
    end if;
  end process;

  m_data_comb   <= s_data when g_bypass_empty and empty = '1' else shreg(to_integer(unsigned(addr)));
  m_valid_comb  <= s_valid or not empty when g_bypass_empty else not empty;

  i_reg_slice_fallthrough : entity lib_common.reg_slice_fallthrough(rtl)
  generic map (
    t_data => t_data
  )
  port map (
    clk       => clk,
    rst       => rst,
    s_data    => m_data_comb,
    s_valid   => m_valid_comb,
    s_ready   => m_ready_comb,
    m_data    => m_data,
    m_valid   => m_valid,
    m_ready   => m_ready
  );

end architecture rtl;