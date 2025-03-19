library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_riscvim;
use lib_riscvim.riscvim_pkg.all;

entity riscvim_lsu is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    lsu_en      : in  std_logic;
    lsu_we      : in  std_logic;
    lsu_size    : in  std_logic_vector(1 downto 0);
    lsu_signed  : in  std_logic;
    op_a        : in  std_logic_vector(t_xlen_range);
    op_b        : in  std_logic_vector(t_xlen_range);
    op_c        : in  std_logic_vector(t_xlen_range);

    -- Status
    lsu_split   : out std_logic;
    lsu_first   : out std_logic;
    lsu_last    : out std_logic;

    -- OBI A
    m_req       : out std_logic;
    m_gnt       : in  std_logic;
    m_addr      : out std_logic_vector(t_xlen_range);
    m_we        : out std_logic;
    m_be        : out std_logic_vector(c_xlen/8-1 downto 0);
    m_wdata     : out std_logic_vector(t_xlen_range);
    m_memtype   : out std_logic_vector(1 downto 0);
    m_prot      : out std_logic_vector(2 downto 0);
    -- OBI R
    m_rvalid    : in  std_logic;
    m_rready    : out std_logic;
    m_rdata     : in  std_logic_vector(t_xlen_range);
    m_err       : in  std_logic;
    m_exokay    : in  std_logic;

    -- Result
    id_valid    : in  std_logic;
    ex_ready    : out std_logic;
    ex_valid    : in  std_logic;
    wb_ready    : out std_logic;
    res         : out std_logic_vector(t_xlen_range) := (others => '0');
  );
end entity;

architecture rtl of riscvim_lsu is

  signal req              : std_logic;
  signal gnt              : std_logic;
  signal addr             : std_logic_vector(t_xlen_range);
  signal we               : std_logic;
  signal be               : std_logic_vector(c_xlen/8-1 downto 0);
  signal wdata            : std_logic_vector(t_xlen_range);
  signal memtype          : std_logic_vector(1 downto 0);
  signal prot             : std_logic_vector(2 downto 0);

  signal split_xfer_comb  : std_logic;
  signal split_xfer       : std_logic;
  signal misaligned       : std_logic;

begin

  addr <= std_logic_vector(unsigned(op_a) + unsigned(op_b));

  p_align : process(all)
  begin
    case lsu_size is
    when "00" => -- byte
      case addr(1 downto 0) is
      when "00" =>
        be <= "0001";
      when "01" =>
        be <= "0010";
      when "10" =>
        be <= "0100";
      when "11" =>
        be <= "1000";
      when others =>
      end case;
    when "01" => -- halfword
      if split_xfer = '0' then
        case addr(1 downto 0) is
        when "00" =>
          be <= "0011";
        when "01" =>
          be <= "0110";
        when "10" =>
          be <= "1100";
        when "11" =>
          be <= "1000";
        when others =>
        end case;
      else
        be <= "0001";
      end if;
    when others => -- word
      if split_xfer = '0' then
        case addr(1 downto 0) is
        when "00" =>
          be <= "1111";
        when "01" =>
          be <= "1110";
        when "10" =>
          be <= "1100";
        when "11" =>
          be <= "1000";
        when others =>
        end case;
      else
        case addr(1 downto 0) is
        when "00" =>
          be <= "0000";
        when "01" =>
          be <= "0001";
        when "10" =>
          be <= "0011";
        when "11" =>
          be <= "0111";
        when others =>
        end case;
      end if;
    end case;

    case addr(1 downto 0) is
    when "00" =>
      wdata <= op_c;
    when "01" =>
      wdata <= op_c(23 downto 0) & op_c(31 downto 24);
    when "10" =>
      wdata <= op_c(15 downto 0) & op_c(31 downto 16);
    when "11" =>
      wdata <= op_c(7 downto 0) & op_c(31 downto 8);
    when others =>
    end case;
  end process;

  p_split_xfer_comb : process(all)
  begin
    split_xfer_comb <= '0';
    misaligned      <= '0';
    if lsu_size = "10" then
      split_xfer_comb <= or addr(1 downto 0);
    elsif lsu_size = "01" then
      split_xfer_comb <= and addr(1 downto 0);
      misaligned      <= addr(0);
    end if;
  end process;

  p_split_xfer : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        split_xfer <= '0';
      elsif id_valid = '0' then
        split_xfer <= '0';
      end if;
    end if;
  end process;



end architecture;