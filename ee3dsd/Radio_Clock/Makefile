#
# Makefile to simulate and synthesize VHDL designs
#

SOURCES = \
	std_logic_textio.vhd \
	util.vhd \
	ddrserdes.vhd \
	dcf_bits.vhd \
	dcf_decode.vhd \
	dcf_sync.vhd \
	edge_detector.vhd \
	fifo.vhd \
	msf_bits.vhd \
	msf_decode.vhd \
	msf_sync.vhd \
	pll.vhd \
	serdes.vhd \
	serial_port.vhd \
	ssg.vhd \
	uptime_counter.vhd

TESTBENCHES = dcf_sync_tb

TMP_DIR=/tmp/$(USER)

all simulation sim:
	@for f in $(SOURCES); do \
		if [ -f $$f ]; then \
			echo "ghdl -a $$f"; \
			ghdl -a $$f; \
		fi; \
	done
	@for t in $(TESTBENCHES); do \
		echo "ghdl -e $$t"; \
		ghdl -e $$t; \
		echo "ghdl -r $$t --vcd=$$t.vcd"; \
		ghdl -r $$t --vcd=$$t.vcd; \
	done

view:
	gtkwave dcf_sync_tb.vcd dcf_sync_tb.sav >/dev/null 2>&1 &

uber: syn impl bit up

