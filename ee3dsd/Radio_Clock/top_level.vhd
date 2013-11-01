library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity top_level is

    generic
    (
        osc_clk_freq: positive := 100000000;  -- Hz
        sys_clk_freq: positive := 125000000;  -- Hz
        gate_delay:   time     := 0.1 ns;
        baud_rate:    positive := 57600;
        uptime_width: positive := 64;
        io_ports:     positive := 16;
        ed_width:     positive := 16;
        ts_offset:    positive := 24
    );

    port
    (
        clkin:    in  std_logic                                          :=            'X';  -- clock
        --pragma synthesis_off
        end_flag: in  std_logic                                          :=            'X';  -- stop clocks
        --pragma synthesis_on
        btnu:     in  std_logic                                          :=            'X';  -- button up
        btnd:     in  std_logic                                          :=            'X';  -- button down
        btnc:     in  std_logic                                          :=            'X';  -- button centre
        btnl:     in  std_logic                                          :=            'X';  -- button left
        btnr:     in  std_logic                                          :=            'X';  -- button right
        sw:       in  std_logic_vector(7 downto 0)                       := (others => 'X'); -- switches
        an:       out std_logic_vector(3 downto 0)                       := (others => '1'); -- anodes   7 segment display
        ka:       out std_logic_vector(7 downto 0)                       := (others => '1'); -- kathodes 7 segment display
        ld:       out std_logic_vector(7 downto 0)                       := (others => '0'); -- leds
        rx:       in  std_logic                                          :=            'X';  -- uart rx 
        tx:       out std_logic                                          :=            '1';  -- uart tx
        msf:      in  std_logic                                          :=            'X';  -- msf signal
        dcf:      in  std_logic                                          :=            'X'   -- dcf signal
   );

end top_level;

