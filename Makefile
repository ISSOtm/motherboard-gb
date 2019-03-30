
.SUFFIXES:
.DEFAULTTARGET: all


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
	$(RGBASM) -M $(DEPFILE).tmp $(ASFLAGS) -o $@ $<; \
	sed 's,\($*\)\.o[ :]*,\1.o $(DEPFILE): ,g' < $(DEPFILE).tmp > $(DEPFILE); \
	for line in $$(cut -d ":" -f 2 $(DEPFILE).tmp); do if [ "$$line" != "$<" ]; then echo "$$line: ;" >> $(DEPFILE); fi; done; \
	rm $(DEPFILE).tmp

# Include (and potentially remake) all dependency files
# Remove duplicated recipes, hence using yet another file grouping everything
$(DEPSDIR)/all: $(patsubst $(SRCDIR)/%.asm,$(DEPSDIR)/%.d,$(ASMFILES))
	cat $^ | sort | uniq > $@
include $(DEPSDIR)/all


# How to make the ROM
$(BINDIR)/motherboard.gb: $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(ASMFILES))
	@mkdir -p $(BINDIR)

	$(RGBASM) $(ASFLAGS) -o $(OBJDIR)/build_date.o $(SRCDIR)/res/build_date.asm

	$(RGBLINK) $(LDFLAGS) -o $(BINDIR)/tmp.gb -m $(@:.gb=.map) -n $(@:.gb=.sym) $^ $(OBJDIR)/build_date.o
	$(RGBFIX) $(FXFLAGS) $(BINDIR)/tmp.gb

	src/tools/crcify.py $(BINDIR)/tmp.gb
	$(RGBFIX) -v $(BINDIR)/tmp.gb

	mv $(BINDIR)/tmp.gb $(BINDIR)/motherboard.gb



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
# Some of these are also present in $(DEPSDIR)/all, so this must be placed after to override them (otherwise we end up with empty recipes)
include $(wildcard $(SRCDIR)/res/*/Makefile)
