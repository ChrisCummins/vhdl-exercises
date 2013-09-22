entity logic_xnor is
  port (a, b : in bit;
        q : out bit);
begin
end entity logic_xnor;

architecture xnor_arch of logic_xnor is
begin
  q <= '1' when a = b else '0';
end architecture xnor_arch;



--
-- TEST BENCH
--

entity xnor_tb is
begin
end entity xnor_tb;

architecture tests of xnor_tb is
  signal a, b, q : bit;
begin
  dut : entity work.logic_xnor(xnor_arch)
    port map (a, b, q);
  stimulus : process is
    begin
      a <= '0'; b <= '0'; wait for 20 ns;
      a <= '0'; b <= '1'; wait for 20 ns;
      a <= '1'; b <= '0'; wait for 20 ns;
      a <= '1'; b <= '1'; wait for 20 ns;
      wait;
    end process stimulus;
end architecture tests;
