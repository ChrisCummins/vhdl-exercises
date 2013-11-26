library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity dcf_decode is

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst:    in  std_logic                    := 'X'; -- reset
        clk:    in  std_logic                    := 'X'; -- clock

        si:     in  std_logic                    := 'X'; -- start of second in
        mi:     in  std_logic                    := 'X'; -- start of minute in
        bi:     in  std_logic                    := 'X'; -- bit in
        year:   out bcd_digit_vector(3 downto 0) := (3 => bcd_two, 2 => bcd_zero, others => bcd_minus);
        month:  out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        day:    out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        hour:   out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        minute: out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        second: out bcd_digit_vector(1 downto 0) := (others => bcd_zero);
        tr:     out std_logic                    := '0'  -- new bit trigger
    );

end dcf_decode;

architecture rtl of dcf_decode is

  type    states             is (st_wait, st_sample, st_write);
  subtype bit_register       is std_logic_vector(59 downto 0);
  subtype bit_register_index is natural range bit_register'length downto 0;

  signal  si_sampled: std_logic          := '0';
  signal  mi_sampled: std_logic          := '0';
  signal  bi_sampled: std_logic          := '0';

  signal  state:      states             := st_wait;
  signal  next_state: states             := st_wait;

  signal  reg:        bit_register       := (others => '0');
  signal  index:      bit_register_index := 0;
  signal  next_index: bit_register_index := 0;

begin

  process(clk, rst)
  begin

    if (rst = '1') then

      si_sampled        <= '0'          after gate_delay;
      mi_sampled        <= '0'          after gate_delay;
      bi_sampled        <= '0'          after gate_delay;

      state             <= st_wait      after gate_delay;
      index             <= 0            after gate_delay;

    elsif clk'event and (clk = '1') then

      si_sampled        <= si           after gate_delay;
      mi_sampled        <= mi           after gate_delay;
      bi_sampled        <= bi           after gate_delay;

      state             <= next_state   after gate_delay;
      index             <= next_index   after gate_delay;

    end if;

  end process;

  process(si_sampled, mi_sampled, bi_sampled, state, index)
  begin

    tr                  <= '0'          after gate_delay;

    case state is

      when st_wait =>

        if (si_sampled = '1') then

          next_state    <= st_sample    after gate_delay;

          if (mi_sampled = '1') then
            next_index  <= 0            after gate_delay;
          else
            next_index  <= index + 1    after gate_delay;
          end if;

        end if;

      when st_sample =>

        tr              <= '1'          after gate_delay;

        -- TODO: set second out.

        reg(index)      <= bi_sampled   after gate_delay;

        if (index = 59) then
          next_state    <= st_write     after gate_delay;
        else
          next_state    <= st_wait      after gate_delay;
        end if;

      when st_write =>

        -- TODO: perform parity checks and write out data.

        next_state      <= st_wait      after gate_delay;

    end case;

  end process;

end rtl;
