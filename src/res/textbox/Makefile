# Will be called with PWD = project root


RESDIR := $(SRCDIR)/res/textbox

CLEANTARGETS := $(CLEANTARGETS) $(RESDIR)/textbox.chr $(RESDIR)/latin.font

INITTARGETS  := $(INITTARGETS) $(RESDIR)/textbox.chr $(RESDIR)/latin.font

$(RESDIR)/textbox.chr: $(RESDIR)/src/textbox.png

$(RESDIR)/%.chr:
	rgbgfx -T -o $@ $<
$(RESDIR)/%.tilemap: $(RESDIR)/%.chr

$(RESDIR)/%.font: $(SRCDIR)/tools/make_font.py $(RESDIR)/src/%.png
	$^ $@
