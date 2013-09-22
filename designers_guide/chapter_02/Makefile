.PHONY: all clean

all: misc_types clock

misc_types:
	@echo "  GHDL   $@.vhdl"
	@ghdl -a $@.vhdl

clock:
	@echo "  GHDL   $@.vhdl"
	@ghdl -a $@.vhdl
	@ghdl -e clock_tb
	@ghdl -r clock_tb --vcd=clock.vcd

clean:
	@rm -vf *.o work-obj93.cf *.vcd tb
