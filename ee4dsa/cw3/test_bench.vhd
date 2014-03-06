library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;
use WORK.util.all;

entity test_bench is
end test_bench;

architecture behav of test_bench is

    constant clk_freq:   positive   := 1000000; -- Hz
    constant clk_period: time       := 1000 ms / clk_freq;
    constant debounce:   natural    := 1; -- us
    constant baud_rate:  positive   := 57600; -- Baud
    constant timer_intr: positive   := 50; -- us
    constant sseg_intr:  positive   := 200; -- us
    constant gate_delay: time       := 1 ns;
    constant word_size:  positive   := 32;
    constant reg_high:   positive   := 255;
    constant ram_size:   positive   := 4096;
    constant intr_size:  positive   := 8;

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

    process
        file     data_file: text;
        variable data_line: line;
        variable sw_var:  std_logic_vector(7 downto 0);
        variable io_var:  std_logic_vector(7 downto 0);
        variable t_var:     time;
    begin
        file_open(data_file, "test_bench_inputs.dat", read_mode);

        while not endfile(data_file) loop
            readline(data_file, data_line);

            read(data_line, sw_var);
            read(data_line, io_var);
            read(data_line, t_var);

            if (t_var > now) then
                wait for t_var - now;
            end if;

            sw   <= sw_var;
            btnu <= io_var(7);
            btnd <= io_var(6);
            btnc <= io_var(5);
            btnl <= io_var(4);
            btnr <= io_var(3);
            rx   <= io_var(2);
            msf  <= io_var(1);
            dcf  <= io_var(0);
        end loop;

        file_close(data_file);
        wait for 5 * clk_period;
        end_flag <= '1';
        wait;
    end process;

    process
        file     data_file:           text;
        variable data_line:           line;
        variable comp_pc_var:         std_logic_vector((n_bits(ram_size) - 1) downto 0);
        variable comp_sp_var:         std_logic_vector((n_bits(ram_size) - 1) downto 0);
        variable comp_sr_var:         std_logic_vector((       word_size - 1) downto 0);
        variable comp_reg_a_addr_var: std_logic_vector((n_bits(reg_high) - 1) downto 0);
        variable comp_reg_a_wr_var:   std_logic;
        variable comp_reg_a_di_var:   std_logic_vector((       word_size - 1) downto 0);
        variable comp_reg_b_addr_var: std_logic_vector((n_bits(reg_high) - 1) downto 0);
        variable comp_reg_b_rd_var:   std_logic;
        variable comp_reg_b_do_var:   std_logic_vector((       word_size - 1) downto 0);
        variable comp_reg_c_addr_var: std_logic_vector((n_bits(reg_high) - 1) downto 0);
        variable comp_reg_c_rd_var:   std_logic;
        variable comp_reg_c_do_var:   std_logic_vector((       word_size - 1) downto 0);
        variable comp_rom_addr_var:   std_logic_vector((n_bits(ram_size) - 1) downto 0);
        variable comp_rom_en_var:     std_logic;
        variable comp_rom_data_var:   std_logic_vector((       word_size - 1) downto 0);
        variable comp_ram_addr_var:   std_logic_vector((n_bits(ram_size) - 1) downto 0);
        variable comp_ram_rd_var:     std_logic;
        variable comp_ram_rdata_var:  std_logic_vector((       word_size - 1) downto 0);
        variable comp_ram_wr_var:     std_logic;
        variable comp_ram_wdata_var:  std_logic_vector((       word_size - 1) downto 0);
        variable comp_ld_var:         std_logic_vector(7 downto 0);
        variable comp_an_var:         std_logic_vector(3 downto 0);
        variable comp_ka_var:         std_logic_vector(7 downto 0);
        variable comp_alu_si_var:     std_logic;
        variable comp_alu_a_c_var:    std_logic;
        variable comp_alu_a_di_var:   std_logic_vector((       word_size - 1) downto 0);
        variable comp_alu_b_c_var:    std_logic;
        variable comp_alu_b_di_var:   std_logic_vector((       word_size - 1) downto 0);
        variable comp_alu_c_in_var:   std_logic;
        variable comp_alu_s_do_var:   std_logic_vector((       word_size - 1) downto 0);
        variable comp_alu_c_out_var:  std_logic;
        variable t_var:               time;
    begin
        file_open(data_file, "test_bench_outputs.dat", read_mode);

        while not endfile(data_file) loop
            readline(data_file, data_line);

             read(data_line, comp_pc_var);
             read(data_line, comp_sp_var);
            hread(data_line, comp_sr_var);
             read(data_line, comp_reg_a_addr_var);
             read(data_line, comp_reg_a_wr_var);
            hread(data_line, comp_reg_a_di_var);
             read(data_line, comp_reg_b_addr_var);
             read(data_line, comp_reg_b_rd_var);
            hread(data_line, comp_reg_b_do_var);
             read(data_line, comp_reg_c_addr_var);
             read(data_line, comp_reg_c_rd_var);
            hread(data_line, comp_reg_c_do_var);
             read(data_line, comp_rom_addr_var);
             read(data_line, comp_rom_en_var);
            hread(data_line, comp_rom_data_var);
             read(data_line, comp_ram_addr_var);
             read(data_line, comp_ram_rd_var);
            hread(data_line, comp_ram_rdata_var);
             read(data_line, comp_ram_wr_var);
            hread(data_line, comp_ram_wdata_var);
            hread(data_line, comp_ld_var);
            hread(data_line, comp_an_var);
            hread(data_line, comp_ka_var);
             read(data_line, comp_alu_si_var);
             read(data_line, comp_alu_a_c_var);
            hread(data_line, comp_alu_a_di_var);
             read(data_line, comp_alu_b_c_var);
            hread(data_line, comp_alu_b_di_var);
             read(data_line, comp_alu_c_in_var);
            hread(data_line, comp_alu_s_do_var);
             read(data_line, comp_alu_c_out_var);
             read(data_line, t_var);

            if (t_var > now) then
                wait for t_var - now;
            end if;

            comp_pc         <= unsigned(comp_pc_var);
            comp_sp         <= unsigned(comp_sp_var);
            comp_sr         <= comp_sr_var;
            comp_reg_a_addr <= comp_reg_a_addr_var;
            comp_reg_a_wr   <= comp_reg_a_wr_var;
            comp_reg_a_di   <= comp_reg_a_di_var;
            comp_reg_b_addr <= comp_reg_b_addr_var;
            comp_reg_b_rd   <= comp_reg_b_rd_var;
            comp_reg_b_do   <= comp_reg_b_do_var;
            comp_reg_c_addr <= comp_reg_c_addr_var;
            comp_reg_c_rd   <= comp_reg_c_rd_var;
            comp_reg_c_do   <= comp_reg_c_do_var;
            comp_rom_addr   <= comp_rom_addr_var;
            comp_rom_en     <= comp_rom_en_var;
            comp_rom_data   <= comp_rom_data_var;
            comp_ram_addr   <= comp_ram_addr_var;
            comp_ram_rd     <= comp_ram_rd_var;
            comp_ram_rdata  <= comp_ram_rdata_var;
            comp_ram_wr     <= comp_ram_wr_var;
            comp_ram_wdata  <= comp_ram_wdata_var;
            comp_ld         <= comp_ld_var;
            comp_an         <= comp_an_var;
            comp_ka         <= comp_ka_var;
            comp_alu_si     <= comp_alu_si_var;
            comp_alu_a_c    <= comp_alu_a_c_var;
            comp_alu_a_di   <= comp_alu_a_di_var;
            comp_alu_b_c    <= comp_alu_b_c_var;
            comp_alu_b_di   <= comp_alu_b_di_var;
            comp_alu_c_in   <= comp_alu_c_in_var;
            comp_alu_s_do   <= comp_alu_s_do_var;
            comp_alu_c_out  <= comp_alu_c_out_var;
        end loop;

        file_close(data_file);
        wait;
    end process;

    process
    begin
        wait for 0.5 * clk_period;

        while end_flag = '0' loop
            assert comp_pc             = test_pc
            report "pc = "             & to_string(std_logic_vector(test_pc)) &
                   ", but should be "  & to_string(std_logic_vector(comp_pc)) severity error;
            assert comp_sp             = test_sp
            report "sp = "             & to_string(std_logic_vector(test_sp)) &
                   ", but should be "  & to_string(std_logic_vector(comp_sp)) severity error;
            assert comp_sr             = test_sr
            report "sr = "             & to_string(test_sr)                   &
                   ", but should be "  & to_string(comp_sr)                   severity error;
            assert comp_reg_a_addr     = test_reg_a_addr
            report "reg_a_addr = "     & to_string(test_reg_a_addr)           &
                   ", but should be "  & to_string(comp_reg_a_addr)           severity error;
            assert comp_reg_a_wr       = test_reg_a_wr
            report "reg_a_wr = "       & std_logic'image(test_reg_a_wr)       &
                   ", but should be "  & std_logic'image(comp_reg_a_wr)       severity error;
            assert comp_reg_a_di       = test_reg_a_di
            report "reg_a_di = "       & to_string(test_reg_a_di)             &
                   ", but should be "  & to_string(comp_reg_a_di)             severity error;
            assert comp_reg_b_addr     = test_reg_b_addr
            report "reg_b_addr = "     & to_string(test_reg_b_addr)           &
                   ", but should be "  & to_string(comp_reg_b_addr)           severity error;
            assert comp_reg_b_rd       = test_reg_b_rd
            report "reg_b_rd = "       & std_logic'image(test_reg_b_rd)       &
                   ", but should be "  & std_logic'image(comp_reg_b_rd)       severity error;
            assert comp_reg_b_do       = test_reg_b_do
            report "reg_b_do = "       & to_string(test_reg_b_do)             &
                   ", but should be "  & to_string(comp_reg_b_do)             severity error;
            assert comp_reg_c_addr     = test_reg_c_addr
            report "reg_c_addr = "     & to_string(test_reg_c_addr)           &
                   ", but should be "  & to_string(comp_reg_c_addr)           severity error;
            assert comp_reg_c_rd       = test_reg_c_rd
            report "reg_c_rd = "       & std_logic'image(test_reg_c_rd)       &
                   ", but should be "  & std_logic'image(comp_reg_c_rd)       severity error;
            assert comp_reg_c_do       = test_reg_c_do
            report "reg_c_do = "       & to_string(test_reg_c_do)             &
                   ", but should be "  & to_string(comp_reg_c_do)             severity error;
            assert comp_rom_addr       = test_rom_addr
            report "rom_addr = "       & to_string(test_rom_addr)             &
                   ", but should be "  & to_string(comp_rom_addr)             severity error;
            assert comp_rom_en         = test_rom_en 
            report "rom_en = "         & std_logic'image(test_rom_en)         & 
                   ", but should be "  & std_logic'image(comp_rom_en)         severity error;
            assert comp_rom_data       = test_rom_data
            report "rom_data = "       & to_string(test_rom_data)             &
                   ", but should be "  & to_string(comp_rom_data)             severity error;
            assert comp_ram_addr       = test_ram_addr
            report "ram_addr = "       & to_string(test_ram_addr)             &
                   ", but should be "  & to_string(comp_ram_addr)             severity error;
            assert comp_ram_rd         = test_ram_rd
            report "ram_rd = "         & std_logic'image(test_ram_rd)         &
                   ", but should be "  & std_logic'image(comp_ram_rd)         severity error;
            assert comp_ram_rdata      = test_ram_rdata
            report "ram_rdata = "      & to_string(test_ram_rdata)            & 
                   ", but should be "  & to_string(comp_ram_rdata)            severity error;
            assert comp_ram_wr         = test_ram_wr
            report "ram_wr = "         & std_logic'image(test_ram_wr)         &
                   ", but should be "  & std_logic'image(comp_ram_wr)         severity error;
            assert comp_ram_wdata      = test_ram_wdata
            report "ram_wdata = "      & to_string(test_ram_wdata)            &
                   ", but should be "  & to_string(comp_ram_wdata)            severity error;
            assert comp_ld             = test_ld
            report "ld = "             & to_string(test_ld)                   &
                  ", but should be "   & to_string(comp_ld)                   severity error;
            assert comp_an             = test_an
            report "an = "             & to_string(test_an)                   &
                  ", but should be "   & to_string(comp_an)                   severity error;
            assert comp_ka             = test_ka
            report "ka = "             & to_string(test_ka)                   &
                  ", but should be "   & to_string(comp_ka)                   severity error;
            assert comp_alu_si         = test_alu_si
            report "alu_si = "         & std_logic'image(test_alu_si)         &
                   ", but should be "  & std_logic'image(comp_alu_si)         severity error;
            assert comp_alu_a_c        = test_alu_a_c
            report "alu_a_c = "        & std_logic'image(test_alu_a_c)        &
                   ", but should be "  & std_logic'image(comp_alu_a_c)        severity error;
            assert comp_alu_a_di       = test_alu_a_di
            report "alu_a_di = "       & to_string(test_alu_a_di)             &
                  ", but should be "   & to_string(comp_alu_a_di)             severity error;
            assert comp_alu_b_c        = test_alu_b_c
            report "alu_b_c = "        & std_logic'image(test_alu_b_c)        &
                   ", but should be "  & std_logic'image(comp_alu_b_c)        severity error;
            assert comp_alu_b_di       = test_alu_b_di
            report "alu_b_di = "       & to_string(test_alu_b_di)             &
                  ", but should be "   & to_string(comp_alu_b_di)             severity error;
            assert comp_alu_c_in       = test_alu_c_in
            report "alu_c_in = "       & std_logic'image(test_alu_c_in)       &
                   ", but should be "  & std_logic'image(comp_alu_c_in)       severity error;
            assert comp_alu_s_do       = test_alu_s_do
            report "alu_s_do = "       & to_string(test_alu_s_do)             &
                  ", but should be "   & to_string(comp_alu_s_do)             severity error;
            assert comp_alu_c_out      = test_alu_c_out
            report "alu_c_out = "      & std_logic'image(test_alu_c_out)      &
                   ", but should be "  & std_logic'image(comp_alu_c_out)      severity error;
            wait for clk_period;
        end loop;

        wait;
    end process;

    process
        file     data_file: text;
        variable data_line: line;
    begin
        file_open(data_file, "trace.dat", write_mode);

        while end_flag = '0' loop

            wait on end_flag,
                    test_pc, test_sp, test_sr,
                    test_reg_a_addr, test_reg_a_wr, test_reg_a_di,
                    test_reg_b_addr, test_reg_b_rd, test_reg_b_do,
                    test_reg_c_addr, test_reg_c_rd, test_reg_c_do,
                    test_rom_en, test_rom_addr,  test_rom_data,
                    test_ram_wr, test_ram_addr, test_ram_wdata,
                    test_ram_rd, test_ram_rdata,
                    test_ld, test_an, test_ka,
                    test_alu_si, test_alu_a_c, test_alu_a_di,
                    test_alu_b_c, test_alu_b_di, test_alu_c_in,
                    test_alu_s_do, test_alu_c_out;

             write(data_line, std_logic_vector(test_pc));
             write(data_line, ' ');
             write(data_line, std_logic_vector(test_sp));
             write(data_line, ' ');
            hwrite(data_line, test_sr);
             write(data_line, ' ');
             write(data_line, test_reg_a_addr);
             write(data_line, ' ');
             write(data_line, test_reg_a_wr);
             write(data_line, ' ');
            hwrite(data_line, test_reg_a_di);
             write(data_line, ' ');
             write(data_line, test_reg_b_addr);
             write(data_line, ' ');
             write(data_line, test_reg_b_rd);
             write(data_line, ' ');
            hwrite(data_line, test_reg_b_do);
             write(data_line, ' ');
             write(data_line, test_reg_c_addr);
             write(data_line, ' ');
             write(data_line, test_reg_c_rd);
             write(data_line, ' ');
            hwrite(data_line, test_reg_c_do);
             write(data_line, ' ');
             write(data_line, test_rom_addr);
             write(data_line, ' ');
             write(data_line, test_rom_en);
             write(data_line, ' ');
            hwrite(data_line, test_rom_data);
             write(data_line, ' ');
             write(data_line, test_ram_addr);
             write(data_line, ' ');
             write(data_line, test_ram_rd);
             write(data_line, ' ');
            hwrite(data_line, test_ram_rdata);
             write(data_line, ' ');
             write(data_line, test_ram_wr);
             write(data_line, ' ');
            hwrite(data_line, test_ram_wdata);
             write(data_line, ' ');
            hwrite(data_line, test_ld);
             write(data_line, ' ');
            hwrite(data_line, test_an);
             write(data_line, ' ');
            hwrite(data_line, test_ka);
             write(data_line, ' ');
             write(data_line, test_alu_si);
             write(data_line, ' ');
             write(data_line, test_alu_a_c);
             write(data_line, ' ');
            hwrite(data_line, test_alu_a_di);
             write(data_line, ' ');
             write(data_line, test_alu_b_c);
             write(data_line, ' ');
            hwrite(data_line, test_alu_b_di);
             write(data_line, ' ');
             write(data_line, test_alu_c_in);
             write(data_line, ' ');
            hwrite(data_line, test_alu_s_do);
             write(data_line, ' ');
             write(data_line, test_alu_c_out);
             write(data_line, ' ');
             write(data_line, now);
            writeline(data_file, data_line);
        end loop;

        file_close(data_file);
        wait;
    end process;

end behav;
