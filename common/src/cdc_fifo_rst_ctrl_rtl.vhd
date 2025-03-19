library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_fifo_rst_ctrl is
  generic (
    g_src_sync_ff : natural range 2 to 12 := 2;
    g_dst_sync_ff : natural range 2 to 12 := 2
  );
  port (
    -- Clock and reset
    src_clk     : in  std_logic;
    src_rst_in  : in  std_logic;
    src_rst_out : out std_logic;
    -- Clock and reset
    dst_clk     : in  std_logic;
    dst_rst_out : out std_logic
  );
end entity cdc_fifo_rst_ctrl;

architecture rtl of cdc_fifo_rst_ctrl is

  type t_src_state is (e_idle, e_src_rst, e_wait_ack);
  type t_dst_state is (e_idle, e_dst_rst, e_wait_ack);

begin

  p_src_state : process(src_clk)
  begin
    if rising_edge(clk) then
      if src_rst_in = '1' then
        src_state <= e_src_rst;
      else
        case src_state is
        when e_idle =>
          -- Do nothing
        when e_src_rst =>
          -- Wait for ack from dst
          if src_rst_ack = '1' then
            src_state <= e_wait;
          end if;
        when e_wait =>
          -- Wait for clear ack from dst
          if src_rst_ack = '0' then
            src_state <= e_idle;
          end if;
        end case;
      end if;
    end if;
  end process;

end architecture rtl;