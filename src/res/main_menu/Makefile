# Will be called with PWD = project root


RESDIR := $(SRCDIR)/res/main_menu

CLEANTARGETS := $(CLEANTARGETS) $(RESDIR)/main_menu.oam.chr $(RESDIR)/music_player.chr $(RESDIR)/music_player.tilemap $(RESDIR)/music_player.90.offset.tilemap

INITTARGETS  := $(INITTARGETS) $(RESDIR)/main_menu.oam.chr $(RESDIR)/music_player.chr $(RESDIR)/music_player.90.offset.tilemap

$(RESDIR)/%.chr $(RESDIR)/%.tilemap: $(RESDIR)/src/%.png
	rgbgfx -u -o $(@D)/$*.chr -t $(@D)/$*.tilemap $<

$(RESDIR)/%.oam.chr: $(RESDIR)/src/%.oam.png
	rgbgfx -h -o $@ $<
