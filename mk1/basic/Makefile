Z88DK_TARGET=z80

APPMAKE_FLAGS=--org 0

AS=zcc
#ASFLAGS=+$(Z88DK_TARGET) -Ca '-I$(PWD)/..' --notemp --list
LD=zcc
LDFLAGS=+$(Z88DK_TARGET) -startup=-1 --no-crt -m -create-app -Cz '$(APPMAKE_FLAGS)'

MODULES=main.o msbasic.o acia.o delay.o romjump.o
IMAGE=main

.PHONY: all clean $(IMAGE)

all: $(IMAGE)

main.o: main.asm ../machine.h.asm workspace.h.asm

acia.o: ../../common/acia.asm ../../include/acia.h.asm ../machine.h.asm workspace.h.asm

delay.o: ../../common/delay.asm

msbasic.o: ../../common/msbasic.asm ../../include/msbasic.h.asm ../machine.h.asm workspace.h.asm

romjump.o: ../../common/romjump.asm ../../include/romjump.h.asm ../machine.h.asm

$(IMAGE): $(MODULES)
	$(LD) $(LDFLAGS) -o $@.bin $(MODULES)

clean:
	-rm -f *.o *.lis *.sym *.map *.ihx *.bin *.bin_* *.rom $(IMAGE)
	-rm -f ../../common/*.lis

%.o %.asm.lis: %.asm
	$(AS) $(ASFLAGS) -c $< -o $(*F).o

%.o %.asm.lis: ../../common/%.asm
	$(AS) $(ASFLAGS) -c $< -o $(*F).o
