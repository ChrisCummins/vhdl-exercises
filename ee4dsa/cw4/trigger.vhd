library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity trigger is

    generic
    (
        clk_freq:     positive;                                                -- clock frequency in Hz
        debounce:     natural                             :=             0;    -- debounce time in us
        signals:      positive                            :=             1;    -- number of signals
        gate_delay:   time                                :=             0 ns  -- gate delay
    );

    port
    (
        rst: in  std_logic                                :=            'X';   -- reset
        clk: in  std_logic                                :=            'X';   -- clock
        
        di:  in  std_logic_vector((signals - 1) downto 0) := (others => 'X');  -- signal in
        do:  out std_logic_vector((signals - 1) downto 0) := (others => '0');  -- signal out
        eo:  out std_logic_vector((signals - 1) downto 0) := (others => '0');  -- event out
        ro:  out std_logic_vector((signals - 1) downto 0) := (others => '0');  -- rising edge out
        fo:  out std_logic_vector((signals - 1) downto 0) := (others => '0');  -- falling edge out
        wo:  out std_logic                                :=            '0'    -- write out
    );

end trigger;

architecture rtl of trigger is

    constant cycles:       natural                                  := (clk_freq / 1000000) * debounce;

    type     states is (st_low, st_rising_edge, st_high, st_falling_edge);
    type     states_vector is array (natural range <>) of states;
    
    subtype  counter is unsigned(max(1, n_bits(cycles) - 1) downto 0);
    type     counter_vector is array (natural range <>) of counter;
    
    constant counter_two:  counter                                  := (1 => '1', others => '0');
    constant no_event:     std_logic_vector((signals - 1) downto 0) := (others => '0');
    
    signal   cnt:          counter_vector((signals - 1) downto 0)   := (others => counter_two);
    signal   next_cnt:     counter_vector((signals - 1) downto 0)   := (others => counter_two);
    signal   state:        states_vector((signals - 1) downto 0)    := (others => st_low);
    signal   next_state:   states_vector((signals - 1) downto 0)    := (others => st_low);
    signal   di_sampled:   std_logic_vector((signals - 1) downto 0) := (others => '0');
    signal   eo_int:       std_logic_vector((signals - 1) downto 0) := (others => '0');

begin

    triggers: for i in 0 to (signals - 1) generate
    begin
    
        process (rst, clk)
        begin
        
            if (rst = '1') then

                cnt(i)        <= counter_two   after gate_delay;
                state(i)      <= st_low        after gate_delay;
                di_sampled(i) <= '0'           after gate_delay;

            elsif clk'event and (clk = '1') then
            
                cnt(i)        <= next_cnt(i)   after gate_delay;
                state(i)      <= next_state(i) after gate_delay;
                di_sampled(i) <= di(i)         after gate_delay;

            end if;

        end process;

        process (di_sampled(i), cnt(i), state(i))
        begin
            do(i)         <= '0'                         after gate_delay;
            eo_int(i)     <= '0'                         after gate_delay;
            ro(i)         <= '0'                         after gate_delay;
            fo(i)         <= '0'                         after gate_delay;
            next_cnt(i)   <= cnt(i)                      after gate_delay;
            next_state(i) <= state(i)                    after gate_delay;
            
            case state(i) is
            
                when st_low =>
                
                    if (cnt(i) < cycles) then
                        next_cnt(i)   <= cnt(i) + 1      after gate_delay;
                    elsif (di_sampled(i) = '1') then
                        next_state(i) <= st_rising_edge  after gate_delay;
                    end if;
                
                when st_rising_edge =>
                
                    do(i)         <= '1'                 after gate_delay;
                    eo_int(i)     <= '1'                 after gate_delay;
                    ro(i)         <= '1'                 after gate_delay;
                    next_cnt(i)   <= counter_two         after gate_delay;
                    next_state(i) <= st_high             after gate_delay;
                
                when st_high =>
                
                    do(i)         <= '1'                 after gate_delay;

                    if (cnt(i) < cycles) then
                        next_cnt(i)   <= cnt(i) + 1      after gate_delay;
                    elsif (di_sampled(i) = '0') then
                        next_state(i) <= st_falling_edge after gate_delay;
                    end if;
                
                when st_falling_edge =>

                    eo_int(i)     <= '1'                 after gate_delay;
                    fo(i)         <= '1'                 after gate_delay;
                    next_cnt(i)   <= counter_two         after gate_delay;
                    next_state(i) <= st_low              after gate_delay;
                
            end case;

        end process;
        
    end generate;
    
    process (eo_int)
    begin
    
        if (eo_int = no_event) then
            wo <= '0' after gate_delay;
        else
            wo <= '1' after gate_delay;
        end if;

    end process;
    
    eo <= eo_int after gate_delay;
    
end rtl;
