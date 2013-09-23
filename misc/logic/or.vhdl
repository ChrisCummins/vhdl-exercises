entity logic_or is
  port (a, b : in bit;
        q : out bit);
begin
end entity logic_or;

architecture behaviour of logic_or is
begin
  q <= a or b;
end architecture behaviour;


entity logic_or4 is
  port (a, b, c, d : in bit;
        q : out bit);
end entity logic_or4;

architecture behaviour of logic_or4 is
  signal a1, b1 : bit;
begin
  or1 : entity work.logic_or(behaviour)
    port map (a, b, a1);
  or2 : entity work.logic_or(behaviour)
    port map (c, d, b1);
  or3 : entity work.logic_or(behaviour)
    port map (a1, b1, q);
end architecture behaviour;



--
-- TEST BENCH
--

entity or_tb is
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

entity or4_tb is
end;

architecture tests of or4_tb is
  signal a, b, c, d, q : bit;
begin
  dut : entity work.logic_or4(behaviour)
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
