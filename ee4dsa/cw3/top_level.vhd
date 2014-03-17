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
        sseg_intr:  positive := 2500;      -- us
        timer_rst:  positive := 10;        -- us
        gate_delay: time     := 1 ns;
        ts_digits:  positive := 5 + 8;
        fifo_size:  positive := 16;
        word_size:  positive := 32;
        reg_low:    positive := 4;
        reg_high:   positive := 255;
        ram_size:   positive := 4096;
        ram_file:   string   := "ram.dat";
        intr_size:  positive := 8;
        ports_in:   positive := 2;
        ports_out:  positive := 3
    );

    port
    (
        clk:            in  std_logic                                         :=            'X';  -- clock

--synopsys synthesis_off
        test_pc:         out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0'); -- program counter
        test_sp:         out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0'); -- stack pointer
        test_sr:         out std_logic_vector((       word_size - 1) downto 0) := (others => '0'); -- status register
        test_reg_a_addr: out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0'); -- register write address
        test_reg_a_wr:   out std_logic                                         :=            '0';  -- register write
        test_reg_a_di:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0'); -- register write data
        test_reg_b_addr: out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0'); -- register read address
        test_reg_b_rd:   out std_logic                                         :=            '0';  -- register read
        test_reg_b_do:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0'); -- register read data
        test_reg_c_addr: out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0'); -- register read address
        test_reg_c_rd:   out std_logic                                         :=            '0';  -- register read
        test_reg_c_do:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0'); -- register read data
        test_rom_addr:   out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');
        test_rom_en:     out std_logic                                         :=            '0';
        test_rom_data:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0');
        test_ram_addr:   out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');
        test_ram_rd:     out std_logic                                         :=            '0';
        test_ram_rdata:  out std_logic_vector((       word_size - 1) downto 0) := (others => '0');
        test_ram_wr:     out std_logic                                         :=            '0';
        test_ram_wdata:  out std_logic_vector((       word_size - 1) downto 0) := (others => '0');
        test_alu_si:     out std_logic                                         :=            'X';  -- signed integers
        test_alu_a_c:    out std_logic                                         :=            'X';  -- A complement
        test_alu_a_di:   out std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- A data in
        test_alu_b_c:    out std_logic                                         :=            'X';  -- B complement
        test_alu_b_di:   out std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- B data in
        test_alu_c_in:   out std_logic                                         :=            'X';  -- carry in
        test_alu_s_do:   out std_logic_vector((       word_size - 1) downto 0) := (others => '0'); -- sum data out
        test_alu_c_out:  out std_logic                                         :=            '0';  -- carry out
--synopsys synthesis_on

        btnu:            in  std_logic                                         :=            'X';  -- button up
        btnd:            in  std_logic                                         :=            'X';  -- button down
        btnc:            in  std_logic                                         :=            'X';  -- button centre
        btnl:            in  std_logic                                         :=            'X';  -- button left
        btnr:            in  std_logic                                         :=            'X';  -- button right
        sw:              in  std_logic_vector(7 downto 0)                      := (others => 'X'); -- switches
        an:              out std_logic_vector(3 downto 0)                      := (others => '0'); -- anodes   7 segment display
        ka:              out std_logic_vector(7 downto 0)                      := (others => '0'); -- kathodes 7 segment display
        ld:              out std_logic_vector(7 downto 0)                      := (others => '0'); -- leds
        rx:              in  std_logic                                         :=            'X';  -- uart rx 
        tx:              out std_logic                                         :=            '0';  -- uart tx
        msf:             in  std_logic                                         :=            'X';  -- msf signal
        dcf:             in  std_logic                                         :=            'X'   -- dcf signal
   );

end top_level;

