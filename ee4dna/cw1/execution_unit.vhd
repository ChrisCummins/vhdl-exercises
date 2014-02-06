library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity execution_unit is

    generic
    (
        gate_delay: time;     -- delay per gate for simulation only
        word_size:  positive; -- width of data bus in bits
        rom_size:   positive; -- size of ROM in words
        ports_in:   positive; -- number of 8 bit wide input ports
        ports_out:  positive  -- number of 8 bit wide output ports
    );

    port
    (
        clk:           in  std_logic                                             :=            'X';  -- clock
        rst:           in  std_logic                                             :=            'X';  -- rst
        en:            in  std_logic                                             :=            'X';  -- enable

--synopsys synthesis_off
        test_pc:       out unsigned((n_bits(rom_size) - 1) downto 0)             := (others => 'X'); -- program counter
        test_opcode:   out std_logic_vector(7 downto 0)                          := (others => 'X'); -- instruction opcode
        test_ins_data: out std_logic_vector(word_size - 9 downto 0)              := (others => 'X'); -- instruction data
--synopsys synthesis_on

        rom_en:        out std_logic                                             :=            'X';  -- ROM enable
        rom_addr:      out std_logic_vector((n_bits(rom_size - 1) - 1) downto 0) := (others => 'X'); -- ROM address to read
        rom_data:      in  std_logic_vector((word_size - 1) downto 0)            := (others => 'Z'); -- ROM data

        io_in:         in  byte_vector((ports_in - 1) downto 0)                  := (others => byte_unknown); -- 8 bit wide input ports
        io_out:        out byte_vector((ports_out - 1) downto 0)                 := (others => byte_null)     -- 8 bit wide output ports

    );

end execution_unit;

architecture syn of execution_unit is

  signal pc: unsigned((n_bits(rom_size) - 1) downto 0) := (others => '0');
  signal next_pc: unsigned((n_bits(rom_size) - 1) downto 0) := (others => '0');
  signal opcode: std_logic_vector(7 downto 0) := (others => '0');
  signal ins_data: std_logic_vector(word_size - 9 downto 0) := (others => '0');

begin

  process (clk, rst, next_pc) is
  begin
    if rst = '1' then

      pc <= (others => '0');
      next_pc <= (others => '0');
      test_pc <= (others => '0');
      rom_en <= '0';

    elsif clk = '1' then

      pc <= next_pc;
      test_pc <= pc;

      rom_addr <= std_logic_vector(pc);
      rom_en <= '1';

      next_pc <= pc + 1; -- FIXME: o rly?

    end if;
  end process;

  process (rom_data) is
  begin

    opcode <= rom_data(word_size - 1 downto word_size - 8);
    ins_data <= rom_data(word_size - 9 downto 0);

    -- Test outputs
    test_opcode <= opcode;
    test_ins_data <= ins_data;

  end process;

  process (pc, opcode, ins_data) is
  begin

    -- FIXME: o rly?
    --case opcode is
    --  when "00000000" => next_pc <= pc + 1;
    --  when "00000001" => next_pc <= pc;
    --  when others => next_pc <= pc + 1;
    --end case;

  end process;

end syn;
