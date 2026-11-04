library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--! AXIS package
--!
package axis_pkg is

  type t_axis is record
    data  : std_logic_vector;
    keep  : std_logic_vector;
    last  : std_logic;
    id    : std_logic_vector;
    dest  : std_logic_vector;
    user  : std_logic_vector;
  end record;

  type t_axis_array is array(natural range <>) of t_axis;

  function f_axis_width(
    DW    : integer; 
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return integer;

  function f_axis_serialize(
    t     : t_axis;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return std_logic_vector;

end package axis_pkg;

package body axis_pkg is

  function f_axis_width(
    DW    : integer; 
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return integer is
  begin
    return DW+DW/8+1+IDW+DSTW+USRW;
  end function;

  function f_axis_serialize(
    t     : t_axis;
    DW    : integer; 
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return std_logic_vector is
    variable v : std_logic_vector(f_axis_width(DW, IDW, DSTW, USRW));
  begin
    if USRW > 0 then
      v(USRW+DSTW+IDW+1+DW/8+DW-1 downto DSTW+IDW+1+DW/8+DW) := t.user;
    end if;
    if DSTW > 0 then
      v(DSTW+IDW+1+DW/8+DW-1 downto IDW+1+DW/8+DW) := t.dst;
    end if;
    if IDW > 0 then
      v(IDW+1+DW/8+DW-1 downto 1+DW/8+DW) := t.dst;
    end if;
    v(1+DW/8+DW-1 downto 0) := t.last & t.keep & t.data;
    return v;
  end function;

  function f_axis_deserialize(
    v     : std_logic_vector;
    DW    : integer;
    IDW   : integer := 0;
    DSTW  : integer := 0;
    USRW  : integer := 0
  ) return t_axis is
    vv  : std_logic_vector(v'length-1 downto 0);
    t   : t_axis(
            data(DW-1 downto 0),
            keep(DW/8-1 downto 0),
            id(maximum(IDW, 1)-1 downto 0),
            dest(maximum(DSTW, 1)-1 downto 0)
            user(maximum(USRW, 1)-1 downto 0)
          );
  begin
    vv      := v;
    t.data  := vv(DW-1 downto 0);
    t.keep  := vv(DW+DW/8-1 downto DW);
    t.last  := vv(DW+DW/8);
    t.id    := (others => '0');
    if IDW > 0 then
      t.id := vv(IDW+1+DW+DW/8-1 downto 1+DW+DW/8);
    end if;
    t.dst   := (others => '0');
    if DSTW > 0 then
      t.dst := vv(DSTW+IDW+1+DW+DW/8-1 downto IDW+1+DW+DW/8);
    end if;
    t.user  := (others => '0');
    if USRW > 0 then
      t.user := vv(USRW+DSTW+IDW+1+DW+DW/8-1 downto DSTW+IDW+1+DW+DW/8);
    end if;
    return t;
  end function;

end package body axis_pkg;