architecture behav of top_level is

    constant ram_addr_bits: positive := n_bits(ram_size);
    constant rom_addr_bits: positive := n_bits(ram_size);

    signal   rst:           std_logic                                         :=            '0';
    signal   rst_pow_on:    std_logic                                         :=            '1';
    signal   rst_db_in:     std_logic_vector(0 downto 0)                      := (others => 'X');
    signal   rst_db_out:    std_logic_vector(0 downto 0)                      := (others => 'X');

    signal   db_data_in:    std_logic_vector((8 * ports_in     - 1) downto 0) := (others => 'X');
    signal   db_data_out:   std_logic_vector((8 * ports_in     - 1) downto 0) := (others => 'X');

    signal   eu_reg_a_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X');          -- register write address
    signal   eu_reg_a_wr:   std_logic                                         :=            'X';           -- register write
    signal   eu_reg_a_di:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register write data
    signal   eu_reg_b_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X');          -- register read address
    signal   eu_reg_b_rd:   std_logic                                         :=            'X';           -- register read
    signal   eu_reg_b_do:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register read data
    signal   eu_reg_c_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X');          -- register read address
    signal   eu_reg_c_rd:   std_logic                                         :=            'X';           -- register read
    signal   eu_reg_c_do:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register read data
    signal   eu_rom_en:     std_logic                                         :=            'X';
    signal   eu_rom_addr:   std_logic_vector((rom_addr_bits    - 1) downto 0) := (others => 'X');
    signal   eu_rom_data:   std_logic_vector((word_size        - 1) downto 0) := (others => 'X');
    signal   eu_ram_addr:   std_logic_vector((ram_addr_bits    - 1) downto 0) := (others => 'X');
    signal   eu_ram_rd:     std_logic                                         :=            'X';
    signal   eu_ram_rdata:  std_logic_vector((word_size        - 1) downto 0) := (others => 'X');
    signal   eu_ram_wr:     std_logic                                         :=            'X';
    signal   eu_ram_wdata:  std_logic_vector((word_size        - 1) downto 0) := (others => 'X');
    signal   eu_intr:       std_logic_vector((intr_size        - 1) downto 0) := (others => '0');
    signal   eu_io_in:      byte_vector(     (ports_in         - 1) downto 0) := (others => byte_null);
    signal   eu_io_out:     byte_vector(     (ports_out        - 1) downto 0) := (others => byte_unknown);

    signal   alu_si:        std_logic                                         :=            'X';  -- signed integers
    signal   alu_a_c:       std_logic                                         :=            'X';  -- A complement
    signal   alu_a_di:      std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- A data in
    signal   alu_b_c:       std_logic                                         :=            'X';  -- B complement
    signal   alu_b_di:      std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- B data in
    signal   alu_c_in:      std_logic                                         :=            'X';  -- carry in
    signal   alu_s_do:      std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- sum data out
    signal   alu_c_out:     std_logic                                         :=            'X';  -- carry out

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

    sseg_unit: entity WORK.timer
    generic map
    (
        gate_delay    => gate_delay,
        clk_freq      => clk_freq,
        tmr_period    => sseg_intr
    )
    port map
    (
        rst           => rst,
        clk           => clk,
        tmr           => eu_intr(1)
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
        a_addr        => eu_ram_addr,
        a_rd          => eu_ram_rd,
        a_do          => eu_ram_rdata,
        a_wr          => eu_ram_wr,
        a_di          => eu_ram_wdata,
        b_addr        => eu_rom_addr,
        b_rd          => eu_rom_en,
        b_do          => eu_rom_data
    );
    
    register_unit: entity WORK.registers
    generic map
    (
        gate_delay    => gate_delay,
        word_size     => word_size,
        reg_low       => reg_low,
        reg_high      => reg_high
    )
    port map
    (
        clk           => clk,
        a_addr        => eu_reg_a_addr,
        a_wr          => eu_reg_a_wr,
        a_di          => eu_reg_a_di,
        b_addr        => eu_reg_b_addr,
        b_rd          => eu_reg_b_rd,
        b_do          => eu_reg_b_do,
        c_addr        => eu_reg_c_addr,
        c_rd          => eu_reg_c_rd,
        c_do          => eu_reg_c_do
    );
    
    eu_io_in(0) <= db_data_out(15 downto 8);
    eu_io_in(1) <= db_data_out( 7 downto 0);

    execution_unit: entity WORK.execution_unit
    generic map
    (
        gate_delay    => gate_delay,
        word_size     => word_size,
        reg_high      => reg_high,
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
        reg_a_addr    => eu_reg_a_addr,
        reg_a_wr      => eu_reg_a_wr,
        reg_a_di      => eu_reg_a_di,
        reg_b_addr    => eu_reg_b_addr,
        reg_b_rd      => eu_reg_b_rd,
        reg_b_do      => eu_reg_b_do,
        reg_c_addr    => eu_reg_c_addr,
        reg_c_rd      => eu_reg_c_rd,
        reg_c_do      => eu_reg_c_do,
        rom_addr      => eu_rom_addr,
        rom_en        => eu_rom_en,
        rom_data      => eu_rom_data,
        ram_addr      => eu_ram_addr,
        ram_rd        => eu_ram_rd,
        ram_rdata     => eu_ram_rdata,
        ram_wr        => eu_ram_wr,
        ram_wdata     => eu_ram_wdata,
        intr          => eu_intr,
        io_in         => eu_io_in,
        io_out        => eu_io_out,
        alu_si        => alu_si,
        alu_a_c       => alu_a_c,
        alu_a_di      => alu_a_di,
        alu_b_c       => alu_b_c,
        alu_b_di      => alu_b_di,
        alu_c_in      => alu_c_in,
        alu_s_do      => alu_s_do,
        alu_c_out     => alu_c_out
    );

    ld <= eu_io_out(0);
    an <= eu_io_out(1)(3 downto 0);
    ka <= eu_io_out(2);
    tx <= '0';

    alu_unit: entity WORK.alu
    generic map
    (
        gate_delay    => gate_delay,
        word_size     => word_size
    )
    port map
    (
        si            => alu_si,
        a_c           => alu_a_c,
        a_di          => alu_a_di,
        b_c           => alu_b_c,
        b_di          => alu_b_di,
        c_in          => alu_c_in,
        s_do          => alu_s_do,
        c_out         => alu_c_out
    );

--synopsys synthesis_off
    test_reg_a_addr    <= eu_reg_a_addr;
    test_reg_a_wr      <= eu_reg_a_wr;
    test_reg_a_di      <= eu_reg_a_di;
    test_reg_b_addr    <= eu_reg_b_addr;
    test_reg_b_rd      <= eu_reg_b_rd;
    test_reg_b_do      <= eu_reg_b_do;
    test_reg_c_addr    <= eu_reg_c_addr;
    test_reg_c_rd      <= eu_reg_c_rd;
    test_reg_c_do      <= eu_reg_c_do;
    test_rom_addr      <= eu_rom_addr;
    test_rom_en        <= eu_rom_en;
    test_rom_data      <= eu_rom_data;
    test_ram_addr      <= eu_ram_addr;
    test_ram_rd        <= eu_ram_rd;
    test_ram_rdata     <= eu_ram_rdata;
    test_ram_wr        <= eu_ram_wr;
    test_ram_wdata     <= eu_ram_wdata;
    test_alu_si        <= alu_si;
    test_alu_a_c       <= alu_a_c;
    test_alu_a_di      <= alu_a_di;
    test_alu_b_c       <= alu_b_c;
    test_alu_b_di      <= alu_b_di;
    test_alu_c_in      <= alu_c_in;
    test_alu_s_do      <= alu_s_do;
    test_alu_c_out     <= alu_c_out;
--synopsys synthesis_on

end behav;
