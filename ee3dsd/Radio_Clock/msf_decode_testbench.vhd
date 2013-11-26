library IEEE;

use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity msf_decode_testbench is

  generic
  (
      clk_freq: positive := 1000 -- Hz
  );

end msf_decode_testbench;

architecture tests of msf_decode_testbench is

  constant test_duration: time      := 58000 ms;
  constant clk_period:    time      := 1000 ms / clk_freq;
  signal end_flag:        std_logic := '0';

  signal rst:             std_logic := '0';
  signal clk:             std_logic := '0';
  signal si:              std_logic := 'X'; -- start of second in
  signal mi:              std_logic := 'X'; -- start of minute in
  signal bai:             std_logic := 'X'; -- bit in
  signal bbi:             std_logic := 'X'; -- bit in
  signal year:   bcd_digit_vector(3 downto 0) := (3 => bcd_two, 2 => bcd_zero, others => bcd_minus);
  signal month:  bcd_digit_vector(1 downto 0) := (others => bcd_minus);
  signal day:    bcd_digit_vector(1 downto 0) := (others => bcd_minus);
  signal hour:   bcd_digit_vector(1 downto 0) := (others => bcd_minus);
  signal minute: bcd_digit_vector(1 downto 0) := (others => bcd_minus);
  signal second: bcd_digit_vector(1 downto 0) := (others => bcd_zero);
  signal tr:              std_logic := '0'; -- new bit trigger

begin

  decode: entity WORK.msf_decode(rtl)
    generic map
    (
        clk_freq => clk_freq
    )
    port map
    (
        rst      => rst,
        clk      => clk,
        si       => si,
        mi       => mi,
        bai      => bai,
        bbi      => bbi,
        year     => year,
        month    => month,
        day      => day,
        hour     => hour,
        minute   => minute,
        second   => second,
        tr       => tr
    );

  process -- Process to end test after duration
  begin

    wait for test_duration;
    end_flag <= '1';

    wait;
  end process;

  process is -- Process to set 'clk'
    variable clk_var:    std_logic := '0';
  begin

    while (end_flag = '0') loop
      clk <= '0';
      wait for clk_period / 2;
      clk <= '1';
      wait for clk_period / 2;
    end loop;

    wait;
  end process;

end tests;
