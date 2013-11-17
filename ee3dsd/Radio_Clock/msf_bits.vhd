library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity msf_bits is

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
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

  type     states  is (st_init, st_wait1, st_sample1, st_wait2, st_sample2);
  subtype  counter is natural range 0 to clk_freq * 3;

  constant sample1_time: natural   := 150; -- ms
  constant sample2_time: natural   := 250; -- ms
  constant cnt_sample1:  counter   := clk_freq * sample1_time / 1000;
  constant cnt_sample2:  counter   := clk_freq * sample2_time / 1000;

  signal   state:        states    := st_init;
  signal   next_state:   states    := st_init;

  signal   bao_var:      std_logic := '0';
  signal   next_bao_var: std_logic := '0';
  signal   next_bao:     std_logic := '0';
  signal   next_bbo:     std_logic := '0';
  signal   next_tr:      std_logic := '0';

  signal   di_sampled:   byte      := byte_null;
  signal   si_sampled:   std_logic := '0';

  signal   cnt:          counter   := 0;
  signal   next_cnt:     counter   := 0;

begin

  process(clk, rst)
  begin

    if (rst = '1') then

      state          <= st_init       after gate_delay;
      cnt            <= 0             after gate_delay;
      bao            <= '0'           after gate_delay;
      bbo            <= '0'           after gate_delay;
      bao_var        <= '0'           after gate_delay;
      tr             <= '0'           after gate_delay;
      di_sampled     <= byte_null     after gate_delay;
      si_sampled     <= '0'           after gate_delay;

    elsif clk'event and (clk = '1') then

      state          <= next_state    after gate_delay;
      cnt            <= next_cnt      after gate_delay;
      bao            <= next_bao      after gate_delay;
      bbo            <= next_bbo      after gate_delay;
      bao_var        <= next_bao_var  after gate_delay;
      tr             <= next_tr       after gate_delay;
      di_sampled     <= di            after gate_delay;
      si_sampled     <= si            after gate_delay;

    end if;

  end process;

  process(di_sampled, si_sampled, cnt, state, bao_var)
  begin

    next_state       <= state         after gate_delay;
    next_cnt         <= cnt + 1       after gate_delay;
    next_bao_var     <= bao_var       after gate_delay;
    next_tr          <= '0'           after gate_delay;

    case state is

      when st_init =>

        next_cnt     <= 0             after gate_delay;

        if (si_sampled = '1') then
          next_state <= st_wait1      after gate_delay;
        end if;

      when st_wait1 =>

        if (cnt = cnt_sample1) then
          next_state <= st_sample1    after gate_delay;
        end if;

      when st_sample1 =>

        next_bao_var <= di_sampled(7) after gate_delay;
        next_state   <= st_wait2      after gate_delay;

      when st_wait2 =>

        if (cnt = cnt_sample2) then
          next_state <= st_sample2    after gate_delay;
        end if;

      when st_sample2 =>

        next_bao     <= bao_var       after gate_delay;

        next_bbo     <= di_sampled(7) after gate_delay;

        next_tr      <= '1'           after gate_delay;
        next_state   <= st_init       after gate_delay;

    end case;

  end process;

end rtl;

------ END OF MSF_BITS ------

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
    generic map (clk_freq => clk_freq)
    port map (rst, clk, di, so, mo);
  bits: entity WORK.msf_bits(rtl)
    generic map (clk_freq => clk_freq)
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
