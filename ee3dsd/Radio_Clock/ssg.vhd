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

  constant wait_period: natural := clk_freq * 4 / 1000;

  type    states  is (st_write, st_wait);
  subtype index   is natural range 3 downto 0;
  subtype counter is natural range wait_period + 1 downto 0;

  signal state:         states                       := st_wait;
  signal next_state:    states                       := st_wait;

  signal curr_an:       std_logic_vector(3 downto 0) := (others => '1');
  signal next_an:       std_logic_vector(3 downto 0) := (others => '1');

  signal curr_ka:       std_logic_vector(7 downto 0) := (others => '1');
  signal next_ka:       std_logic_vector(7 downto 0) := (others => '1');

  signal an_index:      index                        := 0;
  signal next_an_index: index                        := 0;

  signal cnt:           counter                      := 0;
  signal next_cnt:      counter                      := 0;

  signal di_sampled:    byte_vector(3 downto 0)      := (others => byte_zero);

begin

  process(clk)
  begin

    if clk'event and (clk = '1') then

      state               <= next_state               after gate_delay;
      an_index            <= next_an_index            after gate_delay;
      cnt                 <= next_cnt                 after gate_delay;
      curr_an             <= next_an                  after gate_delay;
      an                  <= curr_an                  after gate_delay;
      curr_ka             <= next_ka                  after gate_delay;
      ka                  <= curr_ka                  after gate_delay;

      if (wr = '1') then

        di_sampled        <= di                       after gate_delay;

      end if;

    end if;

  end process;

  process (di_sampled, state, cnt, an_index)
  begin

    next_cnt              <= cnt                      after gate_delay;
    next_an_index         <= an_index                 after gate_delay;
    next_an               <= curr_an                  after gate_delay;
    next_ka               <= curr_ka                  after gate_delay;

    case state is

      when st_write =>

        next_an           <= (others => '1')          after gate_delay;
        next_an(an_index) <= '0'                      after gate_delay;
        next_ka           <= di_sampled(3 - an_index) after gate_delay;
        next_state        <= st_wait                  after gate_delay;

        if (an_index = 3) then

          next_an_index   <= 0                        after gate_delay;

        else

          next_an_index   <= an_index + 1             after gate_delay;

        end if;

      when st_wait =>

        if (cnt = wait_period) then

          next_cnt        <= 0                        after gate_delay;
          next_state      <= st_write                 after gate_delay;

        else

          next_cnt        <= cnt + 1                  after gate_delay;
          next_state      <= st_wait                  after gate_delay;

        end if;

    end case;

  end process;

end behav;
