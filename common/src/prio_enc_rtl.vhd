library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity prio_enc is
  generic (
    g_width     : positive := 5;
    g_lsb_prio  : boolean := true
  );
  port (
    input_mask    : in  std_logic_vector(g_width-1 downto 0);
    output_valid  : out std_logic;
    output_index  : out std_logic_vector(fn_log2nz(g_width)-1 downto 0);
    output_mask   : out std_logic_vector(g_width-1 downto 0)
  );
end entity prio_enc;

architecture rtl of prio_enc is

begin

  b_prio_enc : if g_width > 1 generate
    constant c_levels : natural := fn_log2(g_width);
    signal mask_nodes   : std_logic_vector(2**c_levels-2 downto 0) := (others => '0');
    signal index_nodes  : t_slv_array(2**c_levels-2 downto 0)(output_index'range) := (others => (others => '0'));
    signal valid_nodes  : std_logic_vector(2**c_levels-2 downto 0) := (others => '0');
  begin

    output_valid <= valid_nodes(0);
    output_index <= index_nodes(0);

    mask_nodes(0) <= '1';

    b_tree : for i in c_levels-1 downto 0 generate
      b_node : for j in 2**i-1 downto 0 generate
        constant c_curr : natural := 2**i-1+j;
        constant c_prev : natural := 2**(i+1)+2*j-1;
        signal sel : std_logic := '0';
      begin
        b_leaf : if i = c_levels-1 generate
          b_full : if 2*j < g_width-1 generate
            valid_nodes(c_curr)     <= or input_mask(2*j+1 downto 2*j);
            sel <= not input_mask(2*j) when g_lsb_prio else not input_mask(2*j+1);
            output_mask(2*j+1)      <= mask_nodes(c_curr) and sel;
            output_mask(2*j)        <= mask_nodes(c_curr) and not sel;
            index_nodes(c_curr)(0)  <= sel;
          end generate b_full;
          b_half : if 2*j = g_width-1 generate
            valid_nodes(c_curr)     <= input_mask(2*j);
            output_mask(2*j)        <= mask_nodes(c_curr);
            index_nodes(c_curr)(0)  <= '0';
          end generate b_half;
        else generate
          valid_nodes(c_curr) <= or valid_nodes(c_prev+1 downto c_prev);
          sel <= not valid_nodes(c_prev) when g_lsb_prio else not valid_nodes(c_prev+1);
          mask_nodes(c_prev+1)  <= mask_nodes(c_curr) and sel;
          mask_nodes(c_prev)    <= mask_nodes(c_curr) and not sel;
          index_nodes(c_curr)(c_levels-1-i downto 0) <= ('1' & index_nodes(c_prev+1)(c_levels-2-i downto 0)) when sel = '1' else
                                                        ('0' & index_nodes(c_prev)(c_levels-2-i downto 0));
        end generate b_leaf;
      end generate b_node;
    end generate b_tree;
  else generate

    output_mask   <= input_mask;
    output_valid  <= input_mask(0);
    output_index  <= "0";

  end generate b_prio_enc;


end architecture rtl;