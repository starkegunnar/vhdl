library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity fifo_sync is
  generic (
    g_data_width  : natural := 32;
    g_log2_depth  : natural := 9;
    g_ram_style   : string := "mixed"
  );
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst     : in  std_logic;
    -- FIFO write
    din     : in  std_logic_vector(g_data_width-1 downto 0);
    wen     : in  std_logic := '0';
    full    : out std_logic;
    -- FIFO read
    dout    : out std_logic_vector(g_data_width-1 downto 0);
    ren     : in  std_logic := '0';
    empty   : out std_logic
  );
end entity fifo_sync;

architecture rtl of fifo_sync is

  signal mem        : t_slv_array(0 to 2**g_log2_depth-1)(g_data_width-1 downto 0) := (others => (others => '0'));
  signal rptr       : unsigned(g_log2_depth-1 downto 0) := (others => '0');
  signal wptr       : unsigned(g_log2_depth-1 downto 0) := (others => '0');
  signal count      : unsigned(g_log2_depth-1 downto 0) := (others => '0');

  signal empty_mem  : std_logic := '1';
  signal empty_reg  : std_logic := '1';
  signal full_mem   : std_logic := '0';

  signal wen_mem    : std_logic;
  signal ren_mem    : std_logic;

begin

  wen_mem <= wen and not full_mem;

  p_write : process(clk)
  begin
    if rising_edge(clk) then
      if full_mem = '0' then
        mem(to_integer(wptr)) <= din;
      end if;

      if wen_mem = '1' then
        wptr <= wptr + 1;
      end if;

      if rst = '1' then
        wptr <= (others => '0');
      end if;
    end if;
  end process;

  ren_mem <= (ren or empty_reg) and not empty_mem;

  p_read : process(clk)
  begin
    if rising_edge(clk) then
      if ren_mem = '1' then
        rptr <= rptr + 1;
      end if;

      if rst = '1' then
        rptr <= (others => '0');
      end if;
    end if;
  end process;

  p_count : process(clk)
    variable v_wr : std_logic_vector(1 downto 0);
  begin
    if rising_edge(clk) then
      v_wr := wen_mem & ren_mem;

      case v_wr is
      when "01" =>
        -- read only
        count     <= count - 1;
        full_mem  <= '0';
        if count = 1 then
          empty_mem <= '1';
        end if;
      when "10" =>
        -- write only
        count <= count + 1;
        if count = 2**g_log2_depth-1 then
          full_mem  <= '1';
        end if;
        empty_mem <= '0';
      when others =>
      end case;

      if rst = '1' then
        count     <= (others => '0');
        full_mem  <= '0';
        empty_mem <= '1';
      end if;
    end if;
  end process;

  p_reg_out : process(clk)
  begin
    if rising_edge(clk) then
      if empty_reg = '1' or ren = '1' then
        dout      <= mem(to_integer(rptr));
        empty_reg <= empty_mem;
      end if;

      if rst = '1' then
        empty_reg <= '1';
      end if;
    end if;
  end process;

  full  <= full_mem;
  empty <= empty_reg;

end architecture rtl;