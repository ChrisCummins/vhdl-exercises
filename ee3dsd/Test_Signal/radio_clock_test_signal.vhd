library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.std_logic_textio.all;

entity radio_clock_test_signal is
end radio_clock_test_signal;

architecture behav of radio_clock_test_signal is

    signal   full:       std_logic := 'X';

    signal   btnu:       std_logic := 'X';
    signal   btnd:       std_logic := 'X';
    signal   btnc:       std_logic := 'X';
    signal   btnl:       std_logic := 'X';
    signal   btnr:       std_logic := 'X';

    signal   rx:         std_logic := 'X';

    signal   dcf:        std_logic := 'X';
    signal   msf:        std_logic := 'X';

begin

    process
        file     data:      text;
        variable data_line: line;

        variable full_var:  std_logic;

        variable btnu_var:  std_logic;
        variable btnd_var:  std_logic;
        variable btnc_var:  std_logic;
        variable btnl_var:  std_logic;
        variable btnr_var:  std_logic;

        variable rx_var:    std_logic;

        variable dcf_var:   std_logic;
        variable msf_var:   std_logic;
        variable t_var:     time;
    begin
        file_open(data, "trace.cap", read_mode);
        
        while not endfile(data) loop
            readline(data, data_line);

            read(data_line, dcf_var);
            read(data_line, msf_var);

            read(data_line, rx_var);

            read(data_line, btnr_var);
            read(data_line, btnl_var);
            read(data_line, btnc_var);
            read(data_line, btnd_var);
            read(data_line, btnu_var);

            read(data_line, full_var);

            read(data_line, t_var);
            
            if t_var > now then
                wait for t_var - now;
            end if;

            full   <= full_var;
            btnu   <= btnu_var;
            btnd   <= btnd_var;
            btnc   <= btnc_var;
            btnl   <= btnl_var;
            btnr   <= btnr_var;
            rx     <= rx_var;
            dcf    <= dcf_var;
            msf    <= msf_var;
        end loop;
        
        file_close(data);
        
        assert false report "end of test" severity note;
        wait;
    end process;
    
end behav;
