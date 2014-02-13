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
      ram_size:   positive; -- size of RAM in words
      intr_size:  positive; -- number of interrupt lines
      ports_in:   positive; -- number of 8 bit wide input ports
      ports_out:  positive  -- number of 8 bit wide output ports
    );

  port
    (
      clk:           in  std_logic                                             :=            'X';  -- clock
      rst:           in  std_logic                                             :=            'X';  -- rst
      en:            in  std_logic                                             :=            'X';  -- enable

--synopsys synthesis_off
      test_pc:       out unsigned(        (n_bits(rom_size) - 1) downto 0) := (others => '0');     -- program counter
      test_sp:       out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0');     -- stack pointer
      test_sr:       out std_logic_vector((       word_size - 1) downto 0) := (others => '0');     -- status register
--synopsys synthesis_on

      rom_en:        out std_logic                                             :=            'X';  -- ROM enable
      rom_addr:      out std_logic_vector((n_bits(rom_size - 1) - 1) downto 0) := (others => 'X'); -- ROM address to read
      rom_data:      in  std_logic_vector((word_size - 1) downto 0)            := (others => 'Z'); -- ROM data

      ram_wr:        out std_logic                                         :=            '0';           -- RAM write
      ram_waddr:     out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');          -- RAM address to write
      ram_wdata:     out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- RAM data to write
      ram_rd:        out std_logic                                         :=            '0';           -- RAM read
      ram_raddr:     out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');          -- RAM address to read
      ram_rdata:     in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- RAM data to read

      intr:          in  std_logic_vector((       intr_size - 1) downto 0) := (others => 'X');          -- Interrupt lines

      io_in:         in  byte_vector((ports_in - 1) downto 0)                  := (others => byte_unknown); -- 8 bit wide input ports
      io_out:        out byte_vector((ports_out - 1) downto 0)                 := (others => byte_null)     -- 8 bit wide output ports
    );

end execution_unit;

architecture syn of execution_unit is

  type    pc_mux_src      is (current, increment, load, stack);

  subtype word            is std_logic_vector((word_size - 1) downto 0);
  subtype opcode          is std_logic_vector(7 downto 0);
  subtype address         is std_logic_vector(word_size - 9 downto 0);
  subtype program_counter is unsigned((n_bits(rom_size) - 1) downto 0);
  subtype stack_pointer   is unsigned((n_bits(ram_size) - 1) downto 0);

  -- The instruction set
  constant IUC:  opcode := "00000000";
  constant HUC:  opcode := "00000001";
  constant BUC:  opcode := "00000010";
  constant BIC:  opcode := "00000011";
  constant SETO: opcode := "00000100";
  constant TSTI: opcode := "00000101";
  constant BSR:  opcode := "00000110";
  constant RSR:  opcode := "00000111";
  constant RIR:  opcode := "00001000";
  constant SEI:  opcode := "00001001";
  constant CLI:  opcode := "00001010";

  -- The status register flags
  constant TST_FLAG: integer         := 1;   -- Test flag

  -- Initial values
  constant pc_start:     program_counter := (3 => '1', others => '0'); -- 0x008
  constant sp_start:     stack_pointer   := (others => '1');
  constant sr_start:     word            := (others => '0');

  -- The program counter
  signal current_pc:     program_counter := pc_start;
  signal next_pc:        program_counter := pc_start;
  signal load_address:   program_counter := (others => '0');
  signal stack_address:  program_counter := (others => '0');
  signal next_pc_src:    pc_mux_src      := increment;

  -- The stack pointer
  signal current_sp:     stack_pointer   := sp_start;
  signal next_sp:        stack_pointer   := sp_start;

  -- The status register
  signal current_sr:     word            := sr_start;
  signal next_sr:        word            := sr_start;

  -- IO port registers
  signal current_io_out:    byte_vector((ports_out - 1) downto 0)             := (others => byte_null);
  signal next_io_out:       byte_vector((ports_out - 1) downto 0)             := (others => byte_null);

  -- RAM address registers
  signal current_ram_raddr: std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');
  signal next_ram_raddr:    std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');

  -- Current instruction components
  signal current_opcode:    opcode                       := (others => '0');
  signal current_port:      unsigned(7 downto 0)         := (others => '0');
  signal current_and:       std_logic_vector(7 downto 0) := (others => '0');
  signal current_xor:       std_logic_vector(7 downto 0) := (others => '0');

  -- Debugging registers
  signal debug_invalid_opcode: std_logic := '0';

begin

--synopsys synthesis_off
  test_pc         <= current_pc;
  test_sp         <= current_sp;
  test_sr         <= current_sr;
