# Will be called with PWD = project root


RESDIR := $(SRCDIR)/res/title_screen

CLEANTARGETS := $(CLEANTARGETS) $(RESDIR)/frame_0.chr.pb16 $(RESDIR)/frame_0_xor_frame_1.bin $(RESDIR)/frame_1_xor_frame_2.bin

INITTARGETS  := $(INITTARGETS) $(RESDIR)/frame_0.chr.pb16 $(RESDIR)/frame_0_xor_frame_1.bin $(RESDIR)/frame_1_xor_frame_2.bin

${RESDIR}/%.bin: $(RESDIR)/src/generate_masks.py
	cd $(@D) && $(patsubst $(@D)/%,%,$<)


# TODO: give a way to remake frame_0.chr
