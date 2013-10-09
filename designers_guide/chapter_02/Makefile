.PHONY: all clean

all: misc_types clock alu integrator

misc_types:
	@echo "   GHDL    $@.vhdl"
	@ghdl -a $@.vhdl

clock:
	@echo "   GHDL    $@.vhdl"
	@ghdl -a $@.vhdl
	@ghdl -e clock_tb
	@ghdl -r clock_tb --vcd=clock.vcd

alu:
	@echo "   GHDL    $@.vhdl"
	@ghdl -a $@.vhdl
	@ghdl -e alu_tb
	@ghdl -r alu_tb --vcd=alu.vcd

integrator:
	@echo "   GHDL    $@.vhdl"
	@ghdl -a $@.vhdl
	@ghdl -e integrator_tb
	@ghdl -r integrator_tb --vcd=integrator.vcd

clean:
	@rm -vf *.o work-obj93.cf *.vcd alu_tb clock_tb integrator_tb
