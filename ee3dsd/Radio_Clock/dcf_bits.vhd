library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf_bits is

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
        si:  in  std_logic := 'X';          -- Start of second in
        bo:  out std_logic := '0';          -- Bit out
        tr:  out std_logic := '0'           -- New bit trigger
    );

end dcf_bits;

architecture rtl of dcf_bits is
  -- We use an intermediate signal rather than writing directly to the port:
  signal   tr_var:      std_logic := '0';

  -- This contains the data input from the last clock cycle:
  signal   di_var:      byte      := byte_null;

  -- This keeps track of whether we're currently on a high or low pulse:
  signal   pulse:       std_logic := '0';

  -- This keeps track of whether we're currently sampling a pulse:
  signal   sampling:    bit       := '0'; -- whether we're sampling a pulse or not

  -- The number of clock cycles after a second begins that we decide on the bit
  -- value:
  constant SAMPLE_TIME: natural   := clk_freq * 150 / 1000;

  -- The number of clock cycles since the start of a second:
  signal   s_count:     natural range 0 to SAMPLE_TIME + 1;
begin

  process(clk,rst)
  begin

    if rst = '1' then                       -- Reset everything
      sampling <= '0';
      s_count <= 0;
      bo <= '0' after gate_delay;
      tr <= '0' after gate_delay;
    elsif clk'event and clk = '1' then
      tr_var <= '0';                        -- Zero the trigger

      if di > di_var then                   -- Check for rising or falling edges
        pulse <= '1';
      elsif di < di_var then
        pulse <= '0';
      end if;

      if si = '1' then                      -- Check for a second-in pulse
        sampling <= '1';
      end if;

      if sampling = '1' then                -- Bump our clock counter
        s_count <= s_count + 1;
      end if;

      -- if we're currently sampling a pulse and we've reached the sample time,
      -- then make a decision on whether the bit is a high or low and trigger a
      -- new bit out:
      if sampling = '1' and s_count = SAMPLE_TIME then
        sampling <= '0';
        s_count <= 0;

        bo <= pulse after gate_delay;

        tr_var <= '1';
      end if;

      di_var <= di;                         -- Store the current input
      tr <= tr_var after gate_delay;        -- Set our trigger output
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

entity dcf_bits_tb is
    generic (clk_freq: positive := 100); -- 100 Hz
end dcf_bits_tb;

architecture tests of dcf_bits_tb is
  signal rst: std_logic := '0';
  signal clk: std_logic := '0';
  signal di:  byte      := byte_unknown;

  signal so:  std_logic := 'X';
  signal mo:  std_logic := 'X';
  signal bo:  std_logic := 'X';
  signal tr:  std_logic := 'X';
begin
  sync: entity WORK.dcf_sync(rtl)
    port map (rst, clk, di, so, mo);
  bits: entity WORK.dcf_bits(rtl)
    port map (rst, clk, di, so, bo, tr);
  process is
    constant clk_period: time := 1000 ms / clk_freq;

    file     data:       text;
    variable data_line:  line;

    variable clk_var:    std_logic;
    variable di_var:     byte;
  begin

    file_open(data, "../cw/cw2/dcf_sync_tb-stimulus.txt", read_mode);

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
