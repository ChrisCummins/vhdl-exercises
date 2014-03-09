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
  subtype intr_line        is std_logic_vector(intr_size - 1        downto 0);
  subtype word             is std_logic_vector(word_size - 1        downto 0);
  subtype ram_word         is std_logic_vector(n_bits(ram_size) - 1 downto 0);
  subtype ram_sr           is std_logic_vector(word_size - 1        downto word_size - 16);
  subtype ram_pc           is std_logic_vector(ram_word'length - 1  downto 0);
  subtype program_counter  is unsigned(ram_word'length - 1          downto 0);
  subtype instruction_counter is unsigned(icc_size downto 0);

  -- ROM data components
  alias rom_data_byte0:  byte     is rom_data(word_size - 1         downto word_size - 8);
  alias rom_data_byte1:  byte     is rom_data(word_size - 9         downto word_size - 16);
  alias rom_data_byte2:  byte     is rom_data(word_size - 17        downto word_size - 24);
  alias rom_data_byte3:  byte     is rom_data(word_size - 25        downto 0);
  alias rom_data_addr:   ram_word is rom_data(ram_word'length - 1   downto 0);
  alias rom_data_pc:     ram_pc   is rom_data(ram_word'length - 1   downto 0);

  -- RAM data components
  alias ram_wdata_sr:    ram_sr   is ram_wdata(word_size - 1        downto word_size - 16);
  alias ram_wdata_pc:    ram_pc   is ram_wdata(ram_word'length - 1  downto 0);
  alias ram_rdata_sr:    ram_sr   is ram_rdata(word_size - 1        downto word_size - 16);
  alias ram_rdata_pc:    ram_pc   is ram_rdata(ram_word'length - 1  downto 0);

  -- The status register flags
  constant INTR_EN:         integer := 0;   -- Interrupts enabled
  constant TST_FLAG:        integer := 1;   -- Test flag

  -- Special register indexes
  constant REG_NULL: integer := 0;
  constant REG_PC:   integer := 1;
  constant REG_SP:   integer := 2;
  constant REG_SR:   integer := 3;

  -- Register word padding
  constant pc_word_pad: std_logic_vector(word_size - program_counter'length - 1 downto 0) := (others => '0');
  constant byte_pc_pad: std_logic_vector(program_counter'length - byte'length - 1 downto 0) := (others => '0');
  constant byte_word_pad: std_logic_vector(word_size - byte'length - 1 downto 0) := (others => '0');

  -- Initial values
  constant pc_start:        program_counter  := (3 => '1', others => '0'); -- 0x08
  constant sp_start:        program_counter    := (others => '1');
  constant sr_start:        word             := (others => '0');

  -- The program counter
  signal current_pc:        program_counter  := pc_start;
  signal next_pc:           program_counter  := pc_start;

  -- The instruction cycle counter
  signal current_icc:       instruction_counter := (others => '0');
  signal next_icc:          instruction_counter := (others => '0');

  -- The stack pointer
  signal current_sp:        program_counter    := sp_start;
  signal next_sp:           program_counter    := sp_start;

  -- The status register
  signal current_sr:        word             := sr_start;
  signal next_sr:           word             := sr_start;

  -- Port registers
  signal current_io_out:    ports            := (others => byte_null);
  signal next_io_out:       ports            := (others => byte_null);

  -- Interrupts
  constant intr_null:       intr_line        := (others => '0');
  signal current_intr:      intr_line        := intr_null;
  signal intr_reset:        intr_line        := intr_null;

  -- Register interface
  signal next_reg_b_addr: byte := (others => '0');
  signal next_reg_b_rd: std_logic := '0';
  signal next_reg_b_do: word := (others => '0');

  signal next_reg_c_addr: byte := (others => '0');
  signal next_reg_c_rd: std_logic := '0';
  signal next_reg_c_do: word := (others => '0');

  -- Register components
  alias reg_b_do_addr:   ram_word is next_reg_b_do(ram_word'length - 1 downto 0);
  alias reg_c_do_addr:   ram_word is next_reg_c_do(ram_word'length - 1 downto 0);
  alias reg_b_do_byte:   byte     is next_reg_b_do(byte'length - 1 downto 0);
  alias reg_c_do_byte:   byte     is next_reg_b_do(byte'length - 1 downto 0);

  -- Shift register
  signal current_shift: word := (others => '0');
  signal next_shift: word := (others => '0');

  -- Indexed memory register
  signal current_ram_index_addr: ram_word := (others => '0');
  signal next_ram_index_addr: ram_word := (others => '0');

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
        current_shift            <= (others => '0')            after gate_delay;
        current_ram_index_addr   <= (others => '0')            after gate_delay;
      elsif en = '1' then
        current_pc               <= next_pc                    after gate_delay;
        current_icc              <= next_icc                   after gate_delay;
        current_sp               <= next_sp                    after gate_delay;
        current_sr               <= next_sr                    after gate_delay;
        current_io_out           <= next_io_out                after gate_delay;
        current_shift            <= next_shift                 after gate_delay;
        current_ram_index_addr   <= next_ram_index_addr        after gate_delay;

        for i in intr'range loop
          if intr_reset(i) = '1' then
            current_intr(i) <= '0' after gate_delay;
          elsif intr(i) = '1' then
            current_intr(i) <= '1' after gate_delay;
          end if;
        end loop;

      end if;
    end if;
  end process;


  -- The instruction set implementation.
  process(rst, rom_data, current_pc, current_icc, current_sr, current_io_out,
          current_sp, current_intr, ram_rdata, io_in,
          next_reg_b_do, next_reg_c_do) is

    variable load_pc:  program_counter;
    variable stack_pc: program_counter;
    variable port_val: byte;

  begin

    -- Program counter variables
    load_pc  := unsigned(rom_data_pc);
    stack_pc := unsigned(ram_rdata_pc);

    next_pc                    <= current_pc                   after gate_delay;
    next_icc <= (others => '0') after gate_delay;
    next_sp                    <= current_sp                   after gate_delay;
    next_sr                    <= current_sr                   after gate_delay;
    next_io_out                <= current_io_out               after gate_delay;
    next_ram_index_addr        <= ram_word(unsigned(reg_b_do_addr) +
                                           unsigned(reg_c_do_addr))
                                  after gate_delay;
    intr_reset                 <= intr_null                    after gate_delay;

    ram_rd                     <= '0'                          after gate_delay;
    ram_wr                     <= '0'                          after gate_delay;
    ram_wdata                  <= (others => '0')              after gate_delay;
    ram_addr                   <= (others => '0')              after gate_delay;

    reg_a_addr                 <= (others => '0')              after gate_delay;
    reg_a_wr                   <= '0'                          after gate_delay;
    reg_a_di                   <= (others => '0')              after gate_delay;

    next_reg_b_addr            <= (others => '0')              after gate_delay;
    next_reg_b_rd              <= '0'                          after gate_delay;

    next_reg_c_addr            <= (others => '0')              after gate_delay;
    next_reg_c_rd              <= '0'                          after gate_delay;

    if current_intr /= intr_null and current_icc = 0 and current_sr(INTR_EN) = '1' then

      for i in intr'reverse_range loop
        if current_intr(i) = '1' then
          intr_reset(i)        <= '1'                          after gate_delay;
          next_pc              <= to_unsigned(i, program_counter'length)
                                                               after gate_delay;
          exit;
        end if;
      end loop;

      -- Execute interrupt routine
      next_sp                  <= current_sp - 1               after gate_delay;
      next_sr(INTR_EN)         <= '0'                          after gate_delay;

      -- Push the return address and status register to stack
      ram_wr                   <= '1'                          after gate_delay;
      ram_addr                 <= ram_word(current_sp)         after gate_delay;
      ram_wdata_pc             <= ram_word(current_pc)         after gate_delay;
      ram_wdata_sr             <= current_sr(15 downto 0)      after gate_delay;

    elsif rst /= '1' then
      -- Increment program counter by default
      next_pc                  <= current_pc + 1               after gate_delay;

      case to_integer(unsigned(rom_data_byte0)) is
        when 16#01# =>   -- HUC Halt unconditional
          next_pc              <= current_pc                   after gate_delay;

        when 16#02# =>   -- BUC Branch unconditional
          next_pc              <= load_pc                      after gate_delay;

        when 16#03# =>   -- BIC Branch conditional
          if current_sr(TST_FLAG) = '1' then
            next_pc            <= load_pc                      after gate_delay;
          end if;

        when 16#04# =>   -- SETO Set outputs
          port_val := current_io_out(to_integer(unsigned(rom_data_byte1)));
          port_val := (port_val and rom_data_byte2) xor rom_data_byte3;

          next_io_out(to_integer(unsigned(rom_data_byte1)))
                               <= port_val                     after gate_delay;

        when 16#05# =>   -- TSTI Test Inputs
          port_val := io_in(to_integer(unsigned(rom_data_byte1)));
          port_val := (port_val and rom_data_byte2) xor rom_data_byte3;

          if port_val = byte_null then
            next_sr(TST_FLAG)  <= '1'                          after gate_delay;
          else
            next_sr(TST_FLAG)  <= '0'                          after gate_delay;
          end if;

        when 16#06# =>   -- BSR Branch to Subroutine
          ram_wr               <= '1'                          after gate_delay;
          ram_addr             <= ram_word(current_sp)         after gate_delay;
          ram_wdata_pc         <= ram_word(current_pc + 1)     after gate_delay;
          next_sp              <= current_sp - 1               after gate_delay;
          next_pc              <= load_pc                      after gate_delay;

        when 16#07# =>   -- RSR Return from Subroutine

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              ram_addr         <= ram_word(current_sp + 1)     after gate_delay;
              ram_rd           <= '1'                          after gate_delay;

              -- Halt execution
              next_pc          <= current_pc                   after gate_delay;
              next_icc         <= current_icc + 1              after gate_delay;
            when others =>
              next_pc          <= stack_pc                     after gate_delay;
              next_sp          <= current_sp + 1               after gate_delay;
          end case;

        when 16#08# =>   -- RIR Return from Interrupt:

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              ram_addr         <= ram_word(current_sp + 1)     after gate_delay;
              ram_rd           <= '1'                          after gate_delay;

              -- Halt execution
              next_pc          <= current_pc                   after gate_delay;
              next_icc         <= current_icc + 1              after gate_delay;
            when others =>
              next_pc          <= stack_pc                     after gate_delay;
              next_sp          <= current_sp + 1               after gate_delay;
              next_sr(15 downto 0) <= ram_rdata_sr             after gate_delay;
          end case;

        when 16#09# =>   -- SEI Set Enable Interrupts
          next_sr(INTR_EN)     <= '1'                          after gate_delay;

        when 16#0A# =>   -- CLI Clear Interrupts flag
          next_sr(INTR_EN)     <= '0'                          after gate_delay;

        when 16#0B# =>   -- MTR Memory to register

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              ram_addr         <= rom_data_addr                after gate_delay;
              ram_rd           <= '1'                          after gate_delay;

              -- Halt execution
              next_pc          <= current_pc                   after gate_delay;
              next_icc         <= current_icc + 1              after gate_delay;
            when others =>
              reg_a_addr       <= rom_data_byte1               after gate_delay;
              reg_a_wr         <= '1'                          after gate_delay;
              reg_a_di         <= ram_rdata                    after gate_delay;
          end case;

        when 16#0C# =>   -- RTM Register to memory

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr  <= rom_data_byte1               after gate_delay;
              next_reg_b_rd    <= '1'                          after gate_delay;

              -- Halt execution
              next_pc          <= current_pc                   after gate_delay;
              next_icc         <= current_icc + 1              after gate_delay;
            when others =>
              next_reg_b_rd    <= '0'                          after gate_delay;
              ram_addr         <= rom_data(n_bits(ram_size) - 1 downto 0)
                                                               after gate_delay;
              ram_wr           <= '1'                          after gate_delay;
              ram_wdata        <= next_reg_b_do                after gate_delay;
          end case;

        when 16#0D# =>   -- IMTR Indexed memory to register

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte2 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;
              next_reg_c_addr <= rom_data_byte3 after gate_delay;
              next_reg_c_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when 1 =>
              ram_rd <= '1' after gate_delay;
              ram_addr <= ram_word(unsigned(reg_b_do_addr) + unsigned(reg_c_do_addr)) after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              reg_a_wr <= '1' after gate_delay;
              reg_a_addr <= rom_data_byte1 after gate_delay;
              reg_a_di <= ram_rdata after gate_delay;
          end case;

        when 16#0E# =>   -- RTIM Register to indexed memory

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte1 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;
              next_reg_c_addr <= rom_data_byte2 after gate_delay;
              next_reg_c_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when 1 =>
              next_reg_b_addr <= rom_data_byte3 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              ram_addr <= current_ram_index_addr after gate_delay;
              ram_wr <= '1' after gate_delay;
              ram_wdata <= next_reg_b_do after gate_delay;
          end case;

        when 16#0F# =>   -- PSHR Stack push

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
              ram_addr <= ram_word(current_sp) after gate_delay;
              ram_wr <= '1' after gate_delay;
              ram_wdata <= next_reg_b_do after gate_delay;
              next_sp <= current_sp - 1 after gate_delay;
          end case;

        when 16#10# =>   -- POPR Stack pop

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              ram_addr <= ram_word(current_sp + 1) after gate_delay;
              ram_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              next_sp <= current_sp + 1 after gate_delay;
          end case;

        when 16#11# =>   -- RTIO Register to IO port

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte2 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              next_io_out(to_integer(unsigned(rom_data_byte1))) <= reg_b_do_byte after gate_delay;
          end case;

        when 16#12# =>   -- IOTR IO port to register

          port_val := io_in(to_integer(unsigned(rom_data_byte2)));

          case to_integer(unsigned(rom_data_byte1)) is
            when REG_NULL =>
            when REG_PC =>
              next_pc <= unsigned(byte_pc_pad) & unsigned(port_val) after gate_delay;
            when REG_SP =>
              next_sp <= unsigned(byte_pc_pad) & unsigned(port_val) after gate_delay;
            when REG_SR =>
              next_sr <= byte_word_pad & port_val after gate_delay;
            when others =>
              reg_a_addr <= rom_data_byte1 after gate_delay;
              reg_a_wr <= '1' after gate_delay;
              reg_a_di <= byte_null & byte_null & byte_null & port_val after gate_delay;
          end case;

        when 16#13# =>   -- LDLR Load lower register immediate

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte1 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              reg_a_addr <= rom_data_byte1 after gate_delay;
              reg_a_wr <= '1' after gate_delay;
              reg_a_di <= byte_null & byte_null & rom_data_byte2 & rom_data_byte3 after gate_delay;
          end case;

        when 16#14# =>   -- LDUR Load upper register immediate

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte1 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              reg_a_addr <= rom_data_byte1 after gate_delay;
              reg_a_wr <= '1' after gate_delay;
              reg_a_di <= rom_data_byte2 & rom_data_byte3 & byte_null & byte_null after gate_delay;
          end case;

        when 16#15# =>   -- ANDR
          -- TODO: Implementation

        when 16#16# =>   -- ORR
          -- TODO: Implementation

        when 16#17# =>   -- XORR
          -- TODO: Implementation

        when 16#18# =>   -- SRLR Right shift register

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte2 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when 1 =>
              next_shift <= word(shift_right(unsigned(next_reg_b_do), to_integer(unsigned(rom_data_byte3)))) after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              case to_integer(unsigned(rom_data_byte1)) is
                when REG_NULL =>
                when REG_PC =>
                  next_pc <= program_counter(current_shift) after gate_delay;
                when REG_SP =>
                  next_sp <= stack_pointer(current_shift) after gate_delay;
                when REG_SR =>
                  next_sr <= word(current_shift) after gate_delay;
                when others =>
                  reg_a_addr <= rom_data_byte1 after gate_delay;
                  reg_a_wr <= '1' after gate_delay;
                  reg_a_di <= current_shift after gate_delay;
              end case;
          end case;

        when 16#19# =>   -- SLLR Left shift register

          case to_integer(unsigned(current_icc)) is
            when 0 =>
              next_reg_b_addr <= rom_data_byte2 after gate_delay;
              next_reg_b_rd <= '1' after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when 1 =>
              next_shift <= word(shift_left(unsigned(next_reg_b_do), to_integer(unsigned(rom_data_byte3)))) after gate_delay;

              -- Halt execution
              next_pc <= current_pc after gate_delay;
              next_icc <= current_icc + 1 after gate_delay;
            when others =>
              case to_integer(unsigned(rom_data_byte1)) is
                when REG_NULL =>
                when REG_PC =>
                  next_pc <= program_counter(current_shift) after gate_delay;
                when REG_SP =>
                  next_sp <= stack_pointer(current_shift) after gate_delay;
                when REG_SR =>
                  next_sr <= word(current_shift) after gate_delay;
                when others =>
                  reg_a_addr <= rom_data_byte1 after gate_delay;
                  reg_a_wr <= '1' after gate_delay;
                  reg_a_di <= current_shift after gate_delay;
              end case;
          end case;

        when 16#1A# =>   -- CMPU
          -- TODO: Implementation

        when 16#1B# =>   -- CMPS
          -- TODO: Implementation

        when 16#20# to 16#27# =>   --
          -- TODO: Implementation

        when 16#28# to 16#2F# =>   --
          -- TODO: Implementation

        when others =>  -- Undefined operation
      end case;
    end if;

  end process;

  -- Register B interface
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

    -- Read operation
    if next_reg_b_rd = '1' then
      case to_integer(unsigned(next_reg_b_addr)) is
        when REG_NULL =>
          next_reg_b_do <= (others => '0') after gate_delay;
        when REG_PC =>
          next_reg_b_do <= pc_word_pad & std_logic_vector(current_pc) after gate_delay;
        when REG_SP =>
          next_reg_b_do <= pc_word_pad & std_logic_vector(current_sp) after gate_delay;
        when REG_SR =>
          next_reg_b_do <= current_sr after gate_delay;
        when others =>
          next_reg_b_do <= reg_b_do after gate_delay;
      end case;
    end if;

  end process;

  -- Register C interface
  process (current_icc, next_reg_c_addr, next_reg_c_rd, reg_c_do,
           current_pc, current_sp, current_sr) is
  begin

    case to_integer(unsigned(next_reg_c_addr)) is
      when REG_NULL to REG_SR =>
        reg_c_addr <= (others => '0') after gate_delay;
        reg_c_rd <= '0' after gate_delay;
      when others =>
        reg_c_addr <= next_reg_c_addr after gate_delay;
        reg_c_rd <= next_reg_c_rd after gate_delay;
    end case;

    -- Read operation
    if next_reg_c_rd = '1' then
      case to_integer(unsigned(next_reg_c_addr)) is
        when REG_NULL =>
          next_reg_c_do <= (others => '0') after gate_delay;
        when REG_PC =>
          next_reg_c_do <= pc_word_pad & std_logic_vector(current_pc) after gate_delay;
        when REG_SP =>
          next_reg_c_do <= pc_word_pad & std_logic_vector(current_sp) after gate_delay;
        when REG_SR =>
          next_reg_c_do <= current_sr after gate_delay;
        when others =>
          next_reg_c_do <= reg_c_do after gate_delay;
      end case;
    end if;

  end process;

end syn;
