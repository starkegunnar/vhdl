library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity fifo_srl is
  generic (
    type t_data;
    g_depth         : positive := 4;
    g_bypass_empty  : boolean := true;
    g_reg_output    : boolean := true
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
end entity fifo_srl;

architecture rtl of fifo_srl is

  constant c_cw         : natural := fn_log2(g_depth)+1;
  constant c_crst       : std_logic_vector(c_cw-1 downto 0) := std_logic_vector(to_unsigned(2**(c_cw-1)-1, c_cw));
  constant c_going_full : std_logic_vector(c_cw-1 downto 0) := std_logic_vector(to_unsigned(2**(c_cw)-2, c_cw));
  constant c_depth      : natural := fn_ceil_pow2(g_depth);

  type t_shreg is array(c_depth-1 downto 0) of t_data;

  signal inc, dec       : std_logic;
  signal shreg          : t_shreg;
  signal count          : std_logic_vector(c_cw-1 downto 0) := c_crst;
  signal addr           : std_logic_vector(c_cw-2 downto 0);
  signal m_shreg_data   : t_data;
  signal m_shreg_valid  : std_logic;
  signal m_shreg_ready  : std_logic;
  signal s_reg_data     : t_data;
  signal s_reg_valid    : std_logic;
  signal s_reg_ready    : std_logic;
  signal m_reg_data     : t_data;
  signal m_reg_valid    : std_logic;

begin

  inc <= s_valid and s_ready and not (not m_shreg_valid and m_shreg_ready) when g_bypass_empty else s_valid and s_ready;
  dec <= m_shreg_valid and m_shreg_ready;

  p_count : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count <= c_crst;
      else
        count <= std_logic_vector(unsigned(count) + std_ulogic(inc) - std_ulogic(dec));
      end if;
    end if;
  end process;

  p_ready : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        s_ready <= '1';
      else
        if inc = '1' and dec = '0' then
          if count = c_going_full then
            s_ready <= '0';
          end if;
        elsif inc = '0' and dec = '1' then
          s_ready <= '1';
        end if;
      end if;
    end if;
  end process;

  (m_shreg_valid, addr) <= count;

  p_shreg : process(clk)
  begin
    if rising_edge(clk) then
      if s_valid = '1' and s_ready = '1' then
        shreg <= shreg(shreg'high-1 downto 0) & s_data;
      end if;
    end if;
  end process;

  m_shreg_data    <= shreg(to_integer(unsigned(addr)));

  s_reg_data      <= s_data when g_bypass_empty and m_shreg_valid = '0' else m_shreg_data;
  s_reg_valid     <= s_valid or m_shreg_valid when g_bypass_empty else m_shreg_valid;

  i_reg_slice_fallthrough : entity lib_common.reg_slice_fallthrough(rtl)
  generic map (
    t_data => t_data
  )
  port map (
    clk       => clk,
    rst       => rst,
    s_data    => s_reg_data,
    s_valid   => s_reg_valid,
    s_ready   => s_reg_ready,
    m_data    => m_reg_data,
    m_valid   => m_reg_valid,
    m_ready   => m_ready
  );

  m_data        <= m_reg_data when g_reg_output else s_reg_data;
  m_valid       <= m_reg_valid when g_reg_output else s_reg_valid;
  m_shreg_ready <= s_reg_ready when g_reg_output else m_ready;

end architecture rtl;