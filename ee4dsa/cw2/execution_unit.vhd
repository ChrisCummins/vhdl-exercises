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
      clk:           in  std_logic                                             :=            'X';           -- clock
      rst:           in  std_logic                                             :=            'X';           -- rst
      en:            in  std_logic                                             :=            'X';           -- enable

--synopsys synthesis_off
      test_pc:       out unsigned(        (n_bits(rom_size) - 1) downto 0)     := (others => '0');          -- program counter
      test_sp:       out unsigned(        (n_bits(ram_size) - 1) downto 0)     := (others => '0');          -- stack pointer
      test_sr:       out std_logic_vector((       word_size - 1) downto 0)     := (others => '0');          -- status register
--synopsys synthesis_on

      rom_en:        out std_logic                                             :=            'X';           -- ROM enable
      rom_addr:      out std_logic_vector((n_bits(rom_size - 1) - 1) downto 0) := (others => 'X');          -- ROM address to read
      rom_data:      in  std_logic_vector((word_size - 1) downto 0)            := (others => 'Z');          -- ROM data

      ram_wr:        out std_logic                                             :=            '0';           -- RAM write
      ram_waddr:     out std_logic_vector((n_bits(ram_size) - 1) downto 0)     := (others => '0');          -- RAM address to write
      ram_wdata:     out std_logic_vector((       word_size - 1) downto 0)     := (others => '0');          -- RAM data to write
      ram_rd:        out std_logic                                             :=            '0';           -- RAM read
      ram_raddr:     out std_logic_vector((n_bits(ram_size) - 1) downto 0)     := (others => '0');          -- RAM address to read
      ram_rdata:     in  std_logic_vector((       word_size - 1) downto 0)     := (others => 'X');          -- RAM data to read

      intr:          in  std_logic_vector((       intr_size - 1) downto 0)     := (others => 'X');          -- Interrupt lines

      io_in:         in  byte_vector((ports_in - 1) downto 0)                  := (others => byte_unknown); -- 8 bit wide input ports
      io_out:        out byte_vector((ports_out - 1) downto 0)                 := (others => byte_null)     -- 8 bit wide output ports
    );

end execution_unit;

