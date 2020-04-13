		;----------------------
		; Extension Page CB
		;----------------------
dasm_page_cb:
		; is this instruction targeting IX or IY?
		bit arg_indexed,(iy+st_dasm_flags)
		jr z,dasm_page_cb_10		; not targeting IX or IY
		inc hl				; skip displacement
	
dasm_page_cb_10:
		ld a,(hl)

		; is this instruction targeting IX or IY?
		bit arg_indexed,(iy+st_dasm_flags)
		jr z,dasm_page_cb_20		; not targeting IX or IY
		dec hl				; point to displacement

dasm_page_cb_20:
		; divide into sections
		rla
		jr c,dasm_pcb_s23
		rla
		jr nc,dasm_pcb_s0
		ld c,a				; save row and register bits
		ld a,op_BIT			; ---- BIT ----
		jr dasm_pcb_s13
dasm_pcb_s23:
		rla
		ld c,a				; save row and register bits
		ld a,op_RES			; ---- RES ----
		jr nc,dasm_pcb_s13
		ld a,op_SET			; ---- SET ----
		jr c,dasm_pcb_s13		
		
		;--------------------
		; Page CB, Section 0 
		;--------------------
dasm_pcb_s0:
		push ix				; preserve IX

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct

		; get register argument into the 3 lowest bits of A
		ld c,a				; save row bits
		rra
		rra
		and 0x7

		call mkregr
		ld a,c				; recover row bits
		
		; now split into rows
		rla
		jr c,dasm_pcb_s0_r47
		rla
		jr c,dasm_pcb_s0_r23
		rla
		ld a,op_RLC			; ---- RLC ----
		jr nc,dasm_pcb_s0_done
		ld a,op_RRC			; ---- RRC ----
		jr dasm_pcb_s0_done
dasm_pcb_s0_r23:
		rla
		ld a,op_RL			; ---- RL ----
		jr nc,dasm_pcb_s0_done
		ld a,op_RR			; ---- RR ----
		jr dasm_pcb_s0_done
dasm_pcb_s0_r47:
		rla
		jr c,dasm_pcb_s0_r67
		rla
		ld a,op_SLA			; ---- SLA ----
		jr nc,dasm_pcb_s0_done
		ld a,op_SRA			; ---- SRA ----
		jr dasm_pcb_s0_done
dasm_pcb_s0_r67:
		rla
		ld a,op_SLL			; ---- SLL ----
		jr nc,dasm_pcb_s0_done
		ld a,op_SRL			; ---- SRL ----

dasm_pcb_s0_done:
		pop ix
		ld (ix+st_inst_opcode),a
		ld (ix+st_inst_argc),1

		jp dasm_pcb_done


		;-----------------------
		; Page CB, Sections 1-3
		;-----------------------
dasm_pcb_s13:
		ld (ix+st_inst_opcode),a
		ld (ix+st_inst_argc),2

		ld a,c				; save row and register bits

		ld bc,st_inst_argx
		add ix,bc			; point to arg x struct

		; put bit number into lowest 3 bits of A
		ld c,a				; save row and register bits
		rlca
		rlca
		rlca
		and 0x7
		call mkilit
		ld a,c				; recover register bits

		ld bc,st_arg_size
		add ix,bc			; point to arg y struct

		; put register into lowest 3 bits of A
		rra
		rra		
		and 0x7	
		call mkregr

dasm_pcb_done:
		; is this instruction targeting IX or IY?
		bit arg_indexed,(iy+st_dasm_flags)
		jp z,dasm_p0_done		; not targeting IX or IY
		inc hl				; skip displacement
		jp dasm_p0_done
		
