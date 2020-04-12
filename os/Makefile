# Makefile for SBZ80 Operating System Image

# Align code segment on the next 256-byte page boundary after 
# the SVC dispatch table at 0x100
CSEG_ADDR=0200 

# Align the data segment on the next 256-byte page boundary after
# the interrupt mode 2 dispatch table at 0x2000
DSEG_ADDR=2100

# Port and speed for EEPROM programmer
PORT=/dev/cu.usbmodem14101
SPEED=115200

MODULES=lomem.rel \
	post.rel \
	init.rel \
	rpeek.rel \
	bnksel.rel \
	do.rel \
	exit.rel \
        hex.rel \
	setvec.rel \
	strcpy.rel \
	demo.rel

IMAGE=sbos

.PHONY: all eeprom clean $(IMAGE)

all: $(IMAGE)

$(IMAGE): $(IMAGE).z80

eeprom: $(IMAGE).hex
	sendihex8 $< $(PORT) $(SPEED)

$(IMAGE).z80: $(IMAGE).bin
	z80-bin $< $@

$(IMAGE).bin: $(IMAGE).hex
	makebin $< $@

$(IMAGE).hex: $(MODULES)
	ld80 -c -m -s $(IMAGE).sym -o $@ -P $(CSEG_ADDR) -D $(DSEG_ADDR) $(MODULES)

demo.rel: svc.asm

svc.asm: lomem.lst
	grep "^@" $< | sed -E 's/ *= *([0-9a-fA-F]*)/ equ 0x\1/' >$@

clean:
	-rm -f svc.asm *.rel *.lst *.sym *.hex *.bin *.z80

%.rel %.lst: %.asm
	zmac -o $(*F).rel -o $(*F).lst $<
