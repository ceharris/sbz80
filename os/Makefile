# Makefile for SBZ80 Operating System Image

# Align code segment on the next 256-byte page boundary after 
# the SVC dispatch table at 0x100
CSEG_ADDR=0200 

# Align the data segment at the start of RAM
DSEG_ADDR=2000

# Linker utility
LD=ld80

# EEPROM programmer utility and flags
PU=minipro
EEPROM_TYPE=AT28C64B

MODULES=lomem.rel \
	post.rel \
	init.rel \
	ctc.rel \
	pio.rel \
	rpeek.rel \
	muldiv.rel \
	bnksel.rel \
	tk.rel \
	do.rel \
	ki.rel \
	exit.rel \
        hex.rel \
	setisr.rel \
	setvec.rel \
	strcpy.rel \
	sysvar.rel \
	demo.rel

IMAGE=sbos

.PHONY: all eeprom clean $(IMAGE)

all: $(IMAGE)

$(IMAGE): $(IMAGE).hex

eeprom: $(IMAGE).hex
	$(PU) -p $(EEPROM_TYPE) -f ihex -w $<

erase-eeprom:
	$(PU) -p $(EEPROM_TYPE) -E

zero-eeprom: 
	zmac -o zero.hex zero.asm	
	$(PU) -p $(EEPROM_TYPE) -f ihex -w zero.hex

dump-eeprom:
	$(PU) -p $(EEPROM_TYPE) -r - | xxd

$(IMAGE).hex: $(MODULES)
	$(LD) -c -m -s $(IMAGE).sym -o $@ -P $(CSEG_ADDR) -D $(DSEG_ADDR) $(MODULES)

demo.rel: svc.asm

lomem.rel: lomem.asm memory.asm

post.rel: post.asm memory.asm ports.asm

init.rel: init.asm memory.asm isr.asm ports.asm ctc_defs.asm

ctc.rel: isr.asm ports.asm ctc_defs.asm

pio.rel: ports.asm pio_defs.asm

tk.rel: tk.asm isr.asm ports.asm ctc_defs.asm

do.rel: do.asm ports.asm pio_defs.asm

ki.rel: ki.asm memory.asm isr.asm ports.asm ctc_defs.asm pio_defs.asm

svc.asm: lomem.lst
	grep "^@" $< | sed -E 's/ *= *([0-9a-fA-F]*)/		equ 0x\1/' >$@


clean:
	-rm -f svc.asm *.rel *.lst *.sym *.hex *.bin *.z80

%.rel %.lst: %.asm
	zmac -o $(*F).rel -o $(*F).lst $<
