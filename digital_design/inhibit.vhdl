entity Inhibit is
  port (x, y : in bit;
        z : out bit);
end Inhibit;


architecture behaviour of Inhibit is
begin
  z <= '1' when x = '1' and y = '0' else '0';
end behaviour;


architecture behaviour_f of Inhibit is
  function butNot(a, b : bit) return bit is
  begin
    if b = '0' then
      return a;
    else
      return '0';
    end if;
  end function ButNot;
begin
  z <= butNot(x, y);
end behaviour_f;



--
-- TEST BENCH
--
entity tb is
end entity tb;

architecture tests of tb is
  signal a, b, z : bit;
begin
  dut : entity work.Inhibit(behaviour)
    port map (a, b, z);
  stimulus : process is
  begin
    a <= '0'; b <= '0'; wait for 20 ns;
    a <= '0'; b <= '1'; wait for 20 ns;
    a <= '1'; b <= '0'; wait for 20 ns;
    a <= '1'; b <= '1'; wait for 20 ns;
    wait;
  end process stimulus;
end architecture tests;
