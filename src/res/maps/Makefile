
RESDIR := $(SRCDIR)/res/maps


include $(wildcard $(RESDIR)/*/Makefile)

MAPGFXFILELIST = $(patsubst %,$(RESDIR)/%.chr.pb16,$(MAPGFXFILES)) $(patsubst %,$(RESDIR)/%.chr,$(MAPGFXFILES)) $(patsubst %,$(RESDIR)/%.asm,$(MAPGFXFILES))


CLEANTARGETS := $(CLEANTARGETS) $(MAPGFXFILELIST)

INITTARGETS  := $(INITTARGETS)  $(MAPGFXFILELIST)


$(RESDIR)/%.chr $(RESDIR)/%.asm: $(SRCDIR)/tools/gen_map.py $(RESDIR)/%.json
	$^

$(SRCDIR)/constants/maps.asm: $(SRCDIR)/tools/gen_map_enum.py $(SRCDIR)/maps.asm $(wildcard $(RESDIR)/**/*.json)
	$^

