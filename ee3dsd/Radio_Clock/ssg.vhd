library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ssg is

    generic
    (
        clk_freq:   positive := 125000000;  -- Hz
        gate_delay: time     := 0.1 ns
    );

    port
    (
        clk: in  std_logic                    :=            'X';           -- clock
        wr:  in  std_logic                    :=            'X';           -- write
        di:  in  byte_vector(3 downto 0)      := (others => byte_unknown); -- data in
        an:  out std_logic_vector(3 downto 0) := (others => '1');          -- anodes   7 segment display
        ka:  out std_logic_vector(7 downto 0) := (others => '1')           -- kathodes 7 segment display
   );

end ssg;

architecture behav of ssg is

  constant wait_period: natural := clk_freq * 4 / 1000000;

  type    states  is (st_idle, st_write, st_wait);
  subtype index   is natural range 3 downto 0;
  subtype counter is natural range wait_period + 1 downto 0;

  signal state:         states                  := st_wait;
  signal next_state:    states                  := st_wait;
  signal wr_sampled:    std_logic               := '0';
  signal di_sampled:    byte_vector(3 downto 0) := (others => byte_zero);

  signal an_index:      index                   := 0;
  signal next_an_index: index                   := 0;

  signal cnt:           counter                 := 0;
  signal next_cnt:      counter                 := 0;

begin

  process(clk)
  begin

    if clk'event and (clk = '1') then

      wr_sampled     <= wr              after gate_delay;
      di_sampled     <= di              after gate_delay;
      state          <= next_state      after gate_delay;
      an_index       <= next_an_index   after gate_delay;
      cnt            <= next_cnt        after gate_delay;

    end if;

  end process;

  process (wr_sampled, di_sampled, state)
  begin

    case state is

      when st_idle =>

        if (wr_sampled = '1') then
          next_state    <= st_write        after gate_delay;
        else
          next_state    <= state           after gate_delay;
        end if;

      when st_write =>

        an              <= (others => '1')      after gate_delay;
        an(an_index)    <= '0'                  after gate_delay;
        ka              <= di_sampled(an_index) after gate_delay;

        if (an_index = 3) then

          next_an_index <= 0                    after gate_delay;
          next_state    <= st_idle              after gate_delay;

        else

          next_an_index <= an_index + 1         after gate_delay;
          next_state    <= st_wait              after gate_delay;

        end if;

      when st_wait =>

        if (cnt = wait_period) then

          next_cnt      <= 0                    after gate_delay;
          next_state    <= st_write             after gate_delay;

        else

          next_cnt   <= cnt + 1 after gate_delay;
          next_state <= st_wait after gate_delay;

        end if;

    end case;

  end process;

end behav;
