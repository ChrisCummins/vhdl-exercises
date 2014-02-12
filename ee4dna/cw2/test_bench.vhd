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
    constant gate_delay: time       := 1 ns;
    constant word_size:  positive   := 32;
    constant rom_size:   positive   := 64;
    constant ram_size:   positive   := 128;
    constant intr_size:  positive   := 8;
    
    signal   end_flag:       std_logic                                         :=            '0';
    signal   clk:            std_logic                                         :=            '0';

    signal   comp_pc:        unsigned(        (n_bits(rom_size) - 1) downto 0) := (others => 'X');
    signal   comp_sp:        unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   comp_sr:        std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   comp_rom_en:    std_logic                                         :=            'X';
    signal   comp_rom_addr:  std_logic_vector((n_bits(rom_size) - 1) downto 0) := (others => 'X');
    signal   comp_rom_data:  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   comp_ram_wr:    std_logic                                         :=            'X';
    signal   comp_ram_waddr: std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   comp_ram_wdata: std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   comp_ram_rd:    std_logic                                         :=            'X';
    signal   comp_ram_raddr: std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   comp_ram_rdata: std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   comp_ld:        std_logic_vector(7 downto 0)                      := (others => 'X');

    signal   test_pc:        unsigned(        (n_bits(rom_size) - 1) downto 0) := (others => 'X'); -- program counter
    signal   test_sp:        unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => 'X'); -- stack pointer
    signal   test_sr:        std_logic_vector((       word_size - 1) downto 0) := (others => 'X'); -- status register
    signal   test_rom_en:    std_logic                                         :=            'X';
    signal   test_rom_addr:  std_logic_vector((n_bits(rom_size) - 1) downto 0) := (others => 'X');
    signal   test_rom_data:  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   test_ram_wr:    std_logic                                         :=            'X';
    signal   test_ram_waddr: std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   test_ram_wdata: std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   test_ram_rd:    std_logic                                         :=            'X';
    signal   test_ram_raddr: std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => 'X');
    signal   test_ram_rdata: std_logic_vector((       word_size - 1) downto 0) := (others => 'X');
    signal   test_intr:      std_logic_vector((       intr_size - 1) downto 0) := (others => 'X');

    signal   btnu:           std_logic                                         :=            '0';  -- button up
    signal   btnd:           std_logic                                         :=            '0';  -- button down
    signal   btnc:           std_logic                                         :=            '0';  -- button centre
    signal   btnl:           std_logic                                         :=            '0';  -- button left
    signal   btnr:           std_logic                                         :=            '0';  -- button right
    signal   sw:             std_logic_vector(7 downto 0)                      := (others => '0'); -- switches
    signal   an:             std_logic_vector(3 downto 0)                      := (others => 'X'); -- anodes   7 segment display
    signal   ka:             std_logic_vector(7 downto 0)                      := (others => 'X'); -- kathodes 7 segment display
    signal   ld:             std_logic_vector(7 downto 0)                      := (others => 'X'); -- leds
    signal   rx:             std_logic                                         :=            '0';  -- uart rx 
    signal   tx:             std_logic                                         :=            'X';  -- uart tx
    signal   msf:            std_logic                                         :=            '0';  -- msf signal
    signal   dcf:            std_logic                                         :=            '0';  -- dcf signal

