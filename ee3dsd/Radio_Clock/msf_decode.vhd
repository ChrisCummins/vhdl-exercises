library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity msf_decode is

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst:    in  std_logic                    := 'X'; -- reset
        clk:    in  std_logic                    := 'X'; -- clock

        si:     in  std_logic                    := 'X'; -- start of second in
        mi:     in  std_logic                    := 'X'; -- start of minute in
        bai:    in  std_logic                    := 'X'; -- bit A in
        bbi:    in  std_logic                    := 'X'; -- bit B in
        year:   out bcd_digit_vector(3 downto 0) := (3 => bcd_two, 2 => bcd_zero, others => bcd_minus);
        month:  out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        day:    out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        hour:   out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        minute: out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        second: out bcd_digit_vector(1 downto 0) := (others => bcd_zero);
        tr:     out std_logic                    := '0'  -- new bit trigger
    );

end msf_decode;

architecture rtl of msf_decode is

  type    states             is (st_wait, st_sample, st_write);
  subtype bit_register       is std_logic_vector(59 downto 0);
  subtype bit_register_index is natural range bit_register'length downto 0;

  signal  si_sampled:   std_logic          := '0';
  signal  mi_sampled:   std_logic          := '0';
  signal  bai_sampled:  std_logic          := '0';
  signal  bbi_sampled:  std_logic          := '0';

  signal  state:        states             := st_wait;
  signal  next_state:   states             := st_wait;

  signal  a_reg:        bit_register       := (others => '0');
  signal  b_reg:        bit_register       := (others => '0');
  signal  index:        bit_register_index := 0;
  signal  next_index:   bit_register_index := 0;

begin

  -- Your implementation goes here --

end rtl;
