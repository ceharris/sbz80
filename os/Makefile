# Makefile for SBZ80 Operating System Image
 
CSEG_ADDR=0400
DSEG_ADDR=2000

#
# Linker utility
LD=ld80

# EEPROM programmer utility and flags
PU=minipro
EEPROM_TYPE=AT28C64B

MODULES=lomem.rel \
	init.rel \
	svc.rel \
 	muldiv.rel \
	ctc.rel \
	pio.rel \
	sio.rel \
	spi.rel \
	con.rel \
	ki.rel \
	l7.rel \
	lc.rel \
	tk.rel \
	adc.rel \
	rtc.rel \
	prog.rel

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
	$(LD) -O ihex -c -m -s $(IMAGE).sym -o $@ -P $(CSEG_ADDR) -D $(DSEG_ADDR) $(MODULES)

init.rel: init.asm memory.asm ports.asm isr.asm

ctc.rel: ctc.asm memory.asm ports.asm isr.asm ctc_defs.asm

pio.rel: pio.asm memory.asm ports.asm isr.asm pio_defs.asm

sio.rel: sio.asm memory.asm ports.asm isr.asm sio_defs.asm

spi.rel: spi.asm memory.asm ports.asm

con.rel: con.asm

ki.rel: ki.asm memory.asm ports.asm isr.asm pio_defs.asm

l7.rel: l7.asm spi_defs.asm

lc.rel: lc.asm ports.asm pio_defs.asm

tk.rel: tk.asm memory.asm ports.asm isr.asm ctc_defs.asm

adc.rel: adc.asm ports.asm adc_defs.asm spi_defs.asm

rtc.rel: rtc.asm spi_defs.asm

prog.rel: prog.asm svcid.asm

svcid.asm: lomem.lst
	grep "^@" $< | sed -E 's/ *= *([0-9a-fA-F]*) .*/		.equ 0x\1/' >$@

clean:
	-rm -f svcid.asm *.rel *.lst *.sym *.hex *.bin *.z80

distclean: clean
	-rm -rf .venv

%.rel %.lst: %.asm
	zmac -o $(*F).rel -o $(*F).lst $<
