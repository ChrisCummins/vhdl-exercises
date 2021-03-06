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

  signal  state:      states             := st_wait;
  signal  next_state: states             := st_wait;

  signal  reg:        bit_register       := (others => '0');
  signal  curr_sec:   bit_register_index := 0;
  signal  index:      bit_register_index := 0;

  function bin2bcd(digit : natural)
    return bcd_digit is
  begin
    case digit is
      when 0 => return bcd_zero;
      when 1 => return bcd_one;
      when 2 => return bcd_two;
      when 3 => return bcd_three;
      when 4 => return bcd_four;
      when 5 => return bcd_five;
      when 6 => return bcd_six;
      when 7 => return bcd_seven;
      when 8 => return bcd_eight;
      when 9 => return bcd_nine;
      when others => return bcd_error;
    end case;
  end function;

begin

  process(clk, rst)

    variable sec0: natural;
    variable sec1: natural;

  begin

    if (rst = '1') then

      state    <= st_wait                     after gate_delay;
      curr_sec <= 0                           after gate_delay;
      index    <= 0                           after gate_delay;

      year     <= (3 => bcd_two, 2 => bcd_zero, others => bcd_minus) after gate_delay;
      month    <= (others => bcd_minus)       after gate_delay;
      day      <= (others => bcd_minus)       after gate_delay;
      hour     <= (others => bcd_minus)       after gate_delay;
      minute   <= (others => bcd_minus)       after gate_delay;
      second   <= (others => bcd_zero)        after gate_delay;
      tr       <= '0'                         after gate_delay;

    elsif clk'event and (clk = '1') then

      state               <= next_state       after gate_delay;
      tr                  <= '0'              after gate_delay;

      case state is

        when st_wait =>

          if (si = '1') then

            next_state    <= st_sample        after gate_delay;
            index         <= curr_sec         after gate_delay;

            if (mi = '1') then
              curr_sec    <= 0                after gate_delay;
            else
              curr_sec    <= curr_sec + 1     after gate_delay;
            end if;

          end if;

        when st_sample =>

          tr              <= '1'              after gate_delay;

          -- Split the second count into its single digit components
          sec0            := curr_sec rem 10;
          sec1            := curr_sec / 10;

          -- Set the second output
          second(0)       <= bin2bcd(sec0)    after gate_delay;
          second(1)       <= bin2bcd(sec1)    after gate_delay;

          reg(index)      <= bi               after gate_delay;

          if (index = 58) then
            next_state    <= st_write         after gate_delay;
          else
            next_state    <= st_wait          after gate_delay;
          end if;

        when st_write =>

          -- Minutes (bits: 21 - 27, parity-bit: 28)
          if (reg(21) xor reg(22) xor reg(23) xor reg(24) xor
              reg(25) xor reg(26) xor reg(27) xor reg(28)) = '0' then

            minute <= (('0', reg(27), reg(26), reg(25)),
                       (reg(24), reg(23), reg(22), reg(21)))
                                              after gate_delay;

          else

            minute <= (others => bcd_error)   after gate_delay;

          end if;

          -- Hours (bits: 29 - 34, parity-bit: 35)
          if (reg(29) xor reg(30) xor reg(31) xor reg(32) xor
              reg(33) xor reg(34) xor reg(35)) = '0' then

            hour <= (('0', '0', reg(34), reg(33)),
                     (reg(32), reg(31), reg(30), reg(29)))
                                              after gate_delay;

          else

            hour <= (others => bcd_error)     after gate_delay;

          end if;

          -- Year, month and day (bits: 36 - 57, parity-bit: 58)
          if ((reg(36) xor reg(37) xor reg(38) xor reg(39) xor
               reg(40) xor reg(41) xor reg(42) xor reg(43) xor
               reg(44) xor reg(45) xor reg(46) xor reg(47) xor
               reg(48) xor reg(49) xor reg(50) xor reg(51) xor
               reg(52) xor reg(53) xor reg(54) xor reg(55) xor
               reg(56) xor reg(57) xor reg(58)) = '0') then

            year  <= (bcd_two, bcd_zero,
                      (reg(57), reg(56), reg(55), reg(54)),
                      (reg(53), reg(52), reg(51), reg(50)))
                                              after gate_delay;

            month <= (('0', '0', '0', reg(49)),
                      (reg(48), reg(47), reg(46), reg(45)))
                                              after gate_delay;

            day   <= (('0', '0', reg(41), reg(40)),
                      (reg(39), reg(38), reg(37), reg(36)))
                                              after gate_delay;

          else

            year  <= (bcd_zero, bcd_two, others => bcd_error)
                                              after gate_delay;
            month <= (others => bcd_error)    after gate_delay;
            day   <= (others => bcd_error)    after gate_delay;

          end if;

          next_state <= st_wait               after gate_delay;

      end case;

    end if;

  end process;

end rtl;
