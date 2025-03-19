library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

--! AXIS package
--!
package axis_pkg is

  type t_axis is record
    data : std_logic_vector;
    keep : std_logic_vector;
    last : std_logic;
    id   : std_logic_vector;
    dest : std_logic_vector;
    user : std_logic_vector;
  end record;

  type t_axis_cfg is record
    keep_width  : positive;
    id_width    : natural;
    dest_width  : natural;
    user_width  : natural;
  end record;

  constant c_axis_cfg8 : t_axis_cfg := (
    keep_width  => 1,
    id_width    => 0,
    dest_width  => 0,
    user_width  => 0
  );

  constant c_axis_cfg16 : t_axis_cfg := (
    keep_width  => 2,
    id_width    => 0,
    dest_width  => 0,
    user_width  => 0
  );

  constant c_axis_cfg32 : t_axis_cfg := (
    keep_width  => 4,
    id_width    => 0,
    dest_width  => 0,
    user_width  => 0
  );

  constant c_axis_cfg64 : t_axis_cfg := (
    keep_width  => 8,
    id_width    => 0,
    dest_width  => 0,
    user_width  => 0
  );

end package axis_pkg;

package body axis_pkg is

end package body axis_pkg;