synthesis syn:
	@echo "Synthesis running..."
	@[ -d reports           ] || mkdir reports
	@[ -d $(TMP_DIR)        ] || mkdir $(TMP_DIR)
	@[ -d $(TMP_DIR)/_xmsgs ] || mkdir $(TMP_DIR)/_xmsgs
	@echo "work" > $(TMP_DIR)/top_level.lso
	@( \
	    for f in $(SOURCES); do \
	        [ -f $$f ] && echo "VHDL Source: $$f"; \
	        [ -f $$f ] || echo "IP Core    : $${f%.vhd}.ngc"; \
	    done; \
	)
	@( \
	    for f in $(SOURCES); do \
	        [ -f $$f ] && echo "s/@@$${f%.vhd}@@/entity WORK.$${f%.vhd}/g"; \
	        [ -f $$f ] || echo "s/@@$${f%.vhd}@@/$${f%.vhd}_ipc/g"; \
	    done; \
	) > $(TMP_DIR)/sed.cmd
	@sed -f $(TMP_DIR)/sed.cmd < Templates/top_level.vhd > top_level.vhd
	@( \
	    for f in $(SOURCES); do \
	        [ -f $$f ] && echo "vhdl work \"$$f\""; \
	    done; \
	    echo "vhdl work \"top_level.vhd\"" \
	) > $(TMP_DIR)/top_level.prj
	@( \
	    echo "set -tmpdir \"$(TMP_DIR)\""; \
	    echo "set -xsthdpdir \"$(TMP_DIR)\""; \
	    echo "run"; \
	    echo "-lso $(TMP_DIR)/top_level.lso"; \
	    echo "-ifn $(TMP_DIR)/top_level.prj"; \
	    echo "-ofn top_level"; \
	    echo "-p xc6slx16-csg324-3"; \
	    echo "-infer_ramb8 No"; \
	    echo "-top top_level"; \
	    echo "-opt_mode speed"; \
	    echo "-opt_level 1" \
	) > $(TMP_DIR)/top_level.xst
	@xst -intstyle silent -ifn $(TMP_DIR)/top_level.xst -ofn reports/xst.log
	@mv _xmsgs/* $(TMP_DIR)/_xmsgs
	@rmdir _xmsgs
	@mv top_level_xst.xrpt $(TMP_DIR)
	@grep "ERROR\|WARNING" reports/xst.log | \
	 grep -v "WARNING.*has a constant value.*This FF/Latch will be trimmed during the optimization process." | \
	 grep -v "WARNING.*You are using an internal switch '-infer_ramb8'." | \
	 grep -v "WARNING:Xst:2677 - Node .* of sequential type is unconnected in block .*." | \
	 cat

implementation impl:
	@echo "Implementation running..."
	@[ -d reports                    ] || mkdir reports
	@[ -d $(TMP_DIR)                 ] || mkdir $(TMP_DIR)
	@[ -d $(TMP_DIR)/xlnx_auto_0_xdb ] || mkdir $(TMP_DIR)/xlnx_auto_0_xdb
	@ngdbuild -intstyle silent -quiet -dd $(TMP_DIR) -uc top_level.ucf -p xc6slx16-csg324-3 top_level.ngc top_level.ngd
	@mv top_level.bld reports/ngdbuild.log
	@mv _xmsgs/* $(TMP_DIR)/_xmsgs
	@rmdir _xmsgs
	@mv xlnx_auto_0_xdb/* $(TMP_DIR)
	@rmdir xlnx_auto_0_xdb
	@mv top_level_ngdbuild.xrpt $(TMP_DIR)
	@map -intstyle silent -mt 2 -detail -p xc6slx16-csg324-3 -pr b -c 100 -w -o top_level_map.ncd top_level.ngd top_level.pcf
	@mv top_level_map.mrp reports/map.log
	@mv _xmsgs/* $(TMP_DIR)/_xmsgs
	@rmdir _xmsgs
	@mv top_level_usage.xml top_level_summary.xml top_level_map.map top_level_map.xrpt $(TMP_DIR)
	@par -intstyle silent -mt 4 -w -ol high top_level_map.ncd top_level.ncd top_level.pcf
	@mv top_level.par reports/par.log
	@mv top_level_pad.txt reports/par_pad.txt
	@mv _xmsgs/* $(TMP_DIR)/_xmsgs
	@rmdir _xmsgs
	@mv par_usage_statistics.html top_level.ptwx top_level.pad top_level_pad.csv top_level.unroutes top_level.xpi top_level_par.xrpt $(TMP_DIR)
	@trce -intstyle silent -v 3 -s 3 -n 3 -fastpaths -xml top_level.twx top_level.ncd -o top_level.twr top_level.pcf -ucf top_level.ucf
	@mv top_level.twr reports/trce.log
	@mv _xmsgs/* $(TMP_DIR)/_xmsgs
	@rmdir _xmsgs
	@mv top_level.twx $(TMP_DIR)
	@#netgen -intstyle silent -ofmt vhdl -sim -w top_level.ngc top_level_xsim.vhd
	@#netgen -intstyle silent -ofmt vhdl -sim -w -pcf top_level.pcf top_level.ncd top_level_tsim.vhd
	@#mv _xmsgs/* $(TMP_DIR)/_xmsgs
	@#rmdir _xmsgs
	@#mv top_level_xsim.nlf top_level_tsim.nlf $(TMP_DIR)

bitfile bit:
	@echo "Generate bitfile running..."
	@[ -d reports ] || mkdir reports
	@touch webtalk.log
	@bitgen -intstyle silent -w top_level.ncd 2>&1 | \
	 grep -v "WARNING:PhysDesignRules:367 - The signal" | \
	 grep -v "event_fifo_unit/Mram_data" | \
	 grep -v "incomplete. The signal does not drive any load pins in the design." | \
	 cat
	@sleep 5
	@mv top_level.bit design.bit
	@mv top_level.bgn reports/bitgen.log
	@mv _xmsgs/* $(TMP_DIR)/_xmsgs
	@rmdir _xmsgs
	@mv top_level.drc top_level_bitgen.xwbt top_level_usage.xml top_level_summary.xml webtalk.log $(TMP_DIR)

upload up:
	@echo "Uploading bitfile..."

	djtgcfg prog -d Nexys3 -i 0 -f design.bit

clean:
	@rm -vf *~ *.o trace.dat test_bench test_bench.ghw work-obj93.cf unisim-obj93.cf top_level.ngc top_level.ngd top_level_map.ngm \
	      top_level.pcf top_level_map.ncd top_level.ncd top_level_xsim.vhd top_level_tsim.vhd top_level_tsim.sdf \
	      top_level_tsim.nlf top_level_xst.xrpt top_level_ngdbuild.xrpt top_level_usage.xml top_level_summary.xml \
	      top_level_map.map top_level_map.xrpt par_usage_statistics.html top_level.ptwx top_level.pad top_level_pad.csv \
	      top_level.unroutes top_level.xpi top_level_par.xrpt top_level.twx top_level.nlf design.bit
	@rm -rvf _xmsgs reports $(TMP_DIR) xlnx_auto_0_xdb webtalk.log

help:
	@echo ""
	@echo "Simulation:"
	@echo ""
	@echo "make simulation     - simulate design"
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
	@echo "make uber           - synthesise then upload"
	@echo ""
	@echo "Cleanup:"
	@echo ""
	@echo "make clean          - delete temporary files and cleanup directory"
	@echo ""
