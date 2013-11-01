library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf_sync is

    generic
    (
        clk_freq:   positive := 100; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock

        di:  in  byte      := byte_unknown; -- data in
        so:  out std_logic := '0';          -- start of second
        mo:  out std_logic := '0'           -- start of minute
    );

end dcf_sync;

architecture rtl of dcf_sync is
  signal so_var : std_logic := '0';         -- so port var
  signal mo_var : std_logic := '0';         -- mo port var
  signal di_var : byte := byte_null;        -- Last di sampled

  signal pulse_counter : natural := 0;      -- Clock counter for second
  signal som : std_logic := '0';            -- Flag is raised on the 59th second of each minute
begin
  process(clk, rst)
  begin
    if rst = '1' then
      so <= '0' after gate_delay;           -- Reset our outputs
      mo <= '0' after gate_delay;
    elsif clk'event and clk = '1' then
      so_var <= '0'; mo_var <= '0';         -- Reset our outputs
      pulse_counter <= pulse_counter + 1;   -- Bump the pulse counter

      -- Check for rising edge
      if di > di_var and pulse_counter > clk_freq - clk_freq / 5 then
        so_var <= '1';                      -- Clock rising edge means start of second
        pulse_counter <= 0;                 -- Reset clock counter
        if som = '1' then                   -- Check for start of minute flag
          mo_var <= '1';                    -- Output a start of minute
          som <= '0';                       -- Reset start of minute flag
        end if;
      -- Check for missing second
      elsif pulse_counter > clk_freq + clk_freq / 10  then
        so_var <= '1';                      -- Add in missing second pulse
        som <= '1';                         -- Raise start of minute flag
        pulse_counter <= 0;                 -- Reset for new second
      -- False start reset
      elsif pulse_counter > 3 * clk_freq then  -- If it's been too long then there's probably nothing coming
        pulse_counter <= 0;                 -- Reset our pulse clock and start again
      end if;

      di_var <= di;                         -- Save di for next time
      so <= so_var after gate_delay;        -- Set the outputs
      mo <= mo_var after gate_delay;
    end if;
  end process;
end rtl;

------ END OF DCF_SYNC LOGIC ------

--
-- DCF Sync test bench
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
  signal rst:     std_logic := '0';
  signal clk:     std_logic := '0';
  signal di:      byte      := byte_unknown;

  signal so:      std_logic := 'X';
  signal mo:      std_logic := 'X';
begin
  dut: entity work.dcf_sync(rtl)
    port map (rst, clk, di, so, mo);
  process is
    constant clk_period : time := 10 ms;

    file     data:      text;
    variable data_line: line;

    variable clk_var:   std_logic;
    variable di_var:    byte;
  begin

    file_open(data, "../cw/cw2/tb-stimulus.txt", read_mode);

    while not endfile(data) loop
      readline(data, data_line);
      read(data_line, clk_var);
      read(data_line, di_var);

      clk <= clk_var;
      di <= di_var;

      wait for clk_period / 2; -- TODO: derive this from clk_freq
    end loop;

    file_close(data);
    wait;
  end process;
end tests;
