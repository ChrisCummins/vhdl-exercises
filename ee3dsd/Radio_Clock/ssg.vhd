library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ssg is

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

end ssg;

architecture behav of ssg is

  -- Your declarations go here --

begin

  -- Your implementation goes here --

end behav;

------ END OF SSG ------

--
-- Test bench
--
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity ssg_tb is
  generic (clk_freq: positive := 100); -- Hz
end ssg_tb;

architecture tests of ssg_tb is

  signal clk: std_logic;
  signal wr: std_logic;
  signal di: byte_vector(3 downto 0);
  signal an: std_logic_vector(3 downto 0);
  signal ka: std_logic_vector(7 downto 0);

begin

  dut: entity work.ssg(behav)
    generic map (clk_freq => clk_freq)
    port map (clk, wr, di, an, ka);

end architecture;
