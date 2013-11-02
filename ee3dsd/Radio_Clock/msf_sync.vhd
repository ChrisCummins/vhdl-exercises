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
  -- We use intermediate signals rather than writing directly to the ports:
  signal so_var:           std_logic := '0';
  signal mo_var:           std_logic := '0';

  -- This keeps track of whether we're currently on a high or low pulse:
  signal pulse:            std_logic := 'X';

  -- This contains the data input from the last clock cycle:
  signal di_var:           byte      := byte_null;

  -- This is the minimum acceptable pulse length. The MSF signal uses 100 -
  -- 500ms pulses, so let's set this to a value slightly below the shortest
  -- (~60ms) so as to allow for some margin of error:
  constant MIN_PULSE_TIME: natural   := clk_freq / 15;

  -- The clock cycles counter (s_count). We use this to record the number of
  -- cycles since the last pulse. SOM_PULSE_TIME is the shortest acceptable
  -- start-of-minute pulse (~400ms). MIN_S_TIME and MAX_S_TIME defines the
  -- window of acceptable time between each second pulse (~900ms - ~1100ms).
  -- RESET_S_TIME is a hard limit on the amount of time to wait for a second
  -- pulse before figuring that something has gone wrong and resetting (~3000
  -- ms).
  constant SOM_PULSE_TIME: natural   := clk_freq / 2 - clk_freq / 10;
  constant MIN_S_TIME:     natural   := clk_freq - clk_freq / 10;
  constant MAX_S_TIME:     natural   := clk_freq + clk_freq / 13;
  constant RESET_S_TIME:   natural   := clk_freq * 3;
  signal s_count:          natural range 0 to RESET_S_TIME + 1;

  -- The seconds counter (m_count). This keeps track of what second we are on
  -- within a minute. When we first start, we are in an uninitialised state
  -- (M_UNINIT). After receiving our first clock pulse, we move into a
  -- partially-initialised state (M_PART_INIT), which means that we still don't
  -- know exactly where in the minute we are yet (we haven't received a 500ms
  -- pulse). After that, the counter will be incremented each second in
  -- order to predict when to output the missing second pulse and start of
  -- minute pulse.
  constant M_UNINIT:       natural   := 62;
  constant M_PART_INIT:    natural   := 61;
  signal m_count:          natural range 0 to M_UNINIT := M_UNINIT;
begin
  process(clk, rst)
  begin
    -- Reset signal, so zero everything and reset internal state:
    if rst = '1' then
      s_count <= 0;
      m_count <= M_UNINIT;
      so <= '0' after gate_delay;
      mo <= '0' after gate_delay;
    -- Clock pulse:
    elsif clk'event and clk = '1' then
      so_var  <= '0';                       -- Zero the outputs
      mo_var  <= '0';
      s_count <= s_count + 1;               -- Bump the clock counter

      -- Check for rising edge, either because we're expecting a second, or
      -- because we're in an uninitalised state and we're trying to latch on to
      -- the first received signal:
      if (di > di_var and s_count > MIN_S_TIME and s_count < MAX_S_TIME)
        or (di > di_var and m_count = M_UNINIT) then
        pulse <= '1';                       -- Register pulse
        s_count <= 0;                       -- Reset clock counter
        so_var  <= '1';                     -- Output second pulse

        if m_count < 60 then
          m_count <= m_count + 1;           -- Count another second
        elsif m_count = 60 then
          m_count <= 1;                     -- Reset the minute counter
          mo_var  <= '1';                   -- Output start of minute pulse
        elsif m_count = M_UNINIT then
          -- We've now in a partially-initialised state, i.e. we've found our
          -- first second to latch onto but we haven't received a full minute
          -- yet so don't know when to expect the missing second.
          m_count <= M_PART_INIT;
        end if;

      -- Check for falling edge
      elsif di < di_var then
        pulse <= '0';                       -- Register end of pulse
        -- One further precaution: if we've only just latched on to the first
        -- signal pulse, then make sure that the pulse lasts for at least
        -- MIN_PULSE_TIME, as otherwise we could have just latched on to a
        -- random thermal noise spike. By ensuring that the first signal we
        -- latch on to is at least ~60ms, we minimise the chance that we're
        -- just using noise as our second pulse:
        if m_count = M_PART_INIT and s_count < MIN_PULSE_TIME then
          s_count <= 0;
          m_count <= M_UNINIT;
        -- Check for the start of minute 500ms second pulse:
        elsif m_count = M_PART_INIT and s_count > SOM_PULSE_TIME then
          m_count <= 1;
        end if;

      -- This is our 'false start' check. If we reach this point, it's either
      -- because we initially latched onto a spike and aren't synchronised with
      -- a second properly, or because the signal has dropped. In either case,
      -- it's a bad sign, so just reset all counters to their starting values
      -- and start again:
      elsif s_count = RESET_S_TIME then
        s_count <= 0;
        m_count <= M_UNINIT;
      end if;

      di_var <= di;                         -- Save di for next time
      so     <= so_var after gate_delay;    -- Set our outputs
      mo     <= mo_var after gate_delay;
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
