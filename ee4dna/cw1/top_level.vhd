library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity top_level is

    generic
    (
        clk_freq:   positive := 100000000; -- Hz
        debounce:   natural  := 10000; -- us
        baud_rate:  positive := 57600; -- Baud
        gate_delay: time     := 1 ns;
        ts_digits:  positive := 5 + 8;
        fifo_size:  positive := 16;
        word_size:  positive := 32;
        rom_size:   positive := 64;
        rom_file:   string   := "rom.dat";
        ports_in:   positive := 2;
        ports_out:  positive := 1
    );

    port
    (
        clk:           in  std_logic                                 :=            'X';  -- clock

--synopsys synthesis_off
        test_pc:       out unsigned((n_bits(rom_size) - 1) downto 0) := (others => 'X'); -- program counter
        test_opcode:   out std_logic_vector(7 downto 0)              := (others => 'X'); -- instruction opcode
        test_ins_data: out std_logic_vector(word_size - 9 downto 0)  := (others => 'X'); -- instruction data
--synopsys synthesis_on

        btnu:          in  std_logic                                 :=            'X';  -- button up
        btnd:          in  std_logic                                 :=            'X';  -- button down
        btnc:          in  std_logic                                 :=            'X';  -- button centre
        btnl:          in  std_logic                                 :=            'X';  -- button left
        btnr:          in  std_logic                                 :=            'X';  -- button right
        sw:            in  std_logic_vector(7 downto 0)              := (others => 'X'); -- switches
        an:            out std_logic_vector(3 downto 0)              := (others => '0'); -- anodes   7 segment display
        ka:            out std_logic_vector(7 downto 0)              := (others => '0'); -- kathodes 7 segment display
        ld:            out std_logic_vector(7 downto 0)              := (others => '0'); -- leds
        rx:            in  std_logic                                 :=            'X';  -- uart rx 
        tx:            out std_logic                                 :=            '0';  -- uart tx
        msf:           in  std_logic                                 :=            'X';  -- msf signal
        dcf:           in  std_logic                                 :=            'X'   -- dcf signal
   );

end top_level;

architecture behav of top_level is

    constant rom_addr_bits: positive := n_bits(rom_size - 1);

    signal   rst:         std_logic                                      :=            '0';

    signal   tr_data_in:  std_logic_vector((8 * ports_in - 1) downto 0)  := (others => 'X');
    signal   tr_data_out: std_logic_vector((8 * ports_in - 1) downto 0)  := (others => 'X');

    signal   eu_io_in:    byte_vector((ports_in - 1) downto 0)           := (others => byte_null);
    signal   eu_io_out:   byte_vector((ports_out - 1) downto 0)          := (others => byte_unknown);
    signal   eu_rom_en:   std_logic                                      :=            'X';
    signal   eu_rom_addr: std_logic_vector((rom_addr_bits - 1) downto 0) := (others => 'X');
    signal   eu_rom_data: std_logic_vector((word_size - 1)     downto 0) := (others => 'X');

begin

    trigger_uut: entity WORK.trigger
    generic map
    (
        gate_delay    => gate_delay,
        clk_freq      => clk_freq,
        debounce      => debounce,
        signals       => 8 * ports_in
    )
    port map
    (
        rst           => rst,
        clk           => clk,
        di            => tr_data_in,
        do            => tr_data_out
    );

    rom_unit: entity WORK.rom
    generic map
    (
        gate_delay    => gate_delay,
        word_size     => word_size,
        rom_size      => rom_size,
        file_name     => rom_file
    )
    port map
    (
        clk           => clk,
        en            => eu_rom_en,
        addr          => eu_rom_addr,
        do            => eu_rom_data
    );
    
    execution_unit: entity WORK.execution_unit
    generic map
    (
        gate_delay    => gate_delay,
        word_size     => word_size,
        rom_size      => rom_size,
        ports_in      => ports_in,
        ports_out     => ports_out
    )
    port map
    (
        clk           => clk,
        rst           => rst,
        en            => '1',
--synopsys synthesis_off
        test_pc       => test_pc,
        test_opcode   => test_opcode,
        test_ins_data => test_ins_data,
--synopsys synthesis_on
        rom_en        => eu_rom_en,
        rom_addr      => eu_rom_addr,
        rom_data      => eu_rom_data,
        io_in         => eu_io_in,
        io_out        => eu_io_out
    );

    rst                     <= sw(0);
    tr_data_in(15 downto 8) <= sw;
    tr_data_in( 7 downto 0) <= (btnu, btnd, btnc, btnl, btnr, rx, msf and sw(6), dcf and sw(7));
    eu_io_in(0)             <= tr_data_out(15 downto 8);
    eu_io_in(1)             <= tr_data_out( 7 downto 0);
    an                      <= (others => '1');
    ka                      <= (others => '0');
    ld                      <= eu_io_out(0);
    tx                      <= '0';

end behav;
