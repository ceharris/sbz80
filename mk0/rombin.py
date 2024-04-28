from intelhex import IntelHex

ih = IntelHex()
ih.padding = 0
ih.fromfile("sbos.hex", format="hex")
start = ih.segments()[0][0]
ih.tobinfile("sbos.bin", start=start, size=8192)