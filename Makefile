
# detection of coq
ifeq "$(COQBIN)" ""
COQBIN := $(shell which coqc >/dev/null 2>&1 && dirname `which coqc`)
endif
ifeq "$(COQBIN)" ""
$(error Coq not found, make sure it is installed in your PATH or set COQBIN)
else
$(info Using coq found in $(COQBIN), from COQBIN or PATH)
endif
export COQBIN := $(COQBIN)/

# detection of elpi
ifeq "$(ELPIDIR)" ""
ELPIDIR=$(shell ocamlfind query elpi 2>/dev/null)
endif
ifeq "$(ELPIDIR)" ""
$(error Elpi not found, make sure it is installed in your PATH or set ELPIDIR)
endif
export ELPIDIR

DEPS=$(ELPIDIR)/elpi.cmxa $(ELPIDIR)/elpi.cma

APPS=$(addprefix apps/, derive eltac NES)

ifeq "$(COQ_ELPI_ALREADY_INSTALLED)" ""
DOCDEP=build
else
DOCDEP=
endif

DOCDIR=$(shell $(COQBIN)/coqc -where)/../../share/doc/coq-elpi/

all: build test

build: Makefile.coq $(DEPS)
	@echo "########################## building plugin ##########################"
	@if [ -x $(COQBIN)/coqtop.byte ]; then \
		$(MAKE) --no-print-directory -f Makefile.coq bytefiles; \
	fi
	@$(MAKE) --no-print-directory -f Makefile.coq opt
	@echo "########################## building APPS ############################"
	@$(foreach app,$(APPS),$(MAKE) -C $(app) $@ &&) true

test: Makefile.test.coq $(DEPS) build
	@echo "########################## testing plugin ##########################"
	@$(MAKE) --no-print-directory -f Makefile.test.coq
	@echo "########################## testing APPS ############################"
	@$(foreach app,$(APPS),$(MAKE) -C $(app) $@ &&) true

doc: $(DOCDEP)
	@echo "########################## generating doc ##########################"
	@mkdir -p doc
	@$(foreach tut,$(wildcard examples/tutorial*$(ONLY)*.v),\
		echo ALECTRYON $(tut) && ./etc/alectryon_elpi.py \
		    --frontend coq+rst \
			--output-directory doc \
		    --pygments-style vs \
			-R theories elpi -Q src elpi \
			$(tut) &&) true
	@cp stlc.html doc/

.merlin: force
	@rm -f .merlin
	@$(MAKE) --no-print-directory -f Makefile.coq $@

.PHONY: force build all test doc

Makefile.coq Makefile.coq.conf:  src/coq_elpi_config.ml _CoqProject
	@$(COQBIN)/coq_makefile -f _CoqProject -o Makefile.coq
	@$(MAKE) --no-print-directory -f Makefile.coq .merlin
Makefile.test.coq Makefile.test.coq.conf: _CoqProject
	@$(COQBIN)/coq_makefile -f _CoqProject.test -o Makefile.test.coq

src/coq_elpi_config.ml:
	echo "let elpi_dir = \"$(abspath $(ELPIDIR))\";;" > $@

clean:
	@$(MAKE) -f Makefile.coq $@
	@$(MAKE) -f Makefile.test.coq $@
	@$(foreach app,$(APPS),$(MAKE) -C $(app) $@ &&) true

include Makefile.coq.conf
V_FILES_TO_INSTALL := \
  $(filter-out theories/wip/%.v,\
  $(COQMF_VFILES))

install:
	@echo "########################## installing plugin ############################"
	@$(MAKE) -f Makefile.coq $@ VFILES="$(V_FILES_TO_INSTALL)"
	@if [ -x $(COQBIN)/coqtop.byte ]; then \
		$(MAKE) -f Makefile.coq $@-byte VFILES="$(V_FILES_TO_INSTALL)"; \
	fi
	-cp etc/coq-elpi.lang $(COQMF_COQLIB)/ide/
	@echo "########################## installing APPS ############################"
	@$(foreach app,$(APPS),$(MAKE) -C $(app) $@ &&) true
	@echo "########################## installing doc ############################"
	-mkdir -p $(DOCDIR)
	-cp doc/* $(DOCDIR)


# compile just one file
theories/%.vo: force
	@$(MAKE) --no-print-directory -f Makefile.coq $@
tests/%.vo: force build Makefile.test.coq
	@$(MAKE) --no-print-directory -f Makefile.test.coq $@
examples/%.vo: force build Makefile.test.coq
	@$(MAKE) --no-print-directory -f Makefile.test.coq $@

SPACE=$(XXX) $(YYY)
apps/%.vo: force
	@$(MAKE) -C apps/$(word 1,$(subst /, ,$*)) \
		$(subst $(SPACE),/,$(wordlist 2,99,$(subst /, ,$*))).vo
