library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;

package util is

    subtype  byte             is                             std_logic_vector(7 downto 0);
    type     byte_vector      is array (natural range <>) of byte;
    
    constant byte_unknown: byte      := "XXXXXXXX";
    constant byte_null:    byte      := "00000000";
    constant byte_space:   byte      := std_logic_vector(to_unsigned(character'pos(' '), 8));
    constant byte_zero:    byte      := std_logic_vector(to_unsigned(character'pos('0'), 8));
    constant byte_one:     byte      := std_logic_vector(to_unsigned(character'pos('1'), 8));

    subtype  bcd_digit        is                             unsigned(3 downto 0);
    type     bcd_digit_vector is array (natural range <>) of bcd_digit;
    
    constant bcd_unknown:  bcd_digit := "XXXX";
    constant bcd_zero:     bcd_digit := X"0";
    constant bcd_one:      bcd_digit := X"1";
    constant bcd_two:      bcd_digit := X"2";
    constant bcd_three:    bcd_digit := X"3";
    constant bcd_four:     bcd_digit := X"4";
    constant bcd_five:     bcd_digit := X"5";
    constant bcd_six:      bcd_digit := X"6";
    constant bcd_seven:    bcd_digit := X"7";
    constant bcd_eight:    bcd_digit := X"8";
    constant bcd_nine:     bcd_digit := X"9";
    constant bcd_plus:     bcd_digit := X"A";
    constant bcd_minus:    bcd_digit := X"B";
    constant bcd_dot:      bcd_digit := X"C";
    constant bcd_colon:    bcd_digit := X"D";
    constant bcd_error:    bcd_digit := X"E";
    constant bcd_space:    bcd_digit := X"F";
    
    constant to_byte: byte_vector(0 to 15) := 
    (
        std_logic_vector(to_unsigned(character'pos('0'), 8)),
        std_logic_vector(to_unsigned(character'pos('1'), 8)),
        std_logic_vector(to_unsigned(character'pos('2'), 8)),
        std_logic_vector(to_unsigned(character'pos('3'), 8)),
        std_logic_vector(to_unsigned(character'pos('4'), 8)),
        std_logic_vector(to_unsigned(character'pos('5'), 8)),
        std_logic_vector(to_unsigned(character'pos('6'), 8)),
        std_logic_vector(to_unsigned(character'pos('7'), 8)),
        std_logic_vector(to_unsigned(character'pos('8'), 8)),
        std_logic_vector(to_unsigned(character'pos('9'), 8)),
        std_logic_vector(to_unsigned(character'pos('+'), 8)),
        std_logic_vector(to_unsigned(character'pos('-'), 8)),
        std_logic_vector(to_unsigned(character'pos('.'), 8)),
        std_logic_vector(to_unsigned(character'pos(':'), 8)),
        std_logic_vector(to_unsigned(character'pos('E'), 8)),
        std_logic_vector(to_unsigned(character'pos(' '), 8))
    );

    function n_bits(x: natural) return natural;
    
    function max(a: natural; b: natural) return natural;
    function min(a: natural; b: natural) return natural;

    function str_len(s: string) return natural;

    function gen_byte_vector(l: natural; c: character) return byte_vector;
    function to_byte_vector(s: string) return byte_vector;

    function space_to_zero(bvi: bcd_digit_vector) return bcd_digit_vector;

--synopsys synthesis_off

    function to_string(slv: std_logic_vector) return string;

--synopsys synthesis_on

end util;

package body util is

    function n_bits(x: natural) return natural is
        variable temp: natural := max(x, 1) - 1;
        variable n:    natural := 1;
    begin
    
        while temp > 1 loop
            temp := temp / 2;
            n    := n + 1;
        end loop;
        
        return n;

    end function n_bits;

    function max(a: natural; b: natural) return natural is
    begin
    
        if (a > b) then
            return a;
        else
            return b;
        end if;

    end function max;

    function min(a: natural; b: natural) return natural is
    begin
    
        if (a < b) then
            return a;
        else
            return b;
        end if;

    end function min;

    function str_len(s: string) return natural is
    begin
        return s'high - s'low + 1;
    end function str_len;

    function gen_byte_vector(l: natural; c: character) return byte_vector is
        variable b: byte_vector(0 to max(l, 1) - 1);
    begin
    
        for i in b'range loop
            b(i) := std_logic_vector(to_unsigned(character'pos(c), 8));
        end loop;

        return b;

    end function gen_byte_vector;
    
    function to_byte_vector(s: string) return byte_vector is
        variable b: byte_vector(s'low to s'high);
    begin
    
        for i in b'range loop
            b(i) := std_logic_vector(to_unsigned(character'pos(s(i)), 8));
        end loop;

        return b;

    end function to_byte_vector;

    function space_to_zero(bvi: bcd_digit_vector) return bcd_digit_vector is
        variable bvo: bcd_digit_vector(bvi'low to bvi'high);
    begin
    
        for i in bvi'range loop
        
            if (bvi(i) = bcd_space) then
                bvo(i) := bcd_zero;
            else
                bvo(i) := bvi(i);
            end if;

        end loop;

        return bvo;

    end function space_to_zero;


--synopsys synthesis_off

    function to_string(slv: std_logic_vector) return string is
        variable l: line;
    begin
    
        for i in slv'range loop
            write(l, slv(i));
        end loop;
        
        return l.all;

    end function to_string;

--synopsys synthesis_on

end util;
