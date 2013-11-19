library IEEE;

use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity msf_bits_testbench is

  generic
  (
      clk_freq: positive := 1000 -- Hz
  );

end msf_bits_testbench;

architecture tests of msf_bits_testbench is

  constant test_duration: time      := 60000 ms;
  constant clk_period:    time      := 1000 ms / clk_freq;
  signal end_flag:        std_logic := '0';

  signal rst:             std_logic := '0';
  signal clk:             std_logic := '0';
  signal di:              byte      := byte_unknown;
  signal si:              std_logic := 'X';
  signal bao:             std_logic := 'X';
  signal bbo:             std_logic := 'X';
  signal tr:              std_logic := 'X';

  signal r_bao:           std_logic := '0';
  signal r_bbo:           std_logic := '0';

begin

  bits: entity WORK.msf_bits(rtl)
    generic map
    (
        clk_freq => clk_freq
    )
    port map
    (
        rst      => rst,
        clk      => clk,
        di       => di,
        si       => si,
        bao      => bao,
        bbo      => bbo,
        tr       => tr
    );

  process -- Process to end test after duration
  begin

    wait for test_duration;
    end_flag <= '1';

    wait;
  end process;

  process is -- Process to set 'clk'
    variable clk_var:    std_logic := '0';
  begin

    while (end_flag = '0') loop
      clk <= '0';
      wait for clk_period / 2;
      clk <= '1';
      wait for clk_period / 2;
    end loop;

    wait;
  end process;

  process is -- Process to set 'di' and 'si'

    file     data:       text;
    variable data_line:  line;
    variable t_var:      time;

  begin

    file_open(data, "msf.txt", read_mode);

    while not endfile(data) loop

      di <= byte_zero;

      readline(data, data_line);
      read(data_line, t_var);
      wait for t_var - now;

      di <= byte_255;

      readline(data, data_line);
      read(data_line, t_var);

      si <= '1'; -- Spoof the output of the dcf_sync component
      wait for 1 ms;
      si <= '0';

      wait for t_var - now;

    end loop;

    file_close(data);
    wait;
  end process;

  process is -- Set 'r_bao' and 'r_bbo' signals

    file     data:       text;
    variable data_line:  line;
    variable t_var:      time;
    variable bao_var:    std_logic := '0';
    variable bbo_var:    std_logic := '0';

  begin

    file_open(data, "msf.txt", read_mode);

    while not endfile(data) loop

      r_bao <= bao_var;
      r_bbo <= bbo_var;

      readline(data, data_line);
      read(data_line, t_var);
      if (t_var > now) then
        wait for t_var - now; -- Wait until next second
      end if;

      readline(data, data_line);
      read(data_line, t_var);
      read(data_line, bao_var);
      read(data_line, bbo_var);

    end loop;

    file_close(data);
    wait;

  end process;

  process is -- Assert that our decoded bits match hand decoded bits

    file     data:       text;
    variable data_line:  line;
    variable t_var:      time;
    variable bao_var:    std_logic := '0';
    variable bbo_var:    std_logic := '0';

  begin

    file_open(data, "msf.txt", read_mode);

    while not endfile(data) loop

      readline(data, data_line);
      readline(data, data_line);
      read(data_line, t_var);
      read(data_line, bao_var);
      read(data_line, bbo_var);

      wait until (tr = '1');

      while (now < t_var) loop
        assert (r_bao = bao) report "r_bao: " & std_logic'image(r_bao) & ", 'bao': " & std_logic'image(bao) severity error;
        assert (r_bbo = bbo) report "r_bbo: " & std_logic'image(r_bbo) & ", 'bbo': " & std_logic'image(bbo) severity error;
        wait for clk_period;
      end loop;

    end loop;

    file_close(data);
    wait;

  end process;

end tests;
