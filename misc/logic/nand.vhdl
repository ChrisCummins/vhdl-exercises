entity logic_nand is
  port (a, b : in bit;
        q : out bit);
begin
end entity logic_nand;

architecture nand_arch of logic_nand is
begin
  q <= '0' when a = '1' and b = '1' else '1';
end architecture nand_arch;



--
-- TEST BENCH
--

entity nand_tb is
begin
end entity nand_tb;

architecture tests of nand_tb is
  signal a, b, q : bit;
begin
  dut : entity work.logic_nand(nand_arch)
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
