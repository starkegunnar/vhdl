library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity arbiter_tree is
  generic (
    g_data_width    : natural;
    g_num_inputs    : positive;
    g_round_robin   : boolean := true
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
    m_valid : out std_logic;
    m_ready : in  std_logic;

    index   : out std_logic_vector(fn_log2nz(g_num_inputs)-1 downto 0)
  );
end entity arbiter_tree;

architecture rtl of arbiter_tree is

begin

  b_arbiter : if g_num_inputs > 1 generate
    constant c_levels : natural := fn_log2(g_num_inputs);
    signal data_nodes   : t_slv_array(2**c_levels-2 downto 0)(m_data'range) := (others => (others => '0'));
    signal index_nodes  : t_slv_array(2**c_levels-2 downto 0)(index'range) := (others => (others => '0'));
    signal valid_nodes  : std_logic_vector(2**c_levels-2 downto 0) := (others => '0');
    signal ready_nodes  : std_logic_vector(2**c_levels-2 downto 0) := (others => '0');
    signal rr_prio      : std_logic_vector(index'range) := (others => '0');
    signal valid_mask   : std_logic_vector(s_valid'range) := (others => '1');
    signal valid_masked : std_logic_vector(s_valid'range);
  begin

    m_data          <= data_nodes(0);
    m_valid         <= valid_nodes(0);
    ready_nodes(0)  <= m_ready;

    index           <= index_nodes(0);

    p_valid_mask : process(clk)
    begin
      if rising_edge(clk) then
        if valid_nodes(0) = '1' and m_ready = '0' then
          valid_mask <= s_valid;
        else
          valid_mask <= (others => '1');
        end if;
      end if;
    end process;

    valid_masked <= valid_mask and s_valid;

    b_rr_prio : if g_round_robin generate
      signal msb_mask   : std_logic_vector(s_valid'range);
      signal msb_empty  : std_logic;
      signal lsb_mask   : std_logic_vector(s_valid'range);
      signal lsb_empty  : std_logic;
      signal msb_index  : std_logic_vector(index'range);
      signal lsb_index  : std_logic_vector(index'range);
    begin
      p_rr_prio_comb : process(all)
      begin
        msb_mask <= (others => '0');
        lsb_mask <= (others => '0');
        for i in valid_masked'range loop
          if i > unsigned(rr_prio) then
            msb_mask(i) <= valid_masked(i);
          end if;
          if i <= unsigned(rr_prio) then
            lsb_mask(i) <= valid_masked(i);
          end if;
        end loop;
      end process;

      pr_lzc(msb_mask, msb_index, msb_empty);
      pr_lzc(lsb_mask, lsb_index, lsb_empty);

      p_rr_prio : process(clk)
      begin
        if rising_edge(clk) then
          if valid_nodes(0) = '1' and m_ready = '1' then
            if msb_empty = '1' then
              rr_prio <= lsb_index;
            else
              rr_prio <= msb_index;
            end if;
          end if;

          if rst = '1' then
            rr_prio <= (others => '0');
          end if;
        end if;
      end process;
    else generate
      p_rr_prio : process(clk)
      begin
        if rising_edge(clk) then
          if valid_nodes(0) = '1' and m_ready = '1' then
            if unsigned(rr_prio) = g_num_inputs-1 then
              rr_prio <= (others => '0');
            else
              rr_prio <= std_logic_vector(unsigned(rr_prio) + 1);
            end if;
          end if;

          if rst = '1' then
            rr_prio <= (others => '0');
          end if;
        end if;
      end process;
    end generate b_rr_prio;

    b_arbiter_tree : for i in c_levels-1 downto 0 generate
      b_node : for j in 2**i-1 downto 0 generate
        constant c_curr : natural := 2**i-1+j;
        constant c_prev : natural := 2**(i+1)+2*j-1;
        signal sel : std_logic := '0';
      begin
        b_leaf : if i = c_levels-1 generate
          b_full : if 2*j < g_num_inputs-1 generate
            valid_nodes(c_curr)     <= valid_masked(2*j) or valid_masked(2*j+1);
            sel                     <= not valid_masked(2*j) or (valid_masked(2*j+1) and rr_prio(c_levels-1-i));
            data_nodes(c_curr)      <= s_data(2*j+1) when sel = '1' else s_data(2*j);
            s_ready(2*j+1)          <= ready_nodes(c_curr) and sel;
            s_ready(2*j)            <= ready_nodes(c_curr) and not sel;
            index_nodes(c_curr)(0)  <= sel;
          end generate;
          b_half : if 2*j = g_num_inputs-1 generate
            valid_nodes(c_curr)     <= valid_masked(2*j);
            data_nodes(c_curr)      <= s_data(2*j);
            s_ready(2*j)            <= ready_nodes(c_curr);
            index_nodes(c_curr)(0)  <= '0';
          end generate;
        else generate
          valid_nodes(c_curr)     <= valid_nodes(c_prev) or valid_nodes(2**(i+1)+2*j);
          sel                     <= not valid_nodes(c_prev) or (valid_nodes(c_prev+1) and rr_prio(c_levels-1-i));
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
    index       <= (others => '0');
  end generate b_arbiter;

end architecture rtl;