import csv

def ascii_code(k):
	k = k.strip()
	if k == "":
		return 0
	if k.startswith("0x"):
		return int(k[2:], 16)
	else:
		return ord(k)

def print_table(codes, offset):
	for i in range(0, 16):
		line =  16*" " + "db      " 
		for j in range(0, 8):
			scan_code = 8*i + j
			if scan_code not in codes:
				c = 0
			else:
				c = codes[scan_code][offset]
			line += f"${c:02x}"
			if j < 7:
				line += ","
		print(line)	

codes = {}
with open("kbxlat.csv") as input_file:
	reader = csv.reader(input_file)
	next(reader)
	for rec in reader:
		if rec[0] == "End":
			break
		row = int(rec[0])
		label = rec[1]
		scan_code = int(rec[2], 16)
		if scan_code <= 0x80:
			no_mod = ascii_code(rec[3])
			shift_mod = ascii_code(rec[4])
			ctrl_mod = ascii_code(rec[5])
			codes[scan_code] = [label, no_mod, shift_mod, ctrl_mod]

print("xlt_no_mod:")
print_table(codes, 1)
print("xlt_shift_mod:")
print_table(codes, 2)
print("xlt_ctrl_mod:")
print_table(codes, 3)