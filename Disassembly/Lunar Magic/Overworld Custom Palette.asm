; Routine to load custom palette data on overworld load.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

org $00AD32
    autoclean JSL LoadCustomOverworldPalette
    RTS

;=======================================================================

freecode
prot CustomOverworldPalettes

LoadCustomOverworldPalette:
    TAX
	LDA $1931|!addr
	AND #$000F
	DEC
	CLC
	TXY
	BPL .specialWorldNotPassed
	ADC #$0007
  .specialWorldNotPassed:
	XBA
	ASL
	ADC.w #CustomOverworldPalettes
	TAX
	LDY #$0703|!addr
	LDA #$01FF
	PHB
	MVN $00,CustomOverworldPalettes>>16
	PLB
	SEP #$30
	RTL

  .version:
    db "LM" : dw $0100

;=======================================================================

freedata
CustomOverworldPalettes:
    ; non-special world
    for submap = 0..7
        for j = 0..$100 : dw $0000 : endfor
    endfor

    ; special world
    for submap = 0..7
        for j = 0..$100 : dw $0000 : endfor
    endfor