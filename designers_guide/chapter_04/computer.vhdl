--
-- Representing CPU instructions and data using records (p.129).
-- Chris Cummins - 27/9/13
--

entity computer is
end entity computer;

architecture system_level of computer is
  type opcodes is (add, sub, jmp, breq, brne, nop);
  type reg_number is range 0 to 31;
  constant r0 : reg_number := 0;
  constant r1 : reg_number := 1;
  constant r2 : reg_number := 2;
  constant r3 : reg_number := 3;
  constant r4 : reg_number := 4;
  constant r5 : reg_number := 5;
  constant r6 : reg_number := 6;
  constant r7 : reg_number := 7;

  type instruction is record
    opcode : opcodes;
    operand1, operand2, dest : reg_number;
    displacement : integer;
  end record instruction;

  type word is record
    instr : instruction;
    data : bit_vector(31 downto 0);
  end record word;

  constant word_size : positive := 32;
  constant byte_size : positive := 8;
  constant max_address : positive := 2**14 - 1;

  signal address : natural;
  signal read_word, write_word : word;
  signal mem_read, mem_write : bit := '0';
  signal mem_ready : bit := '0';
begin
  cpu : process is
    variable instr_reg : instruction;
    variable PC : natural; -- program counter
  begin
    address <= PC;

    -- Read instruction from memory
    mem_read <= '1';
    wait until mem_ready = '1';
    instr_reg := read_word.instr;
    mem_read <= '0';

    -- Advance program counter to next instruction
    PC := PC + (word_size / byte_size);

    -- Execute the instruction
    case instr_reg.opcode is -- TODO: instruction implementations
      when add =>
      when sub =>
      when jmp =>
      when breq =>
      when brne =>
      when nop =>
    end case;
  end process cpu;

  memory : process is
    subtype address_range is natural range 0 to max_address;
    type memory_array is array (address_range) of word;

    variable store : memory_array :=
      (0 => ((add, r0, r0, r2, 40), X"00000000"),
       1 => ((sub, r2, r0, r0, 5), X"00000000"),
       others => ((nop, r0, r0, r0, 0), X"00000000"));
  begin

  end process memory;

end architecture system_level;
