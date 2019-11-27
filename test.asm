; basic loader program
;10 SYS 4096; $0801 = 2049

*=$0801
; $0C $08 = $080C 2-byte pointer to the next line of BASIC code
; $0A = 10; 2-byte line number low byte ($000A = 10)
; $00 = 0 ; 2-byte line number high bye
; $9E = SYS BASIC token
; $20 = [space]
; $34 = “4” , $30 = “0”, $39 = “9”, $36 = “6” (ASCII encoded numbers for decimal starting address)
; $0 = end of line
; $00 $00 = 2-byte pointer to the next line of BASIC code ($0000 = end of program)

	!byte $0C,$08,$0A,$00,$9E,$20
	!byte $34,$30,$39,$36,$00,$00,$00

; real start of program $1000 = 4096
*=$1000
	
rasterline = $80

start:
	jsr $e544

loop:
	lda #$03
	sta $d020
	sta $d021

	ldx #$00

drawText:
	lda text,x
	sta $0400+40*12,x
	inx
	cpx #40
	bne drawText

	ldx 5
	stx 53280

	jsr WaitFrame

	inx
	stx 53280

	jmp loop

WaitFrame:
	lda $d012
	cmp #$F8
	beq WaitFrame

.WaitStep2:
	lda $d012
	cmp #$F8
	bne .WaitStep2
	rts

text:
	!scr "              hello world               "