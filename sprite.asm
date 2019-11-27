; basic loader program
; 10 SYS 4096; $0801 = 2049

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

v   = $d000

; real start of program $1000 = 4096
*=$1000

    lda #$93
    jsr $ffd2                       ; Clear screen

    lda #3
    sta $d020                       ; Set background color

    lda #$d
    sta $7f8
    lda #1
    sta v+$15
    sta v+$27

    ldx #$3e
    lda #$ff
loop
    sta $340,x
    dex
    bpl loop

forever
    lda #$ff
    cmp $d012                       ; Wait for raster line $ff
    bne forever
up
    lda $DC00
    and #$1
    bne down
    dec spry
down
    lda $DC00
    and #$2
    bne left
    inc spry
left
    lda $DC00
    and #$4
    bne right
    dec sprx
    bne right
    dec sprx+1
right
    lda $DC00
    and #$8
    bne fire
    inc sprx
    bne fire
    inc sprx+1
fire
    lda $DC00
    and #$10
    bne done
    inc $d020
done
    lda sprx
    sta v
    lda sprx+1
    sta v+$10
    lda spry
    sta v+1

    jmp forever

sprx    !byte 100,0
spry    !byte 100
