entity clock is
  port(clk : in bit;
       q : out integer);
end entity clock;

architecture clock_arch of clock is
begin
  process is
    variable count : integer := 0;
  begin
    wait until clk = '1';
    count := count + 1;
    q <= count;
  end process;
end architecture clock_arch;



--
-- TEST BENCH
--

entity tb is
end entity tb;

architecture tests of tb is
  signal clk : bit;
  signal q : integer;
begin
  dut : entity work.clock(clock_arch) port map (clk, q);
  stimulus : process is
  begin
    clk <= '0'; wait for 10 ns;
    for i in 1 to 16#ff# loop
      clk <= '1'; wait for 20 ns; clk <= '0'; wait for 10 ns;
    end loop;
    wait;
  end process stimulus;
end architecture tests;
