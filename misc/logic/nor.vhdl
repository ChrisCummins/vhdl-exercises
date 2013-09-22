entity logic_nor is
  port (a, b : in bit;
        q : out bit);
begin
end entity logic_nor;

architecture nor_arch of logic_nor is
begin
  q <= '1' when a = '0' and b = '0' else '0';
end architecture nor_arch;



--
-- TEST BENCH
--

entity nor_tb is
begin
end entity nor_tb;

architecture tests of nor_tb is
  signal a, b, q : bit;
begin
  dut : entity work.logic_nor(nor_arch)
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
