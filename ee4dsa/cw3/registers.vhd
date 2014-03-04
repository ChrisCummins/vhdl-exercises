library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity registers is

    generic
    (
        gate_delay: time;     -- delay per gate for simulation only
        word_size:  positive; -- width of data bus in bits
        reg_low:    positive; -- register bank low index
        reg_high:   positive  -- register bank high index
    );

    port
    (
        clk:    in  std_logic                                         :=            'X';  -- clock

        a_addr: in  std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- write address
        a_wr:   in  std_logic                                         :=            'X';  -- write
        a_di:   in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- write data

        b_addr: in  std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- read address
        b_rd:   in  std_logic                                         :=            'X';  -- read
        b_do:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0'); -- read data

        c_addr: in  std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- read address
        c_rd:   in  std_logic                                         :=            'X';  -- read
        c_do:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0')  -- read data
    );

end registers;

architecture syn of registers is

    subtype reg_type    is std_logic_vector(word_size - 1  downto 0);
       type reg_vector  is array (reg_low to reg_high) of reg_type;

    constant reg_null: reg_type   := (others => '0');

    signal   data:     reg_vector := (others => reg_null);

begin

    process (clk)
    begin
    
        if clk'event and (clk = '1') then
        
            if (a_wr = '1') then
                data(to_integer(unsigned(a_addr))) <= a_di after gate_delay;
            end if;
            
            if (b_rd = '1') then
                b_do <= data(to_integer(unsigned(b_addr))) after gate_delay;
            else
                b_do <= (others => '0')                    after gate_delay;
            end if;

            if (c_rd = '1') then
                c_do <= data(to_integer(unsigned(c_addr))) after gate_delay;
            else
                c_do <= (others => '0')                    after gate_delay;
            end if;

        end if;
            
    end process;

end syn;
