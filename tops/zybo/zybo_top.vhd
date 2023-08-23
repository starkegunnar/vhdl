library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity zybo_top is
  port (
--Clock signal (125 MHz)
    clk         : in  std_logic;

--Switches
--    sw          : in  std_logic_vector(3 downto 0);

--Buttons
--    btn         : in  std_logic_vector(3 downto 0);

--LEDs
--    led         : out std_logic_vector(3 downto 0);

--I2S Audio Codec
--    ac_bclk     : out std_logic;
--    ac_mclk     : out std_logic;
--    ac_muten    : out std_logic;
--    ac_pbdat    : out std_logic;
--    ac_pblrc    : out std_logic;
--    ac_recdat   : in  std_logic;
--    ac_reclrc   : out std_logic;

--Audio Codec/external EEPROM IIC bus
--    ac_scl      : out  std_logic;
--    ac_sda      : inout std_logic;


--Additional Ethernet signals
--    eth_int_b   : out std_logic;
--    eth_rst_b   : out std_logic;

--HDMI Signals
--    hdmi_clk_n  : in  std_logic;
--    hdmi_clk_p  : in  std_logic;
--    hdmi_d_n    : in  std_logic_vector(2 downto 1);
--    hdmi_d_p    : in  std_logic_vector(2 downto 1);
--    hdmi_cec    : in  std_logic;
--    hdmi_hpd    : in  std_logic;
--    hdmi_out_en : in  std_logic;
--    hdmi_scl    : in  std_logic;
--    hdmi_sda    : in  std_logic;

--Pmod Header JA (XADC)
--    jd_p        : in  : std_logic_vector(3 downto 0);
--    jd_n        : in  : std_logic_vector(3 downto 0);

--Pmod Header JB
--    jd_p        : in  : std_logic_vector(3 downto 0);
--    jd_n        : in  : std_logic_vector(3 downto 0);

--Pmod Header JC
--    jd_p        : in  : std_logic_vector(3 downto 0);
--    jd_n        : in  : std_logic_vector(3 downto 0);

--Pmod Header JD
--    jd_p        : in  : std_logic_vector(3 downto 0);
--    jd_n        : in  : std_logic_vector(3 downto 0);

--Pmod Header JE
--    je          : in  std_logic_vector(7 downto 0);
--    je          : out std_logic_vector(7 downto 0);

--USB-OTG overcurrent detect pin
--    otg_oc      : in  std_logic;

--VGA Connector
--    vga_r       : out std_logic_vector(4 downto 0);
--    vga_g       : out std_logic_vector(4 downto 0);
--    vga_b       : out std_logic_vector(4 downto 0);
--    vga_hs      : out std_logic;
--    vga_vs      : out std_logic
  );
end entity zybo_top;

architecture top of zybo_top is

end architecture top;