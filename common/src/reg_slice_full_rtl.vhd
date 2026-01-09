library ieee;
use ieee.std_logic_1164.all;

entity reg_slice_full is
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
end entity reg_slice_full;

architecture rtl of reg_slice_full is

  type t_reg is record
    s_data  : std_logic_vector(DW-1 downto 0);
    s_ready : std_logic;
    m_data  : std_logic_vector(DW-1 downto 0);
    m_valid : std_logic;
  end record;

  constant RST : t_reg := (
    s_data  => (others => '0'),
    s_ready => '1',
    m_data  => (others => '0'),
    m_valid => '0'
  );

  signal q, d : t_reg;

begin

  p_comb : process(all)
    variable v : t_reg;
  begin
    v := q;

    -- Fill spill register if receiver is not ready but m_data is valid
    if s_valid and q.s_ready and q.m_valid and not m_ready then
      v.s_ready := '0';
    elsif m_ready then
      v.s_ready := '1';
    end if;

    if q.s_ready then
      v.s_data := s_data;
    end if;

    -- Fill m_data if empty or if receiver is ready
    if not q.m_valid or m_ready then
      v.m_valid := s_valid or not q.s_ready;
      v.m_data  := (s_data and q.s_ready) or (q.s_data and not q.s_ready);
    end if;

    if ASYNC_RESET = 0 and rst_n = '0' then
      v.s_ready := RST.s_ready;
      v.m_valid := RST.m_valid;
      if RESET_DATA /= 0 then
        v.s_data := RST.s_data;
        v.m_data := RST.m_data;
      end if;
    end if;

    d <= v;

    if BYPASS = 0 then
      s_ready <= q.s_ready;
      m_data  <= q.m_data;
      m_valid <= q.m_valid;
    else
      s_ready <= m_ready;
      m_data  <= s_data;
      m_valid <= s_valid;
    end if;
  end process;

  p_reg : process(clk, rst_n)
  begin
    if ASYNC_RESET /= 0 and rst_n = '0' then
      q.s_ready <= RST.s_ready;
      q.m_valid <= RST.m_valid;
      if RESET_DATA /= 0 then
        q.s_data <= RST.s_data;
        q.m_data <= RST.m_data;
      end if;
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture rtl;