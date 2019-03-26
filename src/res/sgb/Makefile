
RESDIR := src/res/sgb


SUPERFAMICONVFLAGS = -M snes --tile-width 8 --tile-height 8
COLORZERO = "\#00000000"


BORDERIMGS := $(wildcard $(RESDIR)/borders/*.png)
BORDERFILES := $(patsubst %.png,%.borderchr,$(BORDERIMGS)) $(patsubst %.png,%.borderattr,$(BORDERIMGS))
BORDERTMPFILES := $(patsubst %.png,%.bordermap,$(BORDERIMGS)) $(patsubst %.png,%.4.bordermap,$(BORDERIMGS)) $(patsubst %.png,%.borderpal,$(BORDERIMGS))

CLEANTARGETS := $(CLEANTARGETS) $(BORDERFILES) $(patsubst %,%.pb16,$(BORDERFILES)) $(BORDERTMPFILES) $(RESDIR)/attr_files.bin $(RESDIR)/attr_files.bin.pb16 $(RESDIR)/palettes.bin.pb16 $(RESDIR)/palettes.bin

INITTARGETS := $(INITTARGETS) $(RESDIR)/attr_files.bin.pb16 $(RESDIR)/palettes.bin.pb16 # $(patsubst %,%.pb16,$(BORDERFILES))


# The command run by this is basically a giant hack, but hey, it works!
$(RESDIR)/%.bin: $(RESDIR)/%.py $(RESDIR)/%.json
	cd $(@D) && ./$(^F) $(@F)

$(RESDIR)/attr_files.bin: $(wildcard $(RESDIR)/attr_files/*.txt)


$(RESDIR)/borders/%.borderpal: $(RESDIR)/borders/%.png $(SRCDIR)/tools/SuperFamiconv/bin/superfamiconv
	$(SRCDIR)/tools/SuperFamiconv/bin/superfamiconv palette -i $< -d $@ \
		$(SUPERFAMICONVFLAGS) -P 3 -C 16 --color-zero $(COLORZERO)
$(RESDIR)/borders/%.borderchr: $(RESDIR)/borders/%.png $(RESDIR)/borders/%.borderpal $(SRCDIR)/tools/SuperFamiconv/bin/superfamiconv
	$(SRCDIR)/tools/SuperFamiconv/bin/superfamiconv tiles -i $< -p $(RESDIR)/borders/%.borderpal -d $@ \
		$(SUPERFAMICONVFLAGS) -B 4 --max-tiles 128
$(RESDIR)/borders/%.bordermap: $(RESDIR)/borders/%.png $(RESDIR)/borders/%.borderpal $(RESDIR)/borders/%.borderchr $(SRCDIR)/tools/SuperFamiconv/bin/superfamiconv
	$(SRCDIR)/tools/SuperFamiconv/bin/superfamiconv map -i $< -p $(RESDIR)/borders/%.borderpal -t $(RESDIR)/borders/%.borderchr -d $@ \
		$(SUPERFAMICONVFLAGS) -B 4 --map-width 32 --map-height 28 --color-zero $(COLORZERO)
	truncate -s $(expr 32 * 32) $@

# SuperFamiconv can't generate palettes starting from #4 (mandatory for SGB borders, which can only use palettes 4-6, maybe also 7?)
$(RESDIR)/borders/%.4.bordermap: $(SRCDIR)/tools/shift_border_palettes.py $(RESDIR)/borders/%.bordermap
	$^ $@

$(RESDIR)/borders/%.borderattr: $(RESDIR)/borders/%.4.bordermap $(RESDIR)/borders/%.borderpal
	cat $^ > $@
