library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity if_stage is
  generic (
    g_C           : boolean;
  );
  port (
    clk           : in  std_logic;
    rst_n         : in  std_logic;

    m_ibus_a      : out t_bus_req;
    m_ibus_avalid : out std_logic;
    m_ibus_aready : in  std_logic;

    m_ibus_r      : in  t_bus_resp;
    m_ibus_rvalid : in  std_logic;
    m_ibus_rready : out std_logic;

    if_ctrl       : in  t_if_ctrl;
    if_id_reg     : out t_if_id_reg;
    if_id_valid   : out std_logic;
    if_id_ready   : in  std_logic
  );
end entity;

architecture rtl of if_stage is

  type t_if_state is (IF_IDLE, IF_WAIT);

  type t_pf_reg is record
    data  : t_hwordx_array(0 to 1);
    valid : std_logic;
    ready : std_logic;
  end record;

  type t_pf_reg_array is array(range 0 to 1) of t_pf_reg;

  constant c_aligned_uncompressed   : std_logic_vector(1 downto 0) := "00";
  constant c_aligned_compressed     : std_logic_vector(1 downto 0) := "01";
  constant c_unaligned_uncompressed : std_logic_vector(1 downto 0) := "10";
  constant c_unaligned_compressed   : std_logic_vector(1 downto 0) := "11";

  type t_if_reg is record
    -- IF signals
    state           : t_if_state;
    apc             : t_wordx;
    priv_lvl        : t_priv_lvl;
    is_ptr          : std_logic;
    ptr             : t_wordx;
    outstanding_cnt : unsigned(1 downto 0);
    rpc             : t_wordx;
    pf              : t_pf_reg_array;
    flush           : std_logic;
  end record;

  constant c_if_reg_reset : t_if_reg := (
    state           => IF_IDLE,
    apc             => (others => '0'),
    priv_lvl        => c_priv_lvl_m,
    is_ptr          => '0',
    ptr             => (others => '0'),
    outstanding_cnt => "00",
    rpc             => (others => '0'),
    pf              => (others => (data => (others => '0'), valid => '0', ready => '1')),
    flush           => '0'
  );

  signal r, rn : t_if_reg;

begin

  p_comb : process(all)
    variable v            : t_if_reg;
    variable pf_push      : std_logic_vector(1 downto 0) := "00";
    variable pf_pop       : std_logic_vector(1 downto 0) := "00";
    variable pf_state     : std_logic_vector(1 downto 0);
    variable vinstr       : t_wordx;
    variable vpc          : t_wordx;
  begin
    v := r;

    -- Increment PC
    v.apc := std_logic_vector(unsigned(r.apc(r.apc'high downto 2)) + 1) & "00";
    if if_ctrl.pc_set = '1' then
      v.apc := if_ctrl.pc;
    end if;

    if m_ibus_avalid = '1' and m_ibus_aready = '1' and (m_ibus_rvalid = '0' or m_ibus_rready = '0') then
      v.outstanding_cnt := r.outstanding_cnt + 1;
    elsif (m_ibus_avalid = '0' or m_ibus_aready = '0') and m_ibus_rvalid = '1' and m_ibus_rready = '1' then
      v.outstanding_cnt := r.outstanding_cnt - 1;
    end if;

    vpf_push(0) := m_ibus_rvalid and not r.flush and (r.rpc(1) = '0' or g_C);
    vpf_push(1) := m_ibus_rvalid and not r.flush;

    if g_C and r.rpc(1) = '1' then
      vinstr := v.pf(0).data(0) & v.pf(1).data(0);
      if f_compressed(r.pf(1).data(0)) then
        -- Unaligned compressed
        vpf_pop := if_id_ready & '0';
        vpc     := std_logic_vector(unsigned(r.rpc(31 downto 2)) + 1) & "00";
      else
        -- Unaligned uncompressed
        vpf_pop := if_id_ready & if_id_ready;
        vpc     := std_logic_vector(unsigned(r.rpc(31 downto 2)) + 1) & "10";
      end if;
    else
      vinstr := v.pf(1).data(0) & v.pf(0).data(0);
      if g_C and f_compressed(r.pf(0).data(0)) then
        -- Aligned compressed
        vpf_pop := '0' & if_id_ready;
        vpc     := r.rpc(31 downto 2) & "10";
      else
        -- Aligned uncompressed
        vpf_pop := if_id_ready & if_id_ready;
        vpc     := std_logic_vector(unsigned(r.rpc(31 downto 2)) + 1) & "00";
      end if;
    end if;

    for i in 0 to 1 loop
      if vpf_push(i) = '1' and r.pf(i).ready = '1' and r.pf(i).valid = '1' and vpf_pop(i) = '0' then
        v.pf(i).ready := '0';
      elsif vpf_pop(i) = '1' then
        v.pf(i).ready := '1';
      end if;

      if v.pf(i).ready = '1' then
        v.pf(i).data(1) := m_ibus_r.data((i+1)*c_hx_w-1 downto i*c_hx_w);
      end if;

      if r.pf(i).valid = '0' or vpf_pop(i) = '1' then
        v.pf(i).valid := vpf_push(i) or not v.pf(i).ready;
        if v.pf(i).ready = '0' then
          v.pf(i).data(0) := r.pf(i).data(1);
        else
          v.pf(i).data(0) := m_ibus_r.data((i+1)*c_hx_w-1 downto i*c_hx_w);
        end if;
      end if;
    end loop;

    if vpf_pop and (r.pf(1).valid & r.pf(0).valid) = vpf_pop then
      v.rpc := vpc;
    end if;

    if r.flush = '1' and v.outstanding_cnt = 0 then
      v.flush := '0';
    end if;

    if if_ctrl.pc_set = '1' then
      v.rpc       := if_ctrl.pc;
      v.flush     := '1';
      for i in 0 to 1 loop
        v.pf(i).valid  := '0';
        v.pf(i).ready  := '1';
      end loop;
    end if;

    case

    rn <= v;
  end process;

  p_reg : process(rst_n, clk)
  begin
    if rising_edge(clk) then
      r <= rn;
      if rst_n = '0' then
        r.rstate          <= c_if_reg_reset.rstate;
        r.apc             <= c_if_reg_reset.apc;
        r.priv_lvl        <= c_if_reg_reset.priv_lvl;
        r.is_ptr          <= c_if_reg_reset.is_ptr;
        r.outstanding_cnt <= c_if_reg_reset.outstanding_cnt;
        r.rpc             <= c_if_reg_reset.rpc;
        r.pf(0).valid     <= c_if_reg_reset.pf(0).valid;
        r.pf(0).ready     <= c_if_reg_reset.pf(0).ready;
        r.pf(1).valid     <= c_if_reg_reset.pf(1).valid;
        r.pf(1).ready     <= c_if_reg_reset.pf(1).ready;
        r.flush           <= c_if_reg_reset.flush;
      end if;
    end if;
  end process;

end architecture;