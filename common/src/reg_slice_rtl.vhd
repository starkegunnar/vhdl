library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity reg_slice is
  generic (
    type t_data;
    g_reg_slice_type  : t_reg_slice_type := e_reg_slice_full
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
end entity reg_slice;

architecture rtl of reg_slice is

begin

  b_register_slice : case g_reg_slice_type generate
  when e_reg_slice_full =>
    i_reg_slice : entity lib_common.reg_slice_full(rtl)
    generic map (
      t_data => t_data
    )
    port map (
      clk       => clk,
      rst       => rst,
      s_data    => s_data,
      s_valid   => s_valid,
      s_ready   => s_ready,
      m_data    => m_data,
      m_valid   => m_valid,
      m_ready   => m_ready
    );
  when e_reg_slice_fallthrough =>
    i_reg_slice : entity lib_common.reg_slice_fallthrough(rtl)
    generic map (
      t_data => t_data
    )
    port map (
      clk       => clk,
      rst       => rst,
      s_data    => s_data,
      s_valid   => s_valid,
      s_ready   => s_ready,
      m_data    => m_data,
      m_valid   => m_valid,
      m_ready   => m_ready
    );
  when e_reg_slice_srl =>
    i_reg_slice : entity lib_common.reg_slice_srl(rtl)
    generic map (
      t_data => t_data
    )
    port map (
      clk       => clk,
      rst       => rst,
      s_data    => s_data,
      s_valid   => s_valid,
      s_ready   => s_ready,
      m_data    => m_data,
      m_valid   => m_valid,
      m_ready   => m_ready
    );
  when others =>
    m_data  <= s_data;
    m_valid <= s_valid;
    s_ready <= m_ready;
  end generate b_register_slice;

end architecture rtl;