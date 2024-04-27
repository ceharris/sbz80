Z88DK_TARGET=z80

#EEPROM_TYPE=AT28C64B
#EEPROM_SIZE=8129
EEPROM_TYPE=AT28C256
EEPROM_SIZE=32768
EEPROM_ORG=0
BASIC_ORG=0x2000

APPMAKE_FLAGS=--org $(EEPROM_ORG)

AS=zcc
ASFLAGS=+$(Z88DK_TARGET) --notemp --list
LD=zcc
LDFLAGS=+$(Z88DK_TARGET) -startup=-1 --no-crt -m -create-app -Cz '$(APPMAKE_FLAGS)'

PU=minipro
PUFLAGS=--no_id_error -p $(EEPROM_TYPE)

MODULES=lomem.o init.o acia.o stdio.o convert.o monitor.o msbasic.o
#MODULES=blink.o

IMAGE=sbos

.PHONY: all eeprom clean $(IMAGE)

all: $(IMAGE).rom

init.o: init.asm machine.h.asm stdio.h.asm bcd.h.asm

bcd.o: bcd.asm machine.h.asm bcd.h.asm

serial.o: serial.asm machine.h.asm serial.h.asm

stdio.o: stdio.asm machine.h.asm stdio.h.asm

acia.o: acia.asm machine.h.asm acia.h.asm

am9511.o: am9511.asm machine.h.asm am9511.h.asm

hex.o: hex.asm machine.h.asm hex.h.asm

convert.o: convert.asm machine.h.asm convert.h.asm

monitor.o: monitor.asm machine.h.asm convert.h.asm stdio.h.asm

msbasic.o: msbasic.asm machine.h.asm stdio.h.asm

eeprom: $(IMAGE).rom
	$(PU) $(PUFLAGS) -u -P -w $<

erase-eeprom:
	$(PU) $(PUFLAGS) -u -P -E

zero-eeprom: 
	z88dk-appmake +rom --org $(EEPROM_ORG) --romsize $(EEPROM_SIZE) --output zero.rom
	$(PU) $(PUFLAGS) -u -P -w zero.rom

dump-eeprom:
	$(PU) $(PUFLAGS) -r - | xxd

$(IMAGE).rom: $(IMAGE)
	z88dk-appmake +rom --org $(EEPROM_ORG) --romsize $(EEPROM_SIZE) --output $@.0
	z88dk-appmake +inject --binfile $@.0 --offset $(EEPROM_ORG) --inject $(IMAGE)_CODE.bin --output $@.1
	z88dk-appmake +inject --binfile $@.1 --offset $(BASIC_ORG) --inject $(IMAGE)_CODE_BASIC.bin --output $@
	rm $@.0 $@.1

$(IMAGE): $(MODULES)
	$(LD) $(LDFLAGS) -o $@ $(MODULES)

clean:
	-rm -f *.o *.lis *.sym *.map *.ihx *.bin *.bin_* *.rom

distclean: clean
	@-rm -rf .venv

%.o %.asm.lis: %.asm
	$(AS) $(ASFLAGS) --list -c $< -o $(*F).o
