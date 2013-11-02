library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf_sync is

    generic
    (
        clk_freq   : positive := 100; -- Hz
        gate_delay : time     := 1 ns
    );

    port
    (
        rst : in  std_logic   := 'X';          -- Reset
        clk : in  std_logic   := 'X';          -- Clock

        di  : in  byte        := byte_unknown; -- Data in
        so  : out std_logic   := '0';          -- Start of second
        mo  : out std_logic   := '0'           -- Start of minute
    );

end dcf_sync;

architecture rtl of dcf_sync is
  signal so_var         : std_logic := '0';                      -- so port var
  signal mo_var         : std_logic := '0';                      -- mo port var
  signal pulse          : std_logic := 'X';                      -- Whether the input is currently high or low
  signal di_var         : byte      := byte_null;                -- Last di sampled

  constant MIN_S_TIME   : natural   := clk_freq - clk_freq / 5;  -- Min time between second pulses
  constant MAX_S_TIME   : natural   := clk_freq + clk_freq / 10; -- Max time between second pulses
  constant RESET_S_TIME : natural   := clk_freq * 3;             -- Max time to wait before resetting
  signal s_count        : natural range 0 to RESET_S_TIME + 1;

  constant M_UNINIT     : natural   := 62;                       -- Value for uninitialised state
  constant M_PART_INIT  : natural   := 61;                       -- Value for partially initialised state
  signal m_count        : natural range 0 to M_UNINIT := M_UNINIT;
begin
  process(clk, rst)
  begin
    if rst = '1' then
      so <= '0' after gate_delay;           -- Reset the outputs
      mo <= '0' after gate_delay;
    elsif clk'event and clk = '1' then
      so_var  <= '0';                       -- Zero the outputs
      mo_var  <= '0';
      s_count <= s_count + 1;               -- Bump the clock counter

      -- Look for rising edges, either because we're expecting a second, or
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
          m_count <= 0;                     -- Reset the minute counter
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

      -- Look for the missing 59th second pulse, either because we're expecting
      -- it (we know it's the 59th second), or because we haven't received a
      -- full minute yet and so we'll assume that any missing pulse is the 59th
      -- second:
      elsif (m_count = 59 and s_count = clk_freq)
        or (m_count = M_PART_INIT and s_count > MAX_S_TIME) then
        s_count <= 0;                       -- Reset clock counter
        so_var  <= '1';                     -- Add in missing second pulse
        m_count <= 60;

      -- This is our 'false start' check. If we reach this point, it's either
      -- because we initially latched onto a spike and aren't synchronised with
      -- a second properly, or because the signal has dropped. In either case,
      -- it's a bad sign, so just reset all counters to their starting values and
      -- start again:
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

------ END OF DCF_SYNC ------

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

entity dcf_sync_tb is
  generic (tick_time:  time := 8 ns);
end dcf_sync_tb;

architecture tests of dcf_sync_tb is
  signal rst : std_logic := '0';
  signal clk : std_logic := '0';
  signal di  : byte      := byte_unknown;

  signal so  : std_logic := 'X';
  signal mo  : std_logic := 'X';
begin
  dut: entity work.dcf_sync(rtl)
    port map (rst, clk, di, so, mo);
  process is
    constant clk_period : time := 10 ms; -- 100 Hz

    file     data       : text;
    variable data_line  : line;

    variable clk_var    : std_logic;
    variable di_var     : byte;
  begin

    file_open(data, "../cw/cw2/tb-stimulus.txt", read_mode);

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
