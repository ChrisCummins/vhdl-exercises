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
        ram_size:   positive; -- size of RAM in words
        intr_size:  positive; -- number of interrupt lines
        ports_in:   positive; -- number of 8 bit wide input ports
        ports_out:  positive  -- number of 8 bit wide output ports
    );

    port
    (
        clk:           in  std_logic                                         :=            'X';           -- clock
        rst:           in  std_logic                                         :=            'X';           -- rst
        en:            in  std_logic                                         :=            'X';           -- enable

--synopsys synthesis_off
        test_pc:       out unsigned(        (n_bits(rom_size) - 1) downto 0) := (others => '0');          -- program counter
        test_sp:       out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0');          -- stack pointer
        test_sr:       out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- status register
--synopsys synthesis_on

        rom_en:        out std_logic                                         :=            '0';           -- ROM enable
        rom_addr:      out std_logic_vector((n_bits(rom_size) - 1) downto 0) := (others => '0');          -- ROM address to read
        rom_data:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- ROM data

        ram_wr:        out std_logic                                         :=            '0';           -- RAM write
        ram_waddr:     out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');          -- RAM address to write
        ram_wdata:     out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- RAM data to write
        ram_rd:        out std_logic                                         :=            '0';           -- RAM read
        ram_raddr:     out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');          -- RAM address to read
        ram_rdata:     in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- RAM data to read

        intr:          in  std_logic_vector((       intr_size - 1) downto 0) := (others => 'X');          -- Interrupt lines

        io_in:         in  byte_vector(     (       ports_in  - 1) downto 0) := (others => byte_unknown); -- 8 bit wide input ports
        io_out:        out byte_vector(     (       ports_out - 1) downto 0) := (others => byte_null)     -- 8 bit wide output ports
    );

end execution_unit;

architecture syn of execution_unit is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end syn;
