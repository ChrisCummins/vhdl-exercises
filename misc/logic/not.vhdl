entity logic_not is
  port (a : in bit;
        q : out bit);
begin
end entity logic_not;

architecture not_arch of logic_not is
begin
  q <= not a;
end architecture not_arch;



--
-- TEST BENCH
--

entity not_tb is
begin
end entity not_tb;

architecture tests of not_tb is
  signal a, q : bit;
begin
  dut : entity work.logic_not(not_arch) port map (a, q);
  stimulus : process is
    begin
      a <= '0'; wait for 20 ns;
      a <= '1'; wait for 20 ns;
      wait;
    end process stimulus;
end architecture tests;
