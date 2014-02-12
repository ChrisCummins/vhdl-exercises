library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity reset is

    generic
    (
        clk_freq:     positive;         -- clock frequency in Hz
        rst_period:   natural  := 0;    -- reset period in us
        gate_delay:   time     := 0 ns  -- gate delay
    );

    port
    (
        clk: in  std_logic := 'X';      -- clock
        
        rst: out std_logic := '0'       -- reset out
    );

end reset;

architecture rtl of reset is

    constant cycles:   natural := (clk_freq / 1000000) * rst_period;

    subtype  counter is unsigned(max(1, n_bits(cycles) - 1) downto 0);

    signal   cnt:      counter := (others => '0');
    signal   next_cnt: counter := (others => '0');

begin

    process (clk)
    begin
    
        if clk'event and (clk = '1') then
        
            cnt <= next_cnt             after gate_delay;

        end if;

    end process;
    
    process (cnt)
    begin
    
        if (cnt = (cycles - 1)) then

            next_cnt <= cnt             after gate_delay;
            rst      <= '0'             after gate_delay;

        else

            next_cnt <= cnt + 1         after gate_delay;
            rst      <= '1'             after gate_delay;

        end if;

    end process;

end rtl;
