library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity execution_unit is

  generic
    (
      gate_delay: time;     -- delay per gate for simulation only
      word_size:  positive; -- width of data bus in bits
      rom_size:   positive; -- size of ROM in words
      ports_in:   positive; -- number of 8 bit wide input ports
      ports_out:  positive  -- number of 8 bit wide output ports
    );

  port
    (
      clk:           in  std_logic                                             :=            'X';  -- clock
      rst:           in  std_logic                                             :=            'X';  -- rst
      en:            in  std_logic                                             :=            'X';  -- enable

--synopsys synthesis_off
      test_pc:       out unsigned((n_bits(rom_size) - 1) downto 0)             := (others => 'X'); -- program counter
      test_opcode:   out std_logic_vector(7 downto 0)                          := (others => 'X'); -- instruction opcode
      test_ins_data: out std_logic_vector(word_size - 9 downto 0)              := (others => 'X'); -- instruction data
--synopsys synthesis_on

      rom_en:        out std_logic                                             :=            'X';  -- ROM enable
      rom_addr:      out std_logic_vector((n_bits(rom_size - 1) - 1) downto 0) := (others => 'X'); -- ROM address to read
      rom_data:      in  std_logic_vector((word_size - 1) downto 0)            := (others => 'Z'); -- ROM data

      io_in:         in  byte_vector((ports_in - 1) downto 0)                  := (others => byte_unknown); -- 8 bit wide input ports
      io_out:        out byte_vector((ports_out - 1) downto 0)                 := (others => byte_null)     -- 8 bit wide output ports
    );

end execution_unit;

architecture syn of execution_unit is

  subtype word            is std_logic_vector((word_size - 1) downto 0);
  subtype opcode          is std_logic_vector(7 downto 0);
  subtype address         is std_logic_vector(word_size - 9 downto 0);
  subtype program_counter is unsigned((n_bits(rom_size) - 1) downto 0);

  -- The instruction set
  constant IUC:  opcode := "00000000";
  constant HUC:  opcode := "00000001";
  constant BUC:  opcode := "00000010";
  constant BIC:  opcode := "00000011";
  constant SETO: opcode := "00000100";
  constant TSTI: opcode := "00000101";

  -- The program counter
  constant pc_start: program_counter := (others => '1'); -- Start on -1

  signal current_pc: program_counter := pc_start;
  signal next_pc:    program_counter := pc_start;

  -- Status registers
  signal pc_en:            std_logic := '0'; -- Program counter enable
  signal pc_ld:            std_logic := '0'; -- Program counter load
  signal current_tst_flag: std_logic := '0';
  signal next_tst_flag:    std_logic := '0';

  -- IO port registers
  signal current_io_out: byte_vector((ports_out - 1) downto 0) := (others => byte_null);
  signal next_io_out:    byte_vector((ports_out - 1) downto 0) := (others => byte_null);

  -- Debugging registers
  signal debug_invalid_opcode: std_logic := '0';

  -- Current instruction components
  signal current_opcode:   opcode                       := (others => '0');
  signal current_ins_data: address                      := (others => '0');
  signal current_address:  program_counter              := (others => '0');
  signal current_port:     unsigned(7 downto 0)         := (others => '0');
  signal current_and:      std_logic_vector(7 downto 0) := (others => '0');
  signal current_xor:      std_logic_vector(7 downto 0) := (others => '0');

