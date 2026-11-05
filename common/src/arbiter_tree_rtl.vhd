library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity arbiter_tree is
  generic (
    N           : positive := 7;
    DW          : integer := 8;
    ARB_PRIO    : integer range 0 to 2 := 2; -- 0 -> External prio, 1 -> Rotate prio, -> Round robin
    ARB_LOCK    : integer range 0 to 1 := 0;
    ASYNC_RESET : integer range 0 to 1 := 0
  );
  port (
    clk       : in  std_logic;
    rstn      : in  std_logic;
    ext_prio  : in  std_logic_vector(f_log2nz(N)-1 downto 0) := (others => '0');
    s_data    : in  t_slv_array(N-1 downto 0)(DW-1 downto 0);
    s_valid   : in  std_logic_vector(N-1 downto 0);
    s_ready   : out std_logic_vector(N-1 downto 0);
    m_data    : out std_logic_vector(DW-1 downto 0);
    m_id      : out std_logic_vector(f_log2nz(N)-1 downto 0);
    m_valid   : out std_logic;
    m_ready   : in  std_logic
  );
end entity arbiter_tree;

architecture rtl of arbiter_tree is

begin

  gen_tree : if N > 1 generate

    constant LVLS : integer := f_log2nz(N);

    type t_reg is record
      valid_lock  : std_logic_vector(N-1 downto 0);
      prio        : std_logic_vector(LVLS-1 downto 0);
    end record;

    constant RST : t_reg := (
      valid_lock  => (others => '1'),
      prio        => (others => '0')
    );

    type t_branch is record
      valid : std_logic;
      ready : std_logic;
      sel   : std_logic;
      data  : std_logic_vector(DW-1 downto 0);
      id    : std_logic_vector(LVLS-1 downto 0);
    end record;
    type t_tree is array(0 to 2**LVLS-2) of t_branch;

    signal q, d : t_reg;

  begin

    p_comb : process(all)
      variable v        : t_reg;
      variable curr     : integer;
      variable prev     : integer;
      variable idxhi    : integer;
      variable tree     : t_tree;
      variable prio     : std_logic_vector(LVLS-1 downto 0);
      variable valid    : std_logic_vector(N-1 downto 0);
      variable ready    : std_logic_vector(N-1 downto 0);
      variable mask_lo  : std_logic_vector(N-1 downto 0);
      variable mask_hi  : std_logic_vector(N-1 downto 0);
      variable prio_lo  : std_logic_vector(LVLS-1 downto 0);
      variable prio_hi  : std_logic_vector(LVLS-1 downto 0);
    begin
      v := q;

      valid := s_valid;
      if ARB_LOCK /= 0 then
        valid := s_valid and q.valid_lock;
      end if;

      prio := q.prio;
      if ARB_PRIO = 0 then
        prio := ext_prio;
      end if;

      -- Loop top to bottom (requests)
      for i in LVLS-1 downto 0 loop
        for j in 2**i-1 downto 0 loop
          curr  := 2**i-1+j;        -- Current branch
          prev  := 2**(i+1)+2*j-1;  -- Previous branch
          idxhi := LVLS-i-1;        -- Index high bit for the current level
          if i = LVLS-1 then
            -- Top level
            if 2*j < N-1 then
              tree(curr).valid  := or valid(2*j+1 downto 2*j);
              tree(curr).sel    := not valid(2*j) or (valid(2*j+1) and prio(idxhi));
              tree(curr).data   := f_cond(tree(curr).sel = '1', s_data(2*j+1), s_data(2*j));
            elsif 2*j = N-1 then
              tree(curr).valid  := valid(2*j);
              tree(curr).sel    := '0';
              tree(curr).data   := s_data(2*j);
            else
              tree(curr).valid  := '0';
              tree(curr).sel    := '0';
              tree(curr).data   := (others => '0');
            end if;
            tree(curr).id(idxhi) := tree(curr).sel;
          else
            tree(curr).valid  := tree(prev).valid or tree(prev+1).valid;
            tree(curr).sel    := not tree(prev).valid or (tree(prev+1).valid and prio(idxhi));
            tree(curr).data   := f_cond(tree(curr).sel = '1', tree(prev+1).data, tree(prev).data);
            if tree(curr).sel = '1' then
              tree(curr).id(idxhi downto 0) := '1' & tree(prev+1).id(idxhi-1 downto 0);
            else
              tree(curr).id(idxhi downto 0) := '0' & tree(prev).id(idxhi-1 downto 0);
            end if;
          end if;
        end loop;
      end loop;

      -- Loop bottom to top (grants)
      tree(0).ready := m_ready;
      for i in 0 to LVLS-1 loop
        for j in 0 to 2**i-1 loop
          curr  := 2**i-1+j;        -- Current branch
          prev  := 2**(i+1)+2*j-1;  -- Previous branch
          if i = LVLS-1 then
            -- Top level
            if 2*j < N-1 then
              ready(2*j)    := tree(curr).ready and not tree(curr).sel;
              ready(2*j+1)  := tree(curr).ready and tree(curr).sel;
            elsif 2*j = N-1 then
              ready(2*j)    := tree(curr).ready;
            end if;
          else
            tree(prev).ready    := tree(curr).ready and not tree(curr).sel;
            tree(prev+1).ready  := tree(curr).ready and tree(curr).sel;
          end if;
        end loop;
      end loop;

      if ARB_LOCK /= 0 then
        if tree(0).valid = '1' and m_ready = '1' then
          v.valid_lock := (others => '1');
        elsif tree(0).valid = '1' then
          v.valid_lock := valid;
        end if;
      end if;

      if ARB_PRIO /= 0 then
        if tree(0).valid = '1' and m_ready = '1' then
          case ARB_PRIO is
          when 1 =>
            v.prio := std_logic_vector(unsigned(q.prio)+1);
            if not f_is_pow2(N) and unsigned(q.prio) = N-1 then
              v.prio := (others => '0');
            end if;
          when 2 =>
            mask_lo := (others => '0');
            mask_hi := (others => '0');
            for i in 0 to N-1 loop
              mask_lo(i) := f_cond(i <= unsigned(q.prio), valid(i), '0');
              mask_hi(i) := f_cond(i > unsigned(q.prio), valid(i), '0');
            end loop;
            prio_lo := f_ctz(mask_lo);
            prio_hi := f_ctz(mask_hi);
            v.prio  := f_cond(or mask_hi = '0', prio_lo, prio_hi);
          when others =>
          end case;
        end if;
      end if;

      if ASYNC_RESET = 0 and rstn = '0' then
        v := RST;
      end if;

      d <= v;

      -- Assign outputs
      s_ready <= ready;
      m_id    <= tree(0).id;
      m_valid <= tree(0).valid;
      m_data  <= tree(0).data;
    end process;

    p_reg : process(clk, rstn)
    begin
      if ASYNC_RESET /= 0 and rstn = '0' then
        q <= RST;
      elsif rising_edge(clk) then
        q <= d;
      end if;
    end process;
  end generate;

  no_tree : if N = 1 generate
    s_ready(0)  <= m_ready;
    m_valid     <= s_valid(0);
    m_data      <= s_data(0);
    m_id        <= "0";
  end generate;

end architecture rtl;