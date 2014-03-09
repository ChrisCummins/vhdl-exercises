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

  -- Perform ALU operations on numbers A and B, outputting value Q:
  process (si, a_c, a_di, b_c, b_di, c_in)

    variable a: number_with_carry;
    variable b: number_with_carry;
    variable c: number_with_carry;
    variable q: number_with_carry;

    alias a_msb:   std_logic is a(word_size);
    alias b_msb:   std_logic is b(word_size);
    alias q_msb:   std_logic is q(word_size);
    alias q_word:  number    is q(word_size - 1 downto 0);

    -- Convenience constants for converting the carry in bit into a number
    -- which can be summed along with the normal A and B inputs.
    constant zero: number_with_carry := (          others => '0');
    constant one:  number_with_carry := (0 => '1', others => '0');

  begin

    -- First we read the input ports into our internal numerical representation,
    -- padding the number with a leading carry bit:
    a := unsigned('0' & a_di);
    b := unsigned('0' & b_di);

    -- We then create a third number "C" which contains the carry value, if
    -- required:
    if c_in = '1' then c := one; else c := zero; end if;

    -- Then we apply the complement flags, inverting the bits if needed:
    if a_c = '1' then a := not a; end if;
    if b_c = '1' then b := not b; end if;

    if si = '1' then
      -- Signed arithmetic operation:
      q := unsigned(signed(a) + signed(b) + signed(c));
      c_out <= a_msb xor b_msb                                 after gate_delay;
    else
      -- Unsigned arithmetic:
      q := a + b + c;
      c_out <= q_msb                                           after gate_delay;
    end if;

    -- Finally, write the result (sans carry bit):
    s_do <= std_logic_vector(q_word)                           after gate_delay;

  end process;

end rtl;
