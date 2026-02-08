library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity arbiter_tree is
  generic (
    N_REQ       : integer := 7;
    DW          : integer := 8;
    ARB_PRIO    : integer range 0 to 2 := 2; -- 0 -> External prio, 1 -> Rotate prio, -> Round robin
    ARB_LOCK    : integer range 0 to 1 := 0;
    ASYNC_RESET : integer range 0 to 1 := 0
  );
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    ext_prio  : in  std_logic_vector(f_log2nz(N_REQ)-1 downto 0) := (others => '0');
    ireq      : in  std_logic_vector(N_REQ-1 downto 0);
    idata     : in  t_slv_array(N_REQ-1 downto 0)(DW-1 downto 0);
    ognt      : out std_logic_vector(N_REQ-1 downto 0);
    oreq      : out std_logic;
    odata     : out std_logic_vector(DW-1 downto 0);
    ignt      : in  std_logic;
    oidx      : out std_logic_vector(f_log2nz(N_REQ)-1 downto 0)
  );
end entity arbiter_tree;

architecture rtl of arbiter_tree is

  constant LVLS : integer := f_log2nz(N_REQ);

  type t_reg is record
    req_lock  : std_logic_vector(N_REQ-1 downto 0);
    prio      : std_logic_vector(LVLS-1 downto 0);
  end record;

  constant RST : t_reg := (
    req_lock  => (others => '1'),
    prio      => (others => '0')
  );

  type t_branch is record
    req   : std_logic;
    gnt   : std_logic;
    sel   : std_logic;
    data  : std_logic_vector(DW-1 downto 0);
    idx   : std_logic_vector(LVLS-1 downto 0);
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
    variable req      : std_logic_vector(N_REQ-1 downto 0);
    variable gnt      : std_logic_vector(N_REQ-1 downto 0);
    variable mask_lo  : std_logic_vector(N_REQ-1 downto 0);
    variable mask_hi  : std_logic_vector(N_REQ-1 downto 0);
    variable prio_lo  : std_logic_vector(LVLS-1 downto 0);
    variable prio_hi  : std_logic_vector(LVLS-1 downto 0);
  begin
    v := q;

    req := ireq;
    if ARB_LOCK /= 0 then
      req := ireq and q.req_lock;
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
          if 2*j < N_REQ-1 then
            tree(curr).req  := or req(2*j+1 downto 2*j);
            tree(curr).sel  := not req(2*j) or (req(2*j+1) and prio(idxhi));
            tree(curr).data := f_cond(tree(curr).sel = '1', idata(2*j+1), idata(2*j));
          elsif 2*j = N_REQ-1 then
            tree(curr).req  := req(2*j);
            tree(curr).sel  := '0';
            tree(curr).data := idata(2*j);
          else
            tree(curr).req  := '0';
            tree(curr).sel  := '0';
            tree(curr).data := (others => '0');
          end if;
          tree(curr).idx(idxhi) := tree(curr).sel;
        else
          tree(curr).req  := tree(prev).req or tree(prev+1).req;
          tree(curr).sel  := not tree(prev).req or (tree(prev+1).req and prio(idxhi));
          tree(curr).data := f_cond(tree(curr).sel = '1', tree(prev+1).data, tree(prev).data);
          if tree(curr).sel = '1' then
            tree(curr).idx(idxhi downto 0) := '1' & tree(prev+1).idx(idxhi-1 downto 0);
          else
            tree(curr).idx(idxhi downto 0) := '0' & tree(prev).idx(idxhi-1 downto 0);
          end if;
        end if;
      end loop;
    end loop;

    -- Loop bottom to top (grants)
    tree(0).gnt := ignt;
    for i in 0 to LVLS-1 loop
      for j in 0 to 2**i-1 loop
        curr  := 2**i-1+j;        -- Current branch
        prev  := 2**(i+1)+2*j-1;  -- Previous branch
        if i = LVLS-1 then
          -- Top level
          if 2*j < N_REQ-1 then
            gnt(2*j)    := tree(curr).gnt and not tree(curr).sel;
            gnt(2*j+1)  := tree(curr).gnt and tree(curr).sel;
          elsif 2*j = N_REQ-1 then
            gnt(2*j)    := tree(curr).gnt;
          end if;
        else
          tree(prev).gnt    := tree(curr).gnt and not tree(curr).sel;
          tree(prev+1).gnt  := tree(curr).gnt and tree(curr).sel;
        end if;
      end loop;
    end loop;

    if ARB_LOCK /= 0 then
      if tree(0).req = '1' and ignt = '1' then
        v.req_lock := (others => '1');
      elsif tree(0).req = '1' then
        v.req_lock := req;
      end if;
    end if;

    if ARB_PRIO /= 0 then
      if tree(0).req = '1' and ignt = '1' then
        case ARB_PRIO is
        when 1 =>
          v.prio := std_logic_vector(unsigned(q.prio)+1);
          if not f_is_pow2(N_REQ) and unsigned(q.prio) = N_REQ-1 then
            v.prio := (others => '0');
          end if;
        when 2 =>
          mask_lo := (others => '0');
          mask_hi := (others => '0');
          for i in 0 to N_REQ-1 loop
            mask_lo(i) := f_cond(i <= unsigned(q.prio), req(i), '0');
            mask_hi(i) := f_cond(i > unsigned(q.prio), req(i), '0');
          end loop;
          prio_lo := f_ctz(mask_lo);
          prio_hi := f_ctz(mask_hi);
          v.prio  := f_cond(or mask_hi = '0', prio_lo, prio_hi);
        when others =>
        end case;
      end if;
    end if;

    if ASYNC_RESET = 0 and rst_n = '0' then
      v := RST;
    end if;

    d <= v;

    -- Assign outputs
    ognt  <= gnt;
    oidx  <= tree(0).idx;
    oreq  <= tree(0).req;
    odata <= tree(0).data;
  end process;

  p_reg : process(clk, rst_n)
  begin
    if ASYNC_RESET /= 0 and rst_n = '0' then
      q <= RST;
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;

end architecture rtl;