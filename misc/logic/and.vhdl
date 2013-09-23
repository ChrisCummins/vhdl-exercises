entity logic_and is
  port (a, b : in bit;
        q : out bit);
begin
end entity logic_and;

architecture behaviour of logic_and is
begin
  q <= '1' when a = '1' and b = '1' else '0';
end architecture behaviour;


entity logic_and4 is
  port (a, b, c, d : in bit;
        q : out bit);
begin
end entity logic_and4;

architecture behaviour of logic_and4 is
  signal a1, b1 : bit;
begin
  and1 : entity work.logic_and(behaviour)
    port map (a, b, a1);
  and2 : entity work.logic_and(behaviour)
    port map (c, d, b1);
  and3 : entity work.logic_and(behaviour)
    port map (a1, b1, q);
end architecture behaviour;

--
-- TEST BENCH
--

entity and_tb is
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

entity and4_tb is
end;

architecture tests of and4_tb is
  signal a, b, c, d, q : bit;
begin
  dut : entity work.logic_and4(behaviour)
    port map (a, b, c, d, q);
  stimulus : process is
    begin
      a <= '0'; b <= '0'; c <= '0'; d <= '0'; wait for 20 ns;
      a <= '0'; b <= '0'; c <= '0'; d <= '1'; wait for 20 ns;
      a <= '0'; b <= '0'; c <= '1'; d <= '0'; wait for 20 ns;
      a <= '0'; b <= '0'; c <= '1'; d <= '1'; wait for 20 ns;
      a <= '0'; b <= '1'; c <= '0'; d <= '0'; wait for 20 ns;
      a <= '0'; b <= '1'; c <= '0'; d <= '1'; wait for 20 ns;
      a <= '0'; b <= '1'; c <= '1'; d <= '0'; wait for 20 ns;
      a <= '0'; b <= '1'; c <= '1'; d <= '1'; wait for 20 ns;
      a <= '1'; b <= '0'; c <= '0'; d <= '0'; wait for 20 ns;
      a <= '1'; b <= '0'; c <= '0'; d <= '1'; wait for 20 ns;
      a <= '1'; b <= '0'; c <= '1'; d <= '0'; wait for 20 ns;
      a <= '1'; b <= '0'; c <= '1'; d <= '1'; wait for 20 ns;
      a <= '1'; b <= '1'; c <= '0'; d <= '0'; wait for 20 ns;
      a <= '1'; b <= '1'; c <= '0'; d <= '1'; wait for 20 ns;
      a <= '1'; b <= '1'; c <= '1'; d <= '0'; wait for 20 ns;
      a <= '1'; b <= '1'; c <= '1'; d <= '1'; wait for 20 ns;
      wait;
    end process stimulus;
end architecture tests;
