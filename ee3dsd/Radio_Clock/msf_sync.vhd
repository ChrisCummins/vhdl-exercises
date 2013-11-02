library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity msf_sync is

    generic
    (
        clk_freq:   positive := 100; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- Reset
        clk: in  std_logic := 'X';          -- Clock

        di:  in  byte      := byte_unknown; -- Data in
        so:  out std_logic := '0';          -- Start of second
        mo:  out std_logic := '0'           -- Start of minute
    );

end msf_sync;

architecture rtl of msf_sync is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end rtl;
