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
    constant debounce:   natural    := 80; -- us
    constant baud_rate:  positive   := 57600; -- Baud
    constant bit_period: time       := 1000 ms / baud_rate;
    constant rst_period: time       := 5 * bit_period;
    constant gate_delay: time       := 1 ns;
    constant ts_digits:  positive   := 6;
    constant signals:    positive   := 2;
    constant fifo_size:  positive   := 2;

    signal   clk:      std_logic                                  :=            '0';
    signal   rst:      std_logic                                  :=            '1';
    signal   end_flag: std_logic                                  :=            '0';
    signal   ev:       std_logic_vector((signals - 1) downto 0)   := (others => '0');

    signal   up_t:     bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);

    signal   tr_d:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_e:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_r:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_f:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_w:     std_logic                                  :=            'X';

    signal   db_d:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   db_e:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   db_r:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   db_f:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   db_w:     std_logic                                  :=            'X';

    signal   fi_t:     bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);
    signal   fi_x:     bcd_digit_vector(ts_digits downto 0)       := (others => bcd_unknown);
    signal   fi_d:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   fi_f:     std_logic                                  :=            'X';
    signal   fi_w:     std_logic                                  :=            'X';
    signal   fi_a:     std_logic_vector(signals downto 0)         := (others => 'X');

    signal   tx_b:     std_logic                                  :=            'X';
    signal   tx_w:     std_logic                                  :=            'X';
    signal   tx_d:     byte                                       :=            byte_unknown;

    signal   sp_b:     std_logic                                  :=            'X';
    signal   sp_d:     std_logic                                  :=            'X';

