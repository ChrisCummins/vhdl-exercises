library IEEE;
library UNISIM;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ddrserdes is

    generic
    (
        gate_delay:   time                                       := 1 ns;
        ibuf_len:     positive                                   := 2
    );

    port
    (
        clk_par:  in  std_logic                                  := 'X';      -- parallel clock in
        clk_2par: in  std_logic                                  := 'X';      -- 2 x parallel clock in
        data_in:  in  std_logic                                  := 'X';      -- serial data in
        data_out: out byte                                       := byte_null -- parallel data out
   );

end ddrserdes;

architecture behav of ddrserdes is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end behav;
