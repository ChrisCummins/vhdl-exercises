library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf_bits is

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- Reset
        clk: in  std_logic := 'X';          -- Clock

        di:  in  byte      := byte_unknown; -- Data in
        si:  in  std_logic := 'X';          -- Start of second in
        bo:  out std_logic := '0';          -- Bit out
        tr:  out std_logic := '0'           -- New bit trigger
    );

end dcf_bits;

architecture rtl of dcf_bits is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end rtl;
