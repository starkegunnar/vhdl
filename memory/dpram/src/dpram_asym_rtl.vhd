library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity dpram_asym is
  generic (
    g_addr_width_a  : natural := 6;
    g_data_width_a  : natural := 36;
    g_addr_width_b  : natural := 7;
    g_data_width_b  : natural := 18;
    g_sync_read     : boolean := true;
    g_opt_reg_out   : boolean := true;
    g_rst_polarity  : std_logic := '1'
  );
  port (
    -- Port A
    clka    : in  std_logic := '0';
    rsta    : in  std_logic := not g_rst_polarity;
    ena     : in  std_logic := '1';
    addra   : in  std_logic_vector(g_addr_width_a - 1 downto 0) := (others => '0');
    wea     : in  std_logic := '0';
    dina    : in  std_logic_vector(g_data_width_a - 1 downto 0) := (others => '0');
    douta   : out std_logic_vector(g_data_width_a - 1 downto 0) := (others => '0');
    -- Port B
    clkb    : in  std_logic := '0';
    rstb    : in  std_logic := not g_rst_polarity;
    enb     : in  std_logic := '1';
    addrb   : in  std_logic_vector(g_addr_width_b - 1 downto 0) := (others => '0');
    web     : in  std_logic := '0';
    dinb    : in  std_logic_vector(g_data_width_b - 1 downto 0) := (others => '0');
    doutb   : out std_logic_vector(g_data_width_b - 1 downto 0) := (others => '0')
  );
end entity dpram_asym;

architecture rtl of dpram_asym is

  -- Internal shorter version
  constant c_awa : natural := g_addr_width_a;
  constant c_awb : natural := g_addr_width_b;
  constant c_dwa : natural := g_data_width_a;
  constant c_dwb : natural := g_data_width_b;
  constant c_sza : natural := 2**g_addr_width_a;
  constant c_szb : natural := 2**g_addr_width_b;

  constant c_min_aw : natural := fn_min(c_awa, c_awb);
  constant c_max_aw : natural := fn_max(c_awa, c_awb);
  constant c_min_dw : natural := fn_min(c_dwa, c_dwb);
  constant c_max_dw : natural := fn_max(c_dwa, c_dwb);
  constant c_min_sz : natural := fn_min(c_sza, c_szb);
  constant c_max_sz : natural := fn_max(c_sza, c_szb);
  constant c_ratio  : natural := c_max_dw / c_min_dw;


  signal mem : t_slv_array(0 to c_max_sz - 1)(c_min_dw - 1 downto 0) := (others => (others => '0'));

  signal clkx       : std_logic;
  signal rstx       : std_logic;
  signal enx        : std_logic;
  signal addrx      : std_logic_vector(c_max_aw - 1 downto 0);
  signal wex        : std_logic;
  signal dinx       : std_logic_vector(c_min_dw - 1 downto 0);
  signal doutx      : std_logic_vector(c_min_dw - 1 downto 0);
  signal doutx_r    : t_slv_array(0 to 1)(c_min_dw - 1 downto 0);

  signal clky       : std_logic;
  signal rsty       : std_logic;
  signal eny        : std_logic;
  signal addry      : std_logic_vector(c_min_aw - 1 downto 0);
  signal wey        : std_logic;
  signal diny       : std_logic_vector(c_max_dw - 1 downto 0);
  signal douty      : std_logic_vector(c_max_dw - 1 downto 0);
  signal douty_r    : t_slv_array(0 to 1)(c_max_dw - 1 downto 0);

begin

  assert c_max_dw mod c_min_dw = 0 report "dpram_asym: Invalid data widths" severity failure;
  assert c_max_sz / c_min_sz = c_ratio report "dpram_asym: Invalid address ratio" severity failure;

  b_gen_ports : if addra'length < addrb'length generate
    clkx  <= clkb;
    rstx  <= rstb;
    enx   <= enb;
    addrx <= addrb;
    wex   <= web;
    dinx  <= dinb;
    doutb <= doutx;

    clky  <= clka;
    rsty  <= rsta;
    eny   <= ena;
    addry <= addra;
    wey   <= wea;
    diny  <= dina;
    douta <= douty;
  else generate
    clkx  <= clka;
    rstx  <= rsta;
    enx   <= ena;
    addrx <= addra;
    wex   <= wea;
    dinx  <= dina;
    douta <= doutx;

    clky  <= clkb;
    rsty  <= rstb;
    eny   <= enb;
    addry <= addrb;
    wey   <= web;
    diny  <= dinb;
    doutb <= douty;
  end generate b_gen_ports;

  p_dpmem_write : process(clkx, clky)
  begin
    -- Port A
    if rising_edge(clkx) then
      if enx = '1' then
        if wex = '1' then
          mem(to_integer(unsigned(addrx))) <= dinx;
        end if;
        if g_sync_read then
          doutx_r(0) <= mem(to_integer(unsigned(addrx)));
        end if;
      end if;
      if g_sync_read and g_opt_reg_out then
        doutx_r(1) <= doutx_r(0);
      end if;

      if g_sync_read and rstx = g_rst_polarity then
        doutx_r(0) <= (others => '0');
      end if;
    end if;

    -- Port B
    if rising_edge(clky) then
      for i in 0 to c_ratio - 1 loop
        if eny = '1' then
          if wey = '1' then
            mem(to_integer(unsigned(addry) & to_unsigned(i, fn_log2(c_ratio)))) <= diny((i + 1) * c_min_dw - 1 downto i * c_min_dw);
          end if;
          if g_sync_read then
            douty_r(0)((i + 1) * c_min_dw - 1 downto i * c_min_dw) <= mem(to_integer(unsigned(addry) & to_unsigned(i, fn_log2(c_ratio))));
          end if;
        end if;
      end loop;
      if g_sync_read and g_opt_reg_out then
        douty_r(1) <= douty_r(0);
      end if;

      if g_sync_read and rsty = g_rst_polarity then
        douty_r(0) <= (others => '0');
      end if;
    end if;
  end process p_dpmem_write;

  -- Output select
  doutx <= doutx_r(1) when g_sync_read and g_opt_reg_out else
           doutx_r(0) when g_sync_read else
           mem(to_integer(unsigned(addrx)));
  p_out_sel_y : process(all)
  begin
    if g_sync_read and g_opt_reg_out then
      douty <= douty_r(1);
    elsif g_sync_read then
      douty <= douty_r(0);
    else
      for i in 0 to c_ratio - 1 loop
        douty((i + 1) * c_min_dw - 1 downto i * c_min_dw) <= mem(to_integer(unsigned(addry) & to_unsigned(i, fn_log2(c_ratio))));
      end loop;
    end if;
  end process;

end architecture rtl;