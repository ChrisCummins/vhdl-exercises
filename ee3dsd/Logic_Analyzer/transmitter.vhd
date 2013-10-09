library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity transmitter is

    generic
    (
        gate_delay: time     := 0 ns;
        ts_digits:  positive := 14;
        signals:    positive := 1
    );

    port
    (
        rst: in  std_logic                                  :=            'X';          -- reset
        clk: in  std_logic                                  :=            'X';          -- clock

        wi:  in  std_logic                                  :=            'X';          -- write in
        ti:  in  bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown); -- timestamp in
        di:  in  std_logic_vector((signals - 1) downto 0)   := (others => 'X');         -- data in
        bi:  out std_logic                                  :=            '0';          -- busy in

        wo:  out std_logic                                  :=            '0';          -- write out
        do:  out byte                                       :=            byte_null;    -- data out
        bo:  in  std_logic                                  :=            'X'           -- busy out
    );

end transmitter;

architecture rtl of transmitter is

    type     states is (st_idle, st_wait, st_transmit);
    
    constant suffix_str: string                             := " ms" & CR & LF;
    constant buf_len:    natural                            := 2 * signals + ts_digits + str_len(suffix_str);
    constant buf_bits:   positive                           := n_bits(buf_len);
    constant buf_low:    unsigned((buf_bits - 1) downto 0)  := to_unsigned(0,  buf_bits);
    constant buf_high:   unsigned((buf_bits - 1) downto 0)  := to_unsigned(buf_len - 1,  buf_bits);
    constant sig_offset: natural                            := 0;
    constant ts_offset:  natural                            := 2 * signals;
    constant buf_init:   byte_vector(0 to buf_len - 1)      := gen_byte_vector(2 * signals + ts_digits, ' ') & to_byte_vector(suffix_str);

    signal   state:      states                             := st_idle;
    signal   next_state: states                             := st_idle;
    signal   buf:        byte_vector(0 to buf_len - 1)      := buf_init;
    signal   next_buf:   byte_vector(0 to buf_len - 1)      := buf_init;
    signal   pos:        unsigned((buf_bits - 1) downto 0)  := buf_low;
    signal   next_pos:   unsigned((buf_bits - 1) downto 0)  := buf_low;

begin

    process (rst, clk)
    begin
    
        if (rst = '1') then

            state <= st_idle    after gate_delay;
            buf   <= buf_init   after gate_delay;
            pos   <= buf_low    after gate_delay;

        elsif clk'event and (clk = '1') then

            state <= next_state after gate_delay;
            buf   <= next_buf   after gate_delay;
            pos   <= next_pos   after gate_delay;

        end if;

    end process;
    
    process (wi, ti, di, bo, state, buf, pos)
    begin
        bi         <= '1'                                                                     after gate_delay;
        wo         <= '0'                                                                     after gate_delay;
        do         <= (others => '0')                                                         after gate_delay;
        next_state <= state                                                                   after gate_delay;
        next_buf   <= buf                                                                     after gate_delay;
        next_pos   <= pos                                                                     after gate_delay;
    
        case state is
        
            when st_idle =>
            
                bi       <= '0'                                                               after gate_delay;
                next_pos <= buf_low                                                           after gate_delay;
            
                if (wi = '1') then

                    next_state <= st_wait                                                     after gate_delay;
                    
                    for i in di'range loop
                    
                        if (di(i) = '1') then
                            next_buf(sig_offset + 2 * i) <= byte_one                          after gate_delay;
                        else
                            next_buf(sig_offset + 2 * i) <= byte_zero                         after gate_delay;
                        end if;

                    end loop;
                    
                    for i in ti'range loop
                        next_buf(ts_offset + ts_digits - 1 - i) <= to_byte(to_integer(ti(i))) after gate_delay;
                    end loop;

                end if;
                
            when st_wait =>
            
                if (bo = '0') then

                    next_state <= st_transmit                                                 after gate_delay;

                end if;
                
            when st_transmit =>
            
                wo <= '1'                                                                     after gate_delay;
                do <= buf(to_integer(pos))                                                    after gate_delay;
            
                if (pos < buf_high) then

                    next_pos   <= pos + 1                                                     after gate_delay;
                    next_state <= st_wait                                                     after gate_delay;
                    
                else

                    next_state <= st_idle                                                     after gate_delay;

                end if;
                
            when others =>
            
                next_state <= st_idle                                                         after gate_delay;

        end case;

    end process;
    
end rtl;
