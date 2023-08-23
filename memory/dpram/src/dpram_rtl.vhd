library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity dpram is
  generic (
    g_addr_width    : natural := 6;
    g_columns       : natural := 1;
    g_column_width  : natural := 32;
    g_sync_read     : boolean := true;
    g_opt_reg_out   : boolean := true;
    g_rst_polarity  : std_logic := '1'
  );
  port (
    -- Port A
    clka    : in  std_logic := '0';
    rsta    : in  std_logic := not g_rst_polarity;
    ena     : in  std_logic := '1';
    addra   : in  std_logic_vector(g_addr_width - 1 downto 0) := (others => '0');
    wea     : in  std_logic_vector(g_columns - 1 downto 0) := (others => '0');
    dina    : in  std_logic_vector(g_columns * g_column_width - 1 downto 0) := (others => '0');
    douta   : out std_logic_vector(g_columns * g_column_width - 1 downto 0) := (others => '0');
    -- Port B
    clkb    : in  std_logic := '0';
    rstb    : in  std_logic := not g_rst_polarity;
    enb     : in  std_logic := '1';
    addrb   : in  std_logic_vector(g_addr_width - 1 downto 0) := (others => '0');
    web     : in  std_logic_vector(g_columns - 1 downto 0) := (others => '0');
    dinb    : in  std_logic_vector(g_columns * g_column_width - 1 downto 0) := (others => '0');
    doutb   : out std_logic_vector(g_columns * g_column_width - 1 downto 0) := (others => '0')
  );
end entity dpram;

architecture rtl of dpram is

  -- Internal shorter version
  constant c_cw : natural := g_column_width;

  signal mem : t_slv_array(0 to 2**g_addr_width - 1)(g_columns * g_column_width - 1 downto 0) := (others => (others => '0'));

  signal douta_r : t_slv_array(0 to 1)(g_columns * g_column_width - 1 downto 0) := (others => (others => '0'));
  signal doutb_r : t_slv_array(0 to 1)(g_columns * g_column_width - 1 downto 0) := (others => (others => '0'));

begin

  p_dpmem_write : process(clka, clkb)
  begin
    -- Port A
    if rising_edge(clka) then
      if ena = '1' then
        for i in 0 to g_columns - 1 loop
          if wea(i) = '1' then
            mem(to_integer(unsigned(addra)))((i + 1) * c_cw - 1 downto i * c_cw) <= dina((i + 1) * c_cw - 1 downto i * c_cw);
          end if;
        end loop;
      end if;
    end if;

    -- Port B
    if rising_edge(clkb) then
      if enb = '1' then
        for i in 0 to g_columns - 1 loop
          if web(i) = '1' then
            mem(to_integer(unsigned(addrb)))((i + 1) * c_cw - 1 downto i * c_cw) <= dinb((i + 1) * c_cw - 1 downto i * c_cw);
          end if;
        end loop;
      end if;
    end if;
  end process p_dpmem_write;

  b_dpmem_sync_read : if g_sync_read generate
    p_dpmem_read : process(clka, clkb)
    begin
      -- Port A
      if rising_edge(clka) then
        if ena = '1' then
          douta_r(0) <= mem(to_integer(unsigned(addra)));
          if g_opt_reg_out then
            douta_r(1) <= douta_r(0);
          end if;
        end if;

        if rsta = g_rst_polarity then
          douta_r(0) <= (others => '0');
        end if;
      end if;

      -- Port B
      if rising_edge(clkb) then
        if enb = '1' then
          doutb_r(0) <= mem(to_integer(unsigned(addrb)));
          if g_opt_reg_out then
            doutb_r(1) <= doutb_r(0);
          end if;
        end if;

        if rstb = g_rst_polarity then
          doutb_r(0) <= (others => '0');
        end if;
      end if;
    end process p_dpmem_read;
  end generate b_dpmem_sync_read;

  -- Output select
  douta <= douta_r(1) when g_sync_read and g_opt_reg_out else
           douta_r(0) when g_sync_read else
           mem(to_integer(unsigned(addra)));
  doutb <= doutb_r(1) when g_sync_read and g_opt_reg_out else
           douta_r(0) when g_sync_read else
           mem(to_integer(unsigned(addrb)));

end architecture rtl;