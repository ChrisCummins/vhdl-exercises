library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity serial_port is

    generic
    (
        clk_freq:   positive := 125000000;  -- Hz
        gate_delay: time     := 0.1 ns;
        baud_rate:  positive := 57600
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock

        wr:  in  std_logic := 'X';          -- write
        di:  in  byte      := byte_unknown; -- data in
        bsy: out std_logic := '0';          -- busy
        tx:  out std_logic := '1'           -- serial out
   );

end serial_port;

architecture behav of serial_port is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end behav;
