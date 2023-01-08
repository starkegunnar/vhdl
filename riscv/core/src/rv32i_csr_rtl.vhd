--! @defgroup   RV32I_ALU_RTL RV32I alu rtl
--!
--! @brief      This file implements RV32I alu rtl.
--!
--! @author     Martin
--! @date       2022
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

library lib_riscv;
use lib_riscv.rv32i_pkg.all;

entity rv32i_csr is
  generic (
    g_hart_id : natural := 0
  );
  port (
    clk                           : in  std_logic;
    rst                           : in  std_logic;
    clr                           : in  std_logic;
    en                            : in  std_logic;
    stall                         : in  std_logic;

    csr_op                        : in  std_logic_vector(t_f3_range);
    csr_addr                      : in  std_logic_vector(t_csr_addr_range);
    csr_re                        : in  std_logic;
    csr_we                        : in  std_logic;
    r1                            : in  std_logic_vector(t_xlen_range);
    imm                           : in  std_logic_vector(t_xlen_range);

    instret                       : in  std_logic := '0';
    pc                            : in  std_logic_vector(t_xlen_range);
    epc_set                       : out std_logic;
    epc                           : out std_logic_vector(t_xlen_range);

    -- Exceptions                                         -- Code     Priority  Source
    excp_inst_breakpoint          : in  std_logic := '0'; -- 00000003  0
    excp_inst_page_fault          : in  std_logic := '0'; -- 0000000C  1
    excp_inst_access_fault        : in  std_logic := '0'; -- 00000001  2
    excp_inst_illegal             : in  std_logic := '0'; -- 00000002  3
    excp_inst_addr_misalign       : in  std_logic := '0'; -- 00000000  4        JAL/JALR/BRANCH
    excp_ecall                    : in  std_logic := '0'; --           5
    -- ecall code depends on privilege mode
    -- ecall from user                                       00000008
    -- ecall from supervisor                                 00000009
    -- ecall from machine                                    0000000B
    excp_env_breakpoint           : in  std_logic := '0'; -- 00000003  6
    excp_load_breakpoint          : in  std_logic := '0'; -- 00000003  7
    excp_store_amo_breakpoint     : in  std_logic := '0'; -- 00000003  8
    excp_load_addr_misalign       : in  std_logic := '0'; -- 00000004  9
    excp_store_amo_addr_misalign  : in  std_logic := '0'; -- 00000006 10
    excp_load_page_fault          : in  std_logic := '0'; -- 0000000D 11
    excp_store_amo_page_fault     : in  std_logic := '0'; -- 0000000F 12
    excp_load_access_fault        : in  std_logic := '0'; -- 00000005 13
    excp_store_amo_access_fault   : in  std_logic := '0'; -- 00000007 14

    -- External interrupts
    excp_ext_int                  : in  std_logic := '0'; --          17
    -- EXT interrupt code depends on privilege mode
    -- EXT interrupt from supervisor mode                     80000009
    -- EXT interrupt from machine mode                        8000000B

    mret                          : in  std_logic;

    valid                         : out std_logic;
    busy                          : out std_logic;
    res                           : out std_logic_vector(t_xlen_range)
  );
end entity rv32i_csr;

