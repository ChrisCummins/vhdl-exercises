--
-- Numerical integrator.
--
-- When clk goes high, add the value of a to internal counter and copy to
-- output q.
--

entity integrator is
  port(clk : in bit;
       a : in real;
       q : out real);
end entity integrator;

architecture integrator_arch of integrator is
begin
  process is
    variable integral : real := 0.0;
  begin
    wait until clk = '1';
    integral := integral + a;
    q <= integral;
  end process;
end architecture integrator_arch;



--
-- TEST BENCH
--

entity integrator_tb is
end entity integrator_tb;

architecture tests of integrator_tb is
  signal clk : bit;
  signal a, q : real;
begin
  dut : entity work.integrator(integrator_arch) port map (clk, a, q);
  stimulus : process is
  begin
    clk <= '0'; wait for 10 ns;
    for i in 1 to 16#f# loop
      a <= real(i); clk <= '1'; wait for 20 ns;
      clk <= '0'; wait for 10 ns;
    end loop;
    wait;
  end process stimulus;
end architecture tests;
