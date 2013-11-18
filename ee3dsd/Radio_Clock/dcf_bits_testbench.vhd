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
      clk_freq: positive := 100 -- 100 Hz
  );

end dcf_bits_testbench;

architecture tests of dcf_bits_testbench is

  constant test_duration: time := 60000 ms;
  constant clk_period: time := 1000 ms / clk_freq;

  signal end_flag: std_logic := '0';

  signal rst: std_logic := '0';
  signal clk: std_logic := '0';
  signal di:  byte      := byte_unknown;

  signal so:  std_logic := 'X';
  signal mo:  std_logic := 'X';
  signal bo:  std_logic := 'X';
  signal tr:  std_logic := 'X';

begin

  sync: entity WORK.dcf_sync(rtl)
    generic map
    (
        clk_freq => clk_freq
    )
    port map
    (
        rst      => rst,
        clk      => clk,
        di       => di,
        so       => so,
        mo       => mo
    );

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
        si       => so,
        bo       => bo,
        tr       => tr
    );

  process
  begin

    wait for test_duration;
    end_flag <= '1';
    wait;

  end process;

  process is

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

end tests;
