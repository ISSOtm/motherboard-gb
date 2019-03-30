
.SUFFIXES:
.DEFAULT_GOAL := all


FillValue = 0xFF

ROMVersion = 1

# Header constants (passed to RGBFIX)
# Keeping the old name Motherboard somewhere... ,o7
GameID = MBGB
GameTitle = SOFTBOUNDGB
# Licensed by Homebrew (lel)
NewLicensee = HB
OldLicensee = 0x33 # SGB compat and all that
# MBC5             0x19
# MBC5+RAM         0x1A
# MBC5+RAM+BATTERY 0x1B
MBCType = 0x1B
# ROM size is automatic
# SRAM sizes:
#   8k 0x02
#  32k 0x03
# 128k 0x04
#  64k 0x05
SRAMSize = 0x03


# Directory constants
SRCDIR  = src
BINDIR  = bin
OBJDIR  = obj
DEPSDIR = deps

# Program constants
RGBASM  = rgbasm
RGBLINK = rgblink
RGBFIX  = rgbfix

# Argument constants
ASFLAGS = -E -h -i $(SRCDIR)/ -i $(SRCDIR)/constants/ -i $(SRCDIR)/macros/ -p 0xFF
LDFLAGS = -d -p 0xFF
FXFLAGS = -sj -f lh -i $(GameID) -k $(NewLicensee) -l $(OldLicensee) -m $(MBCType) -n $(ROMVersion) -p $(FillValue) -r $(SRAMSize) -t $(GameTitle)

# The list of "root" ASM files that RGBASM will be invoked on
ASMFILES := $(wildcard $(SRCDIR)/*.asm)



# `superfamiconv`: Converts images to SNES graphics format, used to encode the SGB border
# To build SuperFamiconv here; not necessary if you already have one
superfamiconv: $(SRCDIR)/tools/SuperFamiconv/bin/superfamiconv
.PHONY: superfamiconv

$(SRCDIR)/tools/SuperFamiconv/bin/superfamiconv: $(SRCDIR)/tools/SuperFamiconv
	cd $< && make

# To clone SuperFamiconv's GitHub repo (only has to be done once)
$(SRCDIR)/tools/SuperFamiconv:
	git clone https://github.com/Optiroc/SuperFamiconv.git $@


# Define how to compress files (same recipe for any file)
%.pb16: %
	src/tools/pb16.py $< $@

%.bit7.tilemap: src/tools/bit7ify.py %.tilemap
	$^ $@


INITTARGETS := $(SRCDIR)/constants/maps.asm

# Include all resource Makefiles
# This must be done before we include `$(DEPSDIR)/all` otherwise `dummy` has no prereqs
# FIXME: This might cause empty recipes when conflicts arise? But that's invalid anyways: how do I fix this?
include $(wildcard $(SRCDIR)/res/*/Makefile)



# `all` (Default target): build the ROM
all: $(BINDIR)/motherboard.gb
.PHONY: all

# `clean`: Clean temp and bin files
CLEANTARGETS := $(BINDIR) $(DEPSDIR) $(OBJDIR) dummy $(SRCDIR)/constants/maps.asm # The list of things that must be cleared; expanded by the resource Makefiles
clean:
	-rm -rf $(CLEANTARGETS)
.PHONY: clean

# `rebuild`: Build everything from scratch
# It's important to do these two in order if we're using more than one job
rebuild:
	$(MAKE) clean
	$(MAKE) all
.PHONY: rebuild

# `dummy` is a dummy target to build the resource files necessary for RGBASM to not fail on compilation
# It's made an actual file to avoid an infinite compilation loop
# INITTARGETS is defined by the resource Makefiles
dummy: $(INITTARGETS)
	@echo "THIS FILE ENSURES THAT COMPILATION GOES RIGHT THE FIRST TIME, DO NOT DELETE" > $@

# `.d` files are generated as dependency lists of the "root" ASM files, to save a lot of hassle.
# > Obj files also depend on `dummy` to ensure all the binary files are present, so RGBASM doesn't choke on them not being present;
# > This would cause the first compilation to never finish, thus Make never knows to build the binary files, thus deadlocking everything.
# Compiling also generates dependency files!
# Also add all obj dependencies to the deps file too, so Make knows to remake it
$(DEPSDIR)/%.d: $(OBJDIR)/%.o ;

$(OBJDIR)/%.o: DEPFILE = $(DEPSDIR)/$*.d
$(OBJDIR)/%.o: $(SRCDIR)/%.asm dummy
	@mkdir -p $(DEPSDIR)
	@mkdir -p $(OBJDIR)
	set -e; \
	TMP_DEPFILE=$$(mktemp); \
	$(RGBASM) -M $$TMP_DEPFILE $(ASFLAGS) -o $@ $<; \
	sed 's,\($*\)\.o[ :]*,\1.o $(DEPFILE): ,g' < $$TMP_DEPFILE > $(DEPFILE); \
	for line in $$(cut -d ":" -f 2 $$TMP_DEPFILE); do if [ "$$line" != "$<" ]; then echo "$$line: ;" >> $(DEPFILE); fi; done; \
	rm $$TMP_DEPFILE

# Include (and potentially remake) all dependency files
# Remove duplicated recipes, hence using yet another file grouping everything
$(DEPSDIR)/all: $(patsubst $(SRCDIR)/%.asm,$(DEPSDIR)/%.d,$(ASMFILES))
	cat $^ | sort | uniq > $@
ifneq ($(MAKECMDGOALS),clean)
include $(DEPSDIR)/all
endif


# How to make the ROM
$(BINDIR)/motherboard.gb: $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(ASMFILES))
	@mkdir -p $(BINDIR)

	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/build_date.o $(SRCDIR)/res/build_date.asm

	set -e; \
	TMP_ROM=$$(mktemp); \
	$(RGBLINK) $(LDFLAGS) -o $$TMP_ROM -m $(@:.gb=.map) -n $(@:.gb=.sym) $^ $(OBJDIR)/build_date.o; \
	$(RGBFIX) $(FXFLAGS) $$TMP_ROM; \
	\
	src/tools/crcify.py $$TMP_ROM; \
	$(RGBFIX) -v $$TMP_ROM; \
	\
	mv $$TMP_ROM $(BINDIR)/motherboard.gb
