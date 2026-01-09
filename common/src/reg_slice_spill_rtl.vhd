library ieee;
use ieee.std_logic_1164.all;

entity reg_slice_spill is
  generic (
    DW          : integer;
    RESET_DATA  : integer := 0;
    ASYNC_RESET : integer := 0;
    BYPASS      : integer := 0
  );
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst_n   : in  std_logic;
    -- Data and flow control
    s_data  : in  std_logic_vector(DW-1 downto 0);
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out std_logic_vector(DW-1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity reg_slice_spill;

architecture rtl of reg_slice_spill is

  type t_reg is record
    s_data    : std_logic_vector(DW-1 downto 0);
    s_valid   : std_logic;
    s_data_d  : std_logic_vector(DW-1 downto 0);
    s_ready_d : std_logic;
  end record;

  constant RST : t_reg := (
    s_data    => (others => '0'),
    s_valid   => '0',
    s_data_d  => (others => '0'),
    s_ready_d => '1'
  );

  signal q, d : t_reg;

begin

  p_comb : process(all)
    variable v : t_reg;
  begin
    v := q;

    if (s_valid or q.s_valid) and q.s_ready_d then
      v.s_valid := s_valid and q.s_ready_d;
    end if;

    if s_valid and q.s_ready_d then
      v.s_data := s_data;
    end if;

    if (q.s_valid and q.s_ready_d and not m_ready) or (not q.s_ready_d and m_ready) then
      v.s_ready_d := not (q.s_valid and q.s_ready_d and not m_ready);
    end if;

    if q.s_ready_d and not m_ready then
      v.s_data_d := q.s_data;
    end if;

    if ASYNC_RESET = 0 and rst_n = '0' then
      v.s_valid   := RST.s_valid;
      v.s_ready_d := RST.s_ready_d;
      if RESET_DATA /= 0 then
        v.s_data    := RST.s_data;
        v.s_data_d  := RST.s_data_d;
      end if;
    end if;

    d <= v;

    if BYPASS = 0 then
      s_ready <= q.s_ready_d;
      m_data  <= (q.s_data and q.s_ready_d) or (q.s_data_d and not q.s_ready_d);
      m_valid <= q.s_valid or not q.s_ready_d;
    else
      s_ready <= m_ready;
      m_data  <= s_data;
      m_valid <= s_valid;
    end if;
  end process;

  p_reg : process(clk, rst_n)
  begin
    if ASYNC_RESET /= 0 and rst_n = '0' then
      q.s_valid   <= RST.s_valid;
      q.s_ready_d <= RST.s_ready_d;
      if RESET_DATA /= 0 then
        q.s_data    <= RST.s_data;
        q.s_data_d  <= RST.s_data_d;
      end if;
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture rtl;