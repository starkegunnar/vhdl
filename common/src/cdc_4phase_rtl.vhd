library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_4phase_src is
  generic (
    DW          : integer;
    SYNC_FF     : integer range 2 to 15 := 2;
    SLICE_OUPUT : integer := 1
  );
  port (
    -- Source clock and reset
    clk         : in  std_logic;
    rstn        : in  std_logic;
    -- Source data and flow control
    s_data      : in  std_logic_vector(DW-1 downto 0);
    s_valid     : in  std_logic;
    s_ready     : out std_logic;
    -- To destination
    async_data  : out std_logic_vector(DW-1 downto 0);
    async_req   : out std_logic;
    async_ack   : in  std_logic
  );
end entity cdc_4phase_src;

architecture rtl of cdc_4phase_src is

  type t_state is (IDLE, WAIT_ACK_SET, WAIT_ACK_CLEAR);

  type t_reg is record
    state : t_state;
    data  : std_logic_vector(DW-1 downto 0);
    req   : std_logic;
  end record;

  constant RST : t_reg := (
    state => IDLE,
    data  => (others => '0'),
    req   => '0'
  );

  signal q, d : t_reg;
  signal ack : std_logic;

begin

  i_ack_sync : entity lib_common.cdc_sync(rtl)
    generic map (WIDTH => 1, SYNC_FF => SYNC_FF)
    port map (clk => clk, rstn => rstn, d(0) => async_ack, q(0) => ack);

  p_comb : process(all)
    variable v      : t_reg;
    variable ready  : std_logic;
  begin
    v := q;

    ready := '0';

    case q.state is
    when IDLE =>
      if SLICE_OUPUT /= 0 then
        ready := '1';
      end if;
      if s_valid then
        v.state := WAIT_ACK_SET;
        v.data  := s_data;
        v.req   := '1';
      end if;
    when WAIT_ACK_SET =>
      if ack then
        v.state := WAIT_ACK_CLEAR;
        v.req   := '0';
      end if;
    when WAIT_ACK_CLEAR =>
      if not ack then
        if SLICE_OUPUT = 0 then
          ready := '1';
        end if;
        v.state := IDLE;
      end if;
    when others =>
      v.state := IDLE;
    end case;

    d <= v;

    s_ready     <= ready;
    async_data  <= q.data;
    async_req   <= q.req;
  end process;

  p_reg : process(clk, rstn)
  begin
    if rstn = '0' then
      q <= RST;
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture rtl;

library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_4phase_dst is
  generic (
    DW          : integer;
    SYNC_FF     : integer range 2 to 15 := 2;
    SLICE_OUPUT : integer := 1;
    RESET_DATA  : integer := 0
  );
  port (
    -- Destination clock and reset
    clk         : in  std_logic;
    rstn        : in  std_logic;
    -- Destination data and flow control
    m_data      : out std_logic_vector(DW-1 downto 0);
    m_valid     : out std_logic;
    m_ready     : in  std_logic;
    -- From source
    async_data  : in  std_logic_vector(DW-1 downto 0);
    async_req   : in  std_logic;
    async_ack   : out std_logic
  );
end entity cdc_4phase_dst;

architecture rtl of cdc_4phase_dst is

  type t_state is (IDLE, WAIT_READY, WAIT_REQ_CLEAR);

  type t_reg is record
    state : t_state;
    ack   : std_logic;
  end record;

  constant RST : t_reg := (
    state => IDLE,
    ack   => '0'
  );

  signal q, d       : t_reg;
  signal req        : std_logic;
  signal valid_out  : std_logic;
  signal ready      : std_logic;

begin

  i_req_sync : entity lib_common.cdc_sync(rtl)
    generic map (WIDTH => 1, SYNC_FF => SYNC_FF)
    port map (clk => clk, rstn => rstn, d(0) => async_req, q(0) => req);

  p_comb : process(all)
    variable v      : t_reg;
    variable valid  : std_logic;
  begin
    v := q;

    valid := '0';

    case q.state is
    when IDLE =>
      if req then
        valid := '1';
        if ready then
          v.state := WAIT_REQ_CLEAR;
          v.ack   := '1';
        else
          v.state := WAIT_READY;
        end if;
      end if;
    when WAIT_READY =>
      valid := '1';
      if ready then
        v.state := WAIT_REQ_CLEAR;
        v.ack   := '1';
      end if;
    when WAIT_REQ_CLEAR =>
      if not req then
        v.state := IDLE;
        v.ack   := '0';
      end if;
    when others =>
      v.state := IDLE;
    end case;

    d <= v;

    valid_out <= valid;
    async_ack <= q.ack;
  end process;

  p_reg : process(clk, rstn)
  begin
    if rstn = '0' then
      q <= RST;
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

  gen_slice : if SLICE_OUPUT /= 0 generate
    i_slice : entity lib_common.reg_slice(rtl)
      generic map (
        DW          => DW,
        SLICE_TYPE  => C_SLICE_TYPE_REG_IN,
        RESET_DATA  => RESET_DATA,
        ASYNC_RESET => 1
      )
      port map (
        clk     => clk,
        rstn    => rstn,
        s_data  => async_data,
        s_valid => valid_out,
        s_ready => ready,
        m_data  => m_data,
        m_valid => m_valid,
        m_ready => m_ready
      );
  end generate gen_slice;

  no_slice : if SLICE_OUPUT = 0 generate
    m_data  <= async_data;
    m_valid <= valid_out;
    ready   <= m_ready;
  end generate;

end architecture rtl;

library ieee;
use ieee.std_logic_1164.all;

library lib_common;
use lib_common.common_pkg.all;

entity cdc_4phase is
  generic (
    DW          : integer := 32;
    SRC_SYNC_FF : integer range 2 to 15 := 2;
    DST_SYNC_FF : integer range 2 to 15 := SRC_SYNC_FF;
    SLICE_OUPUT : integer := 1;
    RESET_DATA  : integer := 0
  );
  port (
    -- Source clock and reset
    s_clk   : in  std_logic;
    s_rstn  : in  std_logic;
    -- Source data and flow control
    s_data  : in  std_logic_vector(DW-1 downto 0);
    s_valid : in  std_logic;
    s_ready : out std_logic;
    -- Destination clock and reset
    m_clk   : in  std_logic;
    m_rstn  : in  std_logic;
    -- Destination data and flow control
    m_data  : out std_logic_vector(DW-1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity cdc_4phase;

architecture rtl of cdc_4phase is

  signal async_data  : std_logic_vector(DW-1 downto 0);
  signal async_req   : std_logic;
  signal async_ack   : std_logic;

begin

  i_src : entity lib_common.cdc_4phase_src(rtl)
    generic map (
      DW          => DW,
      SYNC_FF     => SRC_SYNC_FF,
      SLICE_OUPUT => SLICE_OUPUT
    )
    port map (
      clk         => s_clk,
      rstn        => s_rstn,
      s_data      => s_data,
      s_valid     => s_valid,
      s_ready     => s_ready,
      async_data  => async_data,
      async_req   => async_req,
      async_ack   => async_ack
    );

  i_dst : entity lib_common.cdc_4phase_dst(rtl)
    generic map (
      DW          => DW,
      SYNC_FF     => DST_SYNC_FF,
      SLICE_OUPUT => SLICE_OUPUT,
      RESET_DATA  => RESET_DATA
    )
    port map (
      clk         => m_clk,
      rstn        => m_rstn,
      m_data      => m_data,
      m_valid     => m_valid,
      m_ready     => m_ready,
      async_data  => async_data,
      async_req   => async_req,
      async_ack   => async_ack
    );

end architecture rtl;