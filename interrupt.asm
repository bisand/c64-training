* = $0801

        !byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00 ; = SYS 2061

        v = $d000

* = $080d               ; =2061 (Instead of $0810 as in Richards example
                        ; not to waste unnecessary bytes)
        lda #3
        sta $d020       ; Set background color

        lda #$d         ; Block 13
        sta $7f8        ; Sprite 0 pointer
        lda #$01
        sta v+$15       ; Sprite 0 enable
        lda #$03
        sta v+$27       ; Sprite 0 color
        LDA #$04        ; Sprite multicolor 0
        STA v+$25

        lda #$00
        ldx #$00        
clean
        sta $340,x      ; load sprite data into mem block 13 (13 x 64)
        inx
        cpx #63
        bne clean

        ldx #0
build
        lda data,x      ; Load data from byte array into register a
        sta $340,x      ; load sprite data into mem block 13 (13 x 64)
        inx             ; Increase data position
        cpx #63         ; Stop reading data at pos 63
        bne build       ; 

        lda #$93
        jsr $ffd2       ; Clear screen

        sei             ;disable maskable IRQs

        lda #$7f
        sta $dc0d       ;disable timer interrupts which can be generated by the two CIA chips
        sta $dd0d       ;the kernal uses such an interrupt to flash the cursor and scan the keyboard, so we better
                        ;top it.

        lda $dc0d       ;by reading this two registers we negate any pending CIA irqs.
        lda $dd0d       ;if we don't do this, a pending CIA irq might occur after we finish setting up our irq.
                        ;we don't want that to happen.

        lda #$01        ;this is how to tell the VICII to generate a raster interrupt
        sta $d01a

        lda #$00        ;this is how to tell at which rasterline we want the irq to be triggered
        sta $d012

        lda #$1b        ;as there are more than 256 rasterlines, the topmost bit of $d011 serves as
        sta $d011       ;the 9th bit for the rasterline we want our irq to be triggered.
                        ;here we simply set up a character screen, leaving the topmost bit 0.

        lda #$35        ;we turn off the BASIC and KERNAL rom here
        sta $01         ;the cpu now sees RAM everywhere except at $d000-$e000, where still the registers of
                        ;SID/VICII/etc are visible

        lda #<irq       ;this is how we set up
        sta $fffe       ;the address of our interrupt code
        lda #>irq
        sta $ffff

        cli             ;enable maskable interrupts again

        jmp *           ;we better don't RTS, the ROMS are now switched off, there's no way back to the system


irq

;Being all kernal irq handlers switched off we have to do more work by ourselves.
;When an interrupt happens the CPU will stop what its doing, store the status and return address
;into the stack, and then jump to the interrupt routine. It will not store other registers, and if
;we destroy the value of A/X/Y in the interrupt routine, then when returning from the interrupt to
;what the CPU was doing will lead to unpredictable results (most probably a crash). So we better
;store those registers, and restore their original value before reentering the code the CPU was
;interrupted running.

;If you won't change the value of a register you are safe to not to store / restore its value.
;However, it's easy to screw up code like that with later modifying it to use another register too
;and forgetting about storing its state.

;The method shown here to store the registers is the most orthodox and most failsafe.

        pha         ;store register A in stack
        txa
        pha         ;store register X in stack
        tya
        pha         ;store register Y in stack

        lda #$ff    ;this is the orthodox and safe way of clearing the interrupt condition of the VICII.
        sta $d019   ;if you don't do this the interrupt condition will be present all the time and you end
                    ;up having the CPU running the interrupt code all the time, as when it exists the
                    ;interrupt, the interrupt request from the VICII will be there again regardless of the
                    ;rasterline counter.

                    ;it's pretty safe to use inc $d019 (or any other rmw instrction) for brevity, they
                    ;will only fail on hardware like c65 or supercpu. c64dtv is ok with this though.

; Start interrupt code

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

; End interrupt code

        pla
        tay        ;restore register Y from stack (remember stack is FIFO: First In First Out)
        pla
        tax        ;restore register X from stack
        pla        ;restore register A from stack

        rti        ;Return From Interrupt, this will load into the Program Counter register the address
                    ;where the CPU was when the interrupt condition arised which will make the CPU continue
                  ;the code it was interrupted at also restores the status register of the CPU

sprx
        !byte 100,0
spry    
        !byte 100

data 
        !byte $00,$00,$00,$06,$00,$00,$09,$00
        !byte $00,$0c,$c0,$00,$0c,$7f,$00,$0b
        !byte $ed,$80,$1f,$ec,$c0,$15,$f6,$40
        !byte $13,$6e,$e0,$16,$5f,$a0,$1f,$3e
        !byte $a0,$1f,$df,$c0,$0f,$ff,$e0,$08
        !byte $d1,$c0,$0c,$f2,$20,$07,$ed,$c0
        !byte $00,$f8,$00,$00,$00,$00,$00,$00
        !byte $00,$00,$00,$00,$00,$00,$00,$05
