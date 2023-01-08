library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_slice is
  generic (
    g_data_width : natural := 8;
    g_impl       : string := "full"
  );
  port (
    -- Clock and reset
    i_clk   : in  std_logic;
    i_rst   : in  std_logic;
    -- Data and flow control
    i_data  : in  std_logic_vector(g_data_width - 1 downto 0);
    i_valid : in  std_logic;
    o_ready : out std_logic;
    o_data  : out std_logic_vector(g_data_width - 1 downto 0);
    o_valid : out std_logic;
    i_ready : in  std_logic
  );
end entity reg_slice;

architecture rtl of reg_slice is

  type t_impl is (impl_full, impl_half, impl_reg_input, impl_pass);

  -- Functions
  function f_impl_type return t_impl is
  begin
    if g_impl = "half" then
      return impl_half;
    elsif g_impl = "reg_input" then
      return impl_reg_input;
    elsif g_impl = "passthrough" then
      return impl_pass;
    else
      return impl_full;
    end if;
  end function f_impl_type;

  constant c_impl : t_impl := f_impl_type;
  constant c_fifo_depth : natural := 3;
  constant c_fifo_ptr_max : natural := c_fifo_depth - 1;

  signal r_data         : std_logic_vector(g_data_width - 1 downto 0);
  signal r_valid        : std_logic;
  signal r_ready        : std_logic;
  signal o_valid_int    : std_logic;
  signal r_ready_srl    : std_logic_vector(1 downto 0);

  type t_fifo is array (c_fifo_ptr_max downto 0) of std_logic_vector(g_data_width - 1 downto 0);
  signal fifo         : t_fifo;
  signal wptr         : unsigned(1 downto 0);
  signal rptr         : unsigned(1 downto 0);
  signal cnt          : unsigned(1 downto 0);
  signal we, we1, re  : std_logic := '0';
  signal empty_n      : std_logic;

  attribute keep : string;
  attribute keep of o_valid_int : signal is "true";

begin

  b_impl : if c_impl = impl_full generate

    p_full : process(i_clk)
    begin
      if rising_edge(i_clk) then

        if i_valid = '1' and r_valid = '0' and o_valid_int = '1' and i_ready = '0' then
          r_valid     <= '1';
          o_ready     <= '0';
        elsif i_ready = '1' then
          r_valid     <= '0';
          o_ready     <= '1';
        elsif r_valid = '0' and o_valid_int = '0' then
          o_ready     <= '1';
        end if;

        if i_valid = '1' and r_valid = '0' then
          r_data <= i_data;
        end if;

        if o_valid_int = '0' or i_ready = '1' then
          o_valid_int <= r_valid or i_valid;
          o_valid     <= r_valid or i_valid;
        end if;

        if o_valid_int = '0' or i_ready = '1' then
          if r_valid = '1' then
            o_data <= r_data;
          else
            o_data <= i_data;
          end if;
        end if;

        if i_rst = '1' then
          o_valid_int <= '0';
          o_ready     <= '0';
          o_valid     <= '0';
          r_valid     <= '0';
        end if;
      end if;
    end process;

  elsif c_impl = impl_half generate

    p_half : process(i_clk)
    begin
      if rising_edge(i_clk) then
        if o_valid_int = '0' then
          if i_valid = '1' then
            o_valid_int <= '1';
            o_valid     <= '1';
            o_ready     <= '0';
          else
            o_ready     <= '1';
          end if;
        elsif i_ready = '1' then
          o_valid_int <= '0';
          o_valid     <= '0';
          o_ready     <= '1';
        end if;

        if o_valid_int = '0' or i_ready = '1' then
          o_data <= i_data;
        end if;

        if i_rst = '1' then
          o_valid_int <= '0';
          o_ready     <= '0';
          o_valid     <= '0';
        end if;
      end if;
    end process;

  elsif c_impl = impl_reg_input generate

    o_data  <= fifo(to_integer(rptr(1 downto 0))) when empty_n = '1' else r_data;
    o_valid <= empty_n or (r_valid and r_ready_srl(r_ready_srl'high));

    -- Read from fifo if a transfer happens
    re <= empty_n and i_ready;
    -- Write to fifo if receiver is not ready of if we have data in fifo and a transfer would happen
    we <= r_valid and r_ready_srl(r_ready_srl'high) and (not i_ready or (empty_n and i_ready));

    p_reg_input : process(i_clk)
      variable v_rptr : unsigned(rptr'range);
      variable v_wptr : unsigned(wptr'range);
      variable v_ren  : std_logic;
      variable v_wen  : std_logic;
      variable v_case : std_logic_vector(1 downto 0);
    begin
      if rising_edge(i_clk) then
        r_data  <= i_data;
        r_valid <= i_valid;
        o_ready <= r_ready;

        v_rptr := rptr;
        v_wptr := wptr;

        if re = '1' then
          if rptr(1 downto 0) = c_fifo_ptr_max then
            -- wrap
            v_rptr := (others => '0');
          else
            v_rptr := rptr + 1;
          end if;
        end if;

        if we = '1' then
          fifo(to_integer(wptr)) <= r_data;
          if wptr(1 downto 0) = c_fifo_ptr_max then
            -- wrap
            v_wptr := (others => '0');
          else
            v_wptr := wptr + 1;
          end if;
        end if;

        v_case := re & we;
        case v_case is
        when "01" => -- write
          cnt <= cnt + 1;
          empty_n <= '1';
          r_ready <= '0';
        when "10" => -- read
          cnt <= cnt - 1;
          if cnt <= 1 then
            empty_n <= '0';
          end if;
          r_ready <= '1';
        when "11" => -- read and write
          r_ready <= '1';
        when others => -- nop
          if cnt = 0 then
            r_ready <= '1';
          else
            r_ready <= '0';
          end if;
        end case;

        rptr <= v_rptr;
        wptr <= v_wptr;

        r_ready_srl <= r_ready_srl(r_ready_srl'low) & r_ready;

        if i_rst = '1' then
          o_ready     <= '0';
          r_valid     <= '0';
          r_ready     <= '1';
          empty_n     <= '0';
          r_ready_srl <= "00";
          wptr        <= (others => '0');
          rptr        <= (others => '0');
          cnt         <= (others => '0');
        end if;
      end if;
    end process;

  else generate -- impl_pass

    o_valid <= i_valid;
    o_data  <= i_data;
    o_ready <= i_ready;

  end generate b_impl;


end architecture rtl;