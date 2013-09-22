SRC  := parity.vhdl
UNIT := parity_tb

VCD  := $(SRC:%.vhdl=%.vcd)

.PHONY: all clean

all:
	@echo "  GHDL   $(SRC)"
	@ghdl -a $(SRC)
	@ghdl -e $(UNIT)
	@ghdl -r $(UNIT) --vcd=$(VCD)

clean:
	@rm -vf *.o work-obj93.cf
