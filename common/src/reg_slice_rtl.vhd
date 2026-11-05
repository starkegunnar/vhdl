library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity reg_slice is
  generic (
    DW          : integer;
    SLICE_TYPE  : integer range 0 to 3 := 1; -- 0 -> Passthrough, no slice
                                             -- 1 -> Registered output
                                             -- 2 -> Registered input
                                             -- 3 -> Registered input pipe
    RESET_DATA  : integer range 0 to 1 := 0;
    ASYNC_RESET : integer range 0 to 1 := 0;
    LOW_FANOUT  : integer range 0 to 1 := 0
  );
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rstn    : in  std_logic;
    -- Data and flow control
    s_data  : in  std_logic_vector(DW-1 downto 0);
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out std_logic_vector(DW-1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity reg_slice;

architecture rtl of reg_slice is

  constant DD : integer := f_cond(SLICE_TYPE = 3, 4, 2);
  constant RW : integer := f_cond(SLICE_TYPE = 3, 2, 1);

  type t_reg is record
    data    : t_slv_array(0 to DD-1)(DW-1 downto 0);
    valid   : std_logic;
    ready   : std_logic_vector(1 downto 0);
    ptr     : std_logic_vector(1 downto 0);
  end record;

  constant RST : t_reg := (
    data    => (others => (others => '0')),
    valid   => '0',
    ready   => (others => f_cond(SLICE_TYPE = 3, '0', '1')),
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
      if s_valid = '1' and q.ready(0) = '1' and q.valid = '1' and m_ready = '0' then
        v.ready(0) := '0';
      elsif m_ready = '1' then
        v.ready(0) := '1';
      end if;

      -- Fill spill register data
      if q.ready(0) = '1' and (LOW_FANOUT /= 0 or s_valid = '1') then
        v.data(0) := s_data;
      end if;

      -- Set m_data if empty or if receiver is ready
      if q.valid = '0' or m_ready = '1' then
        v.valid := s_valid or not q.ready(0);
        if LOW_FANOUT /= 0 or s_valid = '1' or q.ready(0) = '0' then
          v.data(1)  := (s_data and q.ready(0)) or (q.data(0) and not q.ready(0));
        end if;
      end if;

      s_ready <= q.ready(0);
      m_data  <= q.data(1);
      m_valid <= q.valid;

    when C_SLICE_TYPE_REG_IN =>

      -- Update valid if input is valid or if spill register is empty
      if (s_valid = '1' or q.valid = '1') and q.ready(0) = '1' then
        v.valid := s_valid and q.ready(0);
      end if;

      -- Sample input data if spill register is empty (and input data is valid)
      if q.ready(0) = '1' and (LOW_FANOUT /= 0 or s_valid = '1') then
        v.data(0) := s_data;
      end if;

      -- Update ready if spill is empty but output is stalled, or if spill is full and output is ready
      if (q.valid = '1' and q.ready(0) = '1' and m_ready = '0') or (q.ready(0) = '0' and m_ready = '1') then
        v.ready(0) := not (q.valid and q.ready(0) and not m_ready);
      end if;

      -- Fill spill if ready and output is stalled
      if (q.ready(0) = '1' and m_ready = '0') and (LOW_FANOUT /= 0 or q.valid = '1') then
        v.data(1) := q.data(0);
      end if;

      s_ready <= q.ready(0);
      m_valid <= q.valid or not q.ready(0);
      m_data  <= (q.data(0) and q.ready(0)) or (q.data(1) and not q.ready(0));

    when C_SLICE_TYPE_PIPE =>

      -- Pipe valid and ready
      v.valid     := s_valid;
      v.ready(1)  := q.ready(0);
      v.ready(0)  := m_ready or nor q.ptr;

      -- Pipe data
      if LOW_FANOUT /= 0 or s_valid = '1' then
        v.data(0) := s_data;
      end if;

      -- Shift data
      if q.valid = '1' and q.ready(1) = '1' and (LOW_FANOUT /= 0 or (q.ptr /= "00" or m_ready = '0')) then
        v.data(1 to DD-1) := q.data(0 to DD-2);
      end if;

      -- Write to shift register if data is valid and the
      -- the pointer is not zero or the output is stalled
      wr := q.valid and q.ready(1) and ((or q.ptr) or not m_ready);
      -- Read from shift register if the pointer is not zero and
      -- the output is ready
      rd := (or q.ptr) and m_ready;
      if wr = '1' and rd = '0' then
        v.ptr := std_logic_vector(unsigned(q.ptr) + 1);
      elsif wr = '0' and rd = '1' then
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
      if ASYNC_RESET = 0 and rstn = '0' then
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

  p_reg : process(clk, rstn)
  begin
    if SLICE_TYPE /= 0 then
      if rising_edge(clk) then
        q <= d;
      end if;
      if ASYNC_RESET /= 0 and rstn = '0' then
        q.ready <= RST.ready;
        q.valid <= RST.valid;
        if RESET_DATA /= 0 then
          q.data <= RST.data;
        end if;
        if SLICE_TYPE = C_SLICE_TYPE_PIPE then
          q.ptr <= RST.ptr;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;