architecture syn of execution_unit is

  -- Multiplex selectors
  type    pc_mux_sel       is (current, increment, load, stack, interrupt);
  type    sr_mux_sel       is (current, ram);

  -- Register types
  subtype opcode           is byte;
  subtype ports            is byte_vector(ports_out - 1             downto 0);
  subtype port_index       is unsigned(byte'length - 1              downto 0);
  subtype word             is std_logic_vector(word_size - 1        downto 0);
  subtype rom_address      is std_logic_vector(n_bits(rom_size) - 1 downto 0);
  subtype ram_address      is std_logic_vector(n_bits(ram_size) - 1 downto 0);
  subtype program_counter  is unsigned(rom_address'length - 1       downto 0);
  subtype stack_pointer    is unsigned(ram_address'length - 1       downto 0);
  subtype status_register  is word;

  -- Instruction components
  alias current_opcode: opcode is rom_data(word_size - 1  downto word_size - 8);
  alias current_port:   byte   is rom_data(word_size - 9  downto word_size - 16);
  alias current_and:    byte   is rom_data(word_size - 17 downto word_size - 24);
  alias current_xor:    byte   is rom_data(word_size - 25 downto 0);

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
  constant INTR_EN:      integer := 0;   -- Interrupts enabled
  constant TST_FLAG:     integer := 1;   -- Test flag

  -- Initial values
  constant pc_start:     program_counter  := (3 => '1', others => '0'); -- 0x008
  constant sp_start:     stack_pointer    := (others => '1');
  constant sr_start:     status_register  := (others => '0');

  -- The program counter
  signal current_pc:     program_counter  := pc_start;
  signal next_pc:        program_counter  := pc_start;
  signal next_pc_src:    pc_mux_sel       := increment;

  signal load_pc:        program_counter  := (others => '0');
  signal stack_pc:       program_counter  := (others => '0');
  signal intr_pc:        program_counter  := (others => '0');

  -- The stack pointer
  signal current_sp:     stack_pointer    := sp_start;
  signal next_sp:        stack_pointer    := sp_start;

  -- The status register
  signal current_sr:     status_register  := sr_start;
  signal next_sr:        status_register  := sr_start;

  signal current_sr_src: sr_mux_sel       := current;
  signal next_sr_src:    sr_mux_sel       := current;

  -- Port registers
  signal current_intr:      byte          := (others => '0');
  signal current_io_out:    ports         := (others => byte_null);
  signal next_io_out:       ports         := (others => byte_null);

  -- RAM address register
  signal current_ram_raddr: ram_address   := (others => '0');
  signal next_ram_raddr:    ram_address   := (others => '0');

begin

--synopsys synthesis_off
  test_pc         <= current_pc;
  test_sp         <= current_sp;
  test_sr         <= current_sr;
--synopsys synthesis_on

  rom_en          <= '1'                                                        after gate_delay;
  rom_addr        <= std_logic_vector(next_pc)                                  after gate_delay;
  ram_rd          <= '1'                                                        after gate_delay;
  ram_raddr       <= current_ram_raddr                                          after gate_delay;
  io_out          <= next_io_out                                                after gate_delay;
  load_pc         <= unsigned(rom_data(program_counter'length - 1  downto 0))   after gate_delay;
  stack_pc        <= unsigned(ram_rdata(program_counter'length - 1 downto 0))   after gate_delay;


  -- Our clock process. Performs house keeping on registers.
  process (clk, rst) is
  begin
    if rst = '1' then
      current_pc               <= pc_start                     after gate_delay;
      current_sp               <= sp_start                     after gate_delay;
      current_sr               <= sr_start                     after gate_delay;
      current_io_out           <= (others => byte_null)        after gate_delay;
      current_ram_raddr        <= (others => '0')              after gate_delay;
      current_intr             <= (others => '0')              after gate_delay;
      current_sr_src           <= current                      after gate_delay;
    elsif clk'event and clk = '1' then
      current_pc               <= next_pc                      after gate_delay;
      current_sp               <= next_sp                      after gate_delay;
      current_sr               <= next_sr                      after gate_delay;
      current_io_out           <= next_io_out                  after gate_delay;
      current_ram_raddr        <= next_ram_raddr               after gate_delay;
      current_intr             <= intr                         after gate_delay;
      current_sr_src           <= next_sr_src                  after gate_delay;
    end if;
  end process;


  -- The instruction set implementation.
  process(rst, current_and, current_pc, current_sr, current_io_out, current_sp,
          current_ram_raddr, current_intr, current_sr_src, ram_rdata, io_in) is
  begin

    next_pc_src                <= current                      after gate_delay;
    next_sr_src                <= current                      after gate_delay;
    next_io_out                <= current_io_out               after gate_delay;
    next_sp                    <= current_sp                   after gate_delay;
    next_ram_raddr             <= current_ram_raddr            after gate_delay;
    ram_wr                     <= '0'                          after gate_delay;
    ram_waddr                  <= (others => '0')              after gate_delay;
    ram_wdata                  <= (others => '0')              after gate_delay;
    intr_pc                    <= (others => '0')              after gate_delay;

    -- Status register input multiplexer
    case current_sr_src is
      when current => -- Preserve status register
        next_sr                <= current_sr                   after gate_delay;
      when ram =>     -- Load status register from RAM
        next_sr                <= (others => '0')              after gate_delay;
        next_sr(15 downto 0)   <= ram_rdata(word_size - 1 downto word_size / 2)
                                                               after gate_delay;
    end case;

    if current_intr /= byte_null and current_sr(INTR_EN) = '1' then
      -- Execute interrupt routine
      next_pc_src              <= interrupt                    after gate_delay;
      next_ram_raddr           <= std_logic_vector(current_sp) after gate_delay;
      next_sp                  <= current_sp - 1               after gate_delay;
      next_sr(INTR_EN)         <= '0'                          after gate_delay;

      -- Push the return address and status register to stack
      ram_wr                   <= '1'                          after gate_delay;
      ram_waddr                <= std_logic_vector(current_sp) after gate_delay;
      ram_wdata(program_counter'length - 1 downto 0)
                               <= std_logic_vector(current_pc) after gate_delay;
      ram_wdata(word_size - 1 downto word_size / 2)
                               <= current_sr(15 downto 0)      after gate_delay;

      -- Set the interrupt handler address
      for i in 0 to intr_size - 1 loop
        if (current_intr(i) = '1') then
          intr_pc              <= to_unsigned(i, program_counter'length)
                                                               after gate_delay;
        end if;
      end loop;

    elsif rst /= '1' then
      -- Increment program counter by default
      next_pc_src              <= increment                    after gate_delay;

      case current_opcode is
        when HUC =>   -- Halt unconditional
          next_pc_src          <= current                      after gate_delay;

        when BUC =>   -- Branch unconditional
          next_pc_src          <= load                         after gate_delay;

        when BIC =>   -- Branch conditional
          if current_sr(TST_FLAG) = '1' then
            next_pc_src        <= load                         after gate_delay;
          end if;

        when SETO =>  -- Set outputs
          next_io_out(to_integer(unsigned(current_port)))
                               <= ((current_io_out(to_integer(unsigned(current_port)))
                                    and current_and) xor current_xor)
                                                               after gate_delay;

        when TSTI =>  -- Test Inputs
          if (std_logic_vector((io_in(to_integer(unsigned(current_port)))
                                and current_and) xor current_xor)
              = "00000000") then
            next_sr(TST_FLAG)  <= '1'                          after gate_delay;
          else
            next_sr(TST_FLAG)  <= '0'                          after gate_delay;
          end if;

        when BSR =>   -- Branch to Subroutine
          ram_wr               <= '1'                          after gate_delay;
          ram_waddr            <= std_logic_vector(current_sp) after gate_delay;
          ram_wdata(program_counter'length - 1 downto 0)
                               <= std_logic_vector(current_pc + 1)
                                                               after gate_delay;
          next_ram_raddr       <= std_logic_vector(current_sp) after gate_delay;
          next_sp              <= current_sp - 1               after gate_delay;
          next_pc_src          <= load                         after gate_delay;

        when RSR =>   -- Return from Subroutine
          next_ram_raddr       <= std_logic_vector(current_sp + 2)
                                                               after gate_delay;
          next_sp              <= current_sp + 1               after gate_delay;
          next_pc_src          <= stack                        after gate_delay;

        when RIR =>   -- Return from Interrupt:
          next_ram_raddr       <= std_logic_vector(current_sp + 2)
                                                               after gate_delay;
          next_sp              <= current_sp + 1               after gate_delay;
          next_pc_src          <= stack                        after gate_delay;

          next_sr(INTR_EN)     <= '1'                          after gate_delay;
          next_sr_src          <= ram                          after gate_delay;

        when SEI =>   -- Set Enable Interrupts
          next_sr(INTR_EN)     <= '1'                          after gate_delay;

        when CLI =>   -- Clear Interrupts flag
          next_sr(INTR_EN)     <= '0'                          after gate_delay;

        when others => -- Undefined operation
      end case;
    end if;
  end process;

  -- Program counter multiplexer.
  process (next_pc_src, current_pc, load_pc, stack_pc, intr_pc) is
  begin
    case next_pc_src is
      when current     => next_pc <= current_pc                after gate_delay;
      when increment   => next_pc <= current_pc + 1            after gate_delay;
      when load        => next_pc <= load_pc                   after gate_delay;
      when stack       => next_pc <= stack_pc                  after gate_delay;
      when interrupt   => next_pc <= intr_pc                   after gate_delay;
    end case;
  end process;

end syn;
