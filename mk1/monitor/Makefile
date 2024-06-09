Z88DK_TARGET=z80

APPMAKE_FLAGS=--org 0

AS=zcc
LD=zcc
LDFLAGS=+$(Z88DK_TARGET) -startup=-1 --no-crt -m -create-app -Cz '$(APPMAKE_FLAGS)'

MODULES=main.o monitor.o convert.o acia.o stdio.o delay.o romjump.o
IMAGE=main

.PHONY: all clean $(IMAGE)

all: $(IMAGE)

main.o: main.asm ../machine.h.asm workspace.h.asm

acia.o: ../../common/acia.asm ../../include/acia.h.asm ../machine.h.asm workspace.h.asm

convert.o: ../../common/convert.asm ../../include/convert.h.asm

delay.o: ../../common/delay.asm

monitor.o: ../../common/monitor.asm ../../include/monitor.h.asm ../machine.h.asm workspace.h.asm 

romjump.o: ../../common/romjump.asm ../../include/romjump.h.asm ../machine.h.asm

stdio.o: ../../common/stdio.asm ../../include/stdio.h.asm


$(IMAGE): $(MODULES)
	$(LD) $(LDFLAGS) -o $@.bin $(MODULES)

clean:
	-rm -f *.o *.lis *.sym *.map *.ihx *.bin *.bin_* *.rom $(IMAGE)
	-rm -f ../../common/*.lis

%.o %.asm.lis: %.asm
	$(AS) $(ASFLAGS) -c $< -o $(*F).o

%.o %.asm.lis: ../../common/%.asm
	$(AS) $(ASFLAGS) -c $< -o $(*F).o
