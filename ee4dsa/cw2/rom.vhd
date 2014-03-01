library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity rom is

    generic
    (
        gate_delay: time;     -- delay per gate for simulation only
        word_size:  positive; -- width of data bus in bits
        rom_size:   positive; -- size of ROM in words
        file_name:  string    -- name of file containing ROM content
    );

    port
    (
        clk:  in  std_logic                                         :=            'X';  -- clock
        en:   in  std_logic                                         :=            'X';  -- enable
        addr: in  std_logic_vector((n_bits(rom_size) - 1) downto 0) := (others => 'X'); -- address
        do:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0')  -- data out
    );

end rom;

architecture syn of rom is

    type rom_type is array ((rom_size - 1) downto 0) of std_logic_vector((word_size - 1) downto 0);

    function init_rom_from_file(file_name: in string) return rom_type is
        file     rom_file: text is in file_name;
        variable line:     line;
        variable rom_data: rom_type;
    begin

        for i in 0 to (rom_size - 1) loop
            readline(rom_file, line);
            hread(line, rom_data(i));
        end loop;

        return rom_data;
    end function;

    constant data: rom_type := init_rom_from_file(file_name);

begin

    process (clk)
    begin
    
        if clk'event and (clk = '1') then
        
            if (en = '1') then
                do <= data(to_integer(unsigned(addr))) after gate_delay;
            end if;
            
        end if;
        
    end process;

end syn;
