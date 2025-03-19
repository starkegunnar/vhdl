library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity rr_arbiter is
  generic (
    g_data_width    : natural;
    g_num_inputs    : positive;
  );
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst     : in  std_logic;
    -- Source data and flow control
    s_data  : in  t_slv_array(g_num_inputs-1 downto 0)(g_data_width-1 downto 0);
    s_valid : in  std_logic_vector(g_num_inputs-1 downto 0);
    s_ready : out std_logic_vector(g_num_inputs-1 downto 0);

    m_data  : out std_logic_vector(g_data_width-1 downto 0);
    m_index : out std_logic_vector(fn_log2nz(g_num_inputs)-1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity rr_arbiter;

architecture rtl of rr_arbiter is

  signal s_valid_mask   : std_logic_vector(2**fn_log2nz(g_num_inputs)-1 downto 0) := (others => '1');
  signal s_valid_masked : s_valid'subtype;
  signal msb_mask       : s_valid'subtype;
  signal msb_empty      : std_logic;
  signal lsb_mask       : s_valid'subtype;
  signal lsb_empty      : std_logic;
  signal msb_index      : m_index'subtype;
  signal lsb_index      : m_index'subtype;
  signal s_prio         : m_index'subtype;

begin

  p_s_valid_mask : process(clk)
  begin
    if rising_edge(clk) then
      if m_valid = '1' and m_ready = '0' then
        s_valid_mask <= (others => '0');
        s_valid_mask(to_integer(unsigned(m_index))) <= '1';
      else
        s_valid_mask <= (others => '1');
      end if;
    end if;
  end process;

  s_valid_masked <= s_valid_mask(s_valid'range) and s_valid;

  p_s_prio_comb : process(all)
  begin
    msb_mask <= (others => '0');
    lsb_mask <= (others => '0');
    for i in s_valid_masked'range loop
      if i > unsigned(s_prio) then
        msb_mask(i) <= s_valid_masked(i);
      end if;
      if i <= unsigned(s_prio) then
        lsb_mask(i) <= s_valid_masked(i);
      end if;
    end loop;
  end process;

  pr_lzc(msb_mask, msb_index, msb_empty);
  pr_lzc(lsb_mask, lsb_index, lsb_empty);

  p_s_prio : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        s_prio <= (others => '0');
      elsif m_valid = '1' and m_ready = '1' then
        if msb_empty = '1' then
          s_prio <= lsb_index;
        else
          s_prio <= msb_index;
        end if;
      end if;
    end if;
  end process;


  i_arbiter_tree : entity lib_common.arbiter_tree(rtl)
  generic map (
    g_data_width => g_data_width,
    g_num_inputs => g_num_inputs
  )
  port map (
    s_data    => s_data,
    s_prio    => s_prio,
    s_valid   => s_valid_masked,
    s_ready   => s_ready,
    m_data    => m_data,
    m_index   => m_index,
    m_valid   => m_valid,
    m_ready   => m_ready
  );

end architecture rtl;