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

  subtype word is std_logic_vector((word_size - 1) downto 0);
  subtype opcode is std_logic_vector(7 downto 0);
  subtype address is std_logic_vector(word_size - 9 downto 0);
  subtype program_counter is unsigned((n_bits(rom_size) - 1) downto 0);

  -- Instruction set
  constant IUC:  opcode := "00000000";
  constant HUC:  opcode := "00000001";
  constant BUC:  opcode := "00000010";
  constant BIC:  opcode := "00000011";
  constant SETO: opcode := "00000100";
  constant TSTI: opcode := "00000101";

  -- Debugging symbols
  signal debug_invalid_opcode: std_logic := '0';

  -- Program counter
  constant pc_start: program_counter := (others => '1'); -- .code section

  signal current_pc: program_counter := pc_start;
  signal next_pc: program_counter := pc_start;

  -- Program counter flags
  signal pc_en: std_logic := '0'; -- Counter enable
  signal pc_ld: std_logic := '0'; -- Counter load

  -- Current instruction components
  signal current_opcode: opcode := (others => '0');
  signal current_ins_data : address := (others => '0');
  signal current_address: program_counter := pc_start;
  signal current_port: unsigned(7 downto 0) := (others => '0');
  signal current_and: std_logic_vector(7 downto 0) := (others => '0');
  signal current_xor: std_logic_vector(7 downto 0) := (others => '0');

  -- Instruction state flags
  signal current_tst_flag: std_logic := '0';
  signal next_tst_flag: std_logic := '0';

  -- IO ports
  signal current_io_out: byte_vector((ports_out - 1) downto 0) :=
    (others => byte_null);
  signal next_io_out: byte_vector((ports_out - 1) downto 0) :=
    (others => byte_null);

begin

--synopsys synthesis_off
  -- Set our test debugging signals
  process (current_pc, current_opcode, current_ins_data) is
  begin
    test_pc <= current_pc;
    test_opcode <= current_opcode;
    test_ins_data <= current_ins_data;
  end process;
--synopsys synthesis_on


  -- Clock process
  process (clk, rst) is
  begin
    if rst = '1' then
      current_pc <= pc_start after gate_delay;
      current_tst_flag <= '0' after gate_delay;
      current_io_out <= (others => byte_null) after gate_delay;
    elsif clk'event and clk = '1' then
      current_pc <= next_pc after gate_delay;
      current_tst_flag <= next_tst_flag after gate_delay;
      current_io_out <= next_io_out after gate_delay;
    end if;
  end process;


  -- Keep the internal and real output ports synced
  process (next_io_out) is
  begin
    io_out <= next_io_out after gate_delay;
  end process;


  -- Request instruction from ROM
  process (next_pc) is
  begin
    rom_en <= '1' after gate_delay;
    rom_addr <= std_logic_vector(next_pc) after gate_delay;
  end process;


  -- Read instruction from ROM
  process (rom_data) is
  begin
    current_opcode <= rom_data(word_size - 1 downto word_size - 8)
                        after gate_delay;
    current_address <= unsigned(rom_data((program_counter'length - 1) downto 0))
                         after gate_delay;
    current_port <= unsigned(rom_data(word_size - 9 downto word_size - 16))
                      after gate_delay;
    current_and <= rom_data(word_size - 17 downto word_size - 24)
                     after gate_delay;
    current_xor <= rom_data(word_size - 25 downto 0) after gate_delay;

--synopsys synthesis_off
    current_ins_data <= rom_data(word_size - 9 downto 0) after gate_delay;
--synopsys synthesis_on
  end process;


  -- Execute instruction
  process(rst, current_opcode, current_port, current_and,
          current_xor, current_tst_flag, current_io_out, io_in) is
  begin
    pc_en <= '0' after gate_delay;
    pc_ld <= '0' after gate_delay;
    next_io_out <= current_io_out after gate_delay;
    next_tst_flag <= current_tst_flag after gate_delay;

--synopsys synthesis_off
    debug_invalid_opcode <= '0' after gate_delay;
--synopsys synthesis_on


    if not rst = '1' then
      case current_opcode is
        when IUC => -- Increment unconditional

          pc_en <= '1' after gate_delay;

        when HUC => -- Halt unconditional

        when BUC => -- Branch unconditional

          pc_ld <= '1' after gate_delay;

        when BIC => -- Branch conditional

          if current_tst_flag = '1' then
            pc_ld <= '1' after gate_delay;
          else
            pc_en <= '1' after gate_delay;
          end if;

        when SETO => -- Set outputs

          next_io_out(to_integer(current_port)) <=
            ((current_io_out(to_integer(current_port))
              and current_and)
             xor current_xor);
          pc_en <= '1' after gate_delay;

        when TSTI => -- Test Inputs

          if (std_logic_vector((io_in(to_integer(current_port))
                                and current_and)
                               xor current_xor) = "00000000") then
            next_tst_flag <= '1' after gate_delay;
          else
            next_tst_flag <= '0' after gate_delay;
          end if;
          pc_en <= '1' after gate_delay;

        when others => -- Invalid operation

--synopsys synthesis_off
          debug_invalid_opcode <= '1' after gate_delay;
--synopsys synthesis_on

      end case;
    end if;
  end process;


  -- Set the program counter
  process (current_pc, pc_en, pc_ld, current_address) is
  begin
    next_pc <= current_pc after gate_delay;

    if pc_en = '1' then    -- Increment program counter
      next_pc <= current_pc + 1 after gate_delay;
    elsif pc_ld = '1' then -- Load program counter
      next_pc <= current_address after gate_delay;
    end if;
  end process;

end syn;
