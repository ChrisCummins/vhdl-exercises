library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity execution_unit is

  generic
    (
      gate_delay: time;           -- delay per gate for simulation only
      word_size:  positive;       -- width of data bus in bits
      icc_size:   positive := 2;  -- width of instruction cycle counter
      reg_high:   positive;       -- number of registers
      ram_size:   positive;       -- size of RAM in words
      intr_size:  positive;       -- number of interrupt lines
      ports_in:   positive;       -- number of 8 bit wide input ports
      ports_out:  positive        -- number of 8 bit wide output ports
    );

  port
    (
      clk:           in  std_logic                                         :=            'X';           -- clock
      rst:           in  std_logic                                         :=            'X';           -- rst
      en:            in  std_logic                                         :=            'X';           -- enable

--synopsys synthesis_off
      test_pc:       out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0');          -- program counter
      test_sp:       out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0');          -- stack pointer
      test_sr:       out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- status register
--synopsys synthesis_on

      reg_a_addr:    out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0');          -- register write address
      reg_a_wr:      out std_logic                                         :=            '0';           -- register write
      reg_a_di:      out std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register write data

      reg_b_addr:    out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0');          -- register read address
      reg_b_rd:      out std_logic                                         :=            '0';           -- register read
      reg_b_do:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register read data

      reg_c_addr:    out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0');          -- register read address
      reg_c_rd:      out std_logic                                         :=            '0';           -- register read
      reg_c_do:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register read data

      rom_addr:      out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');          -- ROM address to read
      rom_en:        out std_logic                                         :=            '0';           -- ROM enable
      rom_data:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- ROM data

      ram_addr:      out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');          -- RAM address to write
      ram_rd:        out std_logic                                         :=            '0';           -- RAM read
      ram_rdata:     in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- RAM data to read
      ram_wr:        out std_logic                                         :=            '0';           -- RAM write
      ram_wdata:     out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- RAM data to write

      intr:          in  std_logic_vector((       intr_size - 1) downto 0) := (others => 'X');          -- Interrupt lines

      io_in:         in  byte_vector(     (       ports_in  - 1) downto 0) := (others => byte_unknown); -- 8 bit wide input ports
      io_out:        out byte_vector(     (       ports_out - 1) downto 0) := (others => byte_null);    -- 8 bit wide output ports

      alu_si:        out std_logic                                         :=            '0';           -- signed integers
      alu_a_c:       out std_logic                                         :=            '0';           -- A complement
      alu_a_di:      out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- A data in
      alu_b_c:       out std_logic                                         :=            '0';           -- B complement
      alu_b_di:      out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- B data in
      alu_c_in:      out std_logic                                         :=            '0';           -- carry in
      alu_s_do:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- sum data out
      alu_c_out:     in  std_logic                                         :=            'X'            -- carry out
    );

end execution_unit;

architecture syn of execution_unit is

  -- Your declarations go here --
    
begin

  -- Your implementation goes here --

end syn;
