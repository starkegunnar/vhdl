library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity fifo_write_ctrl is
  generic (
    DW          : integer;
    DEPTH       : integer;
    COMMON_CLK  : integer range 0 to 1;
    SYNC_FF     : integer range 2 to 15;
    ASYNC_RESET : integer range 0 to 1
  );
  port (
    wclk    : in  std_logic;
    wrst_n  : in  std_logic;
    we      : in  std_logic;
    wfull   : out std_logic;
    wready  : out std_logic;
    wptr    : out std_logic_vector(f_log2(DEPTH) downto 0);
    rptr    : in  std_logic_vector(f_log2(DEPTH) downto 0)
  );
end entity fifo_write_ctrl;

architecture rtl of fifo_write_ctrl is

  function f_full_mask return std_logic_vector is
    variable msk : std_logic_vector(f_log2(DEPTH) downto 0);
  begin
    msk := std_logic_vector(to_unsigned(2**(f_log2(DEPTH)-1), msk'length));
    if COMMON_CLK = 0 then
      msk := msk or std_logic_vector(to_unsigned(2**(f_log2(DEPTH)-2), msk'length));
    end if;
    return msk;
  end function;

  constant CW         : integer := f_log2(DEPTH)+1;
  constant AW         : integer := CW-1;
  constant FULL_MASK  : std_logic_vector(CW-1 downto 0) := f_full_mask;

  type t_reg is record
    full  : std_logic;
    ready : std_logic;
  end record;

  signal counters   : t_slv_array(0 to 1)(CW-1 downto 0);
  signal rptr_sync  : std_logic_vector(CW-1 downto 0);
  signal q, d       : t_reg;

begin

  gen_counters : for i in 0 to 1 generate
    gen_counter : if COMMON_CLK /= 0 generate
      i_counter : entity lib_common.up_down_counter(rtl)
      generic map (
        WIDTH       => CW,
        ASYNC_RESET => ASYNC_RESET,
        RESET_VAL   => std_logic_vector(to_unsigned(i, CW))
      )
      port map (
        clk   => wclk,
        rstn  => wrst_n,
        en    => we,
        up    => wready,
        down  => '0',
        count => counters(i)
      );
    end generate gen_counter;
    gen_gray_counter : if COMMON_CLK = 0 generate
      i_gray_counter : entity lib_common.gray_counter(rtl)
      generic map (
        WIDTH       => CW,
        ASYNC_RESET => ASYNC_RESET,
        RESET_VAL   => std_logic_vector(to_unsigned(i, CW))
      )
      port map (
        clk   => wclk,
        rst_n => wrst_n,
        clear => '0',
        en    => we and not wfull,
        count => counters(i)
      );
    end generate gen_gray_counter;
  end generate gen_counters;

  gen_rptr_sync : if COMMON_CLK = 0 generate
    i_cdc_sync : entity lib_common.cdc_sync(rtl)
    generic map (
      WIDTH     => CW,
      CDC_TYPE  => "cdc_gray",
      SYNC_FF   => SYNC_FF
    )
    port map (
      clk => wclk,
      d   => rptr,
      q   => rptr_sync
    );
  else generate
    rptr_sync <= rptr;
  end generate;

  p_comb : process(all)
    variable v : t_reg;
    variable full, going_full : std_logic;
  begin
    v := q;

    full := '0';
    going_full := '0';

    if (counters(0) xor rptr_sync) = FULL_MASK then
      full := '1';
    end if;
    if ((COMMON_CLK /= 0 and counters(1)(AW-1 downto 0) = rptr_sync(AW-1 downto 0)) or
        (COMMON_CLK = 0 and (counters(1) xor rptr_sync) = FULL_MASK)) then
      going_full := we;
    end if;

    v.full  := going_full or full;
    v.ready := going_full nor full;

    if ASYNC_RESET = 0 and wrst_n = '0' then
      v.full  := '1';
      v.ready := '0';
    end if;

    d <= v;

    wfull   <= q.full;
    wready  <= q.ready;
    wptr    <= counters(0);
  end process;

  p_reg : process(wclk, wrst_n)
  begin
    if ASYNC_RESET /= 0 and wrst_n = '0' then
      q.full  <= '1';
      q.ready <= '0';
    elsif rising_edge(wclk) then
      q <= d;
    end if;
  end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity fifo_read_ctrl is
  generic (
    DW            : integer;
    DEPTH         : integer;
    FWFT          : integer range 0 to 1;
    READ_LATENCY  : integer range 0 to 1;
    COMMON_CLK    : integer range 0 to 1;
    SYNC_FF       : integer range 2 to 15;
    ASYNC_RESET   : integer range 0 to 1
  );
  port (
    rclk    : in  std_logic;
    rrst_n  : in  std_logic;
    ren     : in  std_logic;
    rempty  : out std_logic;
    rvalid  : out std_logic;
    --
    rptr    : out std_logic_vector(f_log2(DEPTH) downto 0);
    wptr    : in  std_logic_vector(f_log2(DEPTH) downto 0)
  );
end entity fifo_read_ctrl;

architecture rtl of fifo_read_ctrl is

  constant CW : integer := f_log2(DEPTH)+1;
  constant AW : integer := CW-1;

  type t_reg is record
    empty : std_logic_vector(0 to 1);
    valid : std_logic_vector(0 to 1);
  end record;

  signal counters   : t_slv_array(0 to 1)(CW-1 downto 0);
  signal wptr_sync  : std_logic_vector(CW-1 downto 0);
  signal q, d       : t_reg;

begin

  gen_counters : for i in 0 to 1 generate
    gen_counter : if COMMON_CLK /= 0 generate
      i_counter : entity lib_common.up_down_counter(rtl)
      generic map (
        WIDTH       => CW,
        ASYNC_RESET => ASYNC_RESET,
        RESET_VAL   => std_logic_vector(to_unsigned(i, CW))
      )
      port map (
        clk   => rclk,
        rstn  => rrst_n,
        en    => ren,
        up    => q.valid(0),
        down  => '0',
        count => counters(i)
      );
    end generate gen_counter;
    gen_gray_counter : if COMMON_CLK = 0 generate
      i_gray_counter : entity lib_common.gray_counter(rtl)
      generic map (
        WIDTH       => CW,
        ASYNC_RESET => ASYNC_RESET,
        RESET_VAL   => std_logic_vector(to_unsigned(i, CW))
      )
      port map (
        clk   => rclk,
        rst_n => rrst_n,
        clear => '0',
        en    => ren and not q.empty(0),
        count => counters(i)
      );
    end generate gen_gray_counter;
  end generate gen_counters;

  gen_wptr_sync : if COMMON_CLK = 0 generate
    i_cdc_sync : entity lib_common.cdc_sync(rtl)
    generic map (
      WIDTH     => CW,
      CDC_TYPE  => "cdc_gray",
      SYNC_FF   => SYNC_FF
    )
    port map (
      clk => rclk,
      d   => wptr,
      q   => wptr_sync
    );
  else generate
    wptr_sync <= wptr;
  end generate;

  p_comb : process(all)
    variable v : t_reg;
    variable empty, going_empty : std_logic;
  begin
    v := q;

    empty := '0';
    going_empty := '0';

    if counters(0) = wptr_sync then
      empty := '1';
    end if;
    if ((COMMON_CLK = 0 and counters(1)(AW-1 downto 0) = wptr_sync(AW-1 downto 0)) or
        (COMMON_CLK /= 0 and counters(1) = wptr_sync)) then
      going_empty := ren;
    end if;

    v.empty(0)  := going_empty or empty;
    v.valid(0)  := going_empty nor empty;

    if ren = '1' then
      v.empty(1)  := q.empty(0);
      v.valid(1)  := q.valid(0);
    end if;

    if ASYNC_RESET = 0 and rrst_n = '0' then
      v.empty := (others => '1');
      v.valid := (others => '0');
    end if;

    d <= v;

    if READ_LATENCY = 0 and FWFT = 0 then
      rempty  <= q.empty(0);
      rvalid  <= q.valid(0);
    else
      rempty  <= q.empty(1);
      rvalid  <= q.valid(1);
    end if;

    rptr <= counters(0);
  end process;

  p_reg : process(rclk, rrst_n)
  begin
    if ASYNC_RESET /= 0 and rrst_n = '0' then
      q.empty <= (others => '1');
      q.valid <= (others => '0');
    elsif rising_edge(rclk) then
      q <= d;
    end if;
  end process;

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity fifo is
  generic (
    DW            : integer := 32;
    DEPTH         : integer := 512;
    FWFT          : integer range 0 to 1 := 1;
    READ_LATENCY  : integer range 0 to 1 := 1;
    COMMON_CLK    : integer range 0 to 1 := 1;
    SYNC_FF       : integer range 2 to 15 := 2;
    ASYNC_RESET   : integer range 0 to 1 := 0
  );
  port (
    wclk    : in  std_logic;
    wrst_n  : in  std_logic;
    wdata   : in  std_logic_vector(DW-1 downto 0);
    we      : in  std_logic;
    wfull   : out std_logic;
    wready  : out std_logic;
    rclk    : in  std_logic;
    rrst_n  : in  std_logic;
    rdata   : out std_logic_vector(DW-1 downto 0);
    ren     : in  std_logic;
    rempty  : out std_logic;
    rvalid  : out std_logic
  );
end entity fifo;

architecture rtl of fifo is

  constant CW : integer := f_log2(DEPTH)+1;
  constant AW : integer := CW-1;

  signal wptr, rptr   : std_logic_vector(CW-1 downto 0);
  signal waddr, raddr : std_logic_vector(AW-1 downto 0);

  signal rclk_int     : std_logic;
  signal rrst_n_int   : std_logic;
  signal ren_int      : std_logic;

begin

  i_write_ctrl : entity lib_common.fifo_write_ctrl(rtl)
  generic map (
    DW          => DW,
    DEPTH       => DEPTH,
    COMMON_CLK  => COMMON_CLK,
    SYNC_FF     => SYNC_FF,
    ASYNC_RESET => ASYNC_RESET
  )
  port map (
    wclk    => wclk,
    wrst_n  => wrst_n,
    we      => we,
    wfull   => wfull,
    wready  => wready,
    wptr    => wptr,
    rptr    => rptr
  );

  waddr <= f_gray2bin(wptr)(AW-1 downto 0) when COMMON_CLK = 0 else
           wptr(AW-1 downto 0);
  raddr <= f_gray2bin(rptr)(AW-1 downto 0) when COMMON_CLK = 0 else
           rptr(AW-1 downto 0);

  i_sdpram : entity lib_common.sdpram(rtl)
  generic map (
    AW            => AW,
    DEPTH         => DEPTH,
    DW            => DW,
    COMMON_CLK    => COMMON_CLK,
    READ_LATENCY  => READ_LATENCY
  )
  port map (
    wclk  => wclk,
    waddr => waddr,
    we    => we and not wfull,
    wdata => wdata,
    rclk  => rclk,
    raddr => raddr,
    rden  => ren_int,
    rdata => rdata
  );

  rclk_int    <= wclk when COMMON_CLK = 0 else rclk;
  rrst_n_int  <= wrst_n when COMMON_CLK = 0 else rrst_n;

  i_read_ctrl : entity lib_common.fifo_read_ctrl(rtl)
  generic map (
    DW            => DW,
    DEPTH         => DEPTH,
    FWFT          => FWFT,
    READ_LATENCY  => READ_LATENCY,
    COMMON_CLK    => COMMON_CLK,
    SYNC_FF       => SYNC_FF,
    ASYNC_RESET   => ASYNC_RESET
  )
  port map (
    rclk    => rclk,
    rrst_n  => rrst_n,
    ren     => ren_int,
    rempty  => rempty,
    rvalid  => rvalid,
    rptr    => rptr,
    wptr    => wptr
  );

  ren_int <= not rvalid or ren when READ_LATENCY /= 0 and FWFT /= 0 else ren;

end architecture;

