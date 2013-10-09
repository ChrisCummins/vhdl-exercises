# Use V=1 to see full verbosity
QUIET_  = @
QUIET   = $(QUIET_$(V))

TARGET = radio_clock_test_signal

SOURCES =				\
	std_logic_textio.vhd		\
	radio_clock_test_signal.vhd	\
	$(NULL)

OBJECTS = $(SOURCES:.vhd=.o)

all simulation sim: $(TARGET).ghw

$(TARGET).ghw: $(TARGET)
	@echo "   GHDL    $(TARGET) --wave=$(TARGET).ghw"
	$(QUIET)ghdl -r $(TARGET) --wave=$(TARGET).ghw

$(TARGET): $(OBJECTS)
	@echo "   GHDL    $(TARGET)"
	$(QUIET)ghdl -e $(TARGET)

%.o: %.vhd
	@echo "   GHDL    $<"
	$(QUIET)ghdl -a $<

viewer view: $(TARGET).ghw
	@echo "   GTKWAVE $(TARGET).ghw $(TARGET).sav"
	$(QUIET)gtkwave $(TARGET).ghw $(TARGET).sav

clean:
	$(QUIET)rm -vf 			\
		$(TARGET) 		\
		$(TARGET).ghw 		\
		*.o 			\
		*~ 			\
		work-obj93.cf 		\
		$(NULL)

help:
	@echo ""
	@echo "Simulation:"
	@echo ""
	@echo "make simulation     - simulate design"
	@echo "make viewer         - start waveform viewer for simulation results"
	@echo ""
	@echo "Cleanup:"
	@echo ""
	@echo "make clean          - delete temporary files and cleanup directory"
	@echo ""
