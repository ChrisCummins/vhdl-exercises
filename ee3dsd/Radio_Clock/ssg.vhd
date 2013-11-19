library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ssg is

    generic
    (
        clk_freq:   positive := 125000000;  -- Hz
        gate_delay: time     := 0.1 ns
    );

    port
    (
        clk: in  std_logic                    :=            'X';           -- clock
        wr:  in  std_logic                    :=            'X';           -- write
        di:  in  byte_vector(3 downto 0)      := (others => byte_unknown); -- data in
        an:  out std_logic_vector(3 downto 0) := (others => '1');          -- anodes   7 segment display
        ka:  out std_logic_vector(7 downto 0) := (others => '1')           -- kathodes 7 segment display
   );

end ssg;

architecture behav of ssg is

  type   states is (st_wait, st_wr0, st_wr1, st_wr2, st_wr3);

  signal state:      states := st_wait;
  signal next_state: states := st_wait;

begin

  process(clk)
  begin

    if clk'event and (clk = '1') then

      state <= next_state after gate_delay;

    end if;

  end process;

  process (state)
  begin

    an <= (others => '1') after gate_delay;

    case state is

      when st_wait =>

        if (wr = '1') then
          next_state <= st_wr0   after gate_delay;
        else
          next_state <= state    after gate_delay;
        end if;

      when st_wr0 =>

        an(0)        <= '0'      after gate_delay;
        ka           <= di(0)    after gate_delay;
        next_state   <= st_wr1   after gate_delay;

      when st_wr1 =>

        an(1)        <= '0'      after gate_delay;
        ka           <= di(1)    after gate_delay;
        next_state   <= st_wr1   after gate_delay;

      when st_wr2 =>

        an(2)        <= '0'      after gate_delay;
        ka           <= di(2)    after gate_delay;
        next_state   <= st_wr1   after gate_delay;

      when st_wr3 =>

        an(3)        <= '0'      after gate_delay;
        ka           <= di(3)    after gate_delay;
        next_state   <= st_wait  after gate_delay;

    end case;

  end process;

end behav;

------ END OF SSG ------

--
-- Test bench
--
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ssg_testbench is

  generic
  (
      clk_freq: positive := 100 -- Hz
  );

end ssg_testbench;

architecture tests of ssg_testbench is

  constant test_duration: time      := 10000 ms;
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

end architecture;
