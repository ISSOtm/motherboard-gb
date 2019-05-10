
RESDIR := src/res/lang_screen


CLEANTARGETS := $(CLEANTARGETS) $(RESDIR)/gfx.chr $(RESDIR)/gfx.chr.pb16

INITTARGETS := $(INITTARGETS) $(RESDIR)/gfx.chr.pb16


$(RESDIR)/gfx.chr: $(RESDIR)/gfx.png
	rgbgfx -u -o $@ $<
