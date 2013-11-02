library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity msf_bits is

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
        bao: out std_logic := '0';          -- Bit A out
        bbo: out std_logic := '0';          -- Bit B out
        tr:  out std_logic := '0'           -- New bit trigger
    );

end msf_bits;

architecture rtl of msf_bits is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

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

entity msf_bits_tb is
    generic (clk_freq: positive := 100); -- 100 Hz
end msf_bits_tb;

architecture tests of msf_bits_tb is
  signal rst: std_logic := '0';
  signal clk: std_logic := '0';
  signal di:  byte      := byte_unknown;

  signal so:  std_logic := 'X';
  signal mo:  std_logic := 'X';
  signal bao: std_logic := 'X';
  signal bbo: std_logic := 'X';
  signal tr:  std_logic := 'X';
begin
  sync: entity WORK.msf_sync(rtl)
    port map (rst, clk, di, so, mo);
  bits: entity WORK.msf_bits(rtl)
    port map (rst, clk, di, so, bao, bbo, tr);
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