begin

    top_level_uut: entity WORK.top_level 
    generic map
    (
        clk_freq   => clk_freq,
        debounce   => debounce,
        baud_rate  => baud_rate,
        timer_intr => timer_intr,
        gate_delay => gate_delay,
        word_size  => word_size,
        rom_size   => rom_size,
        ram_size   => ram_size,
        intr_size  => intr_size
    )
    port map
    (
        clk            => clk,
        test_pc        => test_pc,
        test_sp        => test_sp,
        test_sr        => test_sr,
        test_rom_en    => test_rom_en,
        test_rom_addr  => test_rom_addr,
        test_rom_data  => test_rom_data,
        test_ram_wr    => test_ram_wr,
        test_ram_waddr => test_ram_waddr,
        test_ram_wdata => test_ram_wdata,
        test_ram_rd    => test_ram_rd,
        test_ram_raddr => test_ram_raddr,
        test_ram_rdata => test_ram_rdata,
        test_intr      => test_intr,
        btnu           => btnu,
        btnd           => btnd,
        btnc           => btnc,
        btnl           => btnl,
        btnr           => btnr,
        sw             => sw,
        an             => an,
        ka             => ka,
        ld             => ld,
        rx             => rx,
        tx             => tx,
        msf            => msf,
        dcf            => dcf
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
        file     data_file:          text;
        variable data_line:          line;
        variable comp_pc_var:        std_logic_vector((n_bits(rom_size) - 1) downto 0);
        variable comp_sp_var:        std_logic_vector((n_bits(ram_size) - 1) downto 0);
        variable comp_sr_var:        std_logic_vector((       word_size - 1) downto 0);
        variable comp_rom_en_var:    std_logic;
        variable comp_rom_addr_var:  std_logic_vector((n_bits(rom_size) - 1) downto 0);
        variable comp_rom_data_var:  std_logic_vector((       word_size - 1) downto 0);
        variable comp_ram_wr_var:    std_logic;
        variable comp_ram_waddr_var: std_logic_vector((n_bits(ram_size) - 1) downto 0);
        variable comp_ram_wdata_var: std_logic_vector((       word_size - 1) downto 0);
        variable comp_ram_rd_var:    std_logic;
        variable comp_ram_raddr_var: std_logic_vector((n_bits(ram_size) - 1) downto 0);
        variable comp_ram_rdata_var: std_logic_vector((       word_size - 1) downto 0);
        variable comp_ld_var:        std_logic_vector(7 downto 0);
        variable t_var:              time;
    begin
        file_open(data_file, "test_bench_outputs.dat", read_mode);

        while not endfile(data_file) loop
            readline(data_file, data_line);

             read(data_line, comp_pc_var);
             read(data_line, comp_sp_var);
            hread(data_line, comp_sr_var);
             read(data_line, comp_rom_en_var);
             read(data_line, comp_rom_addr_var);
            hread(data_line, comp_rom_data_var);
             read(data_line, comp_ram_wr_var);
             read(data_line, comp_ram_waddr_var);
            hread(data_line, comp_ram_wdata_var);
             read(data_line, comp_ram_rd_var);
             read(data_line, comp_ram_raddr_var);
            hread(data_line, comp_ram_rdata_var);
            hread(data_line, comp_ld_var);
             read(data_line, t_var);

            if (t_var > now) then
                wait for t_var - now;
            end if;
            
            comp_pc        <= unsigned(comp_pc_var);
            comp_sp        <= unsigned(comp_sp_var);
            comp_sr        <= comp_sr_var;
            comp_rom_en    <= comp_rom_en_var;
            comp_rom_addr  <= comp_rom_addr_var;
            comp_rom_data  <= comp_rom_data_var;
            comp_ram_wr    <= comp_ram_wr_var;
            comp_ram_waddr <= comp_ram_waddr_var;
            comp_ram_wdata <= comp_ram_wdata_var;
            comp_ram_rd    <= comp_ram_rd_var;
            comp_ram_raddr <= comp_ram_raddr_var;
            comp_ram_rdata <= comp_ram_rdata_var;
            comp_ld        <= comp_ld_var;
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
            assert comp_rom_en         = test_rom_en 
            report "rom_en = "         & std_logic'image(test_rom_en)         & 
                   ", but should be "  & std_logic'image(comp_rom_en)         severity error;
            assert comp_rom_addr       = test_rom_addr
            report "rom_addr = "       & to_string(test_rom_addr)             & 
                   ", but should be "  & to_string(comp_rom_addr)             severity error;
            assert comp_rom_data       = test_rom_data
            report "rom_data = "       & to_string(test_rom_data)             & 
                   ", but should be "  & to_string(comp_rom_data)             severity error;
            assert comp_ram_wr         = test_ram_wr
            report "ram_wr = "         & std_logic'image(test_ram_wr)         & 
                   ", but should be "  & std_logic'image(comp_ram_wr)         severity error;
            assert comp_ram_waddr      = test_ram_waddr
            report "ram_waddr = "      & to_string(test_ram_waddr)            & 
                   ", but should be "  & to_string(comp_ram_waddr)            severity error;
            assert comp_ram_wdata      = test_ram_wdata
            report "ram_wdata = "      & to_string(test_ram_wdata)            & 
                   ", but should be "  & to_string(comp_ram_wdata)            severity error;
            assert comp_ram_rd         = test_ram_rd
            report "ram_rd = "         & std_logic'image(test_ram_rd)         & 
                   ", but should be "  & std_logic'image(comp_ram_rd)         severity error;
            assert comp_ram_raddr      = test_ram_raddr
            report "ram_raddr = "      & to_string(test_ram_raddr)            & 
                   ", but should be "  & to_string(comp_ram_raddr)            severity error;
            assert comp_ram_rdata      = test_ram_rdata
            report "ram_rdata = "      & to_string(test_ram_rdata)            & 
                   ", but should be "  & to_string(comp_ram_rdata)            severity error;
            assert comp_ld             = ld
            report "ld = "             & to_string(ld)                        & 
                  ", but should be "   & to_string(comp_ld)                   severity error;

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

            wait on end_flag, test_pc, test_sp, test_sr,
                    test_rom_en, test_rom_addr,  test_rom_data, 
                    test_ram_wr, test_ram_waddr, test_ram_wdata, 
                    test_ram_rd, test_ram_raddr, test_ram_rdata, ld;

             write(data_line, std_logic_vector(test_pc));
             write(data_line, ' ');
             write(data_line, std_logic_vector(test_sp));
             write(data_line, ' ');
            hwrite(data_line, test_sr);
             write(data_line, ' ');
             write(data_line, test_rom_en);
             write(data_line, ' ');
             write(data_line, test_rom_addr);
             write(data_line, ' ');
            hwrite(data_line, test_rom_data);
             write(data_line, ' ');
             write(data_line, test_ram_wr);
             write(data_line, ' ');
             write(data_line, test_ram_waddr);
             write(data_line, ' ');
            hwrite(data_line, test_ram_wdata);
             write(data_line, ' ');
             write(data_line, test_ram_rd);
             write(data_line, ' ');
             write(data_line, test_ram_raddr);
             write(data_line, ' ');
            hwrite(data_line, test_ram_rdata);
             write(data_line, ' ');
            hwrite(data_line, ld);
             write(data_line, ' ');
             write(data_line, now);

            writeline(data_file, data_line);
        end loop;
        
        file_close(data_file);
        wait;
    end process;
    
end behav;
