 --
 -- Parity generator.
 -- Taken from VHDL for Logic Synthesis (3rd edition), section 3.10, p34.
 -- Chris Cummins - 21/9/13
 --

entity parity is
  port (d7, d6, d5, d4, d3, d2, d1, d0 : in bit;
        mode : in bit;
        result : out bit);
end;

architecture behaviour of parity is
  signal sum : bit;
begin
  sum <= d0 xor d1 xor d2 xor d3 xor d4 xor d5 xor d6 xor d7;
  result <= sum when mode = '1' else not sum;
end;

--
-- TEST BENCH
--
entity parity_tb is
end entity parity_tb;

architecture tests of parity_tb is
  signal d0, d1, d2, d3, d4, d5, d6, d7, mode, result : bit;
begin
  dut : entity work.parity(behaviour)
    port map (d0, d1, d2, d3, d4, d5, d6, d7, mode, result);
end architecture tests;
