library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity edge_detector is

    generic
    (
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock
        
        di:  in  byte      := byte_unknown; -- data in
        do:  out byte      := byte_null;    -- data out
        ed:  out std_logic := '0'           -- edge detected
    );

end edge_detector;

architecture rtl of edge_detector is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end rtl;
