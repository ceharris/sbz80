		name test

		include defs.asm

		extern dasm
		extern i2str

		include optest.asm

		aseg
		org 0
		jp test

		cseg
	;-------------------------------------------------------------
	; test:
	;
	; Runs the suite of disassembly tests and returns if successful
	;
test::
		ld sp,0
		ld iy,dbuf

		; page 0 section 0 column 0
		optest <nop>,"NOP"
		optest <ex af,af'>,"EX AF,AF'"
		optest <djnz test_djnz>,"DJNZ -2",test_djnz
		optest <jr test_jr>,"JR -2",test_jr
		optest <jr nz,test_jrnz>,"JR NZ,-2",test_jrnz
		optest <jr z,test_jrz>,"JR Z,-2",test_jrz
		optest <jr nc,test_jrnc>,"JR NC,-2",test_jrnc
		optest <jr c,test_jrc>,"JR C,-2",test_jrc
		
		; page 0 section 0 column 1
		optest <ld bc,0xbeef>,'LD BC,0xBEEF'
		optest <add hl,bc>,'ADD HL,BC'
		optest <ld de,0xbeef>,'LD DE,0xBEEF'
		optest <add hl,de>,'ADD HL,DE'
		optest <ld hl,0xbeef>,'LD HL,0xBEEF'
		optest <add hl,hl>,'ADD HL,HL'
		optest <ld sp,0xbeef>,'LD SP,0xBEEF'
		optest <add hl,sp>,'ADD HL,SP'

		; page 0 section 0 column 2
		optest <ld (bc),a>,'LD (BC),A'
		optest <ld a,(bc)>,'LD A,(BC)'
		optest <ld (de),a>,'LD (DE),A'
		optest <ld a,(de)>,'LD A,(DE)'
		optest <ld (0xbeef),hl>,'LD (0xBEEF),HL'
		optest <ld hl,(0xbeef)>,'LD HL,(0xBEEF)'
		optest <ld (0xbeef),a>,'LD (0xBEEF),A'
		optest <ld a,(0xbeef)>,'LD A,(0xBEEF)'

		; page 0 section 0 column 3
		optest <inc bc>,'INC BC'
		optest <dec bc>,'DEC BC'
		optest <inc de>,'INC DE'
		optest <dec de>,'DEC DE'
		optest <inc hl>,'INC HL'
		optest <dec hl>,'DEC HL'
		optest <inc sp>,'INC SP'
		optest <dec sp>,'DEC SP'

		; page 0 section 0 column 4
		optest <inc b>,'INC B'
		optest <inc c>,'INC C'
		optest <inc d>,'INC D'
		optest <inc e>,'INC E'
		optest <inc h>,'INC H'
		optest <inc l>,'INC L'
		optest <inc (hl)>,'INC (HL)'
		optest <inc a>,'INC A'

		; page 0 section 0 column 5
		optest <dec b>,'DEC B'
		optest <dec c>,'DEC C'
		optest <dec d>,'DEC D'
		optest <dec e>,'DEC E'
		optest <dec h>,'DEC H'
		optest <dec l>,'DEC L'
		optest <dec (hl)>,'DEC (HL)'
		optest <dec a>,'DEC A'

		; page 0 section 0 column 6
		optest <ld b,0x55>,'LD B,0x55'
		optest <ld c,0x55>,'LD C,0x55'
		optest <ld d,0x55>,'LD D,0x55'
		optest <ld e,0x55>,'LD E,0x55'
		optest <ld h,0x55>,'LD H,0x55'
		optest <ld l,0x55>,'LD L,0x55'
		optest <ld (hl),0x55>,'LD (HL),0x55'
		optest <ld a,0x55>,'LD A,0x55'

		; page 0 section 0 column 7
		optest <rlca>,'RLCA'
		optest <rrca>,'RRCA'
		optest <rla>,'RLA'
		optest <rra>,'RRA'
		optest <daa>,'DAA'
		optest <cpl>,'CPL'
		optest <scf>,'SCF'
		optest <ccf>,'CCF'

		; page 0 section 1 row 0
		optest <ld b,b>,'LD B,B'
		optest <ld b,c>,'LD B,C'
		optest <ld b,d>,'LD B,D'
		optest <ld b,e>,'LD B,E'
		optest <ld b,h>,'LD B,H'
		optest <ld b,l>,'LD B,L'
		optest <ld b,(hl)>,'LD B,(HL)'
		optest <ld b,a>,'LD B,A'

		; page 0 section 1 row 1
		optest <ld c,b>,'LD C,B'
		optest <ld c,c>,'LD C,C'
		optest <ld c,d>,'LD C,D'
		optest <ld c,e>,'LD C,E'
		optest <ld c,h>,'LD C,H'
		optest <ld c,l>,'LD C,L'
		optest <ld c,(hl)>,'LD C,(HL)'
		optest <ld c,a>,'LD C,A'

		; page 0 section 1 row 2
		optest <ld d,b>,'LD D,B'
		optest <ld d,c>,'LD D,C'
		optest <ld d,d>,'LD D,D'
		optest <ld d,e>,'LD D,E'
		optest <ld d,h>,'LD D,H'
		optest <ld d,l>,'LD D,L'
		optest <ld d,(hl)>,'LD D,(HL)'
		optest <ld d,a>,'LD D,A'

		; page 0 section 1 row 3
		optest <ld e,b>,'LD E,B'
		optest <ld e,c>,'LD E,C'
		optest <ld e,d>,'LD E,D'
		optest <ld e,e>,'LD E,E'
		optest <ld e,h>,'LD E,H'
		optest <ld e,l>,'LD E,L'
		optest <ld e,(hl)>,'LD E,(HL)'
		optest <ld e,a>,'LD E,A'

		; page 0 section 1 row 4
		optest <ld h,b>,'LD H,B'
		optest <ld h,c>,'LD H,C'
		optest <ld h,d>,'LD H,D'
		optest <ld h,e>,'LD H,E'
		optest <ld h,h>,'LD H,H'
		optest <ld h,l>,'LD H,L'
		optest <ld h,(hl)>,'LD H,(HL)'
		optest <ld h,a>,'LD H,A'

		; page 0 section 1 row 5
		optest <ld l,b>,'LD L,B'
		optest <ld l,c>,'LD L,C'
		optest <ld l,d>,'LD L,D'
		optest <ld l,e>,'LD L,E'
		optest <ld l,h>,'LD L,H'
		optest <ld l,l>,'LD L,L'
		optest <ld l,(hl)>,'LD L,(HL)'
		optest <ld l,a>,'LD L,A'

		; page 0 section 1 row 6
		optest <ld (hl),b>,'LD (HL),B'
		optest <ld (hl),c>,'LD (HL),C'
		optest <ld (hl),d>,'LD (HL),D'
		optest <ld (hl),e>,'LD (HL),E'
		optest <ld (hl),h>,'LD (HL),H'
		optest <ld (hl),l>,'LD (HL),L'
		optest <halt>,'HALT'
		optest <ld (hl),a>,'LD (HL),A'

		; page 0 section 1 row 7
		optest <ld a,b>,'LD A,B'
		optest <ld a,c>,'LD A,C'
		optest <ld a,d>,'LD A,D'
		optest <ld a,e>,'LD A,E'
		optest <ld a,h>,'LD A,H'
		optest <ld a,l>,'LD A,L'
		optest <ld a,(hl)>,'LD A,(HL)'
		optest <ld a,a>,'LD A,A'

		; page 0 section 2 row 0
		optest <add A,b>,'ADD A,B'
		optest <add A,c>,'ADD A,C'
		optest <add A,d>,'ADD A,D'
		optest <add A,e>,'ADD A,E'
		optest <add A,h>,'ADD A,H'
		optest <add A,l>,'ADD A,L'
		optest <add A,(hl)>,'ADD A,(HL)'
		optest <add A,a>,'ADD A,A'

		; page 0 section 2 row 1
		optest <adc A,b>,'ADC A,B'
		optest <adc A,c>,'ADC A,C'
		optest <adc A,d>,'ADC A,D'
		optest <adc A,e>,'ADC A,E'
		optest <adc A,h>,'ADC A,H'
		optest <adc A,l>,'ADC A,L'
		optest <adc A,(hl)>,'ADC A,(HL)'
		optest <adc A,a>,'ADC A,A'

		; page 0 section 2 row 2
		optest <sub b>,'SUB B'
		optest <sub c>,'SUB C'
		optest <sub d>,'SUB D'
		optest <sub e>,'SUB E'
		optest <sub h>,'SUB H'
		optest <sub l>,'SUB L'
		optest <sub (hl)>,'SUB (HL)'
		optest <sub a>,'SUB A'

		; page 0 section 2 row 3
		optest <sbc A,b>,'SBC A,B'
		optest <sbc A,c>,'SBC A,C'
		optest <sbc A,d>,'SBC A,D'
		optest <sbc A,e>,'SBC A,E'
		optest <sbc A,h>,'SBC A,H'
		optest <sbc A,l>,'SBC A,L'
		optest <sbc A,(hl)>,'SBC A,(HL)'
		optest <sbc A,a>,'SBC A,A'

		; page 0 section 2 row 4
		optest <and b>,'AND B'
		optest <and c>,'AND C'
		optest <and d>,'AND D'
		optest <and e>,'AND E'
		optest <and h>,'AND H'
		optest <and l>,'AND L'
		optest <and (hl)>,'AND (HL)'
		optest <and a>,'AND A'

		; page 0 section 2 row 5
		optest <xor b>,'XOR B'
		optest <xor c>,'XOR C'
		optest <xor d>,'XOR D'
		optest <xor e>,'XOR E'
		optest <xor h>,'XOR H'
		optest <xor l>,'XOR L'
		optest <xor (hl)>,'XOR (HL)'
		optest <xor a>,'XOR A'

		; page 0 section 2 row 6
		optest <or b>,'OR B'
		optest <or c>,'OR C'
		optest <or d>,'OR D'
		optest <or e>,'OR E'
		optest <or h>,'OR H'
		optest <or l>,'OR L'
		optest <or (hl)>,'OR (HL)'
		optest <or a>,'OR A'

		; page 0 section 2 row 7
		optest <cp b>,'CP B'
		optest <cp c>,'CP C'
		optest <cp d>,'CP D'
		optest <cp e>,'CP E'
		optest <cp h>,'CP H'
		optest <cp l>,'CP L'
		optest <cp (hl)>,'CP (HL)'
		optest <cp a>,'CP A'

		; page 0 section 3 column 0
		optest <ret nz>,'RET NZ'
		optest <ret z>,'RET Z'
		optest <ret nc>,'RET NC'
		optest <ret c>,'RET C'
		optest <ret po>,'RET PO'
		optest <ret pe>,'RET PE'
		optest <ret p>,'RET P'
		optest <ret m>,'RET M'

		; page 0 section 3 column 1
		optest <pop bc>,'POP BC'
		optest <ret>, 'RET'
		optest <pop de>,'POP DE'
		optest <exx>, 'EXX'
		optest <pop hl>,'POP HL'
		optest <jp (hl)>,'JP (HL)'
		optest <pop af>,'POP AF'
		optest <ld sp,hl>,'LD SP,HL'

		; page 0 section 3 column 2
		optest <jp nz,0xbeef>,'JP NZ,0xBEEF'
		optest <jp z,0xbeef>,'JP Z,0xBEEF'
		optest <jp nc,0xbeef>,'JP NC,0xBEEF'
		optest <jp c,0xbeef>,'JP C,0xBEEF'
		optest <jp po,0xbeef>,'JP PO,0xBEEF'
		optest <jp pe,0xbeef>,'JP PE,0xBEEF'
		optest <jp p,0xbeef>,'JP P,0xBEEF'
		optest <jp m,0xbeef>,'JP M,0xBEEF'

		; page 0 section 3 column 3
		optest <jp 0xbeef>,'JP 0xBEEF'
		optest <out (0x55),a>,'OUT (0x55),A'
		optest <in a,(0x55)>,'IN A,(0x55)'
		optest <ex (sp),hl>,'EX (SP),HL'
		optest <ex de,hl>,'EX DE,HL'
		optest <di>,'DI'
		optest <ei>,'EI'

		; page 0 section 3 column 4
		optest <call nz,0xbeef>,'CALL NZ,0xBEEF'
		optest <call z,0xbeef>,'CALL Z,0xBEEF'
		optest <call nc,0xbeef>,'CALL NC,0xBEEF'
		optest <call c,0xbeef>,'CALL C,0xBEEF'
		optest <call po,0xbeef>,'CALL PO,0xBEEF'
		optest <call pe,0xbeef>,'CALL PE,0xBEEF'
		optest <call p,0xbeef>,'CALL P,0xBEEF'
		optest <call m,0xbeef>,'CALL M,0xBEEF'

		; page 0 section 3 column 5
		optest <push bc>,'PUSH BC'
		optest <call 0xbeef>,'CALL 0xBEEF'
		optest <push de>,'PUSH DE'
		optest <push hl>,'PUSH HL'
		optest <push af>,'PUSH AF'

		; page 0 section 3 column 6
		optest <add a,0x55>,'ADD A,0x55'
		optest <adc a,0x55>,'ADC A,0x55'
		optest <sub 0x55>,'SUB 0x55'
		optest <sbc a,0x55>,'SBC A,0x55'
		optest <and 0x55>,'AND 0x55'
		optest <xor 0x55>,'XOR 0x55'
		optest <or 0x55>,'OR 0x55'
		optest <cp 0x55>,'CP 0x55'

		; page 0 section 3 column 7
		optest <rst 0x00>,'RST 0x00'
		optest <rst 0x08>,'RST 0x08'
		optest <rst 0x10>,'RST 0x10'
		optest <rst 0x18>,'RST 0x18'
		optest <rst 0x20>,'RST 0x20'
		optest <rst 0x28>,'RST 0x28'
		optest <rst 0x30>,'RST 0x30'
		optest <rst 0x38>,'RST 0x38'


ok:
		ld hl,ok_msg
		ld de,rbuf
		ld c,(hl)
		ld b,0
		inc hl
		ldir
		xor a				; clear carry, set zero
		halt

fail:
		push de
		push hl
		ld hl,fail_msg
		ld de,rbuf
		ld c,(hl)
		ld b,0
		inc hl
		ldir
		pop hl 
fail10:
		ld a,(hl)
		ld (de),a
		inc hl
		inc de
		or a
		jr nz,fail10
		pop hl
fail20:
		ld a,(hl)
		ld (de),a
		inc hl
		inc de
		or a
		jr nz,fail20
		
		or 0xff
		scf
		halt

ok_msg		db 3,"OK",0
fail_msg	db 7, "FAIL: ",0

		dseg
dbuf		ds	16
cbuf		ds	32
rbuf		ds	64

