.PHONY: all clean

all: computer

computer:
	@echo "  GHDL   $@.vhdl"
	@ghdl -a $@.vhdl
#	@ghdl -e clock_tb
#	@ghdl -r clock_tb --vcd=clock.vcd

clean:
	@rm -vf *.o work-obj93.cf *.vcd