architecture behav of top_level is

    component dcf_bits_ipc

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock
        
        di:  in  byte      := byte_unknown; -- data in
        si:  in  std_logic := 'X';          -- start of second in
        bo:  out std_logic := '0';          -- bit out
        tr:  out std_logic := '0'           -- new bit trigger
    );

    end component;

    component dcf_decode_ipc

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst:    in  std_logic                    := 'X'; -- reset
        clk:    in  std_logic                    := 'X'; -- clock
        
        si:     in  std_logic                    := 'X'; -- start of second in
        mi:     in  std_logic                    := 'X'; -- start of minute in
        bi:     in  std_logic                    := 'X'; -- bit in
        year:   out bcd_digit_vector(3 downto 0) := (3 => bcd_two, 2 => bcd_zero, others => bcd_minus);
        month:  out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        day:    out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        hour:   out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        minute: out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        second: out bcd_digit_vector(1 downto 0) := (others => bcd_zero);  
        tr:     out std_logic                    := '0'  -- new bit trigger
    );

    end component;

    component dcf_sync_ipc

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock
        
        di:  in  byte      := byte_unknown; -- data in
        so:  out std_logic := '0';          -- start of second
        mo:  out std_logic := '0'           -- start of minute
    );

    end component;

    component ddrserdes_ipc

    generic
    (
        gate_delay:   time                                       := 1 ns;
        ibuf_len:     positive                                   := 2
    );

    port
    (
        clk_par:  in  std_logic                                  := 'X';      -- parallel clock in
        clk_2par: in  std_logic                                  := 'X';      -- 2 x parallel clock in
        data_in:  in  std_logic                                  := 'X';      -- serial data in
        data_out: out byte                                       := byte_null -- parallel data out
    );

    end component;

    component edge_detector_ipc

    generic
    (
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock
        
        di:  in  byte      := byte_unknown; -- data in
        do:  out byte      := byte_null;    -- data out
        ed:  out std_logic := '0'           -- edge detected
    );

    end component;

    component msf_bits_ipc

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock
        
        di:  in  byte      := byte_unknown; -- data in
        si:  in  std_logic := 'X';          -- start of second in
        bao: out std_logic := '0';          -- bit A out
        bbo: out std_logic := '0';          -- bit B out
        tr:  out std_logic := '0'           -- new bit trigger
    );

    end component;

    component msf_decode_ipc

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst:    in  std_logic                    := 'X'; -- reset
        clk:    in  std_logic                    := 'X'; -- clock
        
        si:     in  std_logic                    := 'X'; -- start of second in
        mi:     in  std_logic                    := 'X'; -- start of minute in
        bai:    in  std_logic                    := 'X'; -- bit A in
        bbi:    in  std_logic                    := 'X'; -- bit B in
        year:   out bcd_digit_vector(3 downto 0) := (3 => bcd_two, 2 => bcd_zero, others => bcd_minus);
        month:  out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        day:    out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        hour:   out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        minute: out bcd_digit_vector(1 downto 0) := (others => bcd_minus);
        second: out bcd_digit_vector(1 downto 0) := (others => bcd_zero);  
        tr:     out std_logic                    := '0'  -- new bit trigger
    );

    end component;

    component msf_sync_ipc

    generic
    (
        clk_freq:   positive := 125000000; -- Hz
        gate_delay: time     := 1 ns
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock
        
        di:  in  byte      := byte_unknown; -- data in
        so:  out std_logic := '0';          -- start of second
        mo:  out std_logic := '0'           -- start of minute
    );

    end component;

    component pll_ipc

    generic
    (
        clk_freq:     positive                 := 100000000;  -- Hz
        gate_delay:   time                     := 1 ns;
        clk_mult:     positive                 := 1; -- Range 1 to  64
        clk_div:      positive                 := 1; -- Range 1 to  52
        clk_div0:     positive                 := 1; -- Range 1 to 128
        clk_div1:     positive                 := 1; -- Range 1 to 128
        clk_div2:     positive                 := 1; -- Range 1 to 128
        clk_div3:     positive                 := 1; -- Range 1 to 128
        clk_div4:     positive                 := 1; -- Range 1 to 128
        clk_div5:     positive                 := 1  -- Range 1 to 128
    );

    port
    (
        clkin:    in  std_logic                := 'X';  -- clock in
        --pragma synthesis_off
        end_flag: in  std_logic                := 'X';  -- stop clocks
        --pragma synthesis_on
        clk0:     out std_logic                := '0';  -- clock 0 out
        clk1:     out std_logic                := '0';  -- clock 1 out
        clk2:     out std_logic                := '0';  -- clock 2 out
        clk3:     out std_logic                := '0';  -- clock 3 out
        clk4:     out std_logic                := '0';  -- clock 4 out
        clk5:     out std_logic                := '0';  -- clock 5 out
        strobe:   out std_logic                := '0'   -- strobe
    );

    end component;

    component serdes_ipc

    generic
    (
        gate_delay:   time      := 1 ns
    );

    port
    (
        clk_ser:  in  std_logic := 'X';      -- serial clock in
        clk_par:  in  std_logic := 'X';      -- parallel clock in
        clk_2par: in  std_logic := 'X';      -- 2 x parallel clock in
        strobe:   in  std_logic := 'X';      -- strobe
        data_in:  in  std_logic := 'X';      -- serial data in
        data_out: out byte      := byte_null -- parallel data out
    );

    end component;

    component serial_port_ipc

    generic
    (
        clk_freq:   positive := 125000000;  -- Hz
        gate_delay: time     := 0.1 ns;
        baud_rate:  positive := 57600
    );

    port
    (
        rst: in  std_logic := 'X';          -- reset
        clk: in  std_logic := 'X';          -- clock

        wr:  in  std_logic := 'X';          -- write
        di:  in  byte      := byte_unknown; -- data in
        bsy: out std_logic := '0';          -- busy
        tx:  out std_logic := '1'           -- serial out
    );

    end component;

    component ssg_ipc

    generic
    (
        clk_freq:   positive := 125000000;  -- Hz
        gate_delay: time     := 0.1 ns
    );

    port
    (
        clk: in  std_logic                    :=            'X';           -- clock
        wr:  in  std_logic                    :=            'X';           -- write
        di:  in  byte_vector(3 downto 0)      := (others => byte_unknown); -- data in
        an:  out std_logic_vector(3 downto 0) := (others => '1');          -- anodes   7 segment display
        ka:  out std_logic_vector(7 downto 0) := (others => '1')           -- kathodes 7 segment display
    );

    end component;

    component uptime_counter_ipc

    generic
    (
        gate_delay: time                                := 1 ns;
        width:      positive                            := 64
    );

    port
    (
        rst: in  std_logic                              := 'X';             -- reset
        clk: in  std_logic                              := 'X';             -- clock
        
        cnt: out std_logic_vector((width - 1) downto 0) := (others => '0')  -- clock cycle counter out
    );

    end component;

    type event_record is array (io_ports - 1 downto 0) of byte_vector(9 downto 0);
    type ex_ptr_type  is array (2 downto 0) of unsigned(3 downto 0);
    
    constant msg_len:      natural                                       := 80;
    constant msg_bits:     positive                                      := 7;

    signal clk_1000_MHz:   std_logic                                     :=            'X';
    signal clk_250_MHz:    std_logic                                     :=            'X';
    signal clk_125_MHz:    std_logic                                     :=            'X';
    signal pll_strobe:     std_logic                                     :=            'X';
    signal uptime:         std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal ssg_wr:         std_logic                                     :=            '0';
    signal ssg_di:         byte_vector(3 downto 0)                       := (others => byte_255);
    signal sf_wr:          std_logic                                     :=            '0';
    signal sf_di:          byte_vector(0 downto 0)                       := (others => byte_unknown);
    signal sf_ff:          std_logic                                     :=            'X';
    signal sf_rd:          std_logic_vector(1 downto 0)                  := (others => '0');
    signal sf_do:          byte_vector(0 downto 0)                       := (others => byte_unknown);
    signal sf_fe:          std_logic                                     :=            'X';
    signal sp_wr:          std_logic                                     :=            '0';
    signal sp_di:          byte                                          :=            byte_unknown;
    signal sp_bsy:         std_logic                                     :=            'X';
    signal io_di:          std_logic_vector(io_ports - 1 downto 0)       := (others => 'X');
    signal sd_do:          byte_vector     (io_ports - 1 downto 0)       := (others => byte_unknown);
    signal ed_do:          byte_vector     (io_ports - 1 downto 0)       := (others => byte_unknown);
    signal ed_ed:          std_logic_vector(io_ports - 1 downto 0)       := (others => 'X');
    signal ef_di:          event_record                                  := (others => (others => byte_unknown));
    signal ef_ff:          std_logic_vector(io_ports - 1 downto 0)       := (others => 'X');
    signal ef_do:          event_record                                  := (others => (others => byte_unknown));
    signal ef_rd:          std_logic_vector(io_ports - 1 downto 0)       := (others => 'X');
    signal ef_fe:          std_logic_vector(io_ports - 1 downto 0)       := (others => 'X');
    signal gf_wr:          std_logic                                     :=            'X';
    signal gf_di:          byte_vector(9 downto 0)                       := (others => byte_unknown);
    signal gf_ff:          std_logic                                     :=            'X';
    signal gf_do:          byte_vector(9 downto 0)                       := (others => byte_unknown);
    signal gf_rd:          std_logic                                     :=            'X';
    signal gf_fe:          std_logic                                     :=            'X';
    signal ex_ptr:         ex_ptr_type                                   := (others => (others => '0'));
    signal ex_wr:          std_logic_vector(2 downto 1)                  := (others => '0');
    signal so_data:        byte_vector(0 to msg_len - 1)                 := (16 => "00100000", 
                                                                             19 => "00100000", 
                                                                             22 => "00100000", 
                                                                             23 => "00100000", 
                                                                             24 => "00100000", 
                                                                             25 => "00100000", 
                                                                             29 => "00100000", 
                                                                             31 => "00100000", 
                                                                             35 => "00100000", 
                                                                             36 => "00100000", 
                                                                             37 => "00100000", 
                                                                             38 => "00100000", 
                                                                             39 => "00000100", 
                                                                             others => byte_null);
    signal so_cnt:         unsigned(msg_bits - 1 downto 0)               := to_unsigned(msg_len, msg_bits);
    signal ld_ed:          std_logic_vector(io_ports - 1 downto 0)       := (others => '0');
    signal ee_ed:          std_logic_vector(io_ports - 1 downto 0)       := (others => '0');
    signal ld_reg:         std_logic_vector(7 downto 0)                  := (others => '0');
    signal ld_mask:        std_logic_vector(3 downto 0)                  := "1000";
    signal dcf_so:         std_logic                                     :=            'X';
    signal dcf_buf_so:     std_logic                                     :=            '0';
    signal dcf_buf_so_ts:  std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal dcf_buf_so_ack: std_logic                                     :=            'X';
    signal dcf_mo:         std_logic                                     :=            'X';
    signal dcf_buf_mo:     std_logic                                     :=            '0';
    signal dcf_buf_mo_ts:  std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal dcf_buf_mo_ack: std_logic                                     :=            'X';
    signal dcf_bo:         std_logic                                     :=            'X';
    signal dcf_bo_tr:      std_logic                                     :=            'X';
    signal dcf_buf_bo:     std_logic                                     :=            '0';
    signal dcf_buf_bo_tr:  std_logic                                     :=            '0';
    signal dcf_buf_bo_ts:  std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal dcf_buf_bo_ack: std_logic                                     :=            'X';
    signal dcf_year:       bcd_digit_vector(3 downto 0)                  := (others => bcd_unknown);
    signal dcf_month:      bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_day:        bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_hour:       bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_minute:     bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_second:     bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_dt_tr:      std_logic                                     :=            'X';
    signal dcf_buf_year:   bcd_digit_vector(3 downto 0)                  := (others => bcd_unknown);
    signal dcf_buf_month:  bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_buf_day:    bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_buf_hour:   bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_buf_minute: bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_buf_second: bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal dcf_buf_dt_tr:  std_logic                                     :=            'X';
    signal dcf_buf_dt_ts:  std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal dcf_buf_dt_ack: std_logic                                     :=            'X';
    signal msf_so:         std_logic                                     :=            'X';
    signal msf_buf_so:     std_logic                                     :=            '0';
    signal msf_buf_so_ts:  std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal msf_buf_so_ack: std_logic                                     :=            'X';
    signal msf_mo:         std_logic                                     :=            'X';
    signal msf_buf_mo:     std_logic                                     :=            '0';
    signal msf_buf_mo_ts:  std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal msf_buf_mo_ack: std_logic                                     :=            'X';
    signal msf_bao:        std_logic                                     :=            'X';
    signal msf_bbo:        std_logic                                     :=            'X';
    signal msf_bo_tr:      std_logic                                     :=            'X';
    signal msf_buf_bao:    std_logic                                     :=            '0';
    signal msf_buf_bbo:    std_logic                                     :=            '0';
    signal msf_buf_bo_tr:  std_logic                                     :=            '0';
    signal msf_buf_bo_ts:  std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal msf_buf_bo_ack: std_logic                                     :=            'X';
    signal msf_year:       bcd_digit_vector(3 downto 0)                  := (others => bcd_unknown);
    signal msf_month:      bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_day:        bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_hour:       bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_minute:     bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_second:     bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_dt_tr:      std_logic                                     :=            'X';
    signal msf_buf_year:   bcd_digit_vector(3 downto 0)                  := (others => bcd_unknown);
    signal msf_buf_month:  bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_buf_day:    bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_buf_hour:   bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_buf_minute: bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_buf_second: bcd_digit_vector(1 downto 0)                  := (others => bcd_unknown);
    signal msf_buf_dt_tr:  std_logic                                     :=            'X';
    signal msf_buf_dt_ts:  std_logic_vector(uptime_width - 1 downto 0)   := (others => 'X');
    signal msf_buf_dt_ack: std_logic                                     :=            'X';

