library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity reg_slice_pipe is
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
end entity reg_slice_pipe;

architecture rtl of reg_slice_pipe is

  type t_reg is record
    shreg     : t_slv_array(3 downto 0)(DW-1 downto 0);
    ptr       : std_logic_vector(1 downto 0);
    s_valid_d : std_logic;
    s_ready_d : std_logic;
    s_ready   : std_logic;
  end record;

  constant RST : t_reg := (
    shreg     => (others => (others => '0')),
    ptr       => (others => '0'),
    s_valid_d => '0',
    s_ready_d => '0',
    s_ready   => '0'
  );

  signal q, d : t_reg;

begin

  p_comb : process(all)
    variable v : t_reg;
    variable w, r : std_logic;
  begin
    v := q;

    -- Pipe valid and ready
    v.s_valid_d := s_valid;
    v.s_ready_d := q.s_ready;
    v.s_ready   := m_ready;

    -- Pipe data
    v.shreg(0) := s_data;

    -- Store data if receiver is not ready
    if q.s_valid_d and q.s_ready_d then
      v.shreg(3 downto 1) := q.shreg(2 downto 0);
    end if;

    -- Increment or decrement pointer
    w := q.s_valid_d and q.s_ready_d and ((or q.ptr) or not m_ready);
    r := (or q.ptr) and m_ready;
    if w and not r then
      v.ptr := std_logic_vector(unsigned(q.ptr) + 1);
    elsif not w and r then
      v.ptr := std_logic_vector(unsigned(q.ptr) - 1);
    end if;

    -- Synchronous reset
    if ASYNC_RESET = 0 and rst_n = '0' then
      v.ptr       := RST.ptr;
      v.s_valid_d := RST.s_valid_d;
      v.s_ready_d := RST.s_ready_d;
      v.s_ready   := RST.s_ready;
      if RESET_DATA /= 0 then
        v.shreg := RST.shreg;
      end if;
    end if;

    -- Register data
    d <= v;

    -- Assign outputs
    if BYPASS = 0 then
      s_ready <= q.s_ready;
      m_data  <= q.shreg(to_integer(unsigned(q.ptr)));
      m_valid <= (q.s_valid_d and q.s_ready_d) or (or q.ptr);
    else
      s_ready <= m_ready;
      m_data  <= s_data;
      m_valid <= s_valid;
    end if;
  end process;

  p_reg : process(clk, rst_n)
  begin
    if rising_edge(clk) then
      q <= d;
    end if;
    if ASYNC_RESET /= 0 and rst_n = '0' then
      q.ptr       <= RST.ptr;
      q.s_valid_d <= RST.s_valid_d;
      q.s_ready_d <= RST.s_ready_d;
      q.s_ready   <= RST.s_ready;
      if RESET_DATA /= 0 then
        q.shreg <= RST.shreg;
      end if;
    end if;
  end process;

end architecture rtl;