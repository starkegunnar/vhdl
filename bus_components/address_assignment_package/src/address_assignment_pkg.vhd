library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library lib_common;
use lib_common.common_pkg.all;

package address_assignment_pkg is

  type t_bus_component is record
    name    : string;
    size    : natural;
  end record;

end package address_assignment_pkg;

package body address_assignment_pkg is


end package body address_assignment_pkg;