library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity top_level is

    generic
    (
        clk_freq:   positive := 100000000; -- Hz
        debounce:   natural  := 10000;     -- us
        baud_rate:  positive := 57600;     -- baud
        timer_intr: positive := 500000;    -- us
        timer_rst:  positive := 10;        -- us
        gate_delay: time     := 1 ns;
        ts_digits:  positive := 5 + 8;
        fifo_size:  positive := 16;
        word_size:  positive := 32;
        rom_size:   positive := 64;
        rom_file:   string   := "rom.dat";
        ram_size:   positive := 128;
        ram_file:   string   := "ram.dat";
        intr_size:  positive := 8;
        ports_in:   positive := 2;
        ports_out:  positive := 1
    );

    port
    (
        clk:            in  std_logic                                         :=            'X';  -- clock

--synopsys synthesis_off
        test_pc:        out unsigned(        (n_bits(rom_size) - 1) downto 0) := (others => '0'); -- program counter
        test_sp:        out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0'); -- stack pointer
        test_sr:        out std_logic_vector((       word_size - 1) downto 0) := (others => '0'); -- status register
        test_rom_en:    out std_logic                                         :=            '0';
        test_rom_addr:  out std_logic_vector((n_bits(rom_size) - 1) downto 0) := (others => '0');
        test_rom_data:  out std_logic_vector((       word_size - 1) downto 0) := (others => '0');
        test_ram_wr:    out std_logic                                         :=            '0';
        test_ram_waddr: out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');
        test_ram_wdata: out std_logic_vector((       word_size - 1) downto 0) := (others => '0');
        test_ram_rd:    out std_logic                                         :=            '0';
        test_ram_raddr: out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');
        test_ram_rdata: out std_logic_vector((       word_size - 1) downto 0) := (others => '0');
        test_intr:      out std_logic_vector((       intr_size - 1) downto 0) := (others => '0');
--synopsys synthesis_on

        btnu:           in  std_logic                                         :=            'X';  -- button up
        btnd:           in  std_logic                                         :=            'X';  -- button down
        btnc:           in  std_logic                                         :=            'X';  -- button centre
        btnl:           in  std_logic                                         :=            'X';  -- button left
        btnr:           in  std_logic                                         :=            'X';  -- button right
        sw:             in  std_logic_vector(7 downto 0)                      := (others => 'X'); -- switches
        an:             out std_logic_vector(3 downto 0)                      := (others => '0'); -- anodes   7 segment display
        ka:             out std_logic_vector(7 downto 0)                      := (others => '0'); -- kathodes 7 segment display
        ld:             out std_logic_vector(7 downto 0)                      := (others => '0'); -- leds
        rx:             in  std_logic                                         :=            'X';  -- uart rx 
        tx:             out std_logic                                         :=            '0';  -- uart tx
        msf:            in  std_logic                                         :=            'X';  -- msf signal
        dcf:            in  std_logic                                         :=            'X'   -- dcf signal
   );

end top_level;

architecture behav of top_level is

    constant ram_addr_bits: positive := n_bits(ram_size);
    constant rom_addr_bits: positive := n_bits(rom_size);

    signal   rst:          std_logic                                      :=            '0';
    signal   rst_pow_on:   std_logic                                      :=            '1';
    signal   rst_db_in:    std_logic_vector(0 downto 0)                   := (others => 'X');
    signal   rst_db_out:   std_logic_vector(0 downto 0)                   := (others => 'X');

    signal   db_data_in:   std_logic_vector((8 * ports_in  - 1) downto 0) := (others => 'X');
    signal   db_data_out:  std_logic_vector((8 * ports_in  - 1) downto 0) := (others => 'X');

    signal   eu_rom_en:    std_logic                                      :=            'X';
    signal   eu_rom_addr:  std_logic_vector((rom_addr_bits - 1) downto 0) := (others => 'X');
    signal   eu_rom_data:  std_logic_vector((word_size     - 1) downto 0) := (others => 'X');
    signal   eu_ram_wr:    std_logic                                      :=            'X';
    signal   eu_ram_waddr: std_logic_vector((ram_addr_bits - 1) downto 0) := (others => 'X');
    signal   eu_ram_wdata: std_logic_vector((word_size     - 1) downto 0) := (others => 'X');
    signal   eu_ram_rd:    std_logic                                      :=            'X';
    signal   eu_ram_raddr: std_logic_vector((ram_addr_bits - 1) downto 0) := (others => 'X');
    signal   eu_ram_rdata: std_logic_vector((word_size     - 1) downto 0) := (others => 'X');
    signal   eu_intr:      std_logic_vector((intr_size     - 1) downto 0) := (others => '0');
    signal   eu_io_in:     byte_vector(     (ports_in      - 1) downto 0) := (others => byte_null);
    signal   eu_io_out:    byte_vector(     (ports_out     - 1) downto 0) := (others => byte_unknown);

