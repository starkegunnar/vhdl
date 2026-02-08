library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity arbiter is
  generic (
    WIDTH         : positive := 5;
    LSB_PRIO      : boolean := true;
    ROUND_ROBIN   : boolean := true
  );
  port (
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    req           : in  std_logic_vector(WIDTH-1 downto 0);
    ack           : in  std_logic_vector(WIDTH-1 downto 0);
    grant         : out std_logic_vector(WIDTH-1 downto 0);
    grant_valid   : out std_logic;
    grant_index   : out std_logic_vector(f_log2nz(WIDTH)-1 downto 0)
  );
end entity arbiter;

architecture rtl of arbiter is

  constant c_ones   : unsigned(WIDTH-1 downto 0) := (others => '1');
  constant c_mask   : unsigned(WIDTH-1 downto 0) := c_ones - 1;

  type t_arb is record
    valid : std_logic;
    index : std_logic_vector(f_log2nz(WIDTH)-1 downto 0);
    mask  : std_logic_vector(WIDTH-1 downto 0);
  end record;
  signal arb, arb_masked : t_arb;
  signal mask : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

begin

  p_comb : process(all)
    variable v          : t_arb;
    variable v_masked   : t_arb;
    variable gnt_in     : std_logic := '1';
    variable req_masked : std_logic_vector(WIDTH-1 downto 0);
  begin
    v := arb;
    v_masked := arb_masked;

    req_masked := req and mask;

    pr_prio_enc(req, gnt_in, v.mask, v.index, v.valid);

    if ROUND_ROBIN then
      pr_prio_enc(req_masked, gnt_in, v_masked.mask, v_masked.index, v_masked.valid);
    end if;
  end process;

  p_arbiter : process(clk)
  begin
    if rising_edge(clk) then
      if grant_valid = '1' and (or (grant and ack) = '0') then
        -- Do nothing
      elsif arb.valid = '1' then
        grant_valid <= '1';
        if ROUND_ROBIN and arb_masked.valid = '1' then
          grant       <= arb_masked.mask;
          grant_index <= arb_masked.index;
          if LSB_PRIO then
            mask <= std_logic_vector(shift_left(c_mask, to_integer(unsigned(arb_masked.index))));
          else
            mask <= std_logic_vector(shift_right(c_ones, WIDTH - to_integer(unsigned(arb_masked.index))));
          end if;
        else
          grant       <= arb.mask;
          grant_index <= arb.index;
          if LSB_PRIO then
            mask <= std_logic_vector(shift_left(c_mask, to_integer(unsigned(arb.index))));
          else
            mask <= std_logic_vector(shift_right(c_ones, WIDTH - to_integer(unsigned(arb.index))));
          end if;
        end if;
      else
        grant_valid <= '0';
        grant       <= (others => '0');
      end if;

      if rst_n = '0' then
        grant_valid <= '0';
        grant_index <= (others => '0');
        grant       <= (others => '0');
        mask        <= (others => '0');
      end if;
    end if;
  end process;


end architecture rtl;