architecture rtl of rv32i_csr is

  constant c_privilege_user       : std_logic_vector(1 downto 0) := "00";
  constant c_privilege_supervisor : std_logic_vector(1 downto 0) := "01";
  constant c_privilege_hypervisor : std_logic_vector(1 downto 0) := "10";
  constant c_privilege_machine    : std_logic_vector(1 downto 0) := "11";

  constant c_misa : std_logic_vector(t_xlen_range) := (
    0   =>  '0',  -- A, Atomic extension
    1   =>  '0',  -- B, Bit-manipulation (reserved)
    2   =>  '0',  -- C, Compressed extension
    3   =>  '0',  -- D, Double-precision floating point extension
    4   =>  '0',  -- E, RV32E base ISA
    5   =>  '0',  -- F, Single-precision floating point extension
    6   =>  '0',  -- G, Reserved
    7   =>  '0',  -- H, Hypervisor extension
    8   =>  '1',  -- I, RV32I/64I/128I base ISA
    9   =>  '0',  -- J, Reserved
    10  =>  '0',  -- K, Reserved
    11  =>  '0',  -- L, Reserved
    12  =>  '1',  -- M, Integer multiply/divide extension
    13  =>  '0',  -- N, Reserved
    14  =>  '0',  -- O, Reserved
    15  =>  '0',  -- P, Packed SIMD-extension, reserved
    16  =>  '0',  -- Q, Quad-precision floating point extension
    17  =>  '0',  -- R, Reserved
    18  =>  '0',  -- S, Supervisor mode implemented
    19  =>  '0',  -- T, Reserved
    20  =>  '1',  -- U, User mode implemented
    21  =>  '0',  -- V, Vector extension, reserved
    22  =>  '0',  -- W, Reserved
    23  =>  '0',  -- X, Non-standard extensions present
    24  =>  '0',  -- Y, Reserved
    25  =>  '0',  -- Z, Reserved
    26  =>  '0',  -- WARL Reserved
    27  =>  '0',  -- WARL Reserved
    28  =>  '0',  -- WARL Reserved
    29  =>  '0',  -- WARL Reserved
    30  =>  '1',  -- MXL[0] "01" 32, "10" 64, "11" 128
    31  =>  '0'   -- MXL[1]
  );

  signal valid_r      : std_logic := '0';
  signal addr_r       : std_logic_vector(t_csr_addr_range);
  signal csr_we_r     : std_logic;
  signal csr_op_r     : std_logic_vector(t_csr_op_range);
  signal op_r         : std_logic_vector(t_xlen_range);
  signal rdata        : std_logic_vector(t_xlen_range);
  signal wdata        : std_logic_vector(t_xlen_range);

  signal csr_priv     : std_logic_vector(1 downto 0);
  signal csr_ro       : std_logic;

  signal privilege    : std_logic_vector(1 downto 0) := "11"; -- Default user

  signal exception    : std_logic_vector(15 downto 0);
  signal csr_nop      : std_logic;
  signal csr_illegal  : std_logic;
  signal csr_excp     : std_logic;

  signal epc_set_r    : std_logic;

  -- WPRI : Reserved, Writes Presever values, Reads Ignore values : Writes do nothing, reads always zero
  -- WLRL : Write only Legal values, Read only Legal values       : Check writes for legal values and read legal values
  -- WARL : Write Any values, Read Legal values                   :

  -- Unpriviledged counters
  signal mcycle         : std_logic_vector(t_2xlen_range);
  signal minstret       : std_logic_vector(t_2xlen_range);
  -- Machine level privilege
  -- Machine Status
  -- Bits     : Width : Name  : SPEC  : Description
  -- [63:38]  :    26 : WPRI  : WPRI  : Reserved, always 0
  -- [   37]  :     1 : MBE   : WARL  : Big-Endian (M-mode)
  -- [   37]  :     1 : SBE   : WARL  : Big-Endian (S-mode)
  -- [35:32]  :     4 : WPRI  : WPRI  : Reserved, always 0
  -- [   31]  :     1 : SD    :       : State dirty (XS, FS, VS. RO = 0 when not supported)
  -- [30:23]  :     8 : WPRI  : WPRI  : Reserved, always 0
  -- [   22]  :     1 : TSR   : WARL  : Trap SRET (RO = 0 when not supported)
  -- [   21]  :     1 : TW    : WARL  : Timeout wait (Enable timeout for WFI instruction, RO = 0 when only M-mode exists)
  -- [   20]  :     1 : TVM   : WARL  : Trap virtual memory (RO = 0 when S-mode is not supported)
  -- [   19]  :     1 : MXR   :       : Make executable readable (RO = 0 when S-mode not supported)
  -- [   18]  :     1 : SUM   :       : Permit supervisor user memory access (RO = 0 when S-mode not supported)
  -- [   17]  :     1 : MPRV  :       : Modify privilege (Memory privilege, RO = 0 when U-mode not supported)
  -- [16:15]  :     2 : XS    :       : Read only
  -- [14:13]  :     2 : FS    : WARL  : FPU state (RO = 0 when not supported)
  -- [12:11]  :     2 : MPP   : WARL  : Previous privilege mode (M-mode)
  -- [10: 9]  :     2 : VS    : WARL  : Vector unit state (RO = 0 when not supported)
  -- [    8]  :     1 : SPP   : WARL  : Previous privilege mode (S-mode)
  -- [    7]  :     1 : MPIE  :       : Prior interrupt-enable (M-mode)
  -- [    6]  :     1 : UBE   : WARL  : Big-Endian (U-mode)
  -- [    5]  :     1 : SPIE  :       : Prior interrupt-enable (S-mode)
  -- [    4]  :     1 : WPRI  : WPRI  : Reserved, always 0
  -- [    3]  :     1 : MIE   :       : Global interrupt-enable (M-mode)
  -- [    2]  :     1 : WPRI  : WPRI  : Reserved, always 0
  -- [    1]  :     1 : SIE   :       : Global interrupt-enable (S-mode)
  -- [    0]  :     1 : WPRI  : WPRI  : Reserved, always 0
  type t_mstatus_lo is record
    mprv : std_logic;                     -- 17
    mpp  : std_logic_vector(1 downto 0);  -- 12 downto 11
    mpie : std_logic;                     -- 7
    mie  : std_logic;                     -- 3
  end record;

  type t_mtvec is record
    base : std_logic_vector(29 downto 0);
    mode : std_logic_vector(1 downto 0);
  end record;

  type t_mip is record
    meip : std_logic; -- 11
    mtip : std_logic; -- 7
    msip : std_logic; -- 3
  end record;

  type t_mie is record
    meie : std_logic; -- 11
    mtie : std_logic; -- 7
    msie : std_logic; -- 3
  end record;

