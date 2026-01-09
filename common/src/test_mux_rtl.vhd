library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lib_common;
use lib_common.common_pkg.all;

entity test_mux is
  port (
    -- Clock and reset
    clk     : in  std_logic;
    rst     : in  std_logic;
    -- Data and flow control
    s_data  : in  t_slv_array(4 downto 0)(7 downto 0);
    s_valid : in  std_logic_vector(4 downto 0);
    s_eof   : in  std_logic_vector(4 downto 0);
    s_ready : out std_logic_vector(4 downto 0);
    m_data  : out std_logic_vector(7 downto 0);
    m_valid : out std_logic;
    m_eof   : out std_logic;
    m_ready : in  std_logic
  );
end entity test_mux;

architecture rtl of test_mux is

  signal req          : std_logic_vector(4 downto 0);
  signal ack          : std_logic_vector(4 downto 0);
  signal grant        : std_logic_vector(4 downto 0);
  signal grant_valid  : std_logic;
  signal grant_index  : std_logic_vector(f_log2(5)-1 downto 0);

  signal s_valid_r    : std_logic_vector(4 downto 0) := (others =>'0');
  signal s_data_r     : t_slv_array(4 downto 0)(7 downto 0);
  signal s_eof_r      : std_logic_vector(4 downto 0);

  signal m_data_d     : std_logic_vector(7 downto 0);
  signal m_valid_d    : std_logic;
  signal m_eof_d      : std_logic;

  signal m_data_q     : std_logic_vector(7 downto 0);
  signal m_valid_q    : std_logic;
  signal m_eof_q      : std_logic;
  signal m_ready_q    : std_logic;

begin

  req <= s_valid or (not s_ready and not grant);
  ack <= grant and not s_ready and s_eof_r and m_ready;

  i_arbiter : entity lib_common.arbiter(rtl)
  generic map (
    g_width       => 5
  )
  port map (
    clk         => clk,
    rst         => rst,
    req         => req,
    ack         => ack,
    grant       => grant,
    grant_valid => grant_valid,
    grant_index => grant_index
  );

  s_ready <= not s_valid_r or (m_ready_q and grant);

  p_regs : process(clk)
  begin
    if rising_edge(clk) then
      for i in 0 to 4 loop
        if s_ready(i) = '1' then
          s_valid_r(i)   <= s_valid(i);
          s_data_r(i)  <= s_data(i);
          s_eof_r(i)   <= s_eof(i);
        end if;
      end loop;

      if rst = '1' then
        s_valid_r <= (others => '1');
      end if;
    end if;
  end process;

  m_valid_d <= grant_valid and s_valid_r(to_integer(unsigned(grant_index)));
  m_data_d  <= s_data_r(to_integer(unsigned(grant_index)));
  m_eof_d   <= s_eof_r(to_integer(unsigned(grant_index)));

  p_slice : process(clk)
  begin
    if rising_edge(clk) then

      if m_valid_d = '1' and m_ready_q = '1' and m_valid = '1' and m_ready = '0' then
        m_ready_q <= '0';
      elsif m_ready = '1' then
        m_ready_q <= '1';
      end if;

      if m_ready_q = '1' then
        m_data_q  <= m_data_d;
        m_eof_q   <= m_eof_d;
      end if;

      if m_valid = '0' or m_ready = '1' then
        m_valid <= m_valid_d or not m_ready_q;
        if m_ready_q = '0' then
          m_data <= m_data_q;
          m_eof  <= m_eof_q;
        else
          m_data <= m_data_d;
          m_eof  <= m_eof_d;
        end if;
      end if;

      if rst = '1' then
        m_ready_q <= '1';
        m_valid   <= '0';
      end if;
    end if;
  end process;

end architecture rtl;