begin

    reset_unit: entity WORK.reset
    generic map
    (
        gate_delay    => gate_delay,
        clk_freq      => clk_freq,
        rst_period    => timer_rst
    )
    port map
    (
        clk           => clk,
        rst           => rst_pow_on
    );

    rst_db_in(0) <= sw(0);

    reset_debounce_unit: entity WORK.trigger
    generic map
    (
        gate_delay    => gate_delay,
        clk_freq      => clk_freq,
        debounce      => debounce,
        signals       => 1
    )
    port map
    (
        rst           => '0',
        clk           => clk,
        di            => rst_db_in,
        do            => rst_db_out
    );

    rst <= rst_pow_on or rst_db_out(0);

    timer_unit: entity WORK.timer
    generic map
    (
        gate_delay    => gate_delay,
        clk_freq      => clk_freq,
        tmr_period    => timer_intr
    )
    port map
    (
        rst           => rst,
        clk           => clk,
        tmr           => eu_intr(0)
    );

    db_data_in(15 downto 8) <= sw;
    db_data_in( 7 downto 0) <= (btnu, btnd, btnc, btnl, btnr, rx, msf and sw(6), dcf and sw(7));

    debounce_unit: entity WORK.trigger
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
        di            => db_data_in,
        do            => db_data_out
    );

    ram_unit: entity WORK.ram
    generic map
    (
        gate_delay    => gate_delay,
        word_size     => word_size,
        ram_size      => ram_size,
        file_name     => ram_file
    )
    port map
    (
        clk           => clk,
        wr            => eu_ram_wr,
        waddr         => eu_ram_waddr,
        wdata         => eu_ram_wdata,
        rd            => eu_ram_rd,
        raddr         => eu_ram_raddr,
        rdata         => eu_ram_rdata
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
    
    eu_io_in(0) <= db_data_out(15 downto 8);
    eu_io_in(1) <= db_data_out( 7 downto 0);

    execution_unit: entity WORK.execution_unit
    generic map
    (
        gate_delay    => gate_delay,
        word_size     => word_size,
        rom_size      => rom_size,
        ram_size      => ram_size,
        intr_size     => intr_size,
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
        test_sp       => test_sp,
        test_sr       => test_sr,
--synopsys synthesis_on
        rom_en        => eu_rom_en,
        rom_addr      => eu_rom_addr,
        rom_data      => eu_rom_data,
        ram_wr        => eu_ram_wr,
        ram_waddr     => eu_ram_waddr,
        ram_wdata     => eu_ram_wdata,
        ram_rd        => eu_ram_rd,
        ram_raddr     => eu_ram_raddr,
        ram_rdata     => eu_ram_rdata,
        intr          => eu_intr,
        io_in         => eu_io_in,
        io_out        => eu_io_out
    );

    an <= (others => '1');
    ka <= (others => '0');
    ld <= eu_io_out(0);
    tx <= '0';

--synopsys synthesis_off
    test_rom_en             <= eu_rom_en;
    test_rom_addr           <= eu_rom_addr;
    test_rom_data           <= eu_rom_data;
    test_ram_wr             <= eu_ram_wr;
    test_ram_waddr          <= eu_ram_waddr;
    test_ram_wdata          <= eu_ram_wdata;
    test_ram_rd             <= eu_ram_rd;
    test_ram_raddr          <= eu_ram_raddr;
    test_ram_rdata          <= eu_ram_rdata;
    test_intr               <= eu_intr;
--synopsys synthesis_on

end behav;
