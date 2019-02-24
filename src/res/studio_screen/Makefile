# Will be called with PWD = project root


RESDIR := $(SRCDIR)/res/studio_screen

CLEANTARGETS := $(CLEANTARGETS) $(RESDIR)/studio_screen.chr.pb16 $(RESDIR)/studio_screen.chr $(RESDIR)/studio_screen.tilemap
CLEANTARGETS := $(CLEANTARGETS) $(RESDIR)/credits.chr.pb16 $(RESDIR)/credits.chr $(RESDIR)/credits.tilemap

INITTARGETS  := $(INITTARGETS) $(RESDIR)/studio_screen.chr.pb16 $(RESDIR)/studio_screen.tilemap
INITTARGETS  := $(INITTARGETS) $(RESDIR)/credits.chr.pb16 $(RESDIR)/credits.tilemap

${RESDIR}/studio_screen.chr ${RESDIR}/studio_screen.tilemap: ${RESDIR}/src/itzacom-GB.png
$(RESDIR)/credits.chr $(RESDIR)/credits.tilemap: $(RESDIR)/src/credits.png

$(RESDIR)/%.chr:
	rgbgfx -u -o $@ -t $(@:.chr=.tilemap) $<
$(RESDIR)/%.tilemap: $(RESDIR)/%.chr
