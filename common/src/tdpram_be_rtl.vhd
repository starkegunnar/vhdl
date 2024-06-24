library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity tdpram_be is
  generic (
    g_addr_width    : positive;
    g_col_width     : positive;
    g_num_cols      : positive;
    g_a_ram_mode    : t_ram_mode := e_ram_read_first;
    g_b_ram_mode    : t_ram_mode := e_ram_read_first;
    g_reg_output    : boolean;
    g_init_file     : string := ""
  );
  port (
    clka      : in  std_logic;
    ena       : in  std_logic;
    addra     : in  std_logic_vector(g_addr_width-1 downto 0);
    wea       : in  std_logic_vector(g_num_cols-1 downto 0);
    dina      : in  std_logic_vector(g_num_cols*g_col_width-1 downto 0);
    rsta      : in  std_logic := '0';
    regcea    : in  std_logic := '1';
    douta     : out std_logic_vector(g_num_cols*g_col_width-1 downto 0);
    clkb      : in  std_logic;
    enb       : in  std_logic;
    addrb     : in  std_logic_vector(g_addr_width-1 downto 0);
    web       : in  std_logic_vector(g_num_cols-1 downto 0);
    dinb      : in  std_logic_vector(g_num_cols*g_col_width-1 downto 0);
    rstb      : in  std_logic := '0';
    regceb    : in  std_logic := '1';
    doutb     : out std_logic_vector(g_num_cols*g_col_width-1 downto 0)
  );
end entity tdpram_be;

architecture rtl of tdpram_be is

  constant c_aw     : positive := g_addr_width;
  constant c_cw     : positive := g_col_width;
  constant c_nc     : positive := g_num_cols;
  constant c_dw     : positive := c_nc*c_cw;
  constant c_lsbw   : positive := fn_log2(c_nc);
  constant c_sz     : positive := 2**(c_aw);

  signal ram        : t_slv_array(c_sz-1 downto 0)(c_dw-1 downto 0) := (others => (others => '0'));

  signal ram_douta  : std_logic_vector(c_dw-1 downto 0);
  signal ram_doutb  : std_logic_vector(c_dw-1 downto 0);
  signal reg_douta  : std_logic_vector(c_dw-1 downto 0);
  signal reg_doutb  : std_logic_vector(c_dw-1 downto 0);

