library IEEE;

use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity dcf_decode_testbench is

  generic
  (
      clk_freq: positive := 1000 -- Hz
  );

end dcf_decode_testbench;

architecture tests of dcf_decode_testbench is

  constant clk_period:    time      := 1000 ms / clk_freq;
  constant sec_period:    time      := 1000 ms;
  constant test_duration: time      := 62 * sec_period;
  signal end_flag:        std_logic := '0';

  signal rst:             std_logic := '0';
  signal clk:             std_logic := '0';
  signal si:              std_logic := 'X'; -- start of second in
  signal mi:              std_logic := 'X'; -- start of minute in
  signal bi:              std_logic := '0'; -- bit in
  signal year:   bcd_digit_vector(3 downto 0) := (3 => bcd_two, 2 => bcd_zero, others => bcd_minus);
  signal month:  bcd_digit_vector(1 downto 0) := (others => bcd_minus);
  signal day:    bcd_digit_vector(1 downto 0) := (others => bcd_minus);
  signal hour:   bcd_digit_vector(1 downto 0) := (others => bcd_minus);
  signal minute: bcd_digit_vector(1 downto 0) := (others => bcd_minus);
  signal second: bcd_digit_vector(1 downto 0) := (others => bcd_zero);
  signal tr:              std_logic := '0'; -- new bit trigger

begin

  decode: entity WORK.dcf_decode(rtl)
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
        bi       => bi,
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
  begin

    while (end_flag = '0') loop
      clk <= '0';
      wait for clk_period / 2;
      clk <= '1';
      wait for clk_period / 2;
    end loop;

    wait;
  end process;

  process is -- Process to set 'si'
  begin

    while (end_flag = '0') loop
      si <= '1';
      wait for clk_period;
      si <= '0';
      wait for sec_period - clk_period;
    end loop;

    wait;
  end process;

  process is -- Process to set 'mi'
  begin

    mi <= '1'; -- First minute
    wait for clk_period;
    mi <= '0';
    wait for 60 * sec_period - clk_period;
    mi <= '1'; -- Second minute
    wait for clk_period;
    mi <= '0';

    wait;
  end process;

  process is -- Process to set 'bi'

    file     data:       text;
    variable data_line:  line;
    variable bi_var:     std_logic;

  begin

    file_open(data, "dcf-decode.txt", read_mode);

    while not endfile(data) loop

      readline(data, data_line);
      read(data_line, bi_var);

      wait for 150 ms;
      bi <= bi_var;
      wait for sec_period - 150 ms;

    end loop;

    file_close(data);
    wait;
  end process;

end tests;
