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

  subtype word              is std_logic_vector(word_size - 1 downto 0);
  subtype number            is unsigned(word_size - 1         downto 0);
  subtype number_with_carry is unsigned(word_size             downto 0);

begin

  process (si, a_c, a_di, b_c, b_di, c_in)

    variable a: number_with_carry;
    variable b: number_with_carry;
    variable c: number_with_carry;
    variable q: number_with_carry;

    alias q_carry: std_logic is q(word_size);
    alias q_word:  number    is q(word_size - 1 downto 0);

  begin

    -- A input
    a   := unsigned('0' & a_di);
    if a_c = '1' then
      a := not a;
    end if;

    -- B input
    b   := unsigned('0' & a_di);
    if b_c = '1' then
      b := not b;
    end if;

    -- Carry input
    if c_in = '1' then
      c := (0 => '1', others => '0');
    else
      c := (others => '0');
    end if;

    if si = '1' then
      q := unsigned(signed(a) + signed(b) + signed(c));
    else
      q := a + b + c;
    end if;

    s_do  <= std_logic_vector(q_word) after gate_delay;
    c_out <= q_carry                  after gate_delay;

  end process;

end rtl;
