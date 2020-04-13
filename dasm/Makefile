
CSEG_ADDR=2000
DSEG_ADDR=4000

IMAGE=dasm
MODULES=dasm.rel \
	test.rel

DASM_DEPENDS=dasm.asm pged.asm mkarg.asm text.asm mnemonic.asm operand.asm

.PHONY: clean

$(IMAGE).z80: $(IMAGE).bin

$(IMAGE).bin: $(IMAGE).hex

$(IMAGE).hex: $(MODULES)
	ld80 -c -m -s $(IMAGE).sym -o $@ -P $(CSEG_ADDR) -D $(DSEG_ADDR) \
             $(MODULES)

dasm.rel: $(DASM_DEPENDS) 

clean: 
	-rm -f *.rel *.lst *.sym *.hex *.bin *.z80

%.rel %.lst: %.asm
	zmac -o $(*F).rel -o $(*F).lst $<

%.bin: %.hex
	makebin $< $@

%.z80: %.bin
	z80-bin $< $@
