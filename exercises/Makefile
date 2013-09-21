all: chapter_01

.PHONY: chapter_01

chapter_01:
	@echo "  VHDL   $@"
	@ghdl -a chapter_01.vhdl
	@ghdl -e multiplexer_tb
	@ghdl -r multiplexer_tb --vcd=chapter_01.vcd
