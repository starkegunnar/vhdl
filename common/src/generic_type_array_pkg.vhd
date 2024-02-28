--! @defgroup   GENERIC_TYPE_ARRAY_PKG generic type array package
--!
--! @brief      This file implements a generic type array.
--!
--! @author     Martin Caous George
--! @date       2023
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Generic type array package
--!
package generic_type_array_pkg is

  generic (
    type t_data
  );

  type t_data_array is array(natural range <>) of t_data;

end package generic_type_array_pkg;