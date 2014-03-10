#
# Makefile to simulate and synthesize VHDL designs
#

TARGET = report

TARGETPDF = $(TARGET).pdf
TARGETTEX = $(TARGET).tex
TEXFILES = $(shell find . -name '*.tex')

CLEANFILES = \
	$(TARGETPDF) \
	*.aux \
	*.log \
	*.log \
	*.out \
	*.toc \
	.\#* \
	\#* \
	$(NULL)

PDFLATEX_ARGS = \
	-output-format pdf \
	-progname pdflatex \
	-file-line-error \
	-interaction=nonstopmode \
	$(NULL)

# Compile command. We pipe the output to /dev/null to silence it, and if there
# is an error, we re-run the compilation without the pipe so as to print the
# failure messages.
define compile
pdflatex $(PDFLATEX_ARGS) $1 >/dev/null || pdflatex $(PDFLATEX_ARGS) $1
endef

.PHONY: clean open

all: $(TARGETPDF)

# Compile twice to refresh cross-references
$(TARGETPDF): $(TEXFILES)
	@echo '  LATEX  $(TARGETPDF)'
	@$(call compile,$(TARGETTEX))
	@$(call compile,$(TARGETTEX))

clean:
	rm -fv $(CLEANFILES)

open:
	@test -f $(TARGETPDF) || echo "File '$(TARGETPDF)' not found, is it compiled?"
	@test ! -f $(TARGETPDF) || xdg-open $(TARGETPDF) >/dev/null 2>&1 &
