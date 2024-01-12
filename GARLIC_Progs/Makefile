#---------------------------------------------------------------------------------------------------
# Makefile for building all GARLIC programs and copying them to nitrofiles
# based on this answer from StackOverflow: https://stackoverflow.com/a/17845120
# and: https://lists.gnu.org/archive/html/help-make/2008-04/msg00052.html
#---------------------------------------------------------------------------------------------------
# Usage:
#
# Building/cleaning all programs:
#   make (or make all): build all programs (subfolders) and copy to nitrofiles.
#   make clean: run make clean on all subfolders and remove their .elfs from nitrofiles
#
# Building/cleaning a specific program:
#   make folder_name: build a specific program (subfolder) and copy to nitrofiles.
#   make folder_name.clean: clean a specific program (subfolder) and remove its .elf from nitrofiles
#---------------------------------------------------------------------------------------------------

SUBDIRS := $(patsubst %/.,%,$(wildcard */.))
SUBCLEAN := $(addsuffix .clean,$(SUBDIRS))

# The nitrofiles subfolder that contains the .elf files
PROGRAMS := $(CURDIR)/../GARLIC_OS/nitrofiles/Programas
API := $(CURDIR)/../GARLIC_API

all: $(SUBDIRS) $(API)

clean: $(SUBCLEAN)

$(API):
	@$(MAKE) -C $@

$(SUBDIRS): | $(PROGRAMS)
	@$(MAKE) -C $@
	@cp -f "$@/$@.elf" "$(PROGRAMS)/"

$(SUBCLEAN): %.clean:
	@$(MAKE) -C $* clean
	@rm -f "$(PROGRAMS)/$*.elf"

$(PROGRAMS): | $(API)
	mkdir -p $(PROGRAMS)

.PHONY: all clean $(API) $(SUBDIRS) $(SUBCLEAN)
