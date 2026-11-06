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
    wrstn   : in  std_logic;
    we      : in  std_logic;
    wfull   : out std_logic;
    wready  : out std_logic;
    wptr    : out std_logic_vector(f_log2(DEPTH) downto 0);
    rptr    : in  std_logic_vector(f_log2(DEPTH) downto 0)
  );
end entity fifo_write_ctrl;

architecture rtl of fifo_write_ctrl is

  constant CW         : integer := f_log2(DEPTH)+1;
  constant AW         : integer := CW-1;
  constant FM         : integer := 2**(f_log2(DEPTH)) + (1-COMMON_CLK) * (2**(f_log2(DEPTH)-1));
  constant FULL_MASK  : std_logic_vector(CW-1 downto 0) := std_logic_vector(to_unsigned(FM, CW));

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
      i_counter : counter
      generic map (
        WIDTH       => AW,
        MAX_VALUE   => std_logic_vector(to_unsigned(DEPTH-1, AW)),
        RESET_VAL   => std_logic_vector(to_unsigned(i, AW)),
        ASYNC_RESET => ASYNC_RESET
      )
      port map (
        clk   => wclk,
        rstn  => wrstn,
        en    => we and wready,
        count => counters(i)(AW-1 downto 0),
        wrap  => counters(i)(AW)
      );
    end generate gen_counter;
    gen_gray_counter : if COMMON_CLK = 0 generate
      i_gray_counter : gray_counter
      generic map (
        WIDTH       => CW,
        ASYNC_RESET => ASYNC_RESET,
        RESET_VAL   => std_logic_vector(to_unsigned(i, CW))
      )
      port map (
        clk   => wclk,
        rstn  => wrstn,
        clear => '0',
        en    => we and not wfull,
        count => counters(i)
      );
    end generate gen_gray_counter;
  end generate gen_counters;

  gen_rptr_sync : if COMMON_CLK = 0 generate
    i_cdc_sync : cdc_sync
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

    if ASYNC_RESET = 0 and wrstn = '0' then
      v.full  := '1';
      v.ready := '0';
    end if;

    d <= v;

    wfull   <= q.full;
    wready  <= q.ready;
    wptr    <= counters(0);
  end process;

  p_reg : process(wclk, wrstn)
  begin
    if rising_edge(wclk) then
      q <= d;
    end if;
    if ASYNC_RESET /= 0 and wrstn = '0' then
      q.full  <= '1';
      q.ready <= '0';
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
    rrstn   : in  std_logic;
    ren     : in  std_logic;
    rempty  : out std_logic;
    rvalid  : out std_logic;
    --
    rptr    : out std_logic_vector(f_log2(DEPTH) downto 0);
    wptr    : in  std_logic_vector(f_log2(DEPTH) downto 0)
  );
end entity fifo_read_ctrl;

architecture rtl of fifo_read_ctrl is

  constant CW   : integer := f_log2(DEPTH)+1;
  constant AW   : integer := CW-1;

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
      i_counter : counter
      generic map (
        WIDTH       => AW,
        MAX_VALUE   => std_logic_vector(to_unsigned(DEPTH-1, AW)),
        RESET_VAL   => std_logic_vector(to_unsigned(i, AW)),
        ASYNC_RESET => ASYNC_RESET
      )
      port map (
        clk   => rclk,
        rstn  => rrstn,
        en    => ren and q.valid(0),
        count => counters(i)(AW-1 downto 0),
        wrap  => counters(i)(AW)
      );
    end generate gen_counter;
    gen_gray_counter : if COMMON_CLK = 0 generate
      i_gray_counter : gray_counter
      generic map (
        WIDTH       => CW,
        ASYNC_RESET => ASYNC_RESET,
        RESET_VAL   => std_logic_vector(to_unsigned(i, CW))
      )
      port map (
        clk   => rclk,
        rstn  => rrstn,
        clear => '0',
        en    => ren and not q.empty(0),
        count => counters(i)
      );
    end generate gen_gray_counter;
  end generate gen_counters;

  gen_wptr_sync : if COMMON_CLK = 0 generate
    i_cdc_sync : cdc_sync
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
    if counters(1) = wptr_sync then
      going_empty := ren;
    end if;

    v.empty(0)  := going_empty or empty;
    v.valid(0)  := going_empty nor empty;

    if ren = '1' then
      v.empty(1)  := q.empty(0);
      v.valid(1)  := q.valid(0);
    end if;

    if ASYNC_RESET = 0 and rrstn = '0' then
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

  p_reg : process(rclk, rrstn)
  begin
    if rising_edge(rclk) then
      q <= d;
    end if;
    if ASYNC_RESET /= 0 and rrstn = '0' then
      q.empty <= (others => '1');
      q.valid <= (others => '0');
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
    wrstn   : in  std_logic;
    wdata   : in  std_logic_vector(DW-1 downto 0);
    we      : in  std_logic;
    wfull   : out std_logic;
    wready  : out std_logic;
    rclk    : in  std_logic;
    rrstn   : in  std_logic;
    rdata   : out std_logic_vector(DW-1 downto 0);
    ren     : in  std_logic;
    rempty  : out std_logic;
    rvalid  : out std_logic
  );
end entity fifo;

architecture rtl of fifo is

  constant CW : integer := f_log2(DEPTH)+1;
  constant AW : integer := CW-1;
  -- Async FIFO must have a depth which is a power of two
  constant FD : integer := COMMON_CLK*DEPTH+(1-COMMON_CLK)*2**AW;

  signal wptr, rptr   : std_logic_vector(CW-1 downto 0);
  signal waddr, raddr : std_logic_vector(AW-1 downto 0);

  signal wrstn_int : std_logic;
  signal rrstn_int : std_logic;

begin

  i_write_ctrl : entity lib_common.fifo_write_ctrl(rtl)
  generic map (
    DW          => DW,
    DEPTH       => FD,
    COMMON_CLK  => COMMON_CLK,
    SYNC_FF     => SYNC_FF,
    ASYNC_RESET => ASYNC_RESET
  )
  port map (
    wclk    => wclk,
    wrstn   => wrstn_int,
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

  i_sdpram : sdpram
  generic map (
    AW            => AW,
    DEPTH         => FD,
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

  gen_async_reset : if COMMON_CLK = 0 generate
    i_safe_reset : cdc_safe_reset
      generic map (
        SYNC_STAGES => SYNC_FF+1
      )
      port map (
        src_clk_i  => wclk,
        src_rst_ni => wrstn,
        src_rst_no => wrstn_int,
        dst_clk_i  => rclk,
        dst_rst_ni => rrstn,
        dst_rst_no => rrstn_int
      );
  end generate;

  gen_common_reset : if COMMON_CLK /= 0 generate
    wrstn_int <= wrstn;
    rrstn_int <= rrstn;
  end generate;

  i_read_ctrl : entity lib_common.fifo_read_ctrl(rtl)
  generic map (
    DW            => DW,
    DEPTH         => FD,
    FWFT          => FWFT,
    READ_LATENCY  => READ_LATENCY,
    COMMON_CLK    => COMMON_CLK,
    SYNC_FF       => SYNC_FF,
    ASYNC_RESET   => ASYNC_RESET
  )
  port map (
    rclk    => rclk,
    rrstn   => rrstn_int,
    ren     => ren_int,
    rempty  => rempty,
    rvalid  => rvalid,
    rptr    => rptr,
    wptr    => wptr
  );

  ren_int <= not rvalid or ren when READ_LATENCY /= 0 and FWFT /= 0 else ren;

end architecture;

