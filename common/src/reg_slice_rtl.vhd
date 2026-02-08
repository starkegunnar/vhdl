library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity reg_slice is
  generic (
    DW          : positive;
    RESET_DATA  : integer := 0;
    ASYNC_RESET : integer := 0;
    BYPASS      : integer := 0;
    SLICE_TYPE  : t_reg_slice_type := e_reg_slice_full
  );
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst_n   : in  std_logic;
    -- Data and flow control
    s_data  : in  std_logic_vector(DW-1 downto 0);
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out std_logic_vector(DW-1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity reg_slice;

architecture rtl of reg_slice is

begin

  b_register_slice : case SLICE_TYPE generate
  when e_reg_slice_full =>
    i_reg_slice : entity lib_common.reg_slice_full(rtl)
    generic map (
      DW          => DW,
      RESET_DATA  => RESET_DATA,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS
    )
    port map (
      clk       => clk,
      rst_n     => rst_n,
      s_data    => s_data,
      s_valid   => s_valid,
      s_ready   => s_ready,
      m_data    => m_data,
      m_valid   => m_valid,
      m_ready   => m_ready
    );
  when e_reg_slice_pipe =>
    i_reg_slice : entity lib_common.reg_slice_pipe(rtl)
    generic map (
      DW          => DW,
      RESET_DATA  => RESET_DATA,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS
    )
    port map (
      clk       => clk,
      rst_n     => rst_n,
      s_data    => s_data,
      s_valid   => s_valid,
      s_ready   => s_ready,
      m_data    => m_data,
      m_valid   => m_valid,
      m_ready   => m_ready
    );
  when e_reg_slice_spill =>
    i_reg_slice : entity lib_common.reg_slice_spill(rtl)
    generic map (
      DW          => DW,
      RESET_DATA  => RESET_DATA,
      ASYNC_RESET => ASYNC_RESET,
      BYPASS      => BYPASS
    )
    port map (
      clk       => clk,
      rst_n     => rst_n,
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