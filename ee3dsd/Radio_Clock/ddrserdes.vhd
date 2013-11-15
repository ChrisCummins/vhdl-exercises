library IEEE;
-- library UNISIM;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ddrserdes is

    generic
    (
        gate_delay:   time                                       := 1 ns;
        ibuf_len:     positive                                   := 2
    );

    port
    (
        clk_par:  in  std_logic                                  := 'X';      -- parallel clock in
        clk_2par: in  std_logic                                  := 'X';      -- 2 x parallel clock in
        data_in:  in  std_logic                                  := 'X';      -- serial data in
        data_out: out byte                                       := byte_null -- parallel data out
   );

end ddrserdes;

architecture behav of ddrserdes is

  signal ibuf: std_logic_vector(ibuf_len - 1 downto 0) := (others => '0');

begin

  process (clk_par) is
  begin

    if clk_par'event and (clk_par = '1') then

      for i in 0 to 3 loop -- First nibble
        data_out(i) <= ibuf(0)  after gate_delay;
      end loop;

      for i in 4 to 7 loop -- Second nibble
        data_out(i) <= ibuf(1)  after gate_delay;
      end loop;

    end if;

  end process;

  process (clk_2par) is
  begin

    if clk_2par'event and (clk_2par = '1') then

      for i in 0 to ibuf_len - 2 loop
        ibuf(i + 1) <= ibuf(i)   after gate_delay;
      end loop;

      ibuf(0)       <= data_in   after gate_delay;

    end if;

  end process;

end behav;

------ END OF DDRSERDES ------

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

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ddrserdes_tb is
    generic (clk_freq: positive := 100); -- 100 Hz
end ddrserdes_tb;

architecture tests of ddrserdes_tb is

  signal clk:      std_logic := 'X';       -- parallel clock in
  signal clk2:     std_logic := 'X';       -- 2 x parallel clock in
  signal data_in:  std_logic := 'X';       -- serial data in
  signal data_out: byte      := byte_null; -- parallel data out

begin
  dut: entity work.ddrserdes(behav)
    port map (clk, clk2, data_in, data_out);
  process is
    constant clk_period:  time := 1000 ms / clk_freq;

    file     data:        text;
    variable data_line:   line;

    variable clk_var:     std_logic;
    variable clk2_var:    std_logic;
    variable data_in_var: std_logic;
  begin

    file_open(data, "../cw/cw2/ddrserdes_tb-stimulus.txt", read_mode);

    while not endfile(data) loop
      readline(data, data_line);
      read(data_line, clk_var);
      read(data_line, clk2_var);
      read(data_line, data_in_var);

      clk     <= clk_var;
      clk2    <= clk2_var;
      data_in <= data_in_var;

      wait for clk_period / 2;
    end loop;

    file_close(data);
    wait;
  end process;
end tests;
