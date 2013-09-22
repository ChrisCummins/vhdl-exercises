--
-- Arithmetic logic unit.
--   When 'mode' is high, output is the sum the two inputs.
--   when 'mode' is low, output is the difference between the two inputs.
--

entity alu is
  port (a, b : in integer;
        mode : in bit;
        q : out integer);
end entity alu;

architecture alu_arch of alu is
begin

  q <= a + b when mode = '1' else abs (a - b);
end architecture alu_arch;



--
-- TEST BENCH
--

entity alu_tb is
end entity alu_tb;

architecture tests of alu_tb is
  signal a, b, q : integer;
  signal mode : bit;
begin
  dut : entity work.alu(alu_arch) port map (a, b, mode, q);
  stimulus : process is
  begin
    a <= 0; b <= 0; mode <= '0'; wait for 20 ns;
    a <= 0; b <= 0; mode <= '1'; wait for 20 ns;
    a <= 5; b <= 2; mode <= '0'; wait for 20 ns;
    a <= 5; b <= 2; mode <= '1'; wait for 20 ns;
    a <= 2; b <= 5; mode <= '0'; wait for 20 ns;
    a <= 2; b <= 5; mode <= '1'; wait for 20 ns;
    wait;
  end process stimulus;
end architecture tests;
