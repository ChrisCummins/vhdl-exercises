library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf_sync is

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
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
  signal di_now : byte := byte_null;
begin

  process(clk, rst)
  begin
    if rst = '1' then
      so <= '0';
      mo <= '0';
    elsif clk'event and clk = '1' then
      if di > di_now then
        so <= '1';
        mo <= '0';
      else
        so <= '0';
        mo <= '1';
      end if;

      di_now <= di;
    end if;
  end process;

end rtl;


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
    file     data:      text;
    variable data_line: line;

    variable clk_var:   std_logic;
    variable di_var:    byte;

    variable clk_period: positive := 5000000;
  begin

    file_open(data, "../cw/cw2/tb-stimulus.txt", read_mode);

    while not endfile(data) loop
      readline(data, data_line);
      read(data_line, clk_var);
      read(data_line, di_var);

      clk <= clk_var;
      di <= di_var;

      wait for 5000000 ns; -- TODO: derive this from clk_freq
    end loop;

    file_close(data);
    wait;
  end process;
end tests;
