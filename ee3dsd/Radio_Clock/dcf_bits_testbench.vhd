library IEEE;

use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_1164.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity dcf_bits_testbench is

  generic
  (
      clk_freq: positive := 1000 -- Hz
  );

end dcf_bits_testbench;

architecture tests of dcf_bits_testbench is

  constant test_duration: time := 60000 ms;
  constant clk_period: time := 1000 ms / clk_freq;

  signal end_flag: std_logic := '0';

  signal rst: std_logic := '0';
  signal clk: std_logic := '0';
  signal di:  byte      := byte_unknown;
  signal si:  std_logic := 'X';
  signal bo:  std_logic := 'X';
  signal tr:  std_logic := 'X';

begin

  bits: entity WORK.dcf_bits(rtl)
    generic map
    (
        clk_freq => clk_freq
    )
    port map
    (
        rst      => rst,
        clk      => clk,
        di       => di,
        si       => si,
        bo       => bo,
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
      clk <= '1';
      wait for clk_period / 2;
      clk <= '0';
      wait for clk_period / 2;
    end loop;

    wait;
  end process;

  process is -- Process to set 'di'

    file     data:       text;
    variable data_line:  line;
    variable t_var:      time;

  begin

    file_open(data, "dcf.txt", read_mode);

    while not endfile(data) loop

      di <= byte_zero;

      readline(data, data_line);
      read(data_line, t_var);
      wait for t_var - now;

      di <= byte_255;

      readline(data, data_line);
      read(data_line, t_var);
      wait for t_var - now;

    end loop;

    file_close(data);
    wait;
  end process;

end tests;
