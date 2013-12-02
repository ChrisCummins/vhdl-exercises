library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity msf_decode is

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
        bai:    in  std_logic                    := 'X'; -- bit A in
        bbi:    in  std_logic                    := 'X'; -- bit B in
        year:   out bcd_digit_vector(3 downto 0) := (3 => bcd_two, 2 => bcd_zero, others => bcd_minus);
        month:  out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        day:    out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        hour:   out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        minute: out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        second: out bcd_digit_vector(1 downto 0) := (others => bcd_zero);
        tr:     out std_logic                    := '0'  -- new bit trigger
    );

end msf_decode;

architecture rtl of msf_decode is

  type    states             is (st_wait, st_sample, st_write);
  subtype bit_register       is std_logic_vector(59 downto 0);
  subtype bit_register_index is natural range bit_register'length downto 0;

  signal  state:        states             := st_wait;
  signal  next_state:   states             := st_wait;

  signal  areg:         bit_register       := (others => '0');
  signal  breg:         bit_register       := (others => '0');
  signal  curr_sec:     bit_register_index := 0;
  signal  index:        bit_register_index := 0;

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

    variable dsec_0: natural;
    variable dsec_1: natural;

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

      state             <= next_state         after gate_delay;
      tr                <= '0'                after gate_delay;

      case state is

        when st_wait =>

          if (si = '1') then

            next_state  <= st_sample          after gate_delay;
            index       <= curr_sec           after gate_delay;

            if (mi = '1') then
              curr_sec  <= 0                  after gate_delay;
            else
              curr_sec  <= curr_sec + 1       after gate_delay;
            end if;

          end if;

        when st_sample =>

          tr               <= '1'             after gate_delay;

          -- Set second out
          dsec_0 := curr_sec rem 10;
          dsec_1 := curr_sec / 10;
          second(0) <= bin2bcd(dsec_0);
          second(1) <= bin2bcd(dsec_1);

          areg(index)      <= bai             after gate_delay;
          breg(index)      <= bbi             after gate_delay;

          if (index = 58) then
            next_state     <= st_write        after gate_delay;
          else
            next_state     <= st_wait         after gate_delay;
          end if;

        when st_write =>

          -- Year (bits: 17A - 24A, parity-bit: 54B)
          if ((areg(17) xor areg(18) xor areg(19) xor areg(20) xor
               areg(21) xor areg(22) xor areg(23) xor areg(24) xor
               breg(54))) = '1' then

            year <= (3 => bcd_two, 2 => bcd_zero,
                     1 => (areg(17), areg(18), areg(19), areg(20)),
                     0 => (areg(21), areg(22), areg(23), areg(24)))
                                              after gate_delay;

          else

            year <= (bcd_two, bcd_one, others => bcd_error)
                                              after gate_delay;

          end if;

          -- Month and day (bits: 25A - 35A, parity-bit: 55B)
          if ((areg(25) xor areg(26) xor areg(27) xor areg(28) xor
               areg(29) xor areg(30) xor areg(31) xor areg(32) xor
               areg(33) xor areg(34) xor areg(35) xor breg(55))) = '1' then

            month <= (('0', '0', '0', areg(25)),
                      (areg(26), areg(27), areg(28), areg(29)))
                                              after gate_delay;
            day   <= (('0', '0', areg(30), areg(31)),
                      (areg(32), areg(33), areg(34), areg(35)))
                                              after gate_delay;

          else

            month <= (others => bcd_error)    after gate_delay;
            day   <= (others => bcd_error)    after gate_delay;

          end if;

          -- Hours and minutes (bits: 39A - 51A, parity-bit: 57B)
          if ((areg(39) xor areg(40) xor areg(41) xor areg(42) xor
               areg(43) xor areg(44) xor areg(45) xor areg(46) xor
               areg(47) xor areg(48) xor areg(49) xor areg(50) xor
               areg(51) xor areg(52) xor areg(53) xor areg(54) xor
               areg(55) xor areg(56) xor breg(57))) = '1' then

            hour   <= (('0', '0', areg(39), areg(40)),
                       (areg(41), areg(42), areg(43), areg(44)))
                                              after gate_delay;
            minute <= (('0', '0', areg(39), areg(40)),
                       (areg(41), areg(42), areg(43), areg(44)))
                                              after gate_delay;

          else

            hour   <= (others => bcd_error)   after gate_delay;
            minute <= (others => bcd_error)   after gate_delay;

          end if;

          next_state <= st_wait               after gate_delay;

      end case;

    end if;

  end process;

end rtl;
