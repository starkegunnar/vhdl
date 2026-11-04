library ieee;
use ieee.std_logic_1164.all;

entity reg_slice_full is
  generic (
    DW          : integer;
    RESET_DATA  : integer range 0 to 1 := 0;
    ASYNC_RESET : integer range 0 to 1 := 0;
    SLICE_TYPE  : integer range 0 to 3 := 1;
    LOW_FANOUT  : integer range 0 to 1 := 0
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

  constant DD : integer := cond(SLICE_TYPE = 3, 4, 2);
  constant RW : integer := cond(SLICE_TYPE = 3, 2, 1);

  type t_reg is record
    data    : t_slv_array(0 to DD-1)(DW-1 downto 0);
    valid   : std_logic;
    ready   : std_logic_vector(RW-1 downto 0);
    ptr     : std_logic_vector(1 downto 0);
  end record;

  constant RST : t_reg := (
    data    => (others => (others => '0')),
    valid   => '0',
    ready   => (others => cond(SLICE_TYPE = 3, '0', '1')),
    ptr     => (others => '0')
  );

  signal q, d : t_reg;

begin

  p_comb : process(all)
    variable v : t_reg;
    variable wr, rd : std_logic;
  begin
    v := q;

    case SLICE_TYPE is
    when C_SLICE_TYPE_REG_OUT =>

      -- Fill spill register if receiver is not ready but m_data is valid
      if s_valid and not q.ready(0) and q.valid and not m_ready then
        v.ready(0) := '0';
      elsif m_ready then
        v.ready(0) := '1';
      end if;

      if q.ready(0) and (LOW_FANOUT /= 0 or s_valid) then
        v.data(0) := s_data;
      end if;

      -- Fill m_data if empty or if receiver is ready
      if not q.valid or m_ready then
        if LOW_FANOUT /= 0 then
          v.valid := s_valid or not q.ready(0);
          v.data  := (s_data and q.ready(0)) or (q.data(0) and not q.ready(0));
        elsif not q.ready(0) or s_valid then
          v.valid := '1';
          if not q.ready(0) then
            v.data  := q.data(0);
          elsif s_valid then
            v.data  := s_data;
          end if;
        end if;
      end if;

      s_ready <= q.ready(0);
      m_data  <= q.data(1);
      m_valid <= q.valid;

    when C_SLICE_TYPE_REG_IN =>

      -- Update valid if input is valid or if spill register is empty
      if (s_valid or q.valid) and q.ready(0) then
        v.valid := s_valid and q.ready(0);
      end if;

      -- Sample input data if spill register is empty (and input data is valid)
      if q.ready(0) and (LOW_FANOUT /= 0 or s_valid) then
        v.data(0) := s_data;
      end if;

      -- Update ready if spill is empty but output is stalled, or if spill is full and output is ready
      if (q.valid and q.ready(0) and not m_ready) or (not q.ready(0) and m_ready) then
        v.s_ready(0) := not (q.valid and q.ready(0) and not m_ready);
      end if;

      -- Fill spill if ready and output is stalled
      if (q.ready(0) and not m_ready) and (LOW_FANOUT /= 0 or q.valid) then
        v.data(1) := q.data(0);
      end if;

      s_ready <= q.ready(0);
      m_valid <= q.valid or not q.ready(0);
      m_data  <= (q.data(0) and q.ready(0)) or (q.data(1) and not q.ready(0));

    when C_SLICE_TYPE_PIPE => 

      -- Pipe valid and ready
      v.valid     := s_valid;
      v.ready(1)  := q.ready(0);
      v.ready(0)  := m_ready;

      -- Pipe data
      v.data(0)   := s_data;

      -- Store data if receiver is not ready
      if q.valid and q.s_ready(1) then
        v.shreg(1 to DW-1) := q.shreg(0 to DW-2);
      end if;

      -- Increment or decrement pointer
      wr := q.valid and q.ready(1) and ((or q.ptr) or not m_ready);
      rd := (or q.ptr) and m_ready;
      if wr and not rd then
        v.ptr := std_logic_vector(unsigned(q.ptr) + 1);
      elsif not wr and rd then
        v.ptr := std_logic_vector(unsigned(q.ptr) - 1);
      end if;

      s_ready <= q.ready(0);
      m_data  <= q.data(to_integer(unsigned(q.ptr)));
      m_valid <= (q.valid and q.ready(1)) or (or q.ptr);

    when others =>
      -- Passthrough
      s_ready <= m_ready;
      m_data  <= s_data;
      m_valid <= s_valid;

    end case;

    if SLICE_TYPE /= 0 then
      if ASYNC_RESET = 0 and rst_n = '0' then
        v.ready := RST.ready;
        v.valid := RST.valid;
        if RESET_DATA /= 0 then
          v.data := RST.data;
        end if;
        if SLICE_TYPE = C_SLICE_TYPE_PIPE then
          v.ptr := RST.ptr;
        end if;
      end if;
    end if;

    d <= v;
  end process;

  b_reg : if SLICE_TYPE /= 0 generate
    p_reg : process(clk, rst_n)
    begin
      if rising_edge(clk) then
        q <= d;
      end if;
      if ASYNC_RESET /= 0 and rst_n = '0' then
        q.ready <= RST.ready;
        q.valid <= RST.valid;
        if RESET_DATA /= 0 then
          q.data <= RST.data;
        end if;
        if SLICE_TYPE = C_SLICE_TYPE_PIPE then
          q.ptr <= RST.ptr;
        end if;
      end if;
    end process;
  end generate;

end architecture rtl;