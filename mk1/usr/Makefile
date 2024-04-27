ORG_ADDR=0xfc00

.PHONY:	all clean

all: usr.ihx

usr.ihx: usr.rom

usr.rom: usr.asm
	zcc +z80 $<   --no-crt -o $@ -s -m -l --reloc-info -create-app -Cz '--ihex --org $(ORG_ADDR)'	

clean:
	-rm -f *.ihx *.rom *.lst *.map *.sym
