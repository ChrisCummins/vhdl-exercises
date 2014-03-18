library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is

    generic
    (
        gate_delay: time;
        word_size:  positive
    );

    port
    (
        si:    in  std_logic                                  :=            'X';  -- signed integers
        a_c:   in  std_logic                                  :=            'X';  -- A complement
        a_di:  in  std_logic_vector((word_size - 1) downto 0) := (others => 'X'); -- A data in
        b_c:   in  std_logic                                  :=            'X';  -- B complement
        b_di:  in  std_logic_vector((word_size - 1) downto 0) := (others => 'X'); -- B data in
        c_in:  in  std_logic                                  :=            'X';  -- carry in
        s_do:  out std_logic_vector((word_size - 1) downto 0) := (others => '0'); -- sum data out
        c_out: out std_logic                                  :=            '0'   -- carry out
    );

end alu;

architecture rtl of alu is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end rtl;
