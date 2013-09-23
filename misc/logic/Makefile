SRC  := $(wildcard *.vhdl)

.PHONY: all clean

all:
	@for s in $(SRC); do \
		UNIT=`echo $$s | sed s/.vhdl//`_tb; \
		VCD=`echo $$s | sed s/.vhdl//`.vcd; \
		echo "  GHDL   $$s"; \
		ghdl -a $$s; \
		ghdl -e $$UNIT; \
		ghdl -r $$UNIT --vcd=$$VCD; \
	done
	@echo "  GHDL   and.vhdl"
	@ghdl -e and4_tb
	@ghdl -r and4_tb --vcd=and4.vcd

clean:
	@rm -vf *.o work-obj93.cf *.vcd and4_tb
	@for s in $(SRC); do \
		UNIT=`echo $$s | sed s/.vhdl//`_tb; \
		rm -vf $$UNIT; \
	done
