library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.util.all;

entity execution_unit is

  generic
    (
      gate_delay: time;           -- delay per gate for simulation only
      word_size:  positive;       -- width of data bus in bits
      icc_size:   positive := 2;  -- width of instruction cycle counter
      reg_high:   positive;       -- number of registers
      ram_size:   positive;       -- size of RAM in words
      intr_size:  positive;       -- number of interrupt lines
      ports_in:   positive;       -- number of 8 bit wide input ports
      ports_out:  positive        -- number of 8 bit wide output ports
    );

  port
    (
      clk:           in  std_logic                                         :=            'X';           -- clock
      rst:           in  std_logic                                         :=            'X';           -- rst
      en:            in  std_logic                                         :=            'X';           -- enable

--synopsys synthesis_off
      test_pc:       out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0');          -- program counter
      test_sp:       out unsigned(        (n_bits(ram_size) - 1) downto 0) := (others => '0');          -- stack pointer
      test_sr:       out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- status register
--synopsys synthesis_on

      reg_a_addr:    out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0');          -- register write address
      reg_a_wr:      out std_logic                                         :=            '0';           -- register write
      reg_a_di:      out std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register write data

      reg_b_addr:    out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0');          -- register read address
      reg_b_rd:      out std_logic                                         :=            '0';           -- register read
      reg_b_do:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register read data

      reg_c_addr:    out std_logic_vector((n_bits(reg_high) - 1) downto 0) := (others => '0');          -- register read address
      reg_c_rd:      out std_logic                                         :=            '0';           -- register read
      reg_c_do:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- register read data

      rom_addr:      out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');          -- ROM address to read
      rom_en:        out std_logic                                         :=            '0';           -- ROM enable
      rom_data:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- ROM data

      ram_addr:      out std_logic_vector((n_bits(ram_size) - 1) downto 0) := (others => '0');          -- RAM address to write
      ram_rd:        out std_logic                                         :=            '0';           -- RAM read
      ram_rdata:     in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- RAM data to read
      ram_wr:        out std_logic                                         :=            '0';           -- RAM write
      ram_wdata:     out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- RAM data to write

      intr:          in  std_logic_vector((       intr_size - 1) downto 0) := (others => 'X');          -- Interrupt lines

      io_in:         in  byte_vector(     (       ports_in  - 1) downto 0) := (others => byte_unknown); -- 8 bit wide input ports
      io_out:        out byte_vector(     (       ports_out - 1) downto 0) := (others => byte_null);    -- 8 bit wide output ports

      alu_si:        out std_logic                                         :=            '0';           -- signed integers
      alu_a_c:       out std_logic                                         :=            '0';           -- A complement
      alu_a_di:      out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- A data in
      alu_b_c:       out std_logic                                         :=            '0';           -- B complement
      alu_b_di:      out std_logic_vector((       word_size - 1) downto 0) := (others => '0');          -- B data in
      alu_c_in:      out std_logic                                         :=            '0';           -- carry in
      alu_s_do:      in  std_logic_vector((       word_size - 1) downto 0) := (others => 'X');          -- sum data out
      alu_c_out:     in  std_logic                                         :=            'X'            -- carry out
    );

end execution_unit;

