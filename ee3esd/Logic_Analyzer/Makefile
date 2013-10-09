#
# Makefile to simulate and synthesize VHDL designs
#

# Use V=1 to see full verbosity
QUIET_  = @
QUIET   = $(QUIET_$(V))

SOURCES = \
	std_logic_textio.vhd \
	util.vhd \
	bcd_counter.vhd \
	fifo.vhd \
	trigger.vhd \
	transmitter.vhd \
	serial_port.vhd

all simulation sim:
	$(QUIET)for f in $(SOURCES); do \
	    echo "   GHDL    $$f"; \
	    ghdl -a $$f; \
	done
	@echo "   GHDL    test_bench.vhd"
	$(QUIET)ghdl -a test_bench.vhd
	@echo "   GHDL    test_bench"
	$(QUIET)ghdl -e test_bench
	@echo "   GHDL    test_bench --wave=test_bench.ghw"
	$(QUIET)ghdl -r test_bench --wave=test_bench.ghw

viewer view:
	@echo "   GTKWAVE test_bench.ghw test_bench.sav"
	$(QUIET)gtkwave test_bench.ghw test_bench.sav

synthesis syn:
	@echo "Synthesis running..."

	$(QUIET)[ -d reports    ]    || mkdir reports
	$(QUIET)[ -d tmp        ]    || mkdir tmp
	$(QUIET)[ -d tmp/_xmsgs ]    || mkdir tmp/_xmsgs

	@echo "work" > tmp/top_level.lso

	$(QUIET)( \
	    for f in $(SOURCES); do \
	        echo "vhdl work \"$$f\""; \
	    done; \
	    echo "vhdl work \"top_level.vhd\"" \
	) > tmp/top_level.prj

	$(QUIET)( \
	    echo "set -tmpdir \"tmp\""; \
	    echo "set -xsthdpdir \"tmp\""; \
	    echo "run"; \
	    echo "-lso tmp/top_level.lso"; \
	    echo "-ifn tmp/top_level.prj"; \
	    echo "-ofn top_level"; \
	    echo "-p xc6slx16-csg324-3"; \
	    echo "-top top_level"; \
	    echo "-opt_mode speed"; \
	    echo "-opt_level 1" \
	) > tmp/top_level.xst

	$(QUIET)xst -intstyle silent -ifn tmp/top_level.xst -ofn reports/xst.log
	$(QUIET)mv _xmsgs/* tmp/_xmsgs
	$(QUIET)rmdir _xmsgs
	$(QUIET)mv top_level_xst.xrpt tmp
	$(QUIET)grep "ERROR\|WARNING" reports/xst.log | \
	 grep -v "WARNING.*has a constant value.*This FF/Latch will be trimmed during the optimization process." | \
	 cat

implementation impl:
	@echo "Implementation running..."

	$(QUIET)[ -d reports             ] || mkdir reports
	$(QUIET)[ -d tmp                 ] || mkdir tmp
	$(QUIET)[ -d tmp/xlnx_auto_0_xdb ] || mkdir tmp/xlnx_auto_0_xdb

	$(QUIET)ngdbuild -intstyle silent -quiet -dd tmp -uc top_level.ucf -p xc6slx16-csg324-3 top_level.ngc top_level.ngd
	$(QUIET)mv top_level.bld reports/ngdbuild.log
	$(QUIET)mv _xmsgs/* tmp/_xmsgs
	$(QUIET)rmdir _xmsgs
	$(QUIET)mv xlnx_auto_0_xdb/* tmp
	$(QUIET)rmdir xlnx_auto_0_xdb
	$(QUIET)mv top_level_ngdbuild.xrpt tmp

	$(QUIET)map -intstyle silent -detail -p xc6slx16-csg324-3 -pr b -c 100 -w -o top_level_map.ncd top_level.ngd top_level.pcf
	$(QUIET)mv top_level_map.mrp reports/map.log
	$(QUIET)mv _xmsgs/* tmp/_xmsgs
	$(QUIET)rmdir _xmsgs
	$(QUIET)mv top_level_usage.xml top_level_summary.xml top_level_map.map top_level_map.xrpt tmp

	$(QUIET)par -intstyle silent -w -ol std top_level_map.ncd top_level.ncd top_level.pcf
	$(QUIET)mv top_level.par reports/par.log
	$(QUIET)mv top_level_pad.txt reports/par_pad.txt
	$(QUIET)mv _xmsgs/* tmp/_xmsgs
	$(QUIET)rmdir _xmsgs
	$(QUIET)mv par_usage_statistics.html top_level.ptwx top_level.pad top_level_pad.csv top_level.unroutes top_level.xpi top_level_par.xrpt tmp

	$(QUIET)#trce -intstyle silent -v 3 -s 3 -n 3 -fastpaths -xml top_level.twx top_level.ncd -o top_level.twr top_level.pcf -ucf top_level.ucf
	$(QUIET)#mv top_level.twr reports/trce.log
	$(QUIET)#mv _xmsgs/* tmp/_xmsgs
	$(QUIET)#rmdir _xmsgs
	$(QUIET)#mv top_level.twx tmp

	$(QUIET)#netgen -intstyle silent -ofmt vhdl -sim -w top_level.ngc top_level_xsim.vhd
	$(QUIET)#netgen -intstyle silent -ofmt vhdl -sim -w -pcf top_level.pcf top_level.ncd top_level_tsim.vhd
	$(QUIET)#mv _xmsgs/* tmp/_xmsgs
	$(QUIET)#rmdir _xmsgs
	$(QUIET)#mv top_level_xsim.nlf top_level_tsim.nlf tmp

bitfile bit:
	@echo "Generate bitfile running..."
	$(QUIET)touch webtalk.log
	$(QUIET)bitgen -intstyle silent -w top_level.ncd
	$(QUIET)[ -d reports ] || mkdir reports
	$(QUIET)mv top_level.bit design.bit
	$(QUIET)mv top_level.bgn reports/bitgen.log
	$(QUIET)mv _xmsgs/* tmp/_xmsgs
	$(QUIET)rmdir _xmsgs
	$(QUIET)sleep 5
	$(QUIET)mv top_level.drc top_level_bitgen.xwbt top_level_usage.xml top_level_summary.xml webtalk.log tmp

upload up:
	djtgcfg prog -d Nexys3 -i 0 -f design.bit

clean:
	$(QUIET)rm -fv *~ *.o trace.dat test_bench test_bench.ghw work-obj93.cf top_level.ngc top_level.ngd top_level_map.ngm \
	      top_level.pcf top_level_map.ncd top_level.ncd top_level_xsim.vhd top_level_tsim.vhd top_level_tsim.sdf \
	      top_level_tsim.nlf top_level_xst.xrpt top_level_ngdbuild.xrpt top_level_usage.xml top_level_summary.xml \
	      top_level_map.map top_level_map.xrpt par_usage_statistics.html top_level.ptwx top_level.pad top_level_pad.csv \
	      top_level.unroutes top_level.xpi top_level_par.xrpt top_level.twx top_level.nlf design.bit
	$(QUIET)rm -rfv _xmsgs reports tmp xlnx_auto_0_xdb

help:
	@echo ""
	@echo "Simulation:"
	@echo ""
	@echo "make simulation     - simulate design"
	@echo "make viewer         - start waveform viewer for simulation results"
	@echo ""
	@echo "Synthesis:"
	@echo ""
	@echo "make synthesis      - synthesize design"
	@echo "make implementation - implement design"
	@echo "make bitfile        - generate bitfile"
	@echo ""
	@echo "Upload:"
	@echo ""
	@echo "make upload         - upload design to FPGA"
	@echo ""
	@echo "Cleanup:"
	@echo ""
	@echo "make clean          - delete temporary files and cleanup directory"
	@echo ""
