library IEEE;

use IEEE.std_logic_1164.all;
use WORK.util.all;

entity top_level is

    port
    (
        clk:  in  std_logic;                    -- clock
        btnu: in  std_logic;                    -- button up
        btnd: in  std_logic;                    -- button down
        btnc: in  std_logic;                    -- button centre
        btnl: in  std_logic;                    -- button left
        btnr: in  std_logic;                    -- button right
        sw:   in  std_logic_vector(7 downto 0); -- switches
        an:   out std_logic_vector(3 downto 0); -- anodes   7 segment display
        ka:   out std_logic_vector(7 downto 0); -- kathodes 7 segment display
        ld:   out std_logic_vector(7 downto 0); -- leds
        rx:   in  std_logic;                    -- uart rx 
        tx:   out std_logic;                    -- uart tx
        msf:  in  std_logic;                    -- msf signal
        dcf:  in  std_logic                     -- dcf signal
   );

end top_level;

architecture behav of top_level is

    constant clk_freq:   positive  := 100000000; -- Hz
    constant clk_period: time      :=  1000 ms / clk_freq;
    constant debounce:   natural   := 80; -- us
    constant baud_rate:  positive  :=   57600; -- Baud
    constant bit_period: time      :=  1000 ms / baud_rate;
    constant ts_digits:  positive  := 5 + 8;
    constant signals:    positive  := 8;
    constant fifo_size:  positive  := 16;

    signal   rst:      std_logic                                  :=            '0';
    signal   ev:       std_logic_vector((signals - 1) downto 0)   := (others => '0');

    signal   up_t:     bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_zero); 

    signal   tr_d:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   tr_w:     std_logic                                  :=            'X';

    signal   fi_t:     bcd_digit_vector((ts_digits - 1) downto 0) := (others => bcd_unknown);
    signal   fi_x:     bcd_digit_vector(ts_digits downto 0)       := (others => bcd_unknown);
    signal   fi_d:     std_logic_vector((signals - 1) downto 0)   := (others => 'X');
    signal   fi_f:     std_logic                                  :=            'X';
    signal   fi_w:     std_logic                                  :=            'X';
    signal   fi_a:     std_logic_vector(signals downto 0)         := (others => 'X');

    signal   tx_b:     std_logic                                  :=            '0';
    signal   tx_w:     std_logic                                  :=            '0';
    signal   tx_d:     byte                                       :=            byte_null;

    signal   sp_b:     std_logic                                  :=            '0';
    signal   sp_d:     std_logic                                  :=            '0';

begin

    uptime_unit: entity WORK.bcd_counter
    generic map
    (
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
        signals    => signals
    )
    port map
    (
        rst        => rst,
        clk        => clk,

        di         => ev,

        do         => tr_d,
        wo         => tr_w
    );

    fifo_uut: entity WORK.fifo
    generic map
    (
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
    
    transmitter_unit: entity WORK.transmitter
    generic map
    (
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
    
    serial_port_unit: entity WORK.serial_port 
    generic map
    (
        clk_freq   => clk_freq,
        baud_rate  => baud_rate
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

    fi_x <= fi_t(ts_digits - 1 downto 6) & space_to_zero(fi_t(5 downto 5) & bcd_dot & fi_t(4 downto 0));
    fi_a <= fi_f & fi_d;

    rst   <= sw(0);
    ev    <= (btnu, btnd, btnc, btnl, btnr, rx, msf and sw(6), dcf and sw(7));
    an    <= (others => '1');
    ka    <= (others => '0');

    ld(0) <= rst;
    ld(1) <= sw(1) or sw(2) or sw(3) or sw(4) or sw(5);
    ld(2) <= '0';
    ld(3) <= '0';
    ld(4) <= '0';
    ld(5) <= '0';
    ld(6) <= msf;
    ld(7) <= dcf;
    
    tx    <= sp_d;

end behav;
