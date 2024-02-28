library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity srl_fifo is
  generic (
    type t_data;
    g_log2_depth  : positive := 3;
    g_reg_output  : boolean := true
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

  type t_fifo is array(2**g_log2_depth-1 downto 0) of t_data;

  signal we, re       : std_logic;
  signal fifo         : t_fifo;
  signal cnt          : std_logic_vector(g_log2_depth downto 0);
  signal empty        : std_logic;
  signal full         : std_logic;

  signal m_ready_comb : std_logic;

begin

  we <= s_valid and not full;
  re <= m_ready_comb and not empty;

  p_fifo : process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        fifo <= fifo(fifo'high-1 downto 0) & s_data;
      end if;

      if we = '1' and re = '0' then
        cnt <= std_logic_vector(unsigned(cnt) + 1);
      elsif we = '0' and re = '1' then
        cnt <= std_logic_vector(unsigned(cnt) - 1);
      end if;

      if rst = '1' then
        cnt <= (others => '1');
      end if;
    end if;
  end process;

  empty <= cnt(g_log2_depth);
  full  <= '1' when unsigned(cnt) = 2**g_log2_depth-1 else '0';

  s_ready <= not full;

  b_reg_output : if g_reg_output generate
    i_reg_slice_fallthrough : entity lib_common.reg_slice_fallthrough(rtl)
    generic map (
      t_data => t_data
    )
    port map (
      clk       => clk,
      rst       => rst,
      s_data    => fifo(to_integer(unsigned(cnt(cnt'high-1 downto 0)))),
      s_valid   => not empty,
      s_ready   => m_ready_comb,
      m_data    => m_data,
      m_valid   => m_valid,
      m_ready   => m_ready
    );
  else generate
    m_data        <= fifo(to_integer(unsigned(cnt(cnt'high-1 downto 0))));
    m_valid       <= not empty;
    m_ready_comb  <= m_ready;
  end generate b_reg_output;

end architecture rtl;