--  Priority  Exc. Code     Description
--  Highest   3             Instruction address breakpoint
--                          During instruction address translation:
--            12, 1         First encountered page fault or access fault
--                          With physical address for instruction:
--            1             Instruction access fault
--            2             Illegal instruction
--            0             Instruction address misaligned
--            8, 9, 11      Environment call
--            3             Environment break
--            3             Load/store/AMO address breakpoint
--                          Optionally:
--            4, 6          Load/store/AMO address misaligned
--                          During address translation for an explicit memory access:
--            13, 15, 5, 7  First encountered page fault or access fault
--                          With physical address for an explicit memory access:
--            5, 7          Load/store/AMO access fault
--  If not higher priority:
--  Lowest    4, 6          Load/store/AMO address misaligned
  type t_mcause is record
    interrupt             : std_logic;
    reserved              : std_logic_vector(c_xlen_hi - 1 downto 4);
    exception_code        : std_logic_vector(3 downto 0);
  end record;

  type t_mcounteren is record
    cy : std_logic;
    tm : std_logic;
    ir : std_logic;
  end record;

  signal mstatus        : t_mstatus_lo;
  signal misa           : std_logic_vector(t_xlen_range);
  signal mtvec          : t_mtvec;
  signal mscratch       : std_logic_vector(t_xlen_range);
  signal mepc           : std_logic_vector(c_xlen_hi downto 2);
  signal mcause         : t_mcause := (interrupt => '0', reserved => (others => '0'), exception_code => (others => '0'));
  signal mtval          : std_logic_vector(t_xlen_range);
  signal mie            : t_mie;                          -- Interrupt enables
  signal mip            : t_mip;                          -- Pending interrupts
  signal mcounteren     : t_mcounteren;
  signal mtinst         : std_logic_vector(t_xlen_range);

