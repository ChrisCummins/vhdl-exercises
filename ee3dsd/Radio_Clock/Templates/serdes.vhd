library IEEE;
library UNISIM;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity serdes is

    generic
    (
        gate_delay:   time      := 1 ns
    );

    port
    (
        clk_ser:  in  std_logic := 'X';      -- serial clock in
        clk_par:  in  std_logic := 'X';      -- parallel clock in
        clk_2par: in  std_logic := 'X';      -- 2 x parallel clock in
        strobe:   in  std_logic := 'X';      -- strobe
        data_in:  in  std_logic := 'X';      -- serial data in
        data_out: out byte      := byte_null -- parallel data out
   );

end serdes;

architecture behav of serdes is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end behav;
