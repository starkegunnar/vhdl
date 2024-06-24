library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity tdpram_asym is
  generic (
    g_a_addr_width  : positive;
    g_a_data_width  : positive;
    g_a_ram_mode    : t_ram_mode := e_ram_read_first;
    g_b_addr_width  : positive;
    g_b_data_width  : positive;
    g_b_ram_mode    : t_ram_mode := e_ram_read_first;
    g_reg_output    : boolean;
    g_init_file     : string := ""
  );
  port (
    clka      : in  std_logic;
    ena       : in  std_logic;
    addra     : in  std_logic_vector(g_a_addr_width-1 downto 0);
    wea       : in  std_logic;
    dina      : in  std_logic_vector(g_a_data_width-1 downto 0);
    rsta      : in  std_logic := '0';
    regcea    : in  std_logic := '1';
    douta     : out std_logic_vector(g_a_data_width-1 downto 0);
    clkb      : in  std_logic;
    enb       : in  std_logic;
    addrb     : in  std_logic_vector(g_b_addr_width-1 downto 0);
    web       : in  std_logic;
    dinb      : in  std_logic_vector(g_b_data_width-1 downto 0);
    rstb      : in  std_logic := '0';
    regceb    : in  std_logic := '1';
    doutb     : out std_logic_vector(g_b_data_width-1 downto 0)
  );
end entity tdpram_asym;

architecture rtl of tdpram_asym is

  constant c_dw_max : positive := maximum(g_a_data_width, g_b_data_width);
  constant c_dw_min : positive := minimum(g_a_data_width, g_b_data_width);
  constant c_sz_max : positive := 2**maximum(g_a_addr_width, g_b_addr_width);
  constant c_ratio  : positive := c_dw_max / c_dw_min;
  constant c_lsbw   : positive := fn_log2(c_ratio);

  signal ram        : t_slv_array(c_sz_max-1 downto 0)(c_dw_min-1 downto 0);

  signal ram_douta  : std_logic_vector(g_a_data_width-1 downto 0);
  signal ram_doutb  : std_logic_vector(g_b_data_width-1 downto 0);

begin

  assert minimum(g_a_addr_width, g_b_addr_width) + c_lsbw = maximum(g_a_addr_width, g_b_addr_width)
    report "tdpram_asym: invalid port width ratio"
    severity failure;

  p_tdpram : process(clka, clkb)
    variable v_lsb : unsigned(c_lsbw-1 downto 0);
  begin
    if rising_edge(clka) then
      if ena = '1' then
        if g_a_data_width = c_dw_min then
          if g_a_ram_mode = e_ram_read_first then
            if wea = '1' then
              ram(to_integer(unsigned(addra))) <= dina;
            end if;
            ram_douta <= ram(to_integer(unsigned(addra)));
          elsif g_a_ram_mode = e_ram_write_first then
            if wea = '1' then
              ram(to_integer(unsigned(addra))) <= dina;
              ram_douta <= dina;
            else
              ram_douta <= ram(to_integer(unsigned(addra)));
            end if;
          else
            if wea = '1' then
              ram(to_integer(unsigned(addra))) <= dina;
            else
              ram_douta <= ram(to_integer(unsigned(addra)));
            end if;
          end if;
        else
          for i in 0 to c_ratio-1 loop
            v_lsb := to_unsigned(i,c_lsbw);
            if g_a_ram_mode = e_ram_read_first then
              if wea = '1' then
                ram(to_integer(unsigned(addra) & v_lsb)) <= dina((i+1)*c_dw_min-1 downto i*c_dw_min);
              end if;
              ram_douta((i+1)*c_dw_min-1 downto i*c_dw_min) <= ram(to_integer(unsigned(addra) & v_lsb));
            elsif g_a_ram_mode = e_ram_write_first then
              if wea = '1' then
                ram(to_integer(unsigned(addra) & v_lsb)) <= dina((i+1)*c_dw_min-1 downto i*c_dw_min);
                ram_douta((i+1)*c_dw_min-1 downto i*c_dw_min) <= dina((i+1)*c_dw_min-1 downto i*c_dw_min);
              else
                ram_douta((i+1)*c_dw_min-1 downto i*c_dw_min) <= ram(to_integer(unsigned(addra) & v_lsb));
              end if;
            else
              if wea = '1' then
                ram(to_integer(unsigned(addra) & v_lsb)) <= dina((i+1)*c_dw_min-1 downto i*c_dw_min);
              else
                ram_douta((i+1)*c_dw_min-1 downto i*c_dw_min) <= ram(to_integer(unsigned(addra) & v_lsb));
              end if;
            end if;
          end loop;
        end if;
      end if;
    end if;
    if rising_edge(clkb) then
      if enb = '1' then
        if g_b_data_width = c_dw_min then
          if g_b_ram_mode = e_ram_read_first then
            if web = '1' then
              ram(to_integer(unsigned(addrb))) <= dinb;
            end if;
            ram_doutb <= ram(to_integer(unsigned(addrb)));
          elsif g_b_ram_mode = e_ram_write_first then
            if web = '1' then
              ram(to_integer(unsigned(addrb))) <= dinb;
              ram_doutb <= dinb;
            else
              ram_doutb <= ram(to_integer(unsigned(addrb)));
            end if;
          else
            if web = '1' then
              ram(to_integer(unsigned(addrb))) <= dinb;
            else
              ram_doutb <= ram(to_integer(unsigned(addrb)));
            end if;
          end if;
        else
          for i in 0 to c_ratio-1 loop
            v_lsb := to_unsigned(i,c_lsbw);
            if g_b_ram_mode = e_ram_read_first then
              if web = '1' then
                ram(to_integer(unsigned(addrb) & v_lsb)) <= dinb((i+1)*c_dw_min-1 downto i*c_dw_min);
              end if;
              ram_doutb((i+1)*c_dw_min-1 downto i*c_dw_min) <= ram(to_integer(unsigned(addrb) & v_lsb));
            elsif g_b_ram_mode = e_ram_write_first then
              if web = '1' then
                ram(to_integer(unsigned(addrb) & v_lsb)) <= dinb((i+1)*c_dw_min-1 downto i*c_dw_min);
                ram_doutb((i+1)*c_dw_min-1 downto i*c_dw_min) <= dinb((i+1)*c_dw_min-1 downto i*c_dw_min);
              else
                ram_doutb((i+1)*c_dw_min-1 downto i*c_dw_min) <= ram(to_integer(unsigned(addrb) & v_lsb));
              end if;
            else
              if web = '1' then
                ram(to_integer(unsigned(addrb) & v_lsb)) <= dinb((i+1)*c_dw_min-1 downto i*c_dw_min);
              else
                ram_doutb((i+1)*c_dw_min-1 downto i*c_dw_min) <= ram(to_integer(unsigned(addrb) & v_lsb));
              end if;
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;


  b_reg_output : if g_reg_output generate
    p_reg_output : process(clka, clkb)
    begin
      if rising_edge(clka) then
        if rsta = '1' then
          douta <= (others => '0');
        elsif regcea = '1' then
          douta <= ram_douta;
        end if;
      end if;
      if rising_edge(clkb) then
        if rstb = '1' then
          doutb <= (others => '0');
        elsif regceb = '1' then
          doutb <= ram_doutb;
        end if;
      end if;
    end process;
  else generate
    douta <= ram_douta;
    doutb <= ram_doutb;
  end generate;

end architecture;