architecture syn of execution_unit is

  subtype ports            is byte_vector(ports_out - 1             downto 0);
  subtype port_index       is unsigned(byte'length - 1              downto 0);
  subtype word             is std_logic_vector(word_size - 1        downto 0);
  subtype rom_word         is std_logic_vector(n_bits(ram_size) - 1 downto 0);
  subtype ram_word         is std_logic_vector(n_bits(ram_size) - 1 downto 0);
  subtype ram_sr           is std_logic_vector(word_size - 1        downto word_size - 16);
  subtype ram_pc           is std_logic_vector(rom_word'length - 1  downto 0);
  subtype program_counter  is unsigned(rom_word'length - 1          downto 0);
  subtype instruction_counter is unsigned(icc_size downto 0);
  subtype stack_pointer    is unsigned(ram_word'length - 1          downto 0);
  subtype status_register  is word;
  subtype reg_index        is byte;

  -- ROM data components
  alias rom_data_opcode: byte     is rom_data(word_size - 1         downto word_size - 8);
  alias rom_data_byte1:  byte     is rom_data(word_size - 9         downto word_size - 16);
  alias rom_data_byte2:  byte     is rom_data(word_size - 17        downto word_size - 24);
  alias rom_data_byte3:  byte     is rom_data(word_size - 25        downto 0);
  alias rom_data_addr:   ram_word is rom_data(ram_word'length - 1   downto 0);
  alias rom_data_port:   byte     is rom_data_byte1;
  alias rom_data_and:    byte     is rom_data_byte2;
  alias rom_data_xor:    byte     is rom_data_byte3;
  alias rom_data_pc:     ram_pc   is rom_data(rom_word'length - 1   downto 0);

  -- RAM data components
  alias ram_wdata_sr:    ram_sr   is ram_wdata(word_size - 1        downto word_size - 16);
  alias ram_wdata_pc:    ram_pc   is ram_wdata(rom_word'length - 1  downto 0);
  alias ram_rdata_sr:    ram_sr   is ram_rdata(word_size - 1        downto word_size - 16);
  alias ram_rdata_pc:    ram_pc   is ram_rdata(rom_word'length - 1  downto 0);

  -- The status register flags
  constant INTR_EN:         integer := 0;   -- Interrupts enabled
  constant TST_FLAG:        integer := 1;   -- Test flag

  -- Special register indexes
  constant REG_NULL: integer := 0;
  constant REG_PC:   integer := 1;
  constant REG_SP:   integer := 2;
  constant REG_SR:   integer := 3;

  -- Register word padding
  constant reg_pc_pad: std_logic_vector(word_size - program_counter'length - 1 downto 0) := (others => '0');
  constant reg_sp_pad: std_logic_vector(word_size - stack_pointer'length - 1 downto 0) := (others => '0');

  -- Initial values
  constant pc_start:        program_counter  := (3 => '1', others => '0'); -- 0x08
  constant sp_start:        stack_pointer    := (others => '1');
  constant sr_start:        status_register  := (others => '0');

  -- The program counter
  signal current_pc:        program_counter  := pc_start;
  signal next_pc:           program_counter  := pc_start;

  -- The instruction cycle counter
  signal current_icc:       instruction_counter := (others => '0');
  signal next_icc:          instruction_counter := (others => '0');

  -- The stack pointer
  signal current_sp:        stack_pointer    := sp_start;
  signal next_sp:           stack_pointer    := sp_start;

  -- The status register
  signal current_sr:        status_register  := sr_start;
  signal next_sr:           status_register  := sr_start;

  -- Port registers
  signal current_intr:      byte             := (others => '0');
  signal current_io_out:    ports            := (others => byte_null);
  signal next_io_out:       ports            := (others => byte_null);

  -- Register interface
  signal next_reg_b_addr: reg_index := (others => '0');
  signal next_reg_b_rd: std_logic := '0';
  signal next_reg_b_do: word := (others => '0');

begin

--synopsys synthesis_off
  test_pc   <= current_pc;
  test_sp   <= current_sp;
  test_sr   <= current_sr;
--synopsys synthesis_on

  rom_en    <= '1'                                             after gate_delay;
  rom_addr  <= std_logic_vector(next_pc)                       after gate_delay;
  io_out    <= next_io_out                                     after gate_delay;


  -- Our clock process. Performs house keeping on registers.
  process (clk, rst) is
  begin
    if clk'event and clk = '1' then
      if rst = '1' then
        current_pc               <= pc_start                   after gate_delay;
        current_icc              <= (others => '0')            after gate_delay;
        current_sp               <= sp_start                   after gate_delay;
        current_sr               <= sr_start                   after gate_delay;
        current_io_out           <= (others => byte_null)      after gate_delay;
        current_intr             <= (others => '0')            after gate_delay;
      elsif en = '1' then
        current_pc               <= next_pc                    after gate_delay;
        current_icc              <= next_icc                   after gate_delay;
        current_sp               <= next_sp                    after gate_delay;
        current_sr               <= next_sr                    after gate_delay;
        current_io_out           <= next_io_out                after gate_delay;
        current_intr             <= intr                       after gate_delay;
      end if;
    end if;
  end process;


  -- The instruction set implementation.
  process(rst, rom_data, current_pc, current_icc, current_sr, current_io_out,
          current_sp, current_intr, ram_rdata, io_in,
          next_reg_b_do) is

    variable load_pc:  program_counter;
    variable stack_pc: program_counter;
    variable intr_pc:  program_counter;

    -- Resolve an active port with the AND and XOR masks
    function get_port(ports: byte_vector; active_port: byte; and_mask: byte; xor_mask: byte)
      return byte is
    begin
      return (ports(to_integer(unsigned(active_port))) and and_mask) xor xor_mask;
    end get_port;

  begin

    -- Program counter variables
    load_pc  := unsigned(rom_data_pc);
    stack_pc := unsigned(ram_rdata_pc);
    intr_pc  := (others => '0');

    next_pc                    <= current_pc                   after gate_delay;
    next_icc <= (others => '0') after gate_delay;
    next_sp                    <= current_sp                   after gate_delay;
    next_sr                    <= current_sr                   after gate_delay;
    next_io_out                <= current_io_out               after gate_delay;
    ram_rd                     <= '0'                          after gate_delay;
    ram_wr                     <= '0'                          after gate_delay;
    ram_wdata                  <= (others => '0')              after gate_delay;
    ram_addr <= (others => '0') after gate_delay;

    reg_a_addr <= (others => '0') after gate_delay;
    reg_a_wr <= '0' after gate_delay;
    reg_a_di <= (others => '0') after gate_delay;

    next_reg_b_addr <= (others => '0') after gate_delay;
    next_reg_b_rd <= '0' after gate_delay;

    reg_c_addr <= (others => '0') after gate_delay;
    reg_c_rd <= '0' after gate_delay;

    if current_intr /= byte_null and current_sr(INTR_EN) = '1' then

      -- Set the interrupt handler address
      for i in 0 to intr_size - 1 loop
        if (current_intr(i) = '1') then
          intr_pc := to_unsigned(i, program_counter'length);
        end if;
      end loop;

      -- Execute interrupt routine
      next_pc                  <= intr_pc                      after gate_delay;
      next_sp                  <= current_sp - 1               after gate_delay;
      next_sr(INTR_EN)         <= '0'                          after gate_delay;

      -- Push the return address and status register to stack
      ram_wr                   <= '1'                          after gate_delay;
      ram_addr                 <= ram_word(current_sp)         after gate_delay;
      ram_wdata_pc             <= rom_word(current_pc)         after gate_delay;
      ram_wdata_sr             <= current_sr(15 downto 0)      after gate_delay;

    elsif rst /= '1' then
      -- Increment program counter by default
      next_pc                  <= current_pc + 1               after gate_delay;

      case rom_data_opcode is
        when X"01" =>   -- HUC Halt unconditional
          next_pc              <= current_pc                   after gate_delay;

        when X"02" =>   -- BUC Branch unconditional
          next_pc              <= load_pc                      after gate_delay;

        when X"03" =>   -- BIC Branch conditional
          if current_sr(TST_FLAG) = '1' then
            next_pc            <= load_pc                      after gate_delay;
          end if;

        when X"04" =>   -- SETO Set outputs
          next_io_out(to_integer(unsigned(rom_data_port)))
            <= get_port(current_io_out, rom_data_port, rom_data_and, rom_data_xor)
                                                               after gate_delay;

        when X"05" =>   -- TSTI Test Inputs
          if get_port(io_in, rom_data_port, rom_data_and, rom_data_xor) = byte_null then
            next_sr(TST_FLAG)  <= '1'                          after gate_delay;
          else
            next_sr(TST_FLAG)  <= '0'                          after gate_delay;
          end if;

        when X"06" =>   -- BSR Branch to Subroutine
          ram_wr               <= '1'                          after gate_delay;
          ram_addr             <= ram_word(current_sp)         after gate_delay;
          ram_wdata_pc         <= rom_word(current_pc + 1)     after gate_delay;
          next_sp              <= current_sp - 1               after gate_delay;
          next_pc              <= load_pc                      after gate_delay;

        when X"07" =>   -- RSR Return from Subroutine

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              ram_addr <= ram_word(current_sp + 1) after gate_delay;
              ram_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              next_pc              <= stack_pc                     after gate_delay;
              next_sp              <= current_sp + 1               after gate_delay;
          end case;

        when X"08" =>   -- RIR Return from Interrupt:

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              ram_addr <= ram_word(current_sp + 1) after gate_delay;
              ram_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              next_pc              <= stack_pc                     after gate_delay;
              next_sp              <= current_sp + 1               after gate_delay;
              next_sr(15 downto 0) <= ram_rdata_sr                 after gate_delay;
          end case;

        when X"09" =>   -- SEI Set Enable Interrupts
          next_sr(INTR_EN)     <= '1'                          after gate_delay;

        when X"0A" =>   -- CLI Clear Interrupts flag
          next_sr(INTR_EN)     <= '0'                          after gate_delay;

        when X"0B" =>   -- MTR Memory to register

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              ram_addr <= rom_data_addr after gate_delay;
              ram_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              reg_a_addr <= rom_data_byte1 after gate_delay;
              reg_a_wr <= '1' after gate_delay;
              reg_a_di <= ram_rdata after gate_delay;
          end case;

        when X"0C" =>   -- RTM Register to memory

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte1 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              next_reg_b_rd <= '0' after gate_delay;
              ram_addr <= rom_data(n_bits(ram_size) - 1 downto 0) after gate_delay;
              ram_wr <= '1' after gate_delay;
              ram_wdata <= next_reg_b_do after gate_delay;
          end case;

        when X"0D" =>   -- IMTR Indexed memory to register
          -- TODO: Implement

        when X"0E" =>   -- RTIM Register to indexed memory
          -- TODO: Implement

        when X"0F" =>   -- PSHR Stack push

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte1 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              ram_addr <= rom_word(current_sp) after gate_delay;
              ram_wr <= '1' after gate_delay;
              ram_wdata <= next_reg_b_do after gate_delay;
              next_sp <= current_sp - 1 after gate_delay;
          end case;

        when X"10" =>   -- POPR Stack pop

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              ram_addr <= rom_word(current_sp + 1) after gate_delay;
              ram_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              next_sp <= current_sp + 1 after gate_delay;
          end case;

        when X"11" =>   -- RTIO Register to IO port
          -- TODO: Implement

        when X"12" =>   -- IOTR IO port to register
          -- TODO: Implement

        when X"13" =>   -- LDLR Load lower register immediate

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte1 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              next_reg_b_rd <= '0' after gate_delay;
              reg_a_addr <= rom_data_byte1 after gate_delay;
              reg_a_wr <= '1' after gate_delay;
              reg_a_di <= byte_null & byte_null & rom_data_byte2 & rom_data_byte3 after gate_delay;
          end case;

        when X"14" =>   -- LDUR Load upper register immediate
          -- TODO: Implement

        when others =>  -- Undefined operation
      end case;
    end if;

  end process;

  -- Register interface
  process (current_icc, next_reg_b_addr, next_reg_b_rd, reg_b_do,
           current_pc, current_sp, current_sr) is
  begin

    case to_integer(unsigned(next_reg_b_addr)) is
      when REG_NULL to REG_SR =>
        reg_b_addr <= (others => '0') after gate_delay;
        reg_b_rd <= '0' after gate_delay;
      when others =>
        reg_b_addr <= next_reg_b_addr after gate_delay;
        reg_b_rd <= next_reg_b_rd after gate_delay;
    end case;

    -- READ OPERATION
    if next_reg_b_rd = '1' then
      case to_integer(unsigned(next_reg_b_addr)) is
        when REG_NULL =>
          next_reg_b_do <= (others => '0') after gate_delay;
        when REG_PC =>
          next_reg_b_do <= reg_pc_pad & std_logic_vector(current_pc) after gate_delay;
        when REG_SP =>
          next_reg_b_do <= reg_sp_pad & std_logic_vector(current_sp) after gate_delay;
        when REG_SR =>
          next_reg_b_do <= current_sr after gate_delay;
        when others =>
          next_reg_b_do <= reg_b_do after gate_delay;
      end case;
    end if;

  end process;

end syn;
