library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ssg_testbench is

  generic
  (
      clk_freq: positive := 1000 -- Hz
  );

end ssg_testbench;

architecture tests of ssg_testbench is

  constant test_duration: time      := 40 ms;
  constant clk_period:    time      := 1000 ms / clk_freq;
  signal end_flag:        std_logic := '0';

  signal clk: std_logic;
  signal wr: std_logic;
  signal di: byte_vector(3 downto 0);
  signal an: std_logic_vector(3 downto 0);
  signal ka: std_logic_vector(7 downto 0);

begin

  dut: entity work.ssg(behav)
    generic map
    (
        clk_freq => clk_freq
    )
    port map
    (
         clk     => clk,
         wr      => wr,
         di      => di,
         an      => an,
         ka      => ka
    );

  process -- Process to end test after duration
  begin

    wait for test_duration;
    end_flag <= '1';

    wait;
  end process;

  process is -- Process to set 'clk'
    variable clk_var: std_logic := '0';
  begin

    while (end_flag = '0') loop
      clk <= '0';
      wait for clk_period / 2;
      clk <= '1';
      wait for clk_period / 2;
    end loop;

    wait;
  end process;

  process is -- Process to set 'wr'

    variable index: natural := 0;

  begin

    while (end_flag = '0') loop

      di <= (others => byte_255);
      di(index) <= byte_zero;
      index := index + 1;

      wr <= '1';
      wait for clk_period;
      wr <= '0';

      wait for 10 ms;
    end loop;

    wait;

  end process;

end architecture;
