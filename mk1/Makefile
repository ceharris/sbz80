Z88DK_TARGET=z80

#EEPROM_TYPE=AT28C64B
#EEPROM_SIZE=8129
EEPROM_TYPE=AT28C256
EEPROM_SIZE=32768
EEPROM_ORG=0
BASIC_ORG=0x2000

APPMAKE_FLAGS=--org $(EEPROM_ORG)

AS=zcc
ASFLAGS=+$(Z88DK_TARGET) -Ca -I$(PWD) --notemp --list
LD=zcc
LDFLAGS=+$(Z88DK_TARGET) -startup=-1 --no-crt -m -create-app -Cz '$(APPMAKE_FLAGS)'

PU=minipro
PUFLAGS=--no_id_error -p $(EEPROM_TYPE)

TOPTARGETS := all clean eeprom

APPS=monitor basic

IMAGE=sbos

.PHONY: all clean eeprom $(IMAGE) $(APPS)

all: $(IMAGE).rom

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
	z88dk-appmake +rom --org $(EEPROM_ORG) --romsize $(EEPROM_SIZE) --filler 0 --output $@.0
	z88dk-appmake +inject --binfile $@.0 --offset $(EEPROM_ORG) --inject monitor/main.bin --output $@.1
	z88dk-appmake +inject --binfile $@.1 --offset $(BASIC_ORG) --inject basic/main.bin --output $@
	rm $@.0 $@.1

$(IMAGE): $(APPS)

$(APPS):
	AS=zcc ASFLAGS="$(ASFLAGS)" LD=zcc LDFLAGS="$(LDFLAGS)" $(MAKE) -C $@ all

clean:
	for app in $(APPS); do \
	  make -C $$app clean; \
	done
	-rm -f *.o *.lis *.sym *.map *.ihx *.bin *.bin_* *.rom $(IMAGE)

distclean: clean
	@-rm -rf .venv

%.o %.asm.lis: %.asm
	$(AS) $(ASFLAGS) --list -c $< -o $(*F).o
