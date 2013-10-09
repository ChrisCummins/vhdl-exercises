library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity fifo is

    generic
    (
        gate_delay: time     := 0 ns;
        ts_digits:  positive;
        signals:    positive;
        size:       positive := 1
    );

    port
    (
        rst: in  std_logic                                  :=            'X';          -- reset
        clk: in  std_logic                                  :=            'X';          -- clock

        wi:  in  std_logic                                  :=            'X';          -- write in
        tsi: in  bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown); -- timestamp in
        di:  in  std_logic_vector((signals - 1) downto 0)   := (others => 'X');         -- signals in
        fi:  out std_logic                                  :=            '0';          -- buffer full

        wo:  out std_logic                                  :=            '0';          -- write out
        tso: out bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_zero);    -- timestamp out
        do:  out std_logic_vector((signals - 1) downto 0)   := (others => '0');         -- signals out
        bo:  in  std_logic                                  :=            'X'           -- busy out
    );

end fifo;

architecture rtl of fifo is

    subtype  tword is bcd_digit_vector((ts_digits - 1) downto 0);
    type     tword_vector is array (natural range <>) of tword;
    
    subtype  sword is std_logic_vector((signals - 1) downto 0);
    type     sword_vector is array (natural range <>) of sword;
    
    constant tword_null: tword                               := (others => bcd_zero);
    constant sword_null: sword                               := (others => '0');
    constant tbuf_null:  tword_vector(0 to size - 1)         := (others => tword_null);
    constant sbuf_null:  sword_vector(0 to size - 1)         := (others => sword_null);

    constant buf_bits:   positive                            := n_bits(size);
    constant buf_low:    unsigned((buf_bits - 1) downto 0)   := to_unsigned(0,  buf_bits);
    constant buf_high:   unsigned((buf_bits - 1) downto 0)   := to_unsigned(size - 1,  buf_bits);

    signal   tbuf:       tword_vector(0 to size - 1)         := tbuf_null;
    signal   next_tbuf:  tword_vector(0 to size - 1)         := tbuf_null;
    signal   sbuf:       sword_vector(0 to size - 1)         := sbuf_null;
    signal   next_sbuf:  sword_vector(0 to size - 1)         := sbuf_null;
    signal   cnt:        unsigned(n_bits(size + 1) - 1 downto 0) := (others => '0');
    signal   next_cnt:   unsigned(n_bits(size + 1) - 1 downto 0) := (others => '0');
    signal   rpos:       unsigned(buf_bits - 1 downto 0)     := buf_low;
    signal   next_rpos:  unsigned(buf_bits - 1 downto 0)     := buf_low;
    signal   wpos:       unsigned(buf_bits - 1 downto 0)     := buf_low;
    signal   next_wpos:  unsigned(buf_bits - 1 downto 0)     := buf_low;

begin

    process (rst, clk)
    begin
    
        if (rst = '1') then

            tbuf  <= tbuf_null       after gate_delay;
            sbuf  <= sbuf_null       after gate_delay;
            cnt   <= (others => '0') after gate_delay;
            rpos  <= buf_low         after gate_delay;
            wpos  <= buf_low         after gate_delay;

        elsif clk'event and (clk = '1') then

            tbuf  <= next_tbuf       after gate_delay;
            sbuf  <= next_sbuf       after gate_delay;
            cnt   <= next_cnt        after gate_delay;
            rpos  <= next_rpos       after gate_delay;
            wpos  <= next_wpos       after gate_delay;

        end if;

    end process;
    
    process (wi, tsi, di, bo, tbuf, sbuf, cnt, rpos, wpos)
        variable w: boolean;
        variable r: boolean;
    begin
        fi         <= '0'                                       after gate_delay;
        wo         <= '0'                                       after gate_delay;
        tso        <= (others => bcd_zero)                      after gate_delay;
        do         <= (others => '0')                           after gate_delay;
        next_tbuf  <= tbuf                                      after gate_delay;
        next_sbuf  <= sbuf                                      after gate_delay;
        next_cnt   <= cnt                                       after gate_delay;
        next_rpos  <= rpos                                      after gate_delay;
        next_wpos  <= wpos                                      after gate_delay;
        
        if (cnt = size) then
            fi <= '1'                                           after gate_delay;
        end if;

        if (wi = '1') and (cnt < size) then
            w := true;
            next_tbuf(to_integer(wpos)) <= tsi                  after gate_delay;
            next_sbuf(to_integer(wpos)) <= di                   after gate_delay;
            
            if (wpos < buf_high) then
                next_wpos <= wpos + 1                           after gate_delay;
            else
                next_wpos <= buf_low                            after gate_delay;
            end if;
            
        else
            w := false;
        end if;

        if (bo = '0') and (cnt > 0) then
            r := true;
            tso <= tbuf(to_integer(rpos))                       after gate_delay;
            do  <= sbuf(to_integer(rpos))                       after gate_delay;
            wo  <= '1'                                          after gate_delay;
            
            if (rpos < buf_high) then
                next_rpos <= rpos + 1                           after gate_delay;
            else
                next_rpos <= buf_low                            after gate_delay;
            end if;

        else
            r := false;
        end if;
    
        if (w = true) and (r = false) then
            next_cnt <= cnt + 1                                 after gate_delay;
        elsif (w = false) and (r = true) then
            next_cnt <= cnt - 1                                 after gate_delay;
        end if;

    end process;
    
end rtl;