begin

    uptime_uut: entity WORK.bcd_counter
    generic map
    (
        gate_delay   => gate_delay,
        leading_zero => false,
        digits       => ts_digits
    )
    port map
    (
        rst          => rst,
        clk          => clk,
        en           => '1',
        
        cnt          => up_t
    );
    
    trigger_uut: entity WORK.trigger
    generic map
    (
        clk_freq   => clk_freq,
        debounce   => 0,
        signals    => signals,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        di         => ev,

        do         => tr_d,
        eo         => tr_e,
        ro         => tr_r,
        fo         => tr_f,
        wo         => tr_w
    );

    debounce_uut: entity WORK.trigger
    generic map
    (
        clk_freq   => clk_freq,
        debounce   => debounce,
        signals    => signals,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        di         => ev,

        do         => db_d,
        eo         => db_e,
        ro         => db_r,
        fo         => db_f,
        wo         => db_w
    );

    fifo_uut: entity WORK.fifo
    generic map
    (
        gate_delay => gate_delay,
        ts_digits  => ts_digits,
        signals    => signals,
        size       => fifo_size
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        wi         => tr_w,
        tsi        => up_t,
        di         => tr_d,
        fi         => fi_f,

        wo         => fi_w,
        tso        => fi_t,
        do         => fi_d,
        bo         => tx_b
    );
    
    transmitter_uut: entity WORK.transmitter
    generic map
    (
        gate_delay => gate_delay,
        ts_digits  => ts_digits + 1,
        signals    => signals + 1
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        wi         => fi_w,
        ti         => fi_x,
        di         => fi_a,
        bi         => tx_b,

        wo         => tx_w,
        do         => tx_d,
        bo         => sp_b
    );
    
    serial_port_uut: entity WORK.serial_port 
    generic map
    (
        clk_freq   => clk_freq,
        baud_rate  => baud_rate,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        wi         => tx_w,
        di         => tx_d,
        bi         => sp_b,

        do         => sp_d
    );
    
    fi_x <= fi_t(ts_digits - 1 downto 4) & space_to_zero(fi_t(3 downto 3) & bcd_dot & fi_t(2 downto 0));
    fi_a <= fi_f & fi_d;
    
    process
    begin
        rst <= '1';
        wait for rst_period;
        rst <= '0';
        wait;
    end process;

    process
    begin
    
        while end_flag = '0' loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
        
        wait;
    end process;

    process
    begin
        wait for rst_period + 6 * bit_period;
        ev(0) <= '1';
        wait for 2 * bit_period;
        ev(0) <= '0';
        wait for 2 * bit_period;
        ev(1) <= '1';
        wait for 2 * bit_period;
        ev(1) <= '0';
        
        while (tx_b /= '0') loop
            wait on tx_b;
        end loop;

        wait for bit_period;

        while (tx_b /= '0') loop
            wait on tx_b;
        end loop;

        wait for bit_period;

        while (tx_b /= '0') loop
            wait on tx_b;
        end loop;

        wait for bit_period;

        while (tx_b /= '0') loop
            wait on tx_b;
        end loop;

        wait for 15 * bit_period;
        end_flag <= '1';
        assert false report "--- end of test ---" severity note;
        wait;
    end process;
        
    process
        file     data_file: text;
        variable data_line: line;

        variable tr_d_var:  std_logic_vector((signals - 1) downto 0);
        variable tr_e_var:  std_logic_vector((signals - 1) downto 0);
        variable tr_r_var:  std_logic_vector((signals - 1) downto 0);
        variable tr_f_var:  std_logic_vector((signals - 1) downto 0);
        variable tr_w_var:  std_logic;

        variable db_d_var:  std_logic_vector((signals - 1) downto 0);
        variable db_e_var:  std_logic_vector((signals - 1) downto 0);
        variable db_r_var:  std_logic_vector((signals - 1) downto 0);
        variable db_f_var:  std_logic_vector((signals - 1) downto 0);
        variable db_w_var:  std_logic;

        variable tx_b_var:  std_logic;
        variable tx_w_var:  std_logic;
        variable tx_d_var:  byte;

        variable sp_b_var:  std_logic;
        variable sp_d_var:  std_logic;

        variable t_var:     time;
    begin
        file_open(data_file, "test_bench.dat", read_mode);

        while not endfile(data_file) loop
            readline(data_file, data_line);

            read(data_line, tr_d_var);
            read(data_line, tr_e_var);
            read(data_line, tr_r_var);
            read(data_line, tr_f_var);
            read(data_line, tr_w_var);

            read(data_line, db_d_var);
            read(data_line, db_e_var);
            read(data_line, db_r_var);
            read(data_line, db_f_var);
            read(data_line, db_w_var);

            read(data_line, tx_b_var);
            read(data_line, tx_w_var);
            hread(data_line, tx_d_var);

            read(data_line, sp_b_var);
            read(data_line, sp_d_var);

            read(data_line, t_var);
            
            if (t_var > now) then
                wait for t_var - now;
            end if;
            
            wait for 0.1 * gate_delay;
            
            assert tr_d_var = tr_d report "tr_d = " & to_string(tr_d)       & ", but should be " & to_string(tr_d_var)       severity error;
            assert tr_e_var = tr_e report "tr_e = " & to_string(tr_e)       & ", but should be " & to_string(tr_e_var)       severity error;
            assert tr_r_var = tr_r report "tr_r = " & to_string(tr_r)       & ", but should be " & to_string(tr_r_var)       severity error;
            assert tr_f_var = tr_f report "tr_f = " & to_string(tr_f)       & ", but should be " & to_string(tr_f_var)       severity error;
            assert tr_w_var = tr_w report "tr_w = " & std_logic'image(tr_w) & ", but should be " & std_logic'image(tr_w_var) severity error;

            assert db_d_var = db_d report "db_d = " & to_string(db_d)       & ", but should be " & to_string(db_d_var)       severity error;
            assert db_e_var = db_e report "db_e = " & to_string(db_e)       & ", but should be " & to_string(db_e_var)       severity error;
            assert db_r_var = db_r report "db_r = " & to_string(db_r)       & ", but should be " & to_string(db_r_var)       severity error;
            assert db_f_var = db_f report "db_f = " & to_string(db_f)       & ", but should be " & to_string(db_f_var)       severity error;
            assert db_w_var = db_w report "db_w = " & std_logic'image(db_w) & ", but should be " & std_logic'image(db_w_var) severity error;

            assert tx_b_var = tx_b report "tx_b = " & std_logic'image(tx_b) & ", but should be " & std_logic'image(tx_b_var) severity error;
            assert tx_w_var = tx_w report "tx_w = " & std_logic'image(tx_w) & ", but should be " & std_logic'image(tx_w_var) severity error;
            assert tx_d_var = tx_d report "tx_d = " & to_string(tx_d)       & ", but should be " & to_string(tx_d_var)       severity error;

            assert sp_b_var = sp_b report "sp_b = " & std_logic'image(sp_b) & ", but should be " & std_logic'image(sp_b_var) severity error;
            assert sp_d_var = sp_d report "sp_d = " & std_logic'image(sp_d) & ", but should be " & std_logic'image(sp_d_var) severity error;

        end loop;
        
        file_close(data_file);
        wait;
    end process;

    process
        file     data_file: text;
        variable data_line: line;
    begin
        file_open(data_file, "trace.dat", write_mode);

        while end_flag = '0' loop
            wait on end_flag, tr_d, tr_e, tr_r, tr_f, tr_w, db_d, db_e, db_r, db_f, db_w, tx_b, tx_w, tx_d, sp_b, sp_d;

            write(data_line, tr_d);
            write(data_line, ' ');
            write(data_line, tr_e);
            write(data_line, ' ');
            write(data_line, tr_r);
            write(data_line, ' ');
            write(data_line, tr_f);
            write(data_line, ' ');
            write(data_line, tr_w);
            write(data_line, ' ');

            write(data_line, db_d);
            write(data_line, ' ');
            write(data_line, db_e);
            write(data_line, ' ');
            write(data_line, db_r);
            write(data_line, ' ');
            write(data_line, db_f);
            write(data_line, ' ');
            write(data_line, db_w);
            write(data_line, ' ');

            write(data_line, tx_b);
            write(data_line, ' ');
            write(data_line, tx_w);
            write(data_line, ' ');
            hwrite(data_line, tx_d);
            write(data_line, ' ');

            write(data_line, sp_b);
            write(data_line, ' ');
            write(data_line, sp_d);
            write(data_line, ' ');

            write(data_line, now);

            writeline(data_file, data_line);
        end loop;
        
        file_close(data_file);
        wait;
    end process;

end behav;
