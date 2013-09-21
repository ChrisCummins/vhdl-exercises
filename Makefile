all:
	@for f in `ls *.vhdl`; do	\
		echo "  VHDL    $$f";	\
		ghdl -a $$f;		\
	done

clean:
	rm *.o work-obj93.cf
