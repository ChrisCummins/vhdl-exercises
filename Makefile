SUBDIRS = $(shell find . -type d | grep -v git | tail -n+2)

all:
	@for d in $(SUBDIRS); do \
		test -f $$d/Makefile && { \
			echo "Entering directory \`$$d'"; \
			make -sC $$d; \
		}; \
	done

clean:
	@for d in $(SUBDIRS); do \
		test -f $$d/Makefile && { \
			echo "Entering directory \`$$d'"; \
			make -sC $$d clean; \
		}; \
	done
