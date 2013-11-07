library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity msf_sync is

    generic
    (
        clk_freq:          positive  := 125000000; -- Hz
        gate_delay:        time      := 1 ns
    );

    port
    (
        rst: in            std_logic := 'X';          -- Reset
        clk: in            std_logic := 'X';          -- Clock

        di:  in            byte      := byte_unknown; -- Data in
        so:  out           std_logic := '0';          -- Start of second
        mo:  out           std_logic := '0'           -- Start of minute
    );

end msf_sync;

architecture rtl of msf_sync is

  -- This contains the data input from the last clock cycle:
  signal di_var:           byte      := byte_null;

  -- This is the minimum acceptable pulse length. The MSF signal uses
  -- 100 - 500ms pulses, so let's set this to a value slightly below the
  -- shortest (~60ms) so as to allow for some margin of error:
  constant min_pulse_cnt: natural    := clk_freq / 15;

  -- The clock cycles counter (cnt). We use this to record the number of
  -- cycles since the last pulse. som_pulse_cnt is the shortest acceptable
  -- start-of-minute pulse (~400ms). min_sec and max_sec defines the
  -- window of acceptable time between each second pulse (~900ms - ~1100ms).
  -- max_cnt is a hard limit on the amount of time to wait for a second
  -- pulse before figuring that something has gone wrong and resetting (~3000
  -- ms).
  constant som_pulse_cnt: natural    := clk_freq / 2 - clk_freq / 10;
  constant min_sec:       natural    := clk_freq - clk_freq / 10;
  constant max_sec:       natural    := clk_freq + clk_freq / 13;
  constant max_cnt:       natural    := clk_freq * 3;
  signal cnt:             natural range 0 to max_cnt + 1;

  -- The seconds counter (sec). This keeps track of what second we are on
  -- within a minute. When we first start, we are in an uninitialised state
  -- (sec_uninit). After receiving our first clock pulse, we move into a
  -- partially-initialised state (sec_part_init), which means that we still don't
  -- know exactly where in the minute we are yet (we haven't received a 500ms
  -- pulse). After that, the counter will be incremented each second in
  -- order to predict when to output the missing second pulse and start of
  -- minute pulse.
  constant sec_uninit:    natural    := 62;
  constant sec_part_init: natural    := 61;
  signal sec:             natural range 0 to sec_uninit := sec_uninit;
begin

  process(clk, rst)
  begin

    if rst = '1' then

      cnt        <= 0             after gate_delay;
      sec        <= sec_uninit    after gate_delay;
      so         <= '0'           after gate_delay;
      mo         <= '0'           after gate_delay;

    elsif clk'event and clk = '1' then

      so         <= '0'           after gate_delay; -- Zero the outputs
      mo         <= '0'           after gate_delay;
      cnt        <= cnt + 1       after gate_delay; -- Bump the clock counter

      -- Check for rising edge, either because we're expecting a second, or
      -- because we're in an uninitalised state and we're trying to latch on to
      -- the first received signal:
      if (di > di_var and cnt > min_sec and cnt < max_sec)
        or (di > di_var and sec = sec_uninit) then

        cnt      <= 0             after gate_delay; -- Reset clock counter
        so       <= '1'           after gate_delay; -- Output second pulse

        if sec < 60 then

          sec    <= sec + 1       after gate_delay; -- Count another second

        elsif sec = 60 then

          sec    <= 1             after gate_delay; -- Reset the minute counter
          mo     <= '1'           after gate_delay; -- Output start of minute

        elsif sec = sec_uninit then

          -- We've now in a partially-initialised state, i.e. we've found our
          -- first second to latch onto but we haven't received a full minute
          -- yet so don't know when to expect the missing second.
          sec    <= sec_part_init after gate_delay;

        end if;

      -- Check for falling edge
      elsif di < di_var then

        -- One further precaution: if we've only just latched on to the first
        -- signal pulse, then make sure that the pulse lasts for at least
        -- min_pulse_cnt, as otherwise we could have just latched on to a
        -- random thermal noise spike. By ensuring that the first signal we
        -- latch on to is at least ~60ms, we minimise the chance that we're
        -- just using noise as our second pulse:
        if sec = sec_part_init and cnt < min_pulse_cnt then

          cnt    <= 0             after gate_delay;
          sec    <= sec_uninit    after gate_delay;

        -- Check for the start of minute 500ms second pulse:
        elsif sec = sec_part_init and cnt > som_pulse_cnt then

          sec    <= 1             after gate_delay;

        end if;

      -- This is our 'false start' check. If we reach this point, it's either
      -- because we initially latched onto a spike and aren't synchronised with
      -- a second properly, or because the signal has dropped. In either case,
      -- it's a bad sign, so just reset all counters to their starting values
      -- and start again:
      elsif cnt = max_cnt then

        cnt      <= 0             after gate_delay;
        sec      <= sec_uninit    after gate_delay;

      end if;

      di_var     <= di            after gate_delay; -- Save di for next time

    end if;

  end process;

end rtl;

------ END OF MSF_SYNC ------

--
-- Test bench
--
library IEEE;

use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_1164.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity msf_sync_tb is
    generic (clk_freq: positive := 100); -- 100 Hz
end msf_sync_tb;

architecture tests of msf_sync_tb is
  signal rst: std_logic := '0';
  signal clk: std_logic := '0';
  signal di:  byte      := byte_unknown;

  signal so:  std_logic := 'X';
  signal mo:  std_logic := 'X';
begin
  dut: entity work.msf_sync(rtl)
    port map (rst, clk, di, so, mo);
  process is
    constant clk_period: time := 1000 ms / clk_freq;

    file     data:       text;
    variable data_line:  line;

    variable clk_var:    std_logic;
    variable di_var:     byte;
  begin

    file_open(data, "../cw/cw2/msf_sync_tb-stimulus.txt", read_mode);

    while not endfile(data) loop
      readline(data, data_line);
      read(data_line, clk_var);
      read(data_line, di_var);

      clk <= clk_var;
      di  <= di_var;

      wait for clk_period / 2;
    end loop;

    file_close(data);
    wait;
  end process;
end tests;