begin

  b_read_first_a : if g_a_ram_mode = e_ram_read_first generate
    p_port_a : process(clka)
    begin
      if rising_edge(clka) then
        if ena = '1' then
          ram_douta <= ram(to_integer(unsigned(addra)));
          for i in 0 to c_nc-1 loop
            if wea(i) = '1' then
              ram(to_integer(unsigned(addra)))((i+1)*c_cw-1 downto i*c_cw) <= dina((i+1)*c_cw-1 downto i*c_cw);
            end if;
          end loop;
        end if;
        if regcea = '1' then
          reg_douta <= ram_douta;
        end if;
        if rsta = '1' then
          reg_douta <= (others => '0');
        end if;
      end if;
    end process;
  end generate b_read_first_a;

  b_write_first_a : if g_a_ram_mode = e_ram_write_first generate
    b_port_a : for i in 0 to c_nc-1 generate
      p_port_a : process(clka)
      begin
        if rising_edge(clka) then
          if ena = '1' then
            if wea(i) = '1' then
              ram(to_integer(unsigned(addra)))((i+1)*c_cw-1 downto i*c_cw) <= dina((i+1)*c_cw-1 downto i*c_cw);
              ram_douta((i+1)*c_cw-1 downto i*c_cw) <= dina((i+1)*c_cw-1 downto i*c_cw);
            else
              ram_douta((i+1)*c_cw-1 downto i*c_cw) <= ram(to_integer(unsigned(addra)))((i+1)*c_cw-1 downto i*c_cw);
            end if;
          end if;
        end if;
      end process;
    end generate b_port_a;
    p_reg_a : process(clka)
    begin
      if rising_edge(clka) then
        if regcea = '1' then
          reg_douta <= ram_douta;
        end if;
        if rsta = '1' then
          reg_douta <= (others => '0');
        end if;
      end if;
    end process;
  end generate b_write_first_a;

  b_no_change_a : if g_a_ram_mode = e_ram_no_change generate
    p_port_a : process(clka)
    begin
      if rising_edge(clka) then
        if ena = '1' then
          if nor wea = '1' then
            ram_douta <= ram(to_integer(unsigned(addra)));
          end if;
          for i in 0 to c_nc-1 loop
            if wea(i) = '1' then
              ram(to_integer(unsigned(addra)))((i+1)*c_cw-1 downto i*c_cw) <= dina((i+1)*c_cw-1 downto i*c_cw);
            end if;
          end loop;
        end if;
        if regcea = '1' then
          reg_douta <= ram_douta;
        end if;
        if rsta = '1' then
          reg_douta <= (others => '0');
        end if;
      end if;
    end process;
  end generate b_no_change_a;

  douta <= reg_douta when g_reg_output else ram_douta;

  b_read_first_b: if g_b_ram_mode = e_ram_read_first generate
    p_port_b : process(clkb)
    begin
      if rising_edge(clkb) then
        if enb = '1' then
          ram_doutb <= ram(to_integer(unsigned(addrb)));
          for i in 0 to c_nc-1 loop
            if web(i) = '1' then
              ram(to_integer(unsigned(addrb)))((i+1)*c_cw-1 downto i*c_cw) <= dinb((i+1)*c_cw-1 downto i*c_cw);
            end if;
          end loop;
        end if;
        if regceb = '1' then
          reg_doutb <= ram_doutb;
        end if;
        if rstb = '1' then
          reg_doutb <= (others => '0');
        end if;
      end if;
    end process;
  end generate b_read_first_b;

  b_write_first_b : if g_b_ram_mode = e_ram_write_first generate
    b_port_b : for i in 0 to c_nc-1 generate
      p_port_b : process(clkb)
      begin
        if rising_edge(clkb) then
          if enb = '1' then
            if web(i) = '1' then
              ram(to_integer(unsigned(addrb)))((i+1)*c_cw-1 downto i*c_cw) <= dinb((i+1)*c_cw-1 downto i*c_cw);
              ram_doutb((i+1)*c_cw-1 downto i*c_cw) <= dinb((i+1)*c_cw-1 downto i*c_cw);
            else
              ram_doutb((i+1)*c_cw-1 downto i*c_cw) <= ram(to_integer(unsigned(addrb)))((i+1)*c_cw-1 downto i*c_cw);
            end if;
          end if;
        end if;
      end process;
    end generate b_port_b;
    p_reg_b : process(clkb)
    begin
      if rising_edge(clkb) then
        if regceb = '1' then
          reg_doutb <= ram_doutb;
        end if;
        if rstb = '1' then
          reg_doutb <= (others => '0');
        end if;
      end if;
    end process;
  end generate b_write_first_b;

  b_no_change_b : if g_b_ram_mode = e_ram_no_change generate
    p_port_b : process(clkb)
    begin
      if rising_edge(clkb) then
        if enb = '1' then
          if nor web = '1' then
            ram_doutb <= ram(to_integer(unsigned(addrb)));
          end if;
          for i in 0 to c_nc-1 loop
            if web(i) = '1' then
              ram(to_integer(unsigned(addrb)))((i+1)*c_cw-1 downto i*c_cw) <= dinb((i+1)*c_cw-1 downto i*c_cw);
            end if;
          end loop;
        end if;
        if regceb = '1' then
          reg_doutb <= ram_doutb;
        end if;
        if rstb = '1' then
          reg_doutb <= (others => '0');
        end if;
      end if;
    end process;
  end generate b_no_change_b;

  doutb <= reg_doutb when g_reg_output else ram_doutb;

end architecture;