begin

    pll_unit: pll_ipc
    generic map
    (
        clk_freq   => osc_clk_freq,
        gate_delay => gate_delay,
        clk_mult   =>  10, -- 1000 MHz
        clk_div    =>   1, -- 1000 MHz
        clk_div0   =>   1, -- 1000 MHz
        clk_div1   =>   4, --  250 MHz
        clk_div2   =>   8, --  125 MHz
        clk_div3   =>   8, --  125 MHz
        clk_div4   =>   8, --  125 MHz
        clk_div5   =>   8  --  125 MHz
    )
    port map
    (
        clkin      => clkin,
        --pragma synthesis_off
        end_flag   => end_flag,
        --pragma synthesis_on
        clk0       => clk_1000_MHz,
        clk1       => clk_250_MHz,
        clk2       => clk_125_MHz,
        strobe     => pll_strobe
    );
    
    uptime_unit: uptime_counter_ipc
    generic map
    (
        gate_delay => gate_delay,
        width      => uptime_width - 3
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        cnt        => uptime(uptime_width - 1 downto 3)
    );

    uptime(2 downto 0) <= (others => '0');
    
    ssg_unit: ssg_ipc
    generic map
    (
        clk_freq   => sys_clk_freq,
        gate_delay => gate_delay
    )
    port map
    (
        clk        => clk_125_MHz,
        wr         => ssg_wr,
        di         => ssg_di,
        an         => an,
        ka         => ka
    );

    serial_fifo_unit: entity WORK.fifo
    generic map
    (
        gate_delay => gate_delay,
        data_width => 1,
        fifo_depth => 1024
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        wr         => sf_wr,
        di         => sf_di,
        ff         => sf_ff,
        rd         => sf_rd(0),
        do         => sf_do,
        fe         => sf_fe
    );

    serial_port_unit: serial_port_ipc
    generic map
    (
        clk_freq   => sys_clk_freq,
        gate_delay => gate_delay,
        baud_rate  => baud_rate
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        wr         => sp_wr,
        di         => sp_di,
        bsy        => sp_bsy,
        tx         => tx
    );

    io_di(15 downto  8) <= sw;
    io_di( 7 downto  0) <= (btnu, btnd, btnc, btnl, btnr, rx, dcf, msf);

    fast_io_units: for i in 0 to 1 generate

        serdes_unit: serdes_ipc
        generic map
        (
            gate_delay => gate_delay
        )
        port map
        (
            clk_ser    => clk_1000_MHz,
            clk_par    => clk_125_MHz,
            clk_2par   => clk_250_MHz,
            strobe     => pll_strobe,
            data_in    => io_di(i),
            data_out   => sd_do(i)
        );
        
    end generate;
    
    slow_io_units: for i in 2 to 15 generate
    
        ddrserdes_unit: ddrserdes_ipc
        generic map
        (
            gate_delay => gate_delay,
            ibuf_len   => 4
        )
        port map
        (
            clk_par    => clk_125_MHz,
            clk_2par   => clk_250_MHz,
            data_in    => io_di(i),
            data_out   => sd_do(i)
        );

    end generate;
    
    edge_detect_and_fifo_units: for i in 0 to 15 generate

        edge_detect_unit: edge_detector_ipc
        generic map
        (
            gate_delay => gate_delay
        )
        port map
        (
            rst        => '0',
            clk        => clk_125_MHz,
            di         => sd_do(i),
            do         => ed_do(i),
            ed         => ed_ed(i)
        );
        
        event_fifo_unit: entity WORK.fifo
        generic map
        (
            gate_delay => gate_delay,
            data_width => 10,
            fifo_depth => 16
        )
        port map
        (
            rst        => '0',
            clk        => clk_125_MHz,
            wr         => ld_ed(i),
            di         => ef_di(i),
            ff         => ef_ff(i),
            rd         => ef_rd(i),
            do         => ef_do(i),
            fe         => ef_fe(i)
        );
        
        process (uptime, ed_do(i))
        begin
        
            ef_di(i)(9)          <= std_logic_vector(to_unsigned(i, 8));
            ef_di(i)(8)          <= ed_do(i);

            for j in 7 downto 0 loop

                ef_di(i)(j) <= uptime(8 * j + 7 downto 8 * j);

            end loop;
        
        end process;

    end generate;
    
    global_fifo_unit: entity WORK.fifo
    generic map
    (
        gate_delay => gate_delay,
        data_width => 10,
        fifo_depth => 64
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        wr         => gf_wr,
        di         => gf_di,
        ff         => gf_ff,
        rd         => gf_rd,
        do         => gf_do,
        fe         => gf_fe
    );
    
    dcf_sync_unit: entity WORK.dcf_sync
    generic map
    (
        clk_freq   => sys_clk_freq,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        di         => sd_do(1),
        so         => dcf_so,
        mo         => dcf_mo
    );

    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            if (dcf_so = '1') then

                dcf_buf_so    <= '1'    after gate_delay;
                dcf_buf_so_ts <= uptime after gate_delay;

            end if;
            
            if (dcf_buf_so_ack = '1') then

                dcf_buf_so    <= '0'    after gate_delay;

            end if;

            if (dcf_mo = '1') then

                dcf_buf_mo    <= '1'    after gate_delay;
                dcf_buf_mo_ts <= uptime after gate_delay;

            end if;
            
            if (dcf_buf_mo_ack = '1') then

                dcf_buf_mo    <= '0'    after gate_delay;

            end if;

        end if;
        
    end process;
        
    msf_sync_unit: msf_sync_ipc
    generic map
    (
        clk_freq   => sys_clk_freq,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        di         => sd_do(0),
        so         => msf_so,
        mo         => msf_mo
    );

    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            if (msf_so = '1') then

                msf_buf_so    <= '1'    after gate_delay;
                msf_buf_so_ts <= uptime after gate_delay;

            end if;
            
            if (msf_buf_so_ack = '1') then

                msf_buf_so    <= '0'    after gate_delay;

            end if;

            if (msf_mo = '1') then

                msf_buf_mo    <= '1'    after gate_delay;
                msf_buf_mo_ts <= uptime after gate_delay;

            end if;
            
            if (msf_buf_mo_ack = '1') then

                msf_buf_mo    <= '0'    after gate_delay;

            end if;

        end if;
        
    end process;
        
    dcf_bits_unit: dcf_bits_ipc
    generic map
    (
        clk_freq   => sys_clk_freq,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        di         => sd_do(1),
        si         => dcf_so,
        bo         => dcf_bo,
        tr         => dcf_bo_tr
    );

    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            if (dcf_bo_tr = '1') then

                dcf_buf_bo_tr <= '1'    after gate_delay;
                dcf_buf_bo    <= dcf_bo after gate_delay;
                dcf_buf_bo_ts <= uptime after gate_delay;

            end if;
            
            if (dcf_buf_bo_ack = '1') then

                dcf_buf_bo_tr <= '0'    after gate_delay;

            end if;

        end if;
        
    end process;
        
    msf_bits_unit: msf_bits_ipc
    generic map
    (
        clk_freq   => sys_clk_freq,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        di         => sd_do(0),
        si         => msf_so,
        bao        => msf_bao,
        bbo        => msf_bbo,
        tr         => msf_bo_tr
    );

    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            if (msf_bo_tr = '1') then

                msf_buf_bo_tr <= '1'     after gate_delay;
                msf_buf_bao   <= msf_bao after gate_delay;
                msf_buf_bbo   <= msf_bbo after gate_delay;
                msf_buf_bo_ts <= uptime  after gate_delay;

            end if;
            
            if (msf_buf_bo_ack = '1') then

                msf_buf_bo_tr <= '0'     after gate_delay;

            end if;

        end if;
        
    end process;
        
    dcf_decode_unit: dcf_decode_ipc
    generic map
    (
        clk_freq   => sys_clk_freq,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        si         => dcf_so,
        mi         => dcf_mo,
        bi         => dcf_bo,
        year       => dcf_year,
        month      => dcf_month,
        day        => dcf_day,
        hour       => dcf_hour,
        minute     => dcf_minute,
        second     => dcf_second,
        tr         => dcf_dt_tr
    );

    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            if (dcf_dt_tr = '1') then

                dcf_buf_dt_tr  <= '1'        after gate_delay;
                dcf_buf_year   <= dcf_year   after gate_delay;
                dcf_buf_month  <= dcf_month  after gate_delay;
                dcf_buf_day    <= dcf_day    after gate_delay;
                dcf_buf_hour   <= dcf_hour   after gate_delay;
                dcf_buf_minute <= dcf_minute after gate_delay;
                dcf_buf_second <= dcf_second after gate_delay;
                dcf_buf_dt_ts  <= uptime     after gate_delay;

            end if;
            
            if (dcf_buf_dt_ack = '1') then

                dcf_buf_dt_tr <= '0'         after gate_delay;

            end if;

        end if;
        
    end process;
        
    msf_decode_unit: msf_decode_ipc
    generic map
    (
        clk_freq   => sys_clk_freq,
        gate_delay => gate_delay
    )
    port map
    (
        rst        => '0',
        clk        => clk_125_MHz,
        si         => msf_so,
        mi         => msf_mo,
        bai        => msf_bao,
        bbi        => msf_bbo,
        year       => msf_year,
        month      => msf_month,
        day        => msf_day,
        hour       => msf_hour,
        minute     => msf_minute,
        second     => msf_second,
        tr         => msf_dt_tr
    );

    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            if (msf_dt_tr = '1') then

                msf_buf_dt_tr  <= '1'        after gate_delay;
                msf_buf_year   <= msf_year   after gate_delay;
                msf_buf_month  <= msf_month  after gate_delay;
                msf_buf_day    <= msf_day    after gate_delay;
                msf_buf_hour   <= msf_hour   after gate_delay;
                msf_buf_minute <= msf_minute after gate_delay;
                msf_buf_second <= msf_second after gate_delay;
                msf_buf_dt_ts  <= uptime     after gate_delay;

            end if;
            
            if (msf_buf_dt_ack = '1') then

                msf_buf_dt_tr <= '0'         after gate_delay;

            end if;

        end if;
        
    end process;
        
    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            ef_rd  <= (others => '0')                      after gate_delay;
            ex_ptr <= ex_ptr(1 downto 0) & (ex_ptr(0) + 1) after gate_delay;
            ex_wr  <= ex_wr(1) & '0'                       after gate_delay;
            gf_wr  <= '0'                                  after gate_delay;
            gf_di  <= (others => byte_null)                after gate_delay;
            
            if (ef_fe(to_integer(ex_ptr(0))) = '0') then

                ef_rd(to_integer(ex_ptr(0))) <= '1'        after gate_delay;
                ex_wr(1)                     <= '1'        after gate_delay;

            end if;

            if (ex_wr(2) = '1') then
            
                gf_wr <= '1'                               after gate_delay;
                gf_di <= ef_do(to_integer(ex_ptr(2)))      after gate_delay;
            
            end if;

        end if;
        
    end process;

    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            gf_rd          <= '0'                                                                  after gate_delay;
            sf_wr          <= '0'                                                                  after gate_delay;
            sf_di          <= (others => byte_null)                                                after gate_delay;
            dcf_buf_so_ack <= '0'                                                                  after gate_delay;
            dcf_buf_mo_ack <= '0'                                                                  after gate_delay;
            dcf_buf_bo_ack <= '0'                                                                  after gate_delay;
            dcf_buf_dt_ack <= '0'                                                                  after gate_delay;
            msf_buf_so_ack <= '0'                                                                  after gate_delay;
            msf_buf_mo_ack <= '0'                                                                  after gate_delay;
            msf_buf_bo_ack <= '0'                                                                  after gate_delay;
            msf_buf_dt_ack <= '0'                                                                  after gate_delay;
        
            if (so_cnt = msg_len) then
            
                if (gf_fe = '0') then
                
                    gf_rd  <= '1'                                                                  after gate_delay;
                    so_cnt <= to_unsigned(msg_len + 1, msg_bits)                                   after gate_delay;

                elsif (msf_buf_so = '1') and sd_do(5 + 8)(7) = '1' then

                    so_cnt <= to_unsigned(msg_len + 3, msg_bits)                                   after gate_delay;

                elsif (dcf_buf_so = '1') and sd_do(4 + 8)(7) = '1' then

                    so_cnt <= to_unsigned(msg_len + 4, msg_bits)                                   after gate_delay;

                elsif (msf_buf_mo = '1') and sd_do(5 + 8)(7) = '1' then

                    so_cnt <= to_unsigned(msg_len + 5, msg_bits)                                   after gate_delay;

                elsif (dcf_buf_mo = '1') and sd_do(4 + 8)(7) = '1' then

                    so_cnt <= to_unsigned(msg_len + 6, msg_bits)                                   after gate_delay;

                elsif (msf_buf_bo_tr = '1') and sd_do(3 + 8)(7) = '1' then

                    so_cnt <= to_unsigned(msg_len + 7, msg_bits)                                   after gate_delay;

                elsif (dcf_buf_bo_tr = '1') and sd_do(2 + 8)(7) = '1' then

                    so_cnt <= to_unsigned(msg_len + 8, msg_bits)                                   after gate_delay;

                elsif (msf_buf_dt_tr = '1') and sd_do(1 + 8)(7) = '1' then

                    so_cnt <= to_unsigned(msg_len + 9, msg_bits)                                   after gate_delay;

                elsif (dcf_buf_dt_tr = '1') and sd_do(0 + 8)(7) = '1' then

                    so_cnt <= to_unsigned(msg_len + 10, msg_bits)                                  after gate_delay;

                end if;

            elsif (so_cnt = msg_len + 1) then
            
                so_cnt      <= to_unsigned(msg_len + 2, msg_bits)                                  after gate_delay;

            elsif (so_cnt = msg_len + 2) then
            
                so_cnt      <= to_unsigned(0, msg_bits)                                            after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(gf_do(7 - i)(7 downto 4)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(gf_do(7 - i)(3 downto 0)))) after gate_delay;
                
                end loop;

                so_data(16) <= byte_space                                                          after gate_delay;

                so_data(17) <= byte_hex(to_integer(unsigned(gf_do(9)(7 downto 4))))                after gate_delay;
                so_data(18) <= byte_hex(to_integer(unsigned(gf_do(9)(3 downto 0))))                after gate_delay;

                so_data(19) <= byte_space                                                          after gate_delay;
                
                so_data(20) <= byte_hex(to_integer(unsigned(gf_do(8)(7 downto 4))))                after gate_delay;
                so_data(21) <= byte_hex(to_integer(unsigned(gf_do(8)(3 downto 0))))                after gate_delay;

                case to_integer(unsigned(gf_do(9))) is
                
                    when 16#00# =>

                        so_data(22 to 38) <= to_byte_vector(" -- MSF Signal   ")                   after gate_delay;

                    when 16#01# =>

                        so_data(22 to 38) <= to_byte_vector(" -- DCF Signal   ")                   after gate_delay;

                    when 16#02# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Serial RX    ")                   after gate_delay;

                    when 16#03# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Button Right ")                   after gate_delay;

                    when 16#04# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Button Left  ")                   after gate_delay;

                    when 16#05# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Button Centre")                   after gate_delay;

                    when 16#06# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Button Down  ")                   after gate_delay;

                    when 16#07# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Button Up    ")                   after gate_delay;

                    when 16#08# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Switch 0     ")                   after gate_delay;

                    when 16#09# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Switch 1     ")                   after gate_delay;

                    when 16#0A# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Switch 2     ")                   after gate_delay;

                    when 16#0B# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Switch 3     ")                   after gate_delay;

                    when 16#0C# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Switch 4     ")                   after gate_delay;

                    when 16#0D# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Switch 5     ")                   after gate_delay;

                    when 16#0E# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Switch 6     ")                   after gate_delay;

                    when 16#0F# =>

                        so_data(22 to 38) <= to_byte_vector(" -- Switch 7     ")                   after gate_delay;
                        
                    when others =>

                        so_data(22 to 38) <= to_byte_vector("                 ")                   after gate_delay;
                        
                end case;

                so_data(39) <= byte_CR                                                             after gate_delay;
                so_data(40) <= byte_LF                                                             after gate_delay;
                
                for i in 41 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            elsif (so_cnt = msg_len + 3) then
            
                so_cnt         <= to_unsigned(0, msg_bits)                                         after gate_delay;
                msf_buf_so_ack <= '1'                                                              after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(msf_buf_so_ts(63 - 8 * i downto 60 - 8 * i)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(msf_buf_so_ts(59 - 8 * i downto 56 - 8 * i)))) after gate_delay;
                
                end loop;

                so_data(16 to 48) <= to_byte_vector(" 10    -- MSF - Start of Second" & CR & LF)   after gate_delay;
                
                for i in 49 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            elsif (so_cnt = msg_len + 4) then
            
                so_cnt         <= to_unsigned(0, msg_bits)                                         after gate_delay;
                dcf_buf_so_ack <= '1'                                                              after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(dcf_buf_so_ts(63 - 8 * i downto 60 - 8 * i)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(dcf_buf_so_ts(59 - 8 * i downto 56 - 8 * i)))) after gate_delay;
                
                end loop;

                so_data(16 to 48) <= to_byte_vector(" 20    -- DCF - Start of Second" & CR & LF)   after gate_delay;
                
                for i in 49 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            elsif (so_cnt = msg_len + 5) then
            
                so_cnt         <= to_unsigned(0, msg_bits)                                         after gate_delay;
                msf_buf_mo_ack <= '1'                                                              after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(msf_buf_mo_ts(63 - 8 * i downto 60 - 8 * i)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(msf_buf_mo_ts(59 - 8 * i downto 56 - 8 * i)))) after gate_delay;
                
                end loop;

                so_data(16 to 48) <= to_byte_vector(" 11    -- MSF - Start of Minute" & CR & LF)   after gate_delay;
                
                for i in 49 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            elsif (so_cnt = msg_len + 6) then
            
                so_cnt         <= to_unsigned(0, msg_bits)                                         after gate_delay;
                dcf_buf_mo_ack <= '1'                                                              after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(dcf_buf_mo_ts(63 - 8 * i downto 60 - 8 * i)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(dcf_buf_mo_ts(59 - 8 * i downto 56 - 8 * i)))) after gate_delay;
                
                end loop;

                so_data(16 to 48) <= to_byte_vector(" 21    -- DCF - Start of Minute" & CR & LF)   after gate_delay;
                
                for i in 49 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            elsif (so_cnt = msg_len + 7) then
            
                so_cnt         <= to_unsigned(0, msg_bits)                                         after gate_delay;
                msf_buf_bo_ack <= '1'                                                              after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(msf_buf_bo_ts(63 - 8 * i downto 60 - 8 * i)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(msf_buf_bo_ts(59 - 8 * i downto 56 - 8 * i)))) after gate_delay;
                
                end loop;

                so_data(16 to 19) <= to_byte_vector(" 12 ")                                        after gate_delay;
                
                if (msf_buf_bao = '0') then

                    so_data(20)   <= byte_zero                                                     after gate_delay;

                else

                    so_data(20)   <= byte_one                                                      after gate_delay;

                end if;

                if (msf_buf_bbo = '0') then

                    so_data(21)   <= byte_zero                                                     after gate_delay;

                else

                    so_data(21)   <= byte_one                                                      after gate_delay;

                end if;

                so_data(22 to 45) <= to_byte_vector(" -- MSF - Decoded Bits" & CR & LF)            after gate_delay;
                
                for i in 46 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            elsif (so_cnt = msg_len + 8) then
            
                so_cnt         <= to_unsigned(0, msg_bits)                                         after gate_delay;
                dcf_buf_bo_ack <= '1'                                                              after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(dcf_buf_bo_ts(63 - 8 * i downto 60 - 8 * i)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(dcf_buf_bo_ts(59 - 8 * i downto 56 - 8 * i)))) after gate_delay;
                
                end loop;

                so_data(16 to 20) <= to_byte_vector(" 22  ")                                       after gate_delay;

                if (dcf_buf_bo = '0') then

                    so_data(21)   <= byte_zero                                                     after gate_delay;

                else

                    so_data(21)   <= byte_one                                                      after gate_delay;

                end if;

                so_data(22 to 44) <= to_byte_vector(" -- DCF - Decoded Bit" & CR & LF)             after gate_delay;
                
                for i in 45 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            elsif (so_cnt = msg_len + 9) then
            
                so_cnt         <= to_unsigned(0, msg_bits)                                         after gate_delay;
                msf_buf_dt_ack <= '1'                                                              after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(msf_buf_dt_ts(63 - 8 * i downto 60 - 8 * i)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(msf_buf_dt_ts(59 - 8 * i downto 56 - 8 * i)))) after gate_delay;
                
                end loop;

                so_data(16 to 31) <= to_byte_vector(" 13    -- MSF - ")                            after gate_delay;
                so_data(32)       <= byte_bcd(to_integer(msf_buf_day(1)))                          after gate_delay;
                so_data(33)       <= byte_bcd(to_integer(msf_buf_day(0)))                          after gate_delay;
                so_data(34)       <= byte_bcd(to_integer(bcd_dot))                                 after gate_delay;
                so_data(35)       <= byte_bcd(to_integer(msf_buf_month(1)))                        after gate_delay;
                so_data(36)       <= byte_bcd(to_integer(msf_buf_month(0)))                        after gate_delay;
                so_data(37)       <= byte_bcd(to_integer(bcd_dot))                                 after gate_delay;
                so_data(38)       <= byte_bcd(to_integer(msf_buf_year(3)))                         after gate_delay;
                so_data(39)       <= byte_bcd(to_integer(msf_buf_year(2)))                         after gate_delay;
                so_data(40)       <= byte_bcd(to_integer(msf_buf_year(1)))                         after gate_delay;
                so_data(41)       <= byte_bcd(to_integer(msf_buf_year(0)))                         after gate_delay;
                so_data(42)       <= byte_bcd(to_integer(bcd_space))                               after gate_delay;
                so_data(43)       <= byte_bcd(to_integer(msf_buf_hour(1)))                         after gate_delay;
                so_data(44)       <= byte_bcd(to_integer(msf_buf_hour(0)))                         after gate_delay;
                so_data(45)       <= byte_bcd(to_integer(bcd_colon))                               after gate_delay;
                so_data(46)       <= byte_bcd(to_integer(msf_buf_minute(1)))                       after gate_delay;
                so_data(47)       <= byte_bcd(to_integer(msf_buf_minute(0)))                       after gate_delay;
                so_data(48)       <= byte_bcd(to_integer(bcd_colon))                               after gate_delay;
                so_data(49)       <= byte_bcd(to_integer(msf_buf_second(1)))                       after gate_delay;
                so_data(50)       <= byte_bcd(to_integer(msf_buf_second(0)))                       after gate_delay;
                so_data(51 to 52) <= to_byte_vector(CR & LF)                                       after gate_delay;
                
                for i in 53 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            elsif (so_cnt = msg_len + 10) then
            
                so_cnt         <= to_unsigned(0, msg_bits)                                         after gate_delay;
                dcf_buf_dt_ack <= '1'                                                              after gate_delay;
                
                for i in 0 to 7 loop
                
                    so_data(2 * i + 0) <= byte_hex(to_integer(unsigned(dcf_buf_dt_ts(63 - 8 * i downto 60 - 8 * i)))) after gate_delay;
                    so_data(2 * i + 1) <= byte_hex(to_integer(unsigned(dcf_buf_dt_ts(59 - 8 * i downto 56 - 8 * i)))) after gate_delay;
                
                end loop;

                so_data(16 to 31) <= to_byte_vector(" 23    -- DCF - ")                            after gate_delay;
                so_data(32)       <= byte_bcd(to_integer(dcf_buf_day(1)))                          after gate_delay;
                so_data(33)       <= byte_bcd(to_integer(dcf_buf_day(0)))                          after gate_delay;
                so_data(34)       <= byte_bcd(to_integer(bcd_dot))                                 after gate_delay;
                so_data(35)       <= byte_bcd(to_integer(dcf_buf_month(1)))                        after gate_delay;
                so_data(36)       <= byte_bcd(to_integer(dcf_buf_month(0)))                        after gate_delay;
                so_data(37)       <= byte_bcd(to_integer(bcd_dot))                                 after gate_delay;
                so_data(38)       <= byte_bcd(to_integer(dcf_buf_year(3)))                         after gate_delay;
                so_data(39)       <= byte_bcd(to_integer(dcf_buf_year(2)))                         after gate_delay;
                so_data(40)       <= byte_bcd(to_integer(dcf_buf_year(1)))                         after gate_delay;
                so_data(41)       <= byte_bcd(to_integer(dcf_buf_year(0)))                         after gate_delay;
                so_data(42)       <= byte_bcd(to_integer(bcd_space))                               after gate_delay;
                so_data(43)       <= byte_bcd(to_integer(dcf_buf_hour(1)))                         after gate_delay;
                so_data(44)       <= byte_bcd(to_integer(dcf_buf_hour(0)))                         after gate_delay;
                so_data(45)       <= byte_bcd(to_integer(bcd_colon))                               after gate_delay;
                so_data(46)       <= byte_bcd(to_integer(dcf_buf_minute(1)))                       after gate_delay;
                so_data(47)       <= byte_bcd(to_integer(dcf_buf_minute(0)))                       after gate_delay;
                so_data(48)       <= byte_bcd(to_integer(bcd_colon))                               after gate_delay;
                so_data(49)       <= byte_bcd(to_integer(dcf_buf_second(1)))                       after gate_delay;
                so_data(50)       <= byte_bcd(to_integer(dcf_buf_second(0)))                       after gate_delay;
                so_data(51 to 52) <= to_byte_vector(CR & LF)                                       after gate_delay;
                
                for i in 53 to msg_len - 1 loop
                
                    so_data(i) <= byte_null                                                        after gate_delay;
                    
                end loop;

            else
            
                if (sf_ff = '0') then
                
                    if (so_data(to_integer(so_cnt)) = byte_null) then

                        so_cnt   <= to_unsigned(msg_len, msg_bits)                                 after gate_delay;

                    else

                        so_cnt   <= so_cnt + 1                                                     after gate_delay;
                        sf_wr    <= '1'                                                            after gate_delay;
                        sf_di(0) <= so_data(to_integer(so_cnt))                                    after gate_delay;

                    end if;

                end if;

            end if;

        end if;
        
    end process;

    ee_ed(15 downto 2) <= (others => '1');
    ee_ed(          1) <= sd_do(6 + 8)(7); -- sw(6) -- DCF raw
    ee_ed(          0) <= sd_do(7 + 8)(7); -- sw(7) -- MSF raw

    ld_ed <= ed_ed and ee_ed;

    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then
        
            ssg_wr    <= '0';
        
            for i in 0 to 15 loop
            
                if (ld_ed(i) = '1') then

                    ld_reg <= ed_do(i);

                    ssg_wr <= '1';
                    
                    for j in 0 to 3 loop

                        ssg_di(j) <= ssg_hex(to_integer(unsigned(uptime(4 * j + ts_offset + 3 downto 4 * j + ts_offset))));

                    end loop;

                    exit;

                end if;

            end loop;

        end if;
        
    end process;
            
    process (clk_125_MHz)
    begin

        if clk_125_MHz'event and (clk_125_MHz = '1') then

            sf_rd   <= sf_rd(0) & '0'                   after gate_delay;
            sp_wr   <= '0'                              after gate_delay;
            sp_di   <= byte_null                        after gate_delay;
            ld_mask <= ld_mask(2 downto 0) & ld_mask(3) after gate_delay;

            if (sp_bsy = '0') and (sf_fe = '0') and (ld_mask(0) = '1') then
            
                sf_rd(0) <= '1'                         after gate_delay;
                
            end if;
            
            if (sf_rd(1) = '1') then
            
                sp_wr <= '1'                            after gate_delay;
                sp_di <= sf_do(0)                       after gate_delay;
                
            end if;

        end if;
        
    end process;
    
    ld <= ld_reg;
    
end behav;
