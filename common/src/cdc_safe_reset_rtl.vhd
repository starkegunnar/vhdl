library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_safe_reset is
    generic (
        SYNC_STAGES : integer range 2 to 15 := 2
    );
    port (
        src_clk_i  : in  std_logic;
        src_rst_ni : in  std_logic;
        src_rst_no : out std_logic;
        dst_clk_i  : in  std_logic;
        dst_rst_ni : in  std_logic;
        dst_rst_no : out std_logic
    );
end entity cdc_safe_reset;

architecture rtl of cdc_safe_reset is
    constant C_ONE : std_logic_vector(0 downto 0) := "1";

    signal async_rst_n       : std_logic;
    signal src_local_rst_n   : std_logic_vector(0 downto 0);
    signal dst_local_rst_n   : std_logic_vector(0 downto 0);
    signal dst_ready_src     : std_logic_vector(0 downto 0);
    signal src_ready_dst     : std_logic_vector(0 downto 0);
begin
    -- Either input reset asynchronously asserts reset in both domains.
    async_rst_n <= src_rst_ni and dst_rst_ni;

    -- Local reset release is synchronized to each domain's clock.
    src_reset_release : cdc_sync
        generic map (
            WIDTH     => 1,
            SYNC_FF   => SYNC_STAGES,
            RESET_VAL => '0'
        )
        port map (
            clk  => src_clk_i,
            rstn => async_rst_n,
            d    => C_ONE,
            q    => src_local_rst_n
        );

    dst_reset_release : cdc_sync
        generic map (
            WIDTH     => 1,
            SYNC_FF   => SYNC_STAGES,
            RESET_VAL => '0'
        )
        port map (
            clk  => dst_clk_i,
            rstn => async_rst_n,
            d    => C_ONE,
            q    => dst_local_rst_n
        );

    -- Synchronize each domain's released status into the other domain.
    dst_ready_to_src : cdc_sync
        generic map (
            WIDTH     => 1,
            SYNC_FF   => SYNC_STAGES,
            RESET_VAL => '0'
        )
        port map (
            clk  => src_clk_i,
            rstn => src_local_rst_n(0),
            d    => dst_local_rst_n,
            q    => dst_ready_src
        );

    src_ready_to_dst : cdc_sync
        generic map (
            WIDTH     => 1,
            SYNC_FF   => SYNC_STAGES,
            RESET_VAL => '0'
        )
        port map (
            clk  => dst_clk_i,
            rstn => dst_local_rst_n(0),
            d    => src_local_rst_n,
            q    => src_ready_dst
        );

    -- Remain asserted until both domains have released reset.
    src_rst_no <= src_local_rst_n(0) and dst_ready_src(0);
    dst_rst_no <= dst_local_rst_n(0) and src_ready_dst(0);
end architecture rtl;
