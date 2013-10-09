library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity bcd_counter is

    generic
    (
        gate_delay:   time                               :=             0 ns;
        leading_zero: boolean                            :=             true;
        digits:       positive                           :=             1
    );

    port
    (
        rst: in  std_logic                               :=            'X';
        clk: in  std_logic                               :=            'X';
        en:  in  std_logic                               :=            'X';
        
        cnt: out bcd_digit_vector((digits - 1) downto 0) := (others => bcd_zero);
        c:   out std_logic                               :=            '0'
    );

end bcd_counter;

architecture rtl of bcd_counter is
    signal cnt_en:     std_logic_vector((digits - 1) downto 0) := (others => '0');
    signal cnt_curr:   bcd_digit_vector((digits - 1) downto 0) := (others => bcd_zero); 
    signal cnt_next:   bcd_digit_vector((digits - 1) downto 0) := (others => bcd_zero); 
    signal cnt_reset:  std_logic_vector((digits - 1) downto 0) := (others => '1');
    signal cnt_at_max: std_logic_vector((digits - 1) downto 0) := (others => '0');
    signal cnt_c:      std_logic_vector((digits - 1) downto 0) := (others => '0');
begin

    counter: for i in 0 to (digits - 1) generate
    begin
    
        process (rst, clk)
        begin
        
            if (rst = '1') then
                cnt_curr(i)  <= bcd_zero        after gate_delay;
                cnt_reset(i) <= '1'             after gate_delay;
            elsif clk'event and (clk = '1') then
            
                if (cnt_en(i) = '1') then
                    cnt_curr(i)  <= cnt_next(i) after gate_delay;
                    cnt_reset(i) <= '0'         after gate_delay;
                end if;

            end if;

        end process;
        
        process (cnt_curr(i), cnt_reset(i))
        begin

            if (cnt_curr(i) < 9) then
                cnt_next(i)   <= cnt_curr(i) + 1 after gate_delay;
                cnt_at_max(i) <= '0'             after gate_delay;
            else
                cnt_next(i)   <= bcd_zero        after gate_delay;
                cnt_at_max(i) <= '1'             after gate_delay;
            end if;
            
            if (leading_zero = false) and (cnt_reset(i) = '1') and (cnt_curr(i) = 0) then
                cnt(i)        <= bcd_space       after gate_delay;
            else
                cnt(i)        <= cnt_curr(i)     after gate_delay;
            end if;

        end process;
        
        cnt_c(i) <= cnt_en(i) and cnt_at_max(i)  after gate_delay;
    end generate;
    
    enable_1: if (digits = 1) generate
        cnt_en(0) <= en;
    end generate;

    enable_n: if (digits > 1) generate
        cnt_en <= cnt_c((digits - 2) downto 0) & en;
    end generate;

    c <= cnt_c(digits - 1);
end rtl;
