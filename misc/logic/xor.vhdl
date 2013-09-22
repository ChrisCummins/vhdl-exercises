entity logic_xor is
  port (a, b : in bit;
        q : out bit);
begin
end entity logic_xor;

architecture behaviour of logic_xor is
begin
  q <= a xor b;
end architecture behaviour;



--
-- TEST BENCH
--

entity xor_tb is
begin
end;

architecture tests of xor_tb is
  signal a, b, q : bit;
begin
  dut : entity work.logic_xor(behaviour) port map (a, b, q);
  stimulus : process is
    begin
      a <= '0'; b <= '0'; wait for 20 ns;
      a <= '0'; b <= '1'; wait for 20 ns;
      a <= '1'; b <= '0'; wait for 20 ns;
      a <= '1'; b <= '1'; wait for 20 ns;
      wait;
    end process stimulus;
end;
