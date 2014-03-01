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
    constant gate_delay: time       := 1 ns;
    constant word_size:  positive   := 32;
    constant rom_size:   positive   := 64;
    
    signal   end_flag:      std_logic                                 :=            '0';
    signal   clk:           std_logic                                 :=            '0';

--synopsys synthesis_off
    signal   test_pc:       unsigned((n_bits(rom_size) - 1) downto 0) := (others => 'X'); -- program counter
    signal   test_opcode:   std_logic_vector(7 downto 0)              := (others => 'X'); -- instruction opcode
    signal   test_ins_data: std_logic_vector(word_size - 9 downto 0)  := (others => 'X'); -- instruction data
--synopsys synthesis_on

    signal   btnu:          std_logic                                 :=            '0';  -- button up
    signal   btnd:          std_logic                                 :=            '0';  -- button down
    signal   btnc:          std_logic                                 :=            '0';  -- button centre
    signal   btnl:          std_logic                                 :=            '0';  -- button left
    signal   btnr:          std_logic                                 :=            '0';  -- button right
    signal   sw:            std_logic_vector(7 downto 0)              := (others => '0'); -- switches
    signal   an:            std_logic_vector(3 downto 0)              := (others => 'X'); -- anodes   7 segment display
    signal   ka:            std_logic_vector(7 downto 0)              := (others => 'X'); -- kathodes 7 segment display
    signal   ld:            std_logic_vector(7 downto 0)              := (others => 'X'); -- leds
    signal   rx:            std_logic                                 :=            '0';  -- uart rx 
    signal   tx:            std_logic                                 :=            'X';  -- uart tx
    signal   msf:           std_logic                                 :=            '0';  -- msf signal
    signal   dcf:           std_logic                                 :=            '0';  -- dcf signal

begin

    top_level_uut: entity WORK.top_level 
    generic map
    (
        clk_freq   => clk_freq,
        debounce   => debounce,
        baud_rate  => baud_rate,
        gate_delay => gate_delay,
        word_size  => word_size,
        rom_size   => rom_size
    )
    port map
    (
        clk        => clk,

--synopsys synthesis_off
        test_pc       => test_pc,
        test_opcode   => test_opcode,
        test_ins_data => test_ins_data,
--synopsys synthesis_on

        btnu       => btnu,
        btnd       => btnd,
        btnc       => btnc,
        btnl       => btnl,
        btnr       => btnr,
        sw         => sw,
        an         => an,
        ka         => ka,
        ld         => ld,
        rx         => rx,
        tx         => tx,
        msf        => msf,
        dcf        => dcf
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
        file     data_file:         text;
        variable data_line:         line;
        variable test_pc_var:       std_logic_vector((n_bits(rom_size) - 1) downto 0);
        variable test_opcode_var:   std_logic_vector(7 downto 0);
        variable test_ins_data_var: std_logic_vector(word_size - 9 downto 0);
        variable ld_var:            std_logic_vector(7 downto 0);
        variable t_var:             time;
    begin
        file_open(data_file, "test_bench_outputs.dat", read_mode);

        while not endfile(data_file) loop
            readline(data_file, data_line);

            read(data_line, test_pc_var);
            read(data_line, test_opcode_var);
            read(data_line, test_ins_data_var);
            read(data_line, ld_var);
            read(data_line, t_var);

            if (t_var > now) then
                wait for t_var - now;
            end if;

            assert test_pc_var       = std_logic_vector(test_pc) 
            report "test_pc = " &       to_string(std_logic_vector(test_pc)) & 
                   ", but should be " & to_string(test_pc_var) severity error;
            assert test_opcode_var   = test_opcode               
            report "test_opcode = " &   to_string(test_opcode) & 
                   ", but should be " & to_string(test_opcode_var) severity error;
            assert test_ins_data_var = test_ins_data             
            report "test_ins_data = " & to_string(test_ins_data) & 
                   ", but should be " & to_string(test_ins_data_var) severity error;
            assert ld_var            = ld                        
            report "ld = " &            to_string(ld) & 
                  ", but should be " &  to_string(ld_var) severity error;
        end loop;
        
        file_close(data_file);
        wait;
    end process;
    

    process
      file     data_file:         text;
      variable data_line:         line;
    begin
      file_open(data_file, "my_test_bench_outputs.dat", write_mode);

      wait for 4500 ns;

      while end_flag = '0' loop

        write(data_line, std_logic_vector(test_pc));
        write(data_line, ' ');
        write(data_line, test_opcode);
        write(data_line, ' ');
        write(data_line, test_ins_data);
        write(data_line, ' ');
        write(data_line, ld);
        write(data_line, ' ');
        write(data_line, now);

        writeline(data_file, data_line);
        wait for clk_period;
      end loop;

      file_close(data_file);
      wait;

    end process;

end behav;
