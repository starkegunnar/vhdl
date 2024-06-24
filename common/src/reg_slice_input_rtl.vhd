library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity reg_slice_input is
  generic (
    type t_data
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
end entity reg_slice_input;

architecture rtl of reg_slice_input is

  signal s_data_r     : t_data;
  signal s_valid_r    : std_logic;
  signal s_ready_r    : std_logic;

begin

  p_input_reg : process(clk)
  begin
    if rising_edge(clk) then
      s_data_r  <= s_data;
      s_valid_r <= s_valid;
      s_ready_r <= s_ready;

      s_ready   <= not m_valid or m_ready;

      if rst = '1' then
        s_valid_r <= '0';
      end if;
    end if;
  end process;

  i_srl_fifo : entity lib_common.srl_fifo(rtl)
  generic map (
    t_data          => t_data,
    g_depth         => 3,
    g_bypass_empty  => true
  )
  port map (
    clk       => clk,
    rst       => rst,
    s_data    => s_data_r,
    s_valid   => s_valid_r and s_ready_r,
    s_ready   => open,
    m_data    => m_data,
    m_valid   => m_valid,
    m_ready   => m_ready
  );

end architecture rtl;