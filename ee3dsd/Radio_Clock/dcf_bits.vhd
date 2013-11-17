library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf_bits is

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
        bo:  out std_logic := '0';          -- Bit out
        tr:  out std_logic := '0'           -- New bit trigger
    );

end dcf_bits;

architecture rtl of dcf_bits is

  type     states  is (st_init, st_wait, st_sample);
  subtype  counter is natural range 0 to clk_freq * 3;

  constant sample_time: natural   := 150; -- ms
  constant cnt_sample:  counter   := clk_freq * sample_time / 1000;

  signal   state:       states    := st_init;
  signal   next_state:  states    := st_init;

  signal   next_bo:     std_logic := '0';
  signal   next_tr:     std_logic := '0';

  signal   di_sampled:  byte      := byte_null;
  signal   si_sampled:  std_logic := '0';

  signal   cnt:         counter   := 0;
  signal   next_cnt:    counter   := 0;

begin

  process(clk, rst)
  begin

    if (rst = '1') then

      state          <= st_init       after gate_delay;
      cnt            <= 0             after gate_delay;
      bo             <= '0'           after gate_delay;
      tr             <= '0'           after gate_delay;
      di_sampled     <= byte_null     after gate_delay;
      si_sampled     <= '0'           after gate_delay;

    elsif clk'event and (clk = '1') then

      state          <= next_state    after gate_delay;
      cnt            <= next_cnt      after gate_delay;
      bo             <= next_bo       after gate_delay;
      tr             <= next_tr       after gate_delay;
      di_sampled     <= di            after gate_delay;
      si_sampled     <= si            after gate_delay;

    end if;

  end process;

  process(di_sampled, si_sampled, cnt, state)
  begin

    next_state       <= state         after gate_delay;
    next_cnt         <= 0             after gate_delay;
    next_tr          <= '0'           after gate_delay;

    case state is

      when st_init =>

        if (si_sampled = '1') then
          next_state <= st_wait       after gate_delay;
        end if;

      when st_wait =>

        if (cnt < cnt_sample) then
          next_cnt   <= cnt + 1       after gate_delay;
        else
          next_state <= st_sample     after gate_delay;
        end if;

      when st_sample =>

        next_bo      <= di_sampled(7) after gate_delay;
        next_tr      <= '1'           after gate_delay;
        next_state   <= st_init       after gate_delay;

    end case;

  end process;

end rtl;
