library ieee;
use ieee.std_logic_1164.all;

entity fallthrough_reg is
  generic (
    DW          : integer;
    RESET_DATA  : integer := 0;
    ASYNC_RESET : integer := 0
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
end entity fallthrough_reg;

architecture rtl of fallthrough_reg is

  type t_reg is record
    m_data  : std_logic_vector(DW-1 downto 0);
    m_valid : std_logic;
  end record;

  constant RST : t_reg := (m_data => (others => '0'), m_valid => '0');

  signal q, d : t_reg;

begin

  p_comb : process(all)
    variable v : t_reg;
  begin
    v := q;

    if not q.m_valid or m_ready then
      v.m_valid := s_valid;
      v.m_data  := s_data;
    end if;

    if ASYNC_RESET = 0 and rst_n = '0' then
      v.m_valid := RST.m_valid;
      if RESET_DATA /= 0 then
        v.m_data := RST.m_data;
      end if;
    end if;

    d <= v;

    s_ready <= not q.m_valid or m_ready;
    m_data  <= q.m_data;
    m_valid <= q.m_valid;
  end process;

  p_reg : process(clk, rst_n)
  begin
    if rising_edge(clk) then
      q <= d;
    end if;
    if ASYNC_RESET /= 0 and rst_n = '0' then
      q.m_valid <= RST.m_valid;
      if RESET_DATA /= 0 then
        q.m_data <= RST.m_data;
      end if;
    end if;
  end process;

end architecture rtl;