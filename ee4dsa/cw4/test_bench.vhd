library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity test_bench is
end test_bench;

architecture behav of test_bench is

    constant test_duration: time     := 25 ms;
    constant clk_freq:      positive := 5000000; -- Hz
    constant clk_period:    time     := 1000 ms / clk_freq;
    constant debounce:      natural  := 1; -- us
    constant baud_rate:     positive := 57600; -- Baud
    constant timer_intr:    positive := 500; -- us
    constant sseg_intr:     positive := 175; -- us
    constant gate_delay:    time     := 1 ns;
    constant word_size:     positive := 32;
    constant reg_high:      positive := 255;
    constant ram_size:      positive := 4096;
    constant intr_size:     positive := 8;

    signal   end_flag:        std_logic                                         :=            '0';
    signal   clk:             std_logic                                         :=            '0';

    signal   comp_pc:         unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   comp_sp:         unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   comp_sr:         std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   comp_reg_a_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- register write address
    signal   comp_reg_a_wr:   std_logic                                         :=            'X';  -- register write
    signal   comp_reg_a_di:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- register write data
    signal   comp_reg_b_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- register read address
    signal   comp_reg_b_rd:   std_logic                                         :=            'X';  -- register read
    signal   comp_reg_b_do:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- register read data
    signal   comp_reg_c_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- register read address
    signal   comp_reg_c_rd:   std_logic                                         :=            'X';  -- register read
    signal   comp_reg_c_do:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- register read data
    signal   comp_rom_addr:   std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   comp_rom_en:     std_logic                                         :=            'X';
    signal   comp_rom_data:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   comp_ram_addr:   std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   comp_ram_rd:     std_logic                                         :=            'X';
    signal   comp_ram_rdata:  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   comp_ram_wr:     std_logic                                         :=            'X';
    signal   comp_ram_wdata:  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   comp_alu_si:     std_logic                                         :=            'X';  -- signed integers
    signal   comp_alu_a_c:    std_logic                                         :=            'X';  -- A complement
    signal   comp_alu_a_di:   std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- A data in
    signal   comp_alu_b_c:    std_logic                                         :=            'X';  -- B complement
    signal   comp_alu_b_di:   std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- B data in
    signal   comp_alu_c_in:   std_logic                                         :=            'X';  -- carry in
    signal   comp_alu_s_do:   std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- sum data out
    signal   comp_alu_c_out:  std_logic                                         :=            'X';  -- carry out

    signal   comp_an:         std_logic_vector(3 downto 0)                      := (others => 'X'); -- anodes   7 segment display
    signal   comp_ka:         std_logic_vector(7 downto 0)                      := (others => 'X'); -- kathodes 7 segment display
    signal   comp_ld:         std_logic_vector(7 downto 0)                      := (others => 'X');

    signal   test_pc:         unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => 'X'); -- program counter
    signal   test_sp:         unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => 'X'); -- stack pointer
    signal   test_sr:         std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- status register
    signal   test_reg_a_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- register write address
    signal   test_reg_a_wr:   std_logic                                         :=            'X';  -- register write
    signal   test_reg_a_di:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- register write data
    signal   test_reg_b_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- register read address
    signal   test_reg_b_rd:   std_logic                                         :=            'X';  -- register read
    signal   test_reg_b_do:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- register read data
    signal   test_reg_c_addr: std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => 'X'); -- register read address
    signal   test_reg_c_rd:   std_logic                                         :=            'X';  -- register read
    signal   test_reg_c_do:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- register read data
    signal   test_rom_addr:   std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   test_rom_en:     std_logic                                         :=            'X';
    signal   test_rom_data:   std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   test_ram_addr:   std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   test_ram_rd:     std_logic                                         :=            'X';
    signal   test_ram_rdata:  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   test_ram_wr:     std_logic                                         :=            'X';
    signal   test_ram_wdata:  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   test_alu_si:     std_logic                                         :=            'X';  -- signed integers
    signal   test_alu_a_c:    std_logic                                         :=            'X';  -- A complement
    signal   test_alu_a_di:   std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- A data in
    signal   test_alu_b_c:    std_logic                                         :=            'X';  -- B complement
    signal   test_alu_b_di:   std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- B data in
    signal   test_alu_c_in:   std_logic                                         :=            'X';  -- carry in
    signal   test_alu_s_do:   std_logic_vector((word_size        - 1) downto 0) := (others => 'X'); -- sum data out
    signal   test_alu_c_out:  std_logic                                         :=            'X';  -- carry out

    signal   btnu:            std_logic                                         :=            '0';  -- button up
    signal   btnd:            std_logic                                         :=            '0';  -- button down
    signal   btnc:            std_logic                                         :=            '0';  -- button centre
    signal   btnl:            std_logic                                         :=            '0';  -- button left
    signal   btnr:            std_logic                                         :=            '0';  -- button right
    signal   sw:              std_logic_vector(7 downto 0)                      := (others => '0'); -- switches
    signal   test_an:         std_logic_vector(3 downto 0)                      := (others => 'X'); -- anodes   7 segment display
    signal   test_ka:         std_logic_vector(7 downto 0)                      := (others => 'X'); -- kathodes 7 segment display
    signal   test_ld:         std_logic_vector(7 downto 0)                      := (others => 'X'); -- leds
    signal   rx:              std_logic                                         :=            '0';  -- uart rx
    signal   tx:              std_logic                                         :=            'X';  -- uart tx
    signal   msf:             std_logic                                         :=            '0';  -- msf signal
    signal   dcf:             std_logic                                         :=            '0';  -- dcf signal

