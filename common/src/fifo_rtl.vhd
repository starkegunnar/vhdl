library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity fifo is
  generic (
    type t_data;
    g_log2_depth  : positive := 3;
    g_sync_ram    : boolean := true;
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
    m_ready : in  std_logic;
    -- FIFO status
    cnt     : out std_logic_vector(g_log2_depth downto 0)
  );
end entity fifo;

architecture rtl of fifo is

  type t_fifo is array(2**g_log2_depth-1 downto 0) of t_data;

  signal we, re       : std_logic;
  signal waddr, raddr : unsigned(g_log2_depth-1 downto 0);
  signal fifo         : t_fifo;
  signal empty        : std_logic;
  signal full         : std_logic;
  signal fifo_ren     : std_logic;

  signal mem_data     : t_data;
  signal mem_valid    : std_logic;
  signal mem_ready    : std_logic;

begin

  we <= s_valid and not full;
  re <= fifo_ren and not empty;

  p_fifo : process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        fifo(to_integer(waddr)) <= s_data;

        waddr <= waddr + 1;
      end if;

      if re = '1' then
        raddr <= raddr + 1;
      end if;

      if we = '1' and re = '1' then
        cnt <= cnt;
      elsif we = '1' then
        cnt <= std_logic_vector(unsigned(cnt) + 1);
      elsif re = '1' then
        cnt <= std_logic_vector(unsigned(cnt) - 1);
      end if;

      if rst = '1' then
        waddr <= (others => '0');
        raddr <= (others => '0');
        cnt   <= (others => '0');
      end if;
    end if;
  end process;

  empty <= '1' when unsigned(cnt) = 0 else '0';
  full  <= '1' when unsigned(cnt) = 2**g_log2_depth else '0';

  s_ready <= not full;

  b_sync_ram : if g_sync_ram generate
    i_reg_slice_fallthrough : entity lib_common.reg_slice_fallthrough(rtl)
    generic map (
      t_data => t_data
    )
    port map (
      clk       => clk,
      rst       => rst,
      s_data    => fifo(to_integer(raddr)),
      s_valid   => not empty,
      s_ready   => fifo_ren,
      m_data    => mem_data,
      m_valid   => mem_valid,
      m_ready   => mem_ready
    );
  else generate
    mem_data  <= fifo(to_integer(raddr));
    mem_valid <= not empty;
    fifo_ren  <= mem_ready;
  end generate b_sync_ram;

  b_reg_output : if g_reg_output generate
    i_reg_slice_fallthrough : entity lib_common.reg_slice_fallthrough(rtl)
    generic map (
      t_data => t_data
    )
    port map (
      clk       => clk,
      rst       => rst,
      s_data    => mem_data,
      s_valid   => mem_valid,
      s_ready   => mem_ready,
      m_data    => m_data,
      m_valid   => m_valid,
      m_ready   => m_ready
    );
  else generate
    m_data    <= mem_data;
    m_valid   <= mem_valid;
    mem_ready <= m_ready;
  end generate b_reg_output;

end architecture rtl;