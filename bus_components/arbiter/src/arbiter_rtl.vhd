library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity address_decoder is
  generic (
    g_num_slaves : positive := 4;
    g_addr_width : positive := 8;
    g_data_width : positive := 8;
    g_reg_outout : boolean  := true
  );
  port (
    -- Clock and reset
    clk             : in  std_logic;
    rst             : in  std_logic;
    -- Base addresses and masks
    slave_addresses : in  std_logic_vector(g_addr_width * g_num_slaves - 1 downto 0);
    slave_masks     : in  std_logic_vector(g_addr_width * g_num_slaves - 1 downto 0);
    -- Slave interface
    s_addr          : in  std_logic_vector(g_addr_width - 1 downto 0);
    s_data          : in  std_logic_vector(g_data_width - 1 downto 0);
    s_valid         : in  std_logic;
    s_ready         : out std_logic := '0';
    -- Master interface
    m_request       : out std_logic_vector(g_num_slaves downto 0);
    m_addr          : out std_logic_vector(g_addr_width - 1 downto 0);
    m_data          : out std_logic_vector(g_data_width - 1 downto 0);
    m_valid         : out std_logic := '0';
    m_ready         : in  std_logic
  );
end entity address_decoder;

architecture rtl of address_decoder is

  signal request : std_logic_vector(g_num_slaves downto 0);

begin

  b_gen_request : for i in 0 to g_num_slaves - 1 generate
    subtype t_range is natural range (i + 1) * g_addr_width - 1 downto i * g_num_slaves);
  begin
    request(i) <= s_valid and nor_reduce((s_addr xor slave_addresses(t_range)) and slave_masks(t_range)));
  end generate b_gen_request;
  -- No valid slave selected
  request(g_num_slaves) <= s_valid and nor_reduce(request(g_num_slaves - 1 downto 0));

  b_reg_output : if g_reg_outout generate
    signal m_valid_int : std_logic;
    signal s_ready_int : std_logic;
  begin
    s_ready_int <= m_valid_int and m_ready;
    m_valid     <= m_valid_int;

    p_reg_output : process(clk)
    begin
      if rising_edge(clk) then
        if s_ready_int = '1' then
          m_valid_int <= s_valid;
        end if;

        if (m_valid_int = '0' or m_ready = '1') and s_valid = '1' then
          m_addr    <= s_addr;
          m_data    <= s_data;
          m_request <= request;
        end if;

        if rst = '1' then
          m_valid_int <= '0';
        end if;
      end if;
    end process;
  end generate b_reg_output;

  b_comb_output : if not g_reg_outout generate
    s_ready   <= m_ready;
    m_valid   <= s_valid;
    m_addr    <= s_addr;
    m_data    <= s_data;
    m_request <= s_request;
  end generate b_comb_output;

end architecture rtl;