--synopsys synthesis_on

  -- Immediate outputs and inputs
  rom_en          <= '1'                                                       after gate_delay;
  rom_addr        <= std_logic_vector(next_pc)                                 after gate_delay;
  ram_rd          <= '1'                                                       after gate_delay;
  ram_raddr       <= current_ram_raddr                                         after gate_delay;
  io_out          <= next_io_out                                               after gate_delay;
  current_opcode  <= rom_data(word_size - 1 downto word_size - 8)              after gate_delay;
  current_port    <= unsigned(rom_data(word_size - 9 downto word_size - 16))   after gate_delay;
  current_and     <= rom_data(word_size - 17 downto word_size - 24)            after gate_delay;
  current_xor     <= rom_data(word_size - 25 downto 0)                         after gate_delay;
  load_address    <= unsigned(rom_data((program_counter'length - 1) downto 0)) after gate_delay;
  stack_address   <= unsigned(ram_rdata((n_bits(rom_size) - 1) downto 0))      after gate_delay;


  -- Our clock process. Perform the house keeping of setting new current values
  -- for registers, and nothing more.
  process (clk, rst) is
  begin
    if rst = '1' then
      current_pc               <= pc_start                     after gate_delay;
      current_sp               <= sp_start                     after gate_delay;
      current_sr               <= sr_start                     after gate_delay;
      current_io_out           <= (others => byte_null)        after gate_delay;
      current_ram_raddr        <= (others => '0')              after gate_delay;
    elsif clk'event and clk = '1' then
      current_pc               <= next_pc                      after gate_delay;
      current_sp               <= next_sp                      after gate_delay;
      current_sr               <= next_sr                      after gate_delay;
      current_io_out           <= next_io_out                  after gate_delay;
      current_ram_raddr        <= next_ram_raddr               after gate_delay;
    end if;
  end process;


  -- This process implements the instruction set.
  process(rst, current_opcode, current_port, current_and, current_pc,
          current_xor, current_sr, current_io_out, current_sp,
          current_ram_raddr, io_in) is
  begin
    ram_wr                     <= '0'                          after gate_delay;
    next_io_out                <= current_io_out               after gate_delay;
    next_sp                    <= current_sp                   after gate_delay;
    next_sr                    <= current_sr                   after gate_delay;
    next_ram_raddr             <= current_ram_raddr            after gate_delay;
    ram_waddr                  <= (others => '0')              after gate_delay;
    ram_wdata                  <= (others => '0')              after gate_delay;

--synopsys synthesis_off
    debug_invalid_opcode       <= '0'                          after gate_delay;
--synopsys synthesis_on

    if rst = '1' then
      next_pc_src              <= current                      after gate_delay;
    else
      next_pc_src              <= increment                    after gate_delay;

      case current_opcode is

        -- Increment unconditional:
        when IUC =>

        -- Halt unconditional:
        when HUC =>
          next_pc_src          <= current                      after gate_delay;

        -- Branch unconditional:
        when BUC =>
          next_pc_src          <= load                         after gate_delay;

        -- Branch conditional:
        when BIC =>
          if current_sr(TST_FLAG) = '1' then
            next_pc_src        <= load                         after gate_delay;
          end if;

        -- Set outputs:
        when SETO =>
          next_io_out(to_integer(current_port))
                               <= ((current_io_out(to_integer(current_port))
                                    and current_and) xor current_xor)
                                                               after gate_delay;

        -- Test Inputs:
        when TSTI =>
          if (std_logic_vector((io_in(to_integer(current_port))
                                and current_and) xor current_xor)
              = "00000000") then
            next_sr(TST_FLAG)  <= '1'                          after gate_delay;
          else
            next_sr(TST_FLAG)  <= '0'                          after gate_delay;
          end if;

        -- Branch to Subroutine:
        when BSR =>
          -- Push return address to stack.
          ram_wr               <= '1'                          after gate_delay;
          ram_waddr            <= std_logic_vector(current_sp) after gate_delay;
          ram_wdata((n_bits(rom_size) - 1) downto 0)
                               <= std_logic_vector(current_pc + 1)
                                                               after gate_delay;

          -- Set RAM read address and decrement stack pointer.
          next_ram_raddr       <= std_logic_vector(current_sp) after gate_delay;
          next_sp              <= current_sp - 1               after gate_delay;
          next_pc_src          <= load                         after gate_delay;

        -- Return from Subroutine:
        when RSR =>
          -- Reset RAM read address and increment stack pointer.
          next_ram_raddr       <= (others => '0')              after gate_delay;
          next_sp              <= current_sp + 1               after gate_delay;
          next_pc_src          <= stack                        after gate_delay;

        -- Return from Interrupt:
        when RIR =>
          -- TODO: Interrupts implementation

        -- Set Enable Interrupts:
        when SEI =>
          -- TODO: Interrupts implementation

        -- Clear Interrupts flag:
        when CLI =>
          -- TODO: Interrupts implementation

        -- Invalid operation:
        when others =>
--synopsys synthesis_off
          debug_invalid_opcode <= '1'                          after gate_delay;
--synopsys synthesis_on

      end case;
    end if;
  end process;

  -- Program counter multiplexer. Decides on what the next program counter
  -- should be pased upon the next_pc_src.
  process (next_pc_src, current_pc, load_address, stack_address) is
  begin

    case next_pc_src is
      when current =>   -- Hold counter
        next_pc                <= current_pc                   after gate_delay;
      when increment => -- Increment counter by one
        next_pc                <= current_pc + 1               after gate_delay;
      when load =>      -- Load counter from instruction argument
        next_pc                <= load_address                 after gate_delay;
      when stack =>     -- Load counter from RAM
        next_pc                <= stack_address                after gate_delay;
    end case;

  end process;

end syn;
