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

  type    states is (st_wait, st_wr0, st_wr1, st_wr2, st_wr3);
  subtype index is natural range 3 downto 0;

  signal state:      states                  := st_wait;
  signal next_state: states                  := st_wait;
  signal wr_sampled: std_logic               := '0';
  signal di_sampled: byte_vector(3 downto 0) := (others => byte_zero);

  signal an_index:      index := 0;
  signal next_an_index: index := 0;

begin

  process(clk)
  begin

    if clk'event and (clk = '1') then

      wr_sampled     <= wr              after gate_delay;
      di_sampled     <= di              after gate_delay;
      state          <= next_state      after gate_delay;

    end if;

  end process;

  process (wr_sampled, di_sampled, state)
  begin

    an               <= (others => '1') after gate_delay;
    ka               <= byte_255        after gate_delay;

    case state is

      when st_wait =>

        ka           <= byte_255        after gate_delay;

        if (wr_sampled = '1') then
          next_state <= st_wr0          after gate_delay;
        else
          next_state <= state           after gate_delay;
        end if;

      when st_wr0 =>

        an(0)        <= '0'             after gate_delay ;
        ka           <= di_sampled(0)   after gate_delay;
        next_state   <= st_wr1          after gate_delay;

      when st_wr1 =>

        an(1)        <= '0'             after gate_delay;
        ka           <= di_sampled(1)   after gate_delay;
        next_state   <= st_wr2          after gate_delay;

      when st_wr2 =>

        an(2)        <= '0'             after gate_delay;
        ka           <= di_sampled(2)   after gate_delay;
        next_state   <= st_wr3          after gate_delay;

      when st_wr3 =>

        an(3)        <= '0'             after gate_delay;
        ka           <= di_sampled(3)   after gate_delay;
        next_state   <= st_wait         after gate_delay;

    end case;

  end process;

end behav;
