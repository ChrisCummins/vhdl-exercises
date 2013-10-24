library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity fifo is

    generic
    (
        gate_delay: time     := 0 ns;
        data_width: positive := 1;
        fifo_depth: positive := 8
    );

    port
    (
        rst: in  std_logic                            :=            'X';           -- reset
        clk: in  std_logic                            :=            'X';           -- clock

        wr:  in  std_logic                            :=            'X';           -- write data
        di:  in  byte_vector(data_width - 1 downto 0) := (others => byte_unknown); -- data in
        ff:  out std_logic                            :=            '0';           -- fifo full

        rd:  in  std_logic                            :=            'X';           -- read data
        do:  out byte_vector(data_width - 1 downto 0) := (others => byte_null);    -- data out
        fe:  out std_logic                            :=            '1'            -- fifo empty
    );

end fifo;

architecture rtl of fifo is

    type ram_type is array (0 to fifo_depth - 1) of std_logic_vector((8 * data_width) - 1 downto 0);

    constant buf_bits:   positive                                        := n_bits(fifo_depth);
    constant buf_low:    unsigned((buf_bits - 1) downto 0)               := to_unsigned(0,  buf_bits);
    constant buf_high:   unsigned((buf_bits - 1) downto 0)               := to_unsigned(fifo_depth - 1,  buf_bits);

    signal   data:       ram_type                                        := (others => (others => '0'));
    signal   di_int:     std_logic_vector((8 * data_width) - 1 downto 0) := (others => '0');
    signal   do_int:     std_logic_vector((8 * data_width) - 1 downto 0) := (others => '0');
    signal   rpos:       unsigned(buf_bits - 1 downto 0)                 := buf_low;
    signal   next_rpos:  unsigned(buf_bits - 1 downto 0)                 := buf_low;
    signal   wpos:       unsigned(buf_bits - 1 downto 0)                 := buf_low;
    signal   next_wpos:  unsigned(buf_bits - 1 downto 0)                 := buf_low;
    signal   ff_int:     std_logic                                       := '0';
    signal   fe_int:     std_logic                                       := '1';

begin

    process (rst, clk)
    begin
    
        if clk'event and (clk = '1') then

            if (rst = '1') then

                rpos   <= buf_low                     after gate_delay;
                wpos   <= buf_low                     after gate_delay;
                
            else

                if (wr = '1') and (ff_int = '0') then
                
                    wpos <= next_wpos                 after gate_delay;
                    data(to_integer(wpos)) <= di_int  after gate_delay;
                    
                end if;

                if (rd = '1') and (fe_int = '0') then
                
                    rpos <= next_rpos                 after gate_delay;
                    do_int <= data(to_integer(rpos))  after gate_delay;
                    
                end if;
                
            end if;

        end if;

    end process;
    
    process (di)
    begin
    
        for i in di'range loop
        
            di_int((8 * i) + 7 downto 8 * i) <= di(i) after gate_delay;
        
        end loop;

    end process;

    process (do_int)
    begin

        for i in do'range loop
        
            do(i) <= do_int((8 * i) + 7 downto 8 * i) after gate_delay;
        
        end loop;

    end process;

    process (wpos)
    begin

        if (wpos = buf_high) then

            next_wpos <= buf_low                      after gate_delay;

        else

            next_wpos <= wpos + 1                     after gate_delay;
        
        end if;

    end process;
    
    process (rpos)
    begin

        if (rpos = buf_high) then

            next_rpos <= buf_low                      after gate_delay;

        else

            next_rpos <= rpos + 1                     after gate_delay;
        
        end if;

    end process;
    
    process (next_wpos, rpos)
    begin

        if (next_wpos = rpos) then
        
            ff_int <= '1'                             after gate_delay;
            
        else
        
            ff_int <= '0'                             after gate_delay;
            
        end if;
        
    end process;
    
    process (wpos, rpos, rd)
    begin

        if (wpos = rpos) then
        
            fe_int <= '1'                             after gate_delay;
            
        else
        
            fe_int <= '0'                             after gate_delay;
            
        end if;
            
    end process;
        
    ff <= ff_int                                      after gate_delay;
    fe <= fe_int                                      after gate_delay;
    
end rtl;