begin

  -- Our clock process. Perform the house keeping of setting new current values
  -- for registers, and nothing more.
  process (clk, rst) is
  begin
    if rst = '1' then
      current_pc       <= pc_start              after gate_delay;
      current_tst_flag <= '0'                   after gate_delay;
      current_io_out   <= (others => byte_null) after gate_delay;
    elsif clk'event and clk = '1' then
      current_pc       <= next_pc               after gate_delay;
      current_tst_flag <= next_tst_flag         after gate_delay;
      current_io_out   <= next_io_out           after gate_delay;
    end if;
  end process;


  -- Program counter logic. Set the next program counter dependent on whether
  -- the pc_en and pc_ld flags are set. The pc_en flag causes the program
  -- counter to incremented, the pc_ld flag causes the program counter to
  -- loaded from the current_address register.
  process (current_pc, pc_en, pc_ld, current_address) is
  begin
    next_pc   <= current_pc       after gate_delay;

    if pc_en = '1' then
      next_pc <= current_pc + 1  after gate_delay;
    elsif pc_ld = '1' then
      next_pc <= current_address after gate_delay;
    end if;
  end process;


  -- Request the instruction at address next_pc from ROM.
  process (next_pc) is
  begin
    rom_en   <= '1'                       after gate_delay;
    rom_addr <= std_logic_vector(next_pc) after gate_delay;
  end process;


  -- Read the received instruction from ROM and decode the individual
  -- components into registers.
  process (rom_data) is
  begin
    current_opcode  <= rom_data(word_size - 1 downto word_size - 8)
                         after gate_delay;
    current_address <= unsigned(rom_data((program_counter'length - 1) downto 0))
                         after gate_delay;
    current_port    <= unsigned(rom_data(word_size - 9 downto word_size - 16))
                         after gate_delay;
    current_and     <= rom_data(word_size - 17 downto word_size - 24)
                         after gate_delay;
    current_xor     <= rom_data(word_size - 25 downto 0)
                         after gate_delay;

--synopsys synthesis_off
    current_ins_data <= rom_data(word_size - 9 downto 0) after gate_delay;
--synopsys synthesis_on
  end process;


  -- Execute an instruction, interacting with IO ports and setting the pc_en and
  -- pc_ld registers appropriately. This process implements the instruction set.
  process(rst, current_opcode, current_port, current_and,
          current_xor, current_tst_flag, current_io_out, io_in) is
  begin
    pc_en                <= '0'              after gate_delay;
    pc_ld                <= '0'              after gate_delay;
    next_io_out          <= current_io_out   after gate_delay;
    next_tst_flag        <= current_tst_flag after gate_delay;

--synopsys synthesis_off
    debug_invalid_opcode <= '0'              after gate_delay;
--synopsys synthesis_on

    if not rst = '1' then
      case current_opcode is

        -- Increment unconditional:
        when IUC =>
          pc_en <= '1' after gate_delay;

        -- Halt unconditional:
        when HUC =>

        -- Branch unconditional:
        when BUC =>
          pc_ld <= '1' after gate_delay;

        -- Branch conditional:
        when BIC =>
          if current_tst_flag = '1' then
            pc_ld <= '1' after gate_delay;
          else
            pc_en <= '1' after gate_delay;
          end if;

        -- Set outputs:
        when SETO =>
          next_io_out(to_integer(current_port)) <=
            ((current_io_out(to_integer(current_port))
              and current_and) xor current_xor);
          pc_en <= '1' after gate_delay;

        -- Test Inputs:
        when TSTI =>
          if (std_logic_vector((io_in(to_integer(current_port))
                                and current_and) xor current_xor)
              = "00000000") then
            next_tst_flag <= '1' after gate_delay;
          else
            next_tst_flag <= '0' after gate_delay;
          end if;
          pc_en <= '1' after gate_delay;

        -- Invalid operation:
        when others =>
--synopsys synthesis_off
          debug_invalid_opcode <= '1' after gate_delay;
--synopsys synthesis_on

      end case;
    end if;
  end process;


  -- Keep the internal and real output ports synced. We need to keep an
  -- internal representation of the output ports since we can't read an out
  -- port in VHDL, so we use an intermediate signal.
  process (next_io_out) is
  begin
    io_out <= next_io_out after gate_delay;
  end process;


--synopsys synthesis_off
  -- Set the debugging signals as used in the test bench.
  process (current_pc, current_opcode, current_ins_data) is
  begin
    test_pc       <= current_pc;
    test_opcode   <= current_opcode;
    test_ins_data <= current_ins_data;
  end process;
--synopsys synthesis_on

end syn;
