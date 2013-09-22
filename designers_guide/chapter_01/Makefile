SRC  := multiplexers.vhdl
UNIT := multiplexer_tb

VCD  := $(SRC:%.vhdl=%.vcd)

.PHONY: all clean wave

all:
	@echo "  GHDL   $(SRC)"
	@ghdl -a $(SRC)
	@ghdl -e $(UNIT)
	@ghdl -r $(UNIT) --vcd=$(VCD)

clean:
	@rm -vf *.o work-obj93.cf

wave:
	@gtkwave $(VCD)
