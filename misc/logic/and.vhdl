entity logic_and is
  port (a, b : in bit;
        q : out bit);
begin
end entity logic_and;

architecture behaviour of logic_and is
begin
  q <= '1' when a = '1' and b = '1' else '0';
end architecture behaviour;



--
-- TEST BENCH
--

entity and_tb is
begin
end;

architecture tests of and_tb is
  signal a, b, q : bit;
begin
  dut : entity work.logic_and(behaviour) port map (a, b, q);
  stimulus : process is
    begin
      a <= '0'; b <= '0'; wait for 20 ns;
      a <= '0'; b <= '1'; wait for 20 ns;
      a <= '1'; b <= '0'; wait for 20 ns;
      a <= '1'; b <= '1'; wait for 20 ns;
      wait;
    end process stimulus;
end;
