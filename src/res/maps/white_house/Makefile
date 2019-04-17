# Will be called with PWD = project root

MAPGFXFILES  += white_house/white_house

INITTARGETS  := $(INITTARGETS) $(RESDIR)/white_house/white_house.bit7.tilemap

CLEANTARGETS := $(CLEANTARGETS) $(RESDIR)/white_house/white_house.bit7.tilemap


$(RESDIR)/white_house/white_house.chr $(RESDIR)/white_house/white_house.tilemap: $(RESDIR)/white_house/white_house.png $(RESDIR)/white_house/collision.png
	rgbgfx -o $(<:.png=.chr) -T -u $<

$(RESDIR)/white_house/white_house.asm: $(RESDIR)/white_house/white_house.chr.pb16
