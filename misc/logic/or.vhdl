entity logic_or is
  port (a, b : in bit;
        q : out bit);
begin
end entity logic_or;

architecture behaviour of logic_or is
begin
  q <= a or b;
end architecture behaviour;



--
-- TEST BENCH
--

entity or_tb is
begin
end;

architecture tests of or_tb is
  signal a, b, q : bit;
begin
  dut : entity work.logic_or(behaviour) port map (a, b, q);
  stimulus : process is
    begin
      a <= '0'; b <= '0'; wait for 20 ns;
      a <= '0'; b <= '1'; wait for 20 ns;
      a <= '1'; b <= '0'; wait for 20 ns;
      a <= '1'; b <= '1'; wait for 20 ns;
      wait;
    end process stimulus;
end;
