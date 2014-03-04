library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity ram is

    generic
    (
        gate_delay: time;     -- delay per gate for simulation only
        word_size:  positive; -- width of data bus in bits
        ram_size:   positive; -- size of RAM in words
        file_name:  string    -- name of file containing RAM content
    );

    port
    (
        clk:    in  std_logic                                         :=            'X';  -- clock

        a_addr: in  std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X'); -- write address
        a_rd:   in  std_logic                                         :=            'X';  -- read
        a_do:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0'); -- read data
        a_wr:   in  std_logic                                         :=            'X';  -- write
        a_di:   in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- write data

        b_addr: in  std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X'); -- write address
        b_rd:   in  std_logic                                         :=            'X';  -- read
        b_do:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0')  -- read data
    );

end ram;

architecture syn of ram is

    type ram_type is array ((ram_size - 1) downto 0) of std_logic_vector((word_size - 1) downto 0);

    function init_ram_from_file(file_name: in string) return ram_type is
        file     ram_file: text is in file_name;
        variable line:     line;
        variable ram_data: ram_type;
    begin

        for i in 0 to (ram_size - 1) loop
            readline(ram_file, line);
            hread(line, ram_data(i));
        end loop;

        return ram_data;
    end function;

    signal data: ram_type := init_ram_from_file(file_name);

begin

    process (clk)
    begin
    
        if clk'event and (clk = '1') then
        
            if (a_wr = '1') then
                data(to_integer(unsigned(a_addr))) <= a_di after gate_delay;
            end if;
            
            if (a_rd = '1') then
                a_do <= data(to_integer(unsigned(a_addr))) after gate_delay;
            else
                a_do <= (others => '0')                    after gate_delay;
            end if;
            
        end if;
        
    end process;

    process (clk)
    begin
    
        if clk'event and (clk = '1') then
        
            if (b_rd = '1') then
                b_do <= data(to_integer(unsigned(b_addr))) after gate_delay;
            else
                b_do <= (others => '0')                    after gate_delay;
            end if;
            
        end if;
        
    end process;

end syn;