begin

  res <= rdata;
  busy <= csr_we_r or csr_excp;

  epc_set <= epc_set_r;

  p_valid : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        valid <= csr_re and not csr_nop and not csr_illegal;
      elsif stall = '0' then
        valid <= '0';
      end if;

      if rst = '1' or clr = '1' then
        valid <= '0';
      end if;
    end if;
  end process;

  csr_nop     <= not or_reduce(csr_op);
  csr_priv    <= csr_addr(t_csr_priv_range);
  csr_ro      <= and_reduce(csr_addr(t_csr_access_range));

  p_illegal : process(all)
  begin
    -- Access to counters in user mode is determined by the mcounteren register
    case csr_addr is
    when c_csr_addr_ucycle | c_csr_addr_ucycleh =>
      csr_illegal <= not mcounteren.cy;
    when c_csr_addr_utime | c_csr_addr_utimeh =>
      csr_illegal <= not mcounteren.tm;
    when c_csr_addr_uinstret | c_csr_addr_uinstreth =>
      csr_illegal <= not mcounteren.ir;
    when others =>
    end case;
    -- Write to read only is always illegal
    csr_illegal <= csr_we and csr_ro;
    -- Invalid privilege level is always illegal
    if (csr_priv and privilege) /= csr_priv then
      csr_illegal <= '1';
    end if;
  end process;

  p_csrop : process(clk)
  begin
    if rising_edge(clk) then
      csr_excp <= '0';
      csr_we_r <= '0';
      if en = '1' then
        addr_r    <= csr_addr;
        csr_op_r  <= csr_op(csr_op_r'range);
        csr_we_r  <= csr_we and not csr_nop and not csr_illegal;
        csr_excp  <= csr_illegal;
        op_r      <= r1;
        if csr_op(csr_op'high) = '1' then
          op_r <= imm;
        end if;
      end if;
      if rst = '1' or clr = '1' then
        csr_excp <= '0';
        csr_we_r <= '0';
      end if;
    end if;
  end process;

  p_csr_read : process(clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        rdata <= (others => '0');
        case csr_addr is
        when c_csr_addr_ucycle | c_csr_addr_mcycle =>
          rdata <= mcycle(c_xlen - 1 downto 0);
        when c_csr_addr_ucycleh | c_csr_addr_mcycleh =>
          rdata <= mcycle(2*c_xlen - 1 downto c_xlen);
        when c_csr_addr_uinstret | c_csr_addr_minstret =>
          rdata <= minstret(c_xlen - 1 downto 0);
        when c_csr_addr_uinstreth | c_csr_addr_minstreth =>
          rdata <= minstret(2*c_xlen - 1 downto c_xlen);
        when c_csr_addr_mvendorid =>
        when c_csr_addr_marchid =>
        when c_csr_addr_mimpid =>
          rdata <= x"52564347"; -- "RVCG"
        when c_csr_addr_mhartid =>
          rdata <= std_logic_vector(to_unsigned(g_hart_id, c_xlen));
        when c_csr_addr_mconfigptr =>
        when c_csr_addr_mstatus =>
          rdata(17)            <= mstatus.mprv;
          rdata(12 downto 11)  <= mstatus.mpp;
          rdata(7)             <= mstatus.mpie;
          rdata(3)             <= mstatus.mie;
        when c_csr_addr_mstatush =>
        when c_csr_addr_misa =>
          rdata <= c_misa;
        when c_csr_addr_mie =>
          rdata(11) <= mie.meie;
          rdata( 7) <= mie.mtie;
          rdata( 3) <= mie.msie;
        when c_csr_addr_mip =>
          rdata(11) <= mip.meip;
          rdata( 7) <= mip.mtip;
          rdata( 3) <= mip.msip;
        when c_csr_addr_mtvec =>
          rdata <= mtvec.base & mtvec.mode;
        when c_csr_addr_mcounteren =>
          rdata(2)  <= mcounteren.ir;
          rdata(1)  <= mcounteren.tm;
          rdata(0)  <= mcounteren.cy;
        when c_csr_addr_mscratch =>
          rdata <= mscratch;
        when c_csr_addr_mepc =>
          rdata(mepc'range) <= mepc;
        when c_csr_addr_mcause =>
          rdata(31)         <= mcause.interrupt;
          rdata(3 downto 0) <= mcause.exception_code;
        when c_csr_addr_mtval =>
          rdata <= mtval;
        when others =>
        end case;
      end if;
    end if;
  end process;

  exception( 0) <= excp_inst_breakpoint;
  exception( 1) <= excp_inst_page_fault;
  exception( 2) <= excp_inst_access_fault;
  exception( 3) <= excp_inst_illegal or csr_excp;
  exception( 4) <= excp_inst_addr_misalign;
  exception( 5) <= excp_ecall;
  exception( 6) <= excp_env_breakpoint;
  exception( 7) <= excp_load_breakpoint;
  exception( 8) <= excp_store_amo_breakpoint;
  exception( 9) <= excp_load_addr_misalign;
  exception(10) <= excp_store_amo_addr_misalign;
  exception(11) <= excp_load_page_fault;
  exception(12) <= excp_store_amo_page_fault;
  exception(13) <= excp_load_access_fault;
  exception(14) <= excp_store_amo_access_fault;
  exception(15) <= excp_ext_int;

  wdata <= rdata or op_r      when csr_op_r = c_csr_op_rs else
           rdata and not op_r when csr_op_r = c_csr_op_rc else
           op_r;

  p_csr_write : process(clk)
  begin
    if rising_edge(clk) then

      mcycle <= std_logic_vector(unsigned(mcycle) + 1);
      if instret = '1' and csr_nop = '0' then
        minstret <= std_logic_vector(unsigned(minstret) + 1);
      end if;

      -- Exceptions sorted by priority
      if excp_inst_breakpoint = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"3";
      elsif excp_inst_page_fault = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"C";
      elsif excp_inst_access_fault = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"1";
      elsif excp_inst_illegal = '1' or csr_excp = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"2";
      elsif excp_inst_addr_misalign = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"0";
      elsif excp_ecall = '1' then
        mcause.interrupt      <= '0';
        case privilege is
        when c_privilege_user =>
          mcause.exception_code <= x"8";
        when c_privilege_supervisor =>
          mcause.exception_code <= x"9";
        when others =>
          mcause.exception_code <= x"B";
        end case;
      elsif excp_env_breakpoint = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"3";
      elsif excp_load_breakpoint = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"3";
      elsif excp_store_amo_breakpoint = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"3";
      elsif excp_load_addr_misalign = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"4";
      elsif excp_store_amo_addr_misalign = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"6";
      elsif excp_load_page_fault = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"D";
      elsif excp_store_amo_page_fault = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"F";
      elsif excp_load_access_fault = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"5";
      elsif excp_store_amo_access_fault = '1' then
        mcause.interrupt      <= '0';
        mcause.exception_code <= x"7";
      elsif excp_ext_int = '1' then
        mcause.interrupt      <= '1';
        case privilege is
        when c_privilege_supervisor =>
          mcause.exception_code <= x"9";
        when others =>
          mcause.exception_code <= x"B";
        end case;
      end if;

      epc_set_r <= '0';
      if or_reduce(exception) = '1' then
        privilege     <= c_privilege_machine;
        mstatus.mprv  <= '1';
        mstatus.mpp   <= privilege;
        mstatus.mpie  <= mstatus.mie;
        mstatus.mie   <= '0';
        mepc          <= pc(mepc'range);
        epc_set_r     <= '1';
        epc           <= mtvec.base & (mtvec.mode'range => '0');
      elsif en = '1' and mret = '1' then
        privilege     <= mstatus.mpp;
        mstatus.mprv  <= '0';
        mstatus.mpp   <= c_privilege_user;
        mstatus.mpie  <= '1';
        mstatus.mie   <= mstatus.mpie;
        epc_set_r     <= '1';
        epc           <= mepc & (mepc'low - 1 downto 0 => '0');
      end if;

      if csr_we_r = '1' then
        -- Write
        case addr_r is
        when c_csr_addr_mstatus =>
          mstatus.mprv  <= wdata(17);
          mstatus.mpp   <= wdata(12 downto 11);
          mstatus.mpie  <= wdata(7);
          mstatus.mie   <= wdata(3);
        when c_csr_addr_mie =>
          mie.meie      <= wdata(11);
          mie.mtie      <= wdata( 7);
          mie.msie      <= wdata( 3);
        when c_csr_addr_mip =>
          mip.meip      <= wdata(11);
          mip.mtip      <= wdata( 7);
          mip.msip      <= wdata( 3);
        when c_csr_addr_mtvec =>
          (mtvec.base, mtvec.mode) <= wdata;
        when c_csr_addr_mcounteren =>
          mcounteren.ir <= wdata(2);
          mcounteren.tm <= wdata(1);
          mcounteren.cy <= wdata(0);
        when c_csr_addr_mscratch =>
          mscratch <= wdata;
        when c_csr_addr_mepc =>
          mepc <= wdata(mepc'range);
        when c_csr_addr_mcause =>
          (mcause.interrupt, mcause.exception_code) <= wdata(31) & wdata(3 downto 0);
        when others =>
        end case;
      end if;

      if rst = '1' then
        privilege     <= (others => '1'); -- We boot in machine mode
        mcycle        <= (others => '0');
        minstret      <= (others => '0');
        mstatus.mpp   <= "11";
        mtvec.base    <= x"0000000" & "01";
        mtvec.mode    <= "00";
        mcounteren.ir <= '0';
        mcounteren.tm <= '0';
        mcounteren.cy <= '0';
      end if;
    end if;
  end process;

end architecture rtl;