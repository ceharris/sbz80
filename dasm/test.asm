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
	; Runs the suite of disassembly tests.
	; If all tests are successful, the CPU is halted with the Z flag
	; set. If a test fails, the CPU is halted with the NZ flag set
	; and `rbuf` contains the expected and actual disassembly for the
	; failed test.
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

		;page CB section 0 row 0
		optest <rlc b>,'RLC B'
		optest <rlc c>,'RLC C'
		optest <rlc d>,'RLC D'
		optest <rlc e>,'RLC E'
		optest <rlc h>,'RLC H'
		optest <rlc l>,'RLC L'
		optest <rlc (hl)>,'RLC (HL)'
		optest <rlc a>,'RLC A'

		;page CB section 0 row 1
		optest <rrc b>,'RRC B'
		optest <rrc c>,'RRC C'
		optest <rrc d>,'RRC D'
		optest <rrc e>,'RRC E'
		optest <rrc h>,'RRC H'
		optest <rrc l>,'RRC L'
		optest <rrc (hl)>,'RRC (HL)'
		optest <rrc a>,'RRC A'

		;page CB section 0 row 2
		optest <rl b>,'RL B'
		optest <rl c>,'RL C'
		optest <rl d>,'RL D'
		optest <rl e>,'RL E'
		optest <rl h>,'RL H'
		optest <rl l>,'RL L'
		optest <rl (hl)>,'RL (HL)'
		optest <rl a>,'RL A'

		;page CB section 0 row 3
		optest <rr b>,'RR B'
		optest <rr c>,'RR C'
		optest <rr d>,'RR D'
		optest <rr e>,'RR E'
		optest <rr h>,'RR H'
		optest <rr l>,'RR L'
		optest <rr (hl)>,'RR (HL)'
		optest <rr a>,'RR A'

		;page CB section 0 row 4
		optest <sla b>,'SLA B'
		optest <sla c>,'SLA C'
		optest <sla d>,'SLA D'
		optest <sla e>,'SLA E'
		optest <sla h>,'SLA H'
		optest <sla l>,'SLA L'
		optest <sla (hl)>,'SLA (HL)'
		optest <sla a>,'SLA A'

		;page CB section 0 row 5
		optest <sra b>,'SRA B'
		optest <sra c>,'SRA C'
		optest <sra d>,'SRA D'
		optest <sra e>,'SRA E'
		optest <sra h>,'SRA H'
		optest <sra l>,'SRA L'
		optest <sra (hl)>,'SRA (HL)'
		optest <sra a>,'SRA A'

		;page CB section 0 row 6
		optest <sll b>,'SLL B'
		optest <sll c>,'SLL C'
		optest <sll d>,'SLL D'
		optest <sll e>,'SLL E'
		optest <sll h>,'SLL H'
		optest <sll l>,'SLL L'
		optest <sll (hl)>,'SLL (HL)'
		optest <sll a>,'SLL A'

		;page CB section 0 row 7
		optest <srl b>,'SRL B'
		optest <srl c>,'SRL C'
		optest <srl d>,'SRL D'
		optest <srl e>,'SRL E'
		optest <srl h>,'SRL H'
		optest <srl l>,'SRL L'
		optest <srl (hl)>,'SRL (HL)'
		optest <srl a>,'SRL A'

		; page CB section 1 row 0
		optest <bit 0,b>,'BIT 0,B'
		optest <bit 0,c>,'BIT 0,C'
		optest <bit 0,d>,'BIT 0,D'
		optest <bit 0,e>,'BIT 0,E'
		optest <bit 0,h>,'BIT 0,H'
		optest <bit 0,l>,'BIT 0,L'
		optest <bit 0,(hl)>,'BIT 0,(HL)'
		optest <bit 0,a>,'BIT 0,A'

		; page CB section 1 row 1
		optest <bit 1,b>,'BIT 1,B'
		optest <bit 1,c>,'BIT 1,C'
		optest <bit 1,d>,'BIT 1,D'
		optest <bit 1,e>,'BIT 1,E'
		optest <bit 1,h>,'BIT 1,H'
		optest <bit 1,l>,'BIT 1,L'
		optest <bit 1,(hl)>,'BIT 1,(HL)'
		optest <bit 1,a>,'BIT 1,A'

		; page CB section 1 row 2
		optest <bit 2,b>,'BIT 2,B'
		optest <bit 2,c>,'BIT 2,C'
		optest <bit 2,d>,'BIT 2,D'
		optest <bit 2,e>,'BIT 2,E'
		optest <bit 2,h>,'BIT 2,H'
		optest <bit 2,l>,'BIT 2,L'
		optest <bit 2,(hl)>,'BIT 2,(HL)'
		optest <bit 2,a>,'BIT 2,A'

		; page CB section 1 row 3
		optest <bit 3,b>,'BIT 3,B'
		optest <bit 3,c>,'BIT 3,C'
		optest <bit 3,d>,'BIT 3,D'
		optest <bit 3,e>,'BIT 3,E'
		optest <bit 3,h>,'BIT 3,H'
		optest <bit 3,l>,'BIT 3,L'
		optest <bit 3,(hl)>,'BIT 3,(HL)'
		optest <bit 3,a>,'BIT 3,A'

		; page CB section 1 row 4
		optest <bit 4,b>,'BIT 4,B'
		optest <bit 4,c>,'BIT 4,C'
		optest <bit 4,d>,'BIT 4,D'
		optest <bit 4,e>,'BIT 4,E'
		optest <bit 4,h>,'BIT 4,H'
		optest <bit 4,l>,'BIT 4,L'
		optest <bit 4,(hl)>,'BIT 4,(HL)'
		optest <bit 4,a>,'BIT 4,A'

		; page CB section 1 row 5
		optest <bit 5,b>,'BIT 5,B'
		optest <bit 5,c>,'BIT 5,C'
		optest <bit 5,d>,'BIT 5,D'
		optest <bit 5,e>,'BIT 5,E'
		optest <bit 5,h>,'BIT 5,H'
		optest <bit 5,l>,'BIT 5,L'
		optest <bit 5,(hl)>,'BIT 5,(HL)'
		optest <bit 5,a>,'BIT 5,A'

		; page CB section 1 row 6
		optest <bit 6,b>,'BIT 6,B'
		optest <bit 6,c>,'BIT 6,C'
		optest <bit 6,d>,'BIT 6,D'
		optest <bit 6,e>,'BIT 6,E'
		optest <bit 6,h>,'BIT 6,H'
		optest <bit 6,l>,'BIT 6,L'
		optest <bit 6,(hl)>,'BIT 6,(HL)'
		optest <bit 6,a>,'BIT 6,A'

		; page CB section 1 row 7
		optest <bit 7,b>,'BIT 7,B'
		optest <bit 7,c>,'BIT 7,C'
		optest <bit 7,d>,'BIT 7,D'
		optest <bit 7,e>,'BIT 7,E'
		optest <bit 7,h>,'BIT 7,H'
		optest <bit 7,l>,'BIT 7,L'
		optest <bit 7,(hl)>,'BIT 7,(HL)'
		optest <bit 7,a>,'BIT 7,A'

		; page CB section 2 row 0
		optest <res 0,b>,'RES 0,B'
		optest <res 0,c>,'RES 0,C'
		optest <res 0,d>,'RES 0,D'
		optest <res 0,e>,'RES 0,E'
		optest <res 0,h>,'RES 0,H'
		optest <res 0,l>,'RES 0,L'
		optest <res 0,(hl)>,'RES 0,(HL)'
		optest <res 0,a>,'RES 0,A'

		; page CB section 2 row 1
		optest <res 1,b>,'RES 1,B'
		optest <res 1,c>,'RES 1,C'
		optest <res 1,d>,'RES 1,D'
		optest <res 1,e>,'RES 1,E'
		optest <res 1,h>,'RES 1,H'
		optest <res 1,l>,'RES 1,L'
		optest <res 1,(hl)>,'RES 1,(HL)'
		optest <res 1,a>,'RES 1,A'

		; page CB section 2 row 2
		optest <res 2,b>,'RES 2,B'
		optest <res 2,c>,'RES 2,C'
		optest <res 2,d>,'RES 2,D'
		optest <res 2,e>,'RES 2,E'
		optest <res 2,h>,'RES 2,H'
		optest <res 2,l>,'RES 2,L'
		optest <res 2,(hl)>,'RES 2,(HL)'
		optest <res 2,a>,'RES 2,A'

		; page CB section 2 row 3
		optest <res 3,b>,'RES 3,B'
		optest <res 3,c>,'RES 3,C'
		optest <res 3,d>,'RES 3,D'
		optest <res 3,e>,'RES 3,E'
		optest <res 3,h>,'RES 3,H'
		optest <res 3,l>,'RES 3,L'
		optest <res 3,(hl)>,'RES 3,(HL)'
		optest <res 3,a>,'RES 3,A'

		; page CB section 2 row 4
		optest <res 4,b>,'RES 4,B'
		optest <res 4,c>,'RES 4,C'
		optest <res 4,d>,'RES 4,D'
		optest <res 4,e>,'RES 4,E'
		optest <res 4,h>,'RES 4,H'
		optest <res 4,l>,'RES 4,L'
		optest <res 4,(hl)>,'RES 4,(HL)'
		optest <res 4,a>,'RES 4,A'

		; page CB section 2 row 5
		optest <res 5,b>,'RES 5,B'
		optest <res 5,c>,'RES 5,C'
		optest <res 5,d>,'RES 5,D'
		optest <res 5,e>,'RES 5,E'
		optest <res 5,h>,'RES 5,H'
		optest <res 5,l>,'RES 5,L'
		optest <res 5,(hl)>,'RES 5,(HL)'
		optest <res 5,a>,'RES 5,A'

		; page CB section 2 row 6
		optest <res 6,b>,'RES 6,B'
		optest <res 6,c>,'RES 6,C'
		optest <res 6,d>,'RES 6,D'
		optest <res 6,e>,'RES 6,E'
		optest <res 6,h>,'RES 6,H'
		optest <res 6,l>,'RES 6,L'
		optest <res 6,(hl)>,'RES 6,(HL)'
		optest <res 6,a>,'RES 6,A'

		; page CB section 2 row 7
		optest <res 7,b>,'RES 7,B'
		optest <res 7,c>,'RES 7,C'
		optest <res 7,d>,'RES 7,D'
		optest <res 7,e>,'RES 7,E'
		optest <res 7,h>,'RES 7,H'
		optest <res 7,l>,'RES 7,L'
		optest <res 7,(hl)>,'RES 7,(HL)'
		optest <res 7,a>,'RES 7,A'

		; page CB section 3 row 0
		optest <set 0,b>,'SET 0,B'
		optest <set 0,c>,'SET 0,C'
		optest <set 0,d>,'SET 0,D'
		optest <set 0,e>,'SET 0,E'
		optest <set 0,h>,'SET 0,H'
		optest <set 0,l>,'SET 0,L'
		optest <set 0,(hl)>,'SET 0,(HL)'
		optest <set 0,a>,'SET 0,A'

		; page CB section 3 row 1
		optest <set 1,b>,'SET 1,B'
		optest <set 1,c>,'SET 1,C'
		optest <set 1,d>,'SET 1,D'
		optest <set 1,e>,'SET 1,E'
		optest <set 1,h>,'SET 1,H'
		optest <set 1,l>,'SET 1,L'
		optest <set 1,(hl)>,'SET 1,(HL)'
		optest <set 1,a>,'SET 1,A'

		; page CB section 3 row 2
		optest <set 2,b>,'SET 2,B'
		optest <set 2,c>,'SET 2,C'
		optest <set 2,d>,'SET 2,D'
		optest <set 2,e>,'SET 2,E'
		optest <set 2,h>,'SET 2,H'
		optest <set 2,l>,'SET 2,L'
		optest <set 2,(hl)>,'SET 2,(HL)'
		optest <set 2,a>,'SET 2,A'

		; page CB section 3 row 3
		optest <set 3,b>,'SET 3,B'
		optest <set 3,c>,'SET 3,C'
		optest <set 3,d>,'SET 3,D'
		optest <set 3,e>,'SET 3,E'
		optest <set 3,h>,'SET 3,H'
		optest <set 3,l>,'SET 3,L'
		optest <set 3,(hl)>,'SET 3,(HL)'
		optest <set 3,a>,'SET 3,A'

		; page CB section 3 row 4
		optest <set 4,b>,'SET 4,B'
		optest <set 4,c>,'SET 4,C'
		optest <set 4,d>,'SET 4,D'
		optest <set 4,e>,'SET 4,E'
		optest <set 4,h>,'SET 4,H'
		optest <set 4,l>,'SET 4,L'
		optest <set 4,(hl)>,'SET 4,(HL)'
		optest <set 4,a>,'SET 4,A'

		; page CB section 3 row 5
		optest <set 5,b>,'SET 5,B'
		optest <set 5,c>,'SET 5,C'
		optest <set 5,d>,'SET 5,D'
		optest <set 5,e>,'SET 5,E'
		optest <set 5,h>,'SET 5,H'
		optest <set 5,l>,'SET 5,L'
		optest <set 5,(hl)>,'SET 5,(HL)'
		optest <set 5,a>,'SET 5,A'

		; page CB section 3 row 6
		optest <set 6,b>,'SET 6,B'
		optest <set 6,c>,'SET 6,C'
		optest <set 6,d>,'SET 6,D'
		optest <set 6,e>,'SET 6,E'
		optest <set 6,h>,'SET 6,H'
		optest <set 6,l>,'SET 6,L'
		optest <set 6,(hl)>,'SET 6,(HL)'
		optest <set 6,a>,'SET 6,A'

		; page CB section 3 row 7
		optest <set 7,b>,'SET 7,B'
		optest <set 7,c>,'SET 7,C'
		optest <set 7,d>,'SET 7,D'
		optest <set 7,e>,'SET 7,E'
		optest <set 7,h>,'SET 7,H'
		optest <set 7,l>,'SET 7,L'
		optest <set 7,(hl)>,'SET 7,(HL)'
		optest <set 7,a>,'SET 7,A'

		; page CB section 1 column 0
		optest <in b,(c)>,'IN B,(C)'
		optest <in c,(c)>,'IN C,(C)'
		optest <in d,(c)>,'IN D,(C)'
		optest <in e,(c)>,'IN E,(C)'
		optest <in h,(c)>,'IN H,(C)'
		optest <in l,(c)>,'IN L,(C)'
		optest <in a,(c)>,'IN A,(C)'

		; page CB section 1 column 1
		optest <out (c),b>,'OUT (C),B'
		optest <out (c),c>,'OUT (C),C'
		optest <out (c),d>,'OUT (C),D'
		optest <out (c),e>,'OUT (C),E'
		optest <out (c),h>,'OUT (C),H'
		optest <out (c),l>,'OUT (C),L'
		optest <out (c),a>,'OUT (C),A'

		; page CB section 1 column 2
		optest <sbc hl,bc>,'SBC HL,BC'
		optest <adc hl,bc>,'ADC HL,BC'
		optest <sbc hl,de>,'SBC HL,DE'
		optest <adc hl,de>,'ADC HL,DE'
		optest <sbc hl,hl>,'SBC HL,HL'
		optest <adc hl,hl>,'ADC HL,HL'
		optest <sbc hl,sp>,'SBC HL,SP'
		optest <adc hl,sp>,'ADC HL,SP'

		; page CB section 1 column 3
		optest <ld (0xbeef),bc>,'LD (0xBEEF),BC'
		optest <ld bc,(0xbeef)>,'LD BC,(0xBEEF)'
		optest <ld (0xbeef),de>,'LD (0xBEEF),DE'
		optest <ld de,(0xbeef)>,'LD DE,(0xBEEF)'
		optest <ld (0xbeef),sp>,'LD (0xBEEF),SP'
		optest <ld sp,(0xbeef)>,'LD SP,(0xBEEF)'

		; page CB section 1 columns 4-7
		optest <neg>,'NEG'
		optest <retn>,'RETN'
		optest <reti>,'RETI'
		optest <im 0>,'IM 0'
		optest <im 1>,'IM 1'
		optest <im 2>,'IM 2'
		optest <ld i,a>,'LD I,A'
		optest <ld r,a>,'LD R,A'
		optest <ld a,i>,'LD A,I'
		optest <ld a,r>,'LD A,R'
		optest <rrd>,'RRD'
		optest <rld>,'RLD'

		; page CB section 2 column 0
		optest <ldi>,'LDI'
		optest <ldd>,'LDD'
		optest <ldir>,'LDIR'
		optest <lddr>,'LDDR'

		; page CB section 2 column 1
		optest <cpi>,'CPI'
		optest <cpd>,'CPD'
		optest <cpir>,'CPIR'
		optest <cpdr>,'CPDR'
		
		; page CB section 2 column 2
		optest <ini>,'INI'
		optest <ind>,'IND'
		optest <inir>,'INIR'
		optest <indr>,'INDR'

		; page CB section 2 column 3
		optest <outi>,'OUTI'
		optest <outd>,'OUTD'
		optest <otir>,'OTIR'
		optest <otdr>,'OTDR'

		; page DD section 0
		optest <add ix,bc>,'ADD IX,BC'
		optest <add ix,de>,'ADD IX,DE'
		optest <add ix,ix>,'ADD IX,IX'
		optest <add ix,sp>,'ADD IX,SP'
		optest <ld ix,0xbeef>,'LD IX,0xBEEF'
		optest <ld (0xbeef),ix>,'LD (0xBEEF),IX'
		optest <ld ix,(0xbeef)>,'LD IX,(0xBEEF)'
		optest <inc (ix+1)>,'INC (IX+1)'
		optest <dec (ix-1)>,'DEC (IX-1)'
		optest <ld (ix+1),0x55>,'LD (IX+1),0x55'

		; page DD section 1
		optest <ld b,(ix-1)>,'LD B,(IX-1)'
		optest <ld c,(ix-1)>,'LD C,(IX-1)'
		optest <ld d,(ix-1)>,'LD D,(IX-1)'
		optest <ld e,(ix-1)>,'LD E,(IX-1)'
		optest <ld h,(ix-1)>,'LD H,(IX-1)'
		optest <ld l,(ix-1)>,'LD L,(IX-1)'
		optest <ld a,(ix-1)>,'LD A,(IX-1)'
		optest <ld (ix+1),b>,'LD (IX+1),B'
		optest <ld (ix+1),c>,'LD (IX+1),C'
		optest <ld (ix+1),d>,'LD (IX+1),D'
		optest <ld (ix+1),e>,'LD (IX+1),E'
		optest <ld (ix+1),h>,'LD (IX+1),H'
		optest <ld (ix+1),l>,'LD (IX+1),L'
		optest <ld (ix+1),a>,'LD (IX+1),A'

		; page DD section 1
		optest <add a,(ix-1)>,'ADD A,(IX-1)'
		optest <adc a,(ix-1)>,'ADC A,(IX-1)'
		optest <sub (ix-1)>,'SUB (IX-1)'
		optest <sbc a,(ix-1)>,'SBC A,(IX-1)'
		optest <and (ix-1)>,'AND (IX-1)'
		optest <xor (ix-1)>,'XOR (IX-1)'
		optest <or (ix-1)>,'OR (IX-1)'
		optest <cp (ix-1)>,'CP (IX-1)'

		; page DD section 3
		optest <pop ix>,'POP IX'
		optest <push ix>,'PUSH IX'
		optest <ex (sp),ix>,'EX (SP),IX'
		optest <jp (ix)>,'JP (IX)'
		optest <ld sp,ix>,'LD SP,IX'

		; page DD CB section 0
		optest <rlc (ix+1)>,'RLC (IX+1)'
		optest <rrc (ix+1)>,'RRC (IX+1)'
		optest <rl (ix+1)>,'RL (IX+1)'
		optest <rr (ix+1)>,'RR (IX+1)'
		optest <sla (ix+1)>,'SLA (IX+1)'
		optest <sra (ix+1)>,'SRA (IX+1)'
		optest <sll (ix+1)>,'SLL (IX+1)'
		optest <srl (ix+1)>,'SRL (IX+1)'

		; page DD CB section 1
		optest <bit 0,(ix+1)>,'BIT 0,(IX+1)'
		optest <bit 1,(ix+1)>,'BIT 1,(IX+1)'
		optest <bit 2,(ix+1)>,'BIT 2,(IX+1)'
		optest <bit 3,(ix+1)>,'BIT 3,(IX+1)'
		optest <bit 4,(ix+1)>,'BIT 4,(IX+1)'
		optest <bit 5,(ix+1)>,'BIT 5,(IX+1)'
		optest <bit 6,(ix+1)>,'BIT 6,(IX+1)'
		optest <bit 7,(ix+1)>,'BIT 7,(IX+1)'

		; page DD CB section 2
		optest <res 0,(ix+1)>,'RES 0,(IX+1)'
		optest <res 1,(ix+1)>,'RES 1,(IX+1)'
		optest <res 2,(ix+1)>,'RES 2,(IX+1)'
		optest <res 3,(ix+1)>,'RES 3,(IX+1)'
		optest <res 4,(ix+1)>,'RES 4,(IX+1)'
		optest <res 5,(ix+1)>,'RES 5,(IX+1)'
		optest <res 6,(ix+1)>,'RES 6,(IX+1)'
		optest <res 7,(ix+1)>,'RES 7,(IX+1)'

		; page DD CB section 3
		optest <set 0,(ix+1)>,'SET 0,(IX+1)'
		optest <set 1,(ix+1)>,'SET 1,(IX+1)'
		optest <set 2,(ix+1)>,'SET 2,(IX+1)'
		optest <set 3,(ix+1)>,'SET 3,(IX+1)'
		optest <set 4,(ix+1)>,'SET 4,(IX+1)'
		optest <set 5,(ix+1)>,'SET 5,(IX+1)'
		optest <set 6,(ix+1)>,'SET 6,(IX+1)'
		optest <set 7,(ix+1)>,'SET 7,(IX+1)'

		; page FD section 0
		optest <add iy,bc>,'ADD IY,BC'
		optest <add iy,de>,'ADD IY,DE'
		optest <add iy,iy>,'ADD IY,IY'
		optest <add iy,sp>,'ADD IY,SP'
		optest <ld iy,0xbeef>,'LD IY,0xBEEF'
		optest <ld (0xbeef),iy>,'LD (0xBEEF),IY'
		optest <ld iy,(0xbeef)>,'LD IY,(0xBEEF)'
		optest <inc (iy+1)>,'INC (IY+1)'
		optest <dec (iy-1)>,'DEC (IY-1)'
		optest <ld (iy+1),0x55>,'LD (IY+1),0x55'

		; page FD section 1
		optest <ld b,(iy-1)>,'LD B,(IY-1)'
		optest <ld c,(iy-1)>,'LD C,(IY-1)'
		optest <ld d,(iy-1)>,'LD D,(IY-1)'
		optest <ld e,(iy-1)>,'LD E,(IY-1)'
		optest <ld h,(iy-1)>,'LD H,(IY-1)'
		optest <ld l,(iy-1)>,'LD L,(IY-1)'
		optest <ld a,(iy-1)>,'LD A,(IY-1)'
		optest <ld (iy+1),b>,'LD (IY+1),B'
		optest <ld (iy+1),c>,'LD (IY+1),C'
		optest <ld (iy+1),d>,'LD (IY+1),D'
		optest <ld (iy+1),e>,'LD (IY+1),E'
		optest <ld (iy+1),h>,'LD (IY+1),H'
		optest <ld (iy+1),l>,'LD (IY+1),L'
		optest <ld (iy+1),a>,'LD (IY+1),A'

		; page FD section 1
		optest <add a,(iy-1)>,'ADD A,(IY-1)'
		optest <adc a,(iy-1)>,'ADC A,(IY-1)'
		optest <sub (iy-1)>,'SUB (IY-1)'
		optest <sbc a,(iy-1)>,'SBC A,(IY-1)'
		optest <and (iy-1)>,'AND (IY-1)'
		optest <xor (iy-1)>,'XOR (IY-1)'
		optest <or (iy-1)>,'OR (IY-1)'
		optest <cp (iy-1)>,'CP (IY-1)'

		; page FD section 3
		optest <pop iy>,'POP IY'
		optest <push iy>,'PUSH IY'
		optest <ex (sp),iy>,'EX (SP),IY'
		optest <jp (iy)>,'JP (IY)'
		optest <ld sp,iy>,'LD SP,IY'

		; page FD CB section 0
		optest <rlc (iy+1)>,'RLC (IY+1)'
		optest <rrc (iy+1)>,'RRC (IY+1)'
		optest <rl (iy+1)>,'RL (IY+1)'
		optest <rr (iy+1)>,'RR (IY+1)'
		optest <sla (iy+1)>,'SLA (IY+1)'
		optest <sra (iy+1)>,'SRA (IY+1)'
		optest <sll (iy+1)>,'SLL (IY+1)'
		optest <srl (iy+1)>,'SRL (IY+1)'

		; page FD CB section 1
		optest <bit 0,(iy+1)>,'BIT 0,(IY+1)'
		optest <bit 1,(iy+1)>,'BIT 1,(IY+1)'
		optest <bit 2,(iy+1)>,'BIT 2,(IY+1)'
		optest <bit 3,(iy+1)>,'BIT 3,(IY+1)'
		optest <bit 4,(iy+1)>,'BIT 4,(IY+1)'
		optest <bit 5,(iy+1)>,'BIT 5,(IY+1)'
		optest <bit 6,(iy+1)>,'BIT 6,(IY+1)'
		optest <bit 7,(iy+1)>,'BIT 7,(IY+1)'

		; page FD CB section 2
		optest <res 0,(iy+1)>,'RES 0,(IY+1)'
		optest <res 1,(iy+1)>,'RES 1,(IY+1)'
		optest <res 2,(iy+1)>,'RES 2,(IY+1)'
		optest <res 3,(iy+1)>,'RES 3,(IY+1)'
		optest <res 4,(iy+1)>,'RES 4,(IY+1)'
		optest <res 5,(iy+1)>,'RES 5,(IY+1)'
		optest <res 6,(iy+1)>,'RES 6,(IY+1)'
		optest <res 7,(iy+1)>,'RES 7,(IY+1)'

		; page FD CB section 3
		optest <set 0,(iy+1)>,'SET 0,(IY+1)'
		optest <set 1,(iy+1)>,'SET 1,(IY+1)'
		optest <set 2,(iy+1)>,'SET 2,(IY+1)'
		optest <set 3,(iy+1)>,'SET 3,(IY+1)'
		optest <set 4,(iy+1)>,'SET 4,(IY+1)'
		optest <set 5,(iy+1)>,'SET 5,(IY+1)'
		optest <set 6,(iy+1)>,'SET 6,(IY+1)'
		optest <set 7,(iy+1)>,'SET 7,(IY+1)'
		
ok:
		ld hl,ok_msg
		ld de,rbuf
		ld c,(hl)
		ld b,0
		inc hl
		ldir
		xor a				; set Z flag
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
		
		or 0xff				; set NZ flag
		halt

validate:
		push hl
		ld de,cbuf
validate10:
		ld a,(de)
		cp (hl)		
		jr z,validate20
		pop hl
		ret
validate20:
		inc hl
		inc de
		or a
		jr nz,validate10
		pop hl
		ret

ok_msg		db 3,"OK",0
fail_msg	db 6, "FAIL:",0

		dseg
dbuf		ds	32
cbuf		ds	32
rbuf		ds	64

