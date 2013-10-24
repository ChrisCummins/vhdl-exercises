library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uptime_counter is

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

end uptime_counter;

architecture rtl of uptime_counter is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end rtl;
