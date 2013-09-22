 --
 -- BCD to 7-segment decoder with zero blanking.
 -- Taken from VHDL for Logic Synthesis (3rd edition), section 8.8, p187.
 -- Chris Cummins - 21/9/13
 --

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

entity display_decoder is
  port (value : in unsigned (3 downto 0);
        zero_blank : in std_logic;
        display : out std_logic_vector (6 downto 0);
        zero_blank_out : out std_logic);
end;

architecture behaviour of display_decoder is
begin
  process (value, zero_blank) begin
    display <= "1001111";
    zero_blank_out <= '0';
    case value is
      when "0000" =>
        display <= "1111110";
        if zero_blank = '1' then
          display <= "0000000";
          zero_blank_out <= '1';
        end if;
      when "0001" => display <= "0110000";
      when "0010" => display <= "1101101";
      when "0011" => display <= "1111001";
      when "0100" => display <= "0110011";
      when "0101" => display <= "1011011";
      when "0110" => display <= "1011111";
      when "0111" => display <= "1110000";
      when "1000" => display <= "1111111";
      when "1001" => display <= "1110011";
      when others => null;
    end case;
  end process;
end;



--
-- TEST BENCH
--

library ieee;
use ieee.std_logic_1164.all, ieee.numeric_std.all;

entity tb is
begin
end entity tb;

architecture tests of tb is
  signal value : unsigned (3 downto 0);
  signal display : std_logic_vector (6 downto 0);
  signal zero_blank, zero_blank_out : std_logic;
begin
  dut : entity work.display_decoder(behaviour)
    port map (value, zero_blank, display, zero_blank_out);
  stimulus : process is
    begin
      zero_blank <= '0';
      value <= "0000"; wait for 20 ns;
      value <= "0001"; wait for 20 ns;
      value <= "0010"; wait for 20 ns;
      value <= "0011"; wait for 20 ns;
      value <= "0100"; wait for 20 ns;
      value <= "0101"; wait for 20 ns;
      value <= "0110"; wait for 20 ns;
      value <= "0111"; wait for 20 ns;
      value <= "1000"; wait for 20 ns;
      value <= "1001"; wait for 20 ns;
      value <= "1010"; wait for 20 ns;
      value <= "1011"; wait for 20 ns;
      value <= "1100"; wait for 20 ns;
      value <= "1101"; wait for 20 ns;
      value <= "1110"; wait for 20 ns;
      value <= "1111"; wait for 20 ns;
      zero_blank <= '1';
      value <= "0000"; wait for 20 ns;
      value <= "0001"; wait for 20 ns;
      value <= "0010"; wait for 20 ns;
      value <= "0011"; wait for 20 ns;
      value <= "0100"; wait for 20 ns;
      value <= "0101"; wait for 20 ns;
      value <= "0110"; wait for 20 ns;
      value <= "0111"; wait for 20 ns;
      value <= "1000"; wait for 20 ns;
      value <= "1001"; wait for 20 ns;
      value <= "1010"; wait for 20 ns;
      value <= "1011"; wait for 20 ns;
      value <= "1100"; wait for 20 ns;
      value <= "1101"; wait for 20 ns;
      value <= "1110"; wait for 20 ns;
      value <= "1111"; wait for 20 ns;
      wait;
    end process stimulus;
end architecture tests;
