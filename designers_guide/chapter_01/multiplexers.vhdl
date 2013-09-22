 --
 -- 2-bit multiplexer.
 -- Taken from The Designer's Guide to VHDL, Ch1 exercise 10, p30.
 -- Chris Cummins - 21/9/13
 --

entity multiplexer_2bit is
  port (a, b : in bit;
        sel : in bit;
        z : out bit);
end multiplexer_2bit;

architecture behaviour of multiplexer_2bit is
begin
  -- Contents of port a are copied to z when sel is high, else port b is copied
  -- to z.
  z <= a when sel = '1' else b;
end architecture behaviour;



 --
 -- 4-bit multiplexer.
 -- Taken from The Designer's Guide to VHDL, Ch1 exercise 11, p30.
 -- Chris Cummins - 21/9/13
 --

entity multiplexer_4bit is
  port (a3, a2, a1, a0 : in bit;
        b3, b2, b1, b0 : in bit;
        sel: in bit;
        z3, z2, z1, z0: out bit);
end multiplexer_4bit;

architecture struct of multiplexer_4bit is
begin
  bit3 : entity work.multiplexer_2bit(behaviour)
    port map (a3, b3, sel, z3);
  bit2 : entity work.multiplexer_2bit(behaviour)
    port map (a2, b2, sel, z1);
  bit1 : entity work.multiplexer_2bit(behaviour)
    port map (a1, b1, sel, z1);
  bit0 : entity work.multiplexer_2bit(behaviour)
    port map (a0, b0, sel, z0);
end architecture struct;



--
-- TEST BENCH
--
entity multiplexer_tb is
end entity multiplexer_tb;

architecture test_multiplexer_2bit of multiplexer_tb is
  signal a, b, sel, z : bit;
begin
  dut : entity work.multiplexer_2bit(behaviour)
    port map (a, b, sel, z);
  stimulus: process is
  begin
    a <= '1'; b <= '0';
    sel <= '1'; wait for 20 ns;
    sel <= '0'; wait for 20 ns;
    a <= '0'; b <= '1';
    sel <= '0'; wait for 20 ns;
    sel <= '1'; wait for 20 ns;
    wait;
  end process stimulus;
end architecture test_multiplexer_2bit;

--architecture test_multiplexer_4bit of multiplexer_tb is
--  signal a3, a2, a1, a0, b3, b2, b1, b0, s, z3, z2, z1, z0 : bit;
--begin
--  dut : entity work.multiplexer_4bit(struct)
--    port map (a3, a2, a1, a0, b3, b2, b1, b0, s, z3, z2, z1, z0);
--  stimulus: process is
--  begin
--    a3 <= '1'; a2 <= '0'; a1 <= '1'; a0 <= '0';
--    b3 <= '0'; b2 <= '1'; b1 <= '0'; b0 <= '1';
--    s <= '0'; wait for 20 ns;
--    s <= '1'; wait for 20 ns;
--    a3 <= '0'; a2 <= '1'; a1 <= '0'; a0 <= '1';
--    b3 <= '1'; b2 <= '0'; b1 <= '1'; b0 <= '0';
--    s <= '0'; wait for 20 ns;
--    s <= '1'; wait for 20 ns;
--    wait;
--  end process stimulus;
--end architecture test_multiplexer_4bit;
