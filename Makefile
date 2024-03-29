
.SUFFIXES:
.DEFAULT_GOAL := all
.SECONDEXPANSION:



################################################
#                                              #
#             CONSTANT DEFINITIONS             #
#                                              #
################################################

# Directory constants
SRCDIR  = src
BINDIR  = bin
OBJDIR  = obj
DEPSDIR = deps

# Program constants
RGBASM  = rgbasm
RGBLINK = rgblink
RGBFIX  = rgbfix
MKDIR   = $(shell which mkdir)

ROMFile = $(BINDIR)/$(ROMName).$(ROMExt)

# Project-specific configuration
include Makefile.conf


# Argument constants
ASFLAGS += -E -h -i $(SRCDIR)/ -i $(SRCDIR)/constants/ -i $(SRCDIR)/macros/ -p $(FillValue)
LDFLAGS += -d -p $(FillValue)
FXFLAGS += -j -f lh -i $(GameID) -k $(NewLicensee) -l $(OldLicensee) -m $(MBCType) -n $(ROMVersion) -p $(FillValue) -r $(SRAMSize) -t $(GameTitle)

# The list of "root" ASM files that RGBASM will be invoked on
ASMFILES := $(wildcard $(SRCDIR)/*.asm)



################################################
#                                              #
#                RESOURCE FILES                #
#                                              #
################################################

# Define how to compress files (same recipe for any file)
%.pb16: %
	src/tools/pb16.py $< $@

# RGBGFX generates tilemaps with sequential tile IDs, which works fine for $8000 mode but not $8800 mode; `bit7ify.py` takes care to flip bit 7 so maps become $8800-compliant
%.bit7.tilemap: src/tools/bit7ify.py %.tilemap
	$^ $@

# RGBGFX generates tilemaps with IDs starting at 0, which is not always the address things are loaded
# Note: to generate `foo.90.offset.tilemap`, we want `foo.tilemap`, which is a tad difficult to specify in Make terms
%.offset.tilemap: src/tools/offset_tilemap.py $$(dir $$@)$$(basename $$*).tilemap
	$^ $@


CLEANTARGETS := $(BINDIR) $(DEPSDIR) $(OBJDIR) dummy $(SRCDIR)/constants/maps.asm # The list of things that must be cleared; expanded by the resource Makefiles
INITTARGETS := $(SRCDIR)/constants/maps.asm

# Include all resource Makefiles
# This must be done before we include `$(DEPSDIR)/all` otherwise `dummy` has no prereqs
include $(wildcard $(SRCDIR)/res/*/Makefile)



# `all` (Default target): build the ROM
all: $(ROMFile)
.PHONY: all

# `clean`: Clean temp and bin files
clean:
	-rm -rf $(CLEANTARGETS)
.PHONY: clean

# `.d` files are generated as dependency lists of the "root" ASM files, to save a lot of hassle.
# Compiling also generates dependency files!
# Also add all obj dependencies to the deps file too, so Make knows to remake it
$(DEPSDIR)/%.d: $(SRCDIR)/%.asm
	@$(MKDIR) -p $(DEPSDIR)
	$(RGBASM) $(ASFLAGS) -M "$@" -MG -MP -MQ "$@" -MQ "$@" "$<"

$(OBJDIR)/%.o: $(SRCDIR)/%.asm
	@$(MKDIR) -p $(OBJDIR)
	$(RGBASM) $(ASFLAGS) -o $@ $<

ifneq ($(MAKECMDGOALS),clean)
include $(patsubst $(SRCDIR)/%.asm,$(DEPSDIR)/%.d,$(ASMFILES))
endif


# How to make the ROM
$(ROMFile): $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(ASMFILES))
	@$(MKDIR) -p $(BINDIR)

	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/build_date.o $(SRCDIR)/res/build_date.asm

	set -e; \
	TMP_ROM=$$(mktemp); \
	$(RGBLINK) $(LDFLAGS) -o $$TMP_ROM -m $(@:.gb=.map) -n $(@:.gb=.sym) $^ $(OBJDIR)/build_date.o; \
	$(RGBFIX) $(FXFLAGS) $$TMP_ROM; \
	\
	src/tools/crcify.py $$TMP_ROM; \
	$(RGBFIX) -v $$TMP_ROM; \
	\
	mv $$TMP_ROM $(ROMFile)
