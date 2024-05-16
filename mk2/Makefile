Z88DK_TARGET=z80

#EEPROM_TYPE=AT28C64B
#EEPROM_SIZE=8129
#EEPROM_TYPE=AT28C256
#EEPROM_SIZE=32768
EEPROM_TYPE=SST29EE020
EEPROM_SIZE=262144

CODE_ORG=0
BASIC_OFFSET=0x22000

APPMAKE_FLAGS=--org $(CODE_ORG)

AS=zcc
ASFLAGS=+$(Z88DK_TARGET) --notemp --list
LD=zcc
LDFLAGS=+$(Z88DK_TARGET) -startup=-1 --no-crt -m -create-app -Cz '$(APPMAKE_FLAGS)'

PU=minipro
PUFLAGS=--no_id_error -p $(EEPROM_TYPE)

MODULES=lomem.o init.o acia.o stdio.o l7x4.o convert.o delay.o monitor.o msbasic.o
IMAGE=sbos

.PHONY: all eeprom clean $(IMAGE)

all: $(IMAGE).rom

acia.o: acia.asm machine.h.asm ascii.h.asm ioctl.h.asm

blink.o: blink.asm

convert.o: convert.asm machine.h.asm

delay.o: delay.asm machine.h.asm

init.o: init.asm machine.h.asm

l7x4.o: l7x4.asm machine.h.asm

lomem.o: lomem.asm machine.h.asm stdio.h.asm

monitor.o: monitor.asm machine.h.asm stdio.h.asm convert.h.asm

msbasic.o: msbasic.asm machine.h.asm

eeprom: $(IMAGE).rom
	$(PU) $(PUFLAGS) -u -P -w $<

erase-eeprom:
	$(PU) $(PUFLAGS) -u -P -E

zero-eeprom: 
	z88dk-appmake +rom --org $(CODE_ORG) --romsize $(EEPROM_SIZE) --output zero.rom
	$(PU) $(PUFLAGS) -u -P -w zero.rom

dump-eeprom:
	$(PU) $(PUFLAGS) -r - | xxd

$(IMAGE).rom: $(IMAGE)
	z88dk-appmake +rom --org $(CODE_ORG) --romsize $(EEPROM_SIZE) --filler 0 --output $@.0
#	The purpose of this loop is to create 16 identical copies of the base 8K ROM image, so that 
#	no matter which ROM page is selected when A13 is low, we're always accessing the same 8K image
	for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do \
	    j=`expr $$i + 1`; \
	    offset=`expr 8192 \* $$i`; \
	    z88dk-appmake +inject --binfile $@.$$i --offset $$offset --inject $(IMAGE)_CODE.bin --output $@.$$j; \
            rm $@.$$i; \
	done; \
	mv $@.$$j $@.1
	z88dk-appmake +inject --binfile $@.1 --offset $(BASIC_OFFSET) --inject $(IMAGE)_CODE_BASIC.bin --output $@.2
	rm $@.1
	mv $@.2 $@


$(IMAGE): $(MODULES)
	$(LD) $(LDFLAGS) -o $@ $(MODULES)

clean:
	-rm -f *.o *.lis *.sym *.map *.ihx *.bin *.bin_* *.rom $(IMAGE)

distclean: clean
	@-rm -rf .venv

%.o %.asm.lis: %.asm
	$(AS) $(ASFLAGS) --list -c $< -o $(*F).o
