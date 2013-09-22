SRC  := multiplexers.vhdl

.PHONY: all clean

all:
	@echo "  GHDL   $(SRC)"
	@ghdl -a $(SRC)
	@ghdl -e tb_2bit
	@ghdl -r tb_2bit --vcd=tb_2bit.vcd
	@ghdl -e tb_4bit
	@ghdl -r tb_4bit --vcd=tb_4bit.vcd

clean:
	@rm -vf *.o work-obj93.cf *.vcd tb_2bit tb_4bit
