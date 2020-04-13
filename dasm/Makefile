
CSEG_ADDR=2000
DSEG_ADDR=4000
TEST_DSEG_ADDR=C000

IMAGE=dasm
TEST_IMAGE=dasm-test

MODULES=dasm.rel \
	mkarg.rel \
	text.rel

.PHONY: all clean

all: $(IMAGE).z80 $(TEST_IMAGE).z80
	
$(IMAGE).z80: $(IMAGE).bin

$(IMAGE).bin: $(IMAGE).hex

$(IMAGE).hex: $(MODULES)
	ld80 -c -m -s $(IMAGE).sym -o $@ \
	     -P $(CSEG_ADDR) -D $(DSEG_ADDR) $(MODULES)

$(TEST_IMAGE).z80: $(TEST_IMAGE).bin

$(TEST_IMAGE).bin: $(TEST_IMAGE).hex

$(TEST_IMAGE).hex: $(MODULES) test.rel
	ld80 -c -m -s $(TEST_IMAGE).sym -o $@ \
	     -P $(CSEG_ADDR) -D $(TEST_DSEG_ADDR) -E test $(MODULES) test.rel

dasm.rel: dasm.asm pgcb.asm pged.asm defs.asm

mkarg.rel: mkarg.asm defs.asm

text.rel: text.asm defs.asm operand.asm mnemonic.asm

test.rel: test.asm optest.asm

clean: 
	-rm -f *.rel *.lst *.sym *.hex *.bin *.z80

%.rel %.lst: %.asm
	zmac -o $(*F).rel -o $(*F).lst $<

%.bin: %.hex
	makebin $< $@

%.z80: %.bin
	z80-bin $< $@
