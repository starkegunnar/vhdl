library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity arbiter is
  generic (
    g_width       : positive := 5;
    g_lsb_prio    : boolean := true;
    g_round_robin : boolean := true
  );
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;
    req           : in  std_logic_vector(g_width-1 downto 0);
    ack           : in  std_logic_vector(g_width-1 downto 0);
    grant         : out std_logic_vector(g_width-1 downto 0);
    grant_valid   : out std_logic;
    grant_index   : out std_logic_vector(fn_log2nz(g_width)-1 downto 0)
  );
end entity arbiter;

architecture rtl of arbiter is

  constant c_ones   : unsigned(g_width-1 downto 0) := (others => '1');
  constant c_mask   : unsigned(g_width-1 downto 0) := c_ones - 1;

  signal req_valid  : std_logic;
  signal req_index  : std_logic_vector(fn_log2nz(g_width)-1 downto 0);
  signal req_mask   : std_logic_vector(g_width-1 downto 0);

  signal mask : std_logic_vector(g_width-1 downto 0) := (others => '0');
  signal req_masked_valid : std_logic := '0';
  signal req_masked_index : std_logic_vector(fn_log2nz(g_width)-1 downto 0) := (others => '0');
  signal req_masked_mask  : std_logic_vector(g_width-1 downto 0) := (others => '0');

begin

  i_prio_enc : entity lib_common.prio_enc(rtl)
  generic map (
    g_width       => g_width,
    g_lsb_prio    => g_lsb_prio
  )
  port map (
    input_mask    => req,
    output_valid  => req_valid,
    output_index  => req_index,
    output_mask   => req_mask
  );

  b_round_robin : if g_round_robin generate
    signal req_masked : std_logic_vector(g_width-1 downto 0);
  begin
    req_masked <= req and mask;
    i_prio_enc_masked : entity lib_common.prio_enc(rtl)
    generic map (
      g_width       => g_width,
      g_lsb_prio    => g_lsb_prio
    )
    port map (
      input_mask    => req_masked,
      output_valid  => req_masked_valid,
      output_index  => req_masked_index,
      output_mask   => req_masked_mask
    );
  end generate b_round_robin;

  p_arbiter : process(clk)
  begin
    if rising_edge(clk) then
      if grant_valid = '1' and (or (grant and ack) = '0') then
        -- Do nothing
      elsif req_valid = '1' then
        grant_valid <= '1';
        if g_round_robin and req_masked_valid = '1' then
          grant       <= req_masked_mask;
          grant_index <= req_masked_index;
          if g_lsb_prio then
            mask <= std_logic_vector(shift_left(c_mask, to_integer(unsigned(req_masked_index))));
          else
            mask <= std_logic_vector(shift_right(c_ones, g_width - to_integer(unsigned(req_masked_index))));
          end if;
        else
          grant       <= req_mask;
          grant_index <= req_index;
          if g_lsb_prio then
            mask <= std_logic_vector(shift_left(c_mask, to_integer(unsigned(req_index))));
          else
            mask <= std_logic_vector(shift_right(c_ones, g_width - to_integer(unsigned(req_index))));
          end if;
        end if;
      else
        grant_valid <= '0';
        grant       <= (others => '0');
      end if;

      if rst = '1' then
        grant_valid <= '0';
        grant       <= (others => '0');
        mask        <= (others => '0');
      end if;
    end if;
  end process;


end architecture rtl;