library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity arbiter_tree is
  generic (
    g_data_width    : natural;
    g_num_inputs    : positive;
  );
  port (
    -- Source data and flow control
    s_data  : in  t_slv_array(g_num_inputs-1 downto 0)(g_data_width-1 downto 0);
    s_prio  : in  std_logic_vector(fn_log2nz(g_num_inputs)-1 downto 0) := (others => '0');
    s_valid : in  std_logic_vector(g_num_inputs-1 downto 0);
    s_ready : out std_logic_vector(g_num_inputs-1 downto 0);

    m_data  : out std_logic_vector(g_data_width-1 downto 0);
    m_index : out std_logic_vector(fn_log2nz(g_num_inputs)-1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity arbiter_tree;

architecture rtl of arbiter_tree is

begin

  b_arbiter : if g_num_inputs > 1 generate
    constant c_levels : natural := fn_log2(g_num_inputs);
    signal data_nodes   : t_slv_array(2**c_levels-2 downto 0)(m_data'range) := (others => (others => '0'));
    signal index_nodes  : t_slv_array(2**c_levels-2 downto 0)(m_index'range) := (others => (others => '0'));
    signal valid_nodes  : std_logic_vector(2**c_levels-2 downto 0) := (others => '0');
    signal ready_nodes  : std_logic_vector(2**c_levels-2 downto 0) := (others => '0');
  begin

    m_data          <= data_nodes(0);
    m_valid         <= valid_nodes(0);
    ready_nodes(0)  <= m_ready;

    m_index         <= index_nodes(0);

    b_arbiter_tree : for i in c_levels-1 downto 0 generate
      b_node : for j in 2**i-1 downto 0 generate
        constant c_curr : natural := 2**i-1+j;
        constant c_prev : natural := 2**(i+1)+2*j-1;
        signal sel : std_logic := '0';
      begin
        b_leaf : if i = c_levels-1 generate
          b_full : if 2*j < g_num_inputs-1 generate
            valid_nodes(c_curr)     <= s_valid(2*j) or s_valid(2*j+1);
            sel                     <= not s_valid(2*j) or (s_valid(2*j+1) and s_prio(c_levels-1-i));
            data_nodes(c_curr)      <= s_data(2*j+1) when sel = '1' else s_data(2*j);
            s_ready(2*j+1)          <= ready_nodes(c_curr) and sel;
            s_ready(2*j)            <= ready_nodes(c_curr) and not sel;
            index_nodes(c_curr)(0)  <= sel;
          end generate;
          b_half : if 2*j = g_num_inputs-1 generate
            valid_nodes(c_curr)     <= s_valid(2*j);
            data_nodes(c_curr)      <= s_data(2*j);
            s_ready(2*j)            <= ready_nodes(c_curr);
            index_nodes(c_curr)(0)  <= '0';
          end generate;
        else generate
          valid_nodes(c_curr)     <= valid_nodes(c_prev) or valid_nodes(2**(i+1)+2*j);
          sel                     <= not valid_nodes(c_prev) or (valid_nodes(c_prev+1) and s_prio(c_levels-1-i));
          data_nodes(c_curr)      <= data_nodes(c_prev+1) when sel = '1' else data_nodes(c_prev);
          ready_nodes(c_prev+1)   <= ready_nodes(c_curr) and sel;
          ready_nodes(c_prev)     <= ready_nodes(c_curr) and not sel;
          index_nodes(c_curr)(c_levels-1-i downto 0) <= ('1' & index_nodes(c_prev+1)(c_levels-2-i downto 0)) when sel = '1' else
                                                        ('0' & index_nodes(c_prev)(c_levels-2-i downto 0));
        end generate;
      end generate;
    end generate;

  else generate
    m_data      <= s_data(0);
    m_valid     <= s_valid(0);
    s_ready(0)  <= m_ready;
    m_index     <= (others => '0');
  end generate b_arbiter;

end architecture rtl;