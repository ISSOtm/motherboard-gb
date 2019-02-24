
RESDIR := src/res/sgb


CLEANTARGETS := $(CLEANTARGETS) $(RESDIR)/attr_files.bin $(RESDIR)/attr_files.bin.pb16 $(RESDIR)/palettes.bin.pb16 $(RESDIR)/palettes.bin

INITTARGETS := $(INITTARGETS) $(RESDIR)/attr_files.bin.pb16 $(RESDIR)/palettes.bin.pb16


# The command run by this is basically a giant hack, but hey, it works!
$(RESDIR)/%.bin: $(RESDIR)/%.py $(RESDIR)/%.json
	cd $(@D) && ./$(^F) $(@F)

$(RESDIR)/attr_files.bin: $(wildcard $(RESDIR)/attr_files/*.txt)
