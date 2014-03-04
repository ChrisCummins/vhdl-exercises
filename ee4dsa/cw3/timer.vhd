library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity timer is

    generic
    (
        clk_freq:     positive;         -- clock frequency in Hz
        tmr_period:   natural  := 0;    -- timer period in us
        gate_delay:   time     := 0 ns  -- gate delay
    );

    port
    (
        rst: in  std_logic := 'X';      -- reset
        clk: in  std_logic := 'X';      -- clock
        
        tmr: out std_logic := '0'       -- timer out
    );

end timer;

architecture rtl of timer is

    constant cycles:   natural := (clk_freq / 1000000) * tmr_period;

    subtype  counter is unsigned(max(1, n_bits(cycles) - 1) downto 0);

    signal   cnt:      counter := (others => '0');
    signal   next_cnt: counter := (others => '0');

begin

    process (rst, clk)
    begin
    
        if (rst = '1') then

            cnt <= (others => '0')      after gate_delay;

        elsif clk'event and (clk = '1') then
        
            cnt <= next_cnt             after gate_delay;

        end if;

    end process;
    
    process (cnt)
    begin
    
        if (cnt = (cycles - 1)) then

            next_cnt <= (others => '0') after gate_delay;
            tmr      <= '1'             after gate_delay;

        else

            next_cnt <= cnt + 1         after gate_delay;
            tmr      <= '0'             after gate_delay;

        end if;

    end process;

end rtl;