begin

    top_level_uut: entity WORK.top_level
    generic map
    (
        clk_freq        => clk_freq,
        debounce        => debounce,
        baud_rate       => baud_rate,
        timer_intr      => timer_intr,
        sseg_intr       => sseg_intr,
        gate_delay      => gate_delay,
        word_size       => word_size,
        reg_high        => reg_high,
        ram_size        => ram_size,
        intr_size       => intr_size
    )
    port map
    (
        clk             => clk,
        test_pc         => test_pc,
        test_sp         => test_sp,
        test_sr         => test_sr,
        test_reg_a_addr => test_reg_a_addr,
        test_reg_a_wr   => test_reg_a_wr,
        test_reg_a_di   => test_reg_a_di,
        test_reg_b_addr => test_reg_b_addr,
        test_reg_b_rd   => test_reg_b_rd,
        test_reg_b_do   => test_reg_b_do,
        test_reg_c_addr => test_reg_c_addr,
        test_reg_c_rd   => test_reg_c_rd,
        test_reg_c_do   => test_reg_c_do,
        test_rom_addr   => test_rom_addr,
        test_rom_en     => test_rom_en,
        test_rom_data   => test_rom_data,
        test_ram_addr   => test_ram_addr,
        test_ram_rd     => test_ram_rd,
        test_ram_rdata  => test_ram_rdata,
        test_ram_wr     => test_ram_wr,
        test_ram_wdata  => test_ram_wdata,
        test_alu_si     => test_alu_si,
        test_alu_a_c    => test_alu_a_c,
        test_alu_a_di   => test_alu_a_di,
        test_alu_b_c    => test_alu_b_c,
        test_alu_b_di   => test_alu_b_di,
        test_alu_c_in   => test_alu_c_in,
        test_alu_s_do   => test_alu_s_do,
        test_alu_c_out  => test_alu_c_out,
        btnu            => btnu,
        btnd            => btnd,
        btnc            => btnc,
        btnl            => btnl,
        btnr            => btnr,
        sw              => sw,
        an              => test_an,
        ka              => test_ka,
        ld              => test_ld,
        rx              => rx,
        tx              => tx,
        msf             => msf,
        dcf             => dcf
    );

    sw <= "00000000";
    btnu <= '0';
    btnd <= '0';
    btnl <= '0';
    btnr <= '0';
    rx   <= '0';
    msf  <= '0';
    dcf  <= '0';

    -- Set end of test
    process
    begin
      wait for test_duration;
      end_flag <= '1';
      wait;
    end process;

    -- Set clock
    process
    begin
        while end_flag = '0' loop
            clk <= '1';
            wait for clk_period / 2;
            clk <= '0';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    -- Set centre button input
    process
    begin
      wait for 500 us;
      while end_flag <= '0' loop
        btnc <= '0';
        wait for 250 us;
        btnc <= '1';
        wait for 50 us;
      end loop;
      wait;
    end process;

end behav;
