; Routine to load custom palette data on level load.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!RAM_LevelNum   =   $FE
    ; 2-byte level number, +1. If 0000, the custom palette code is skipped.

;=======================================================================

org $00A5BF
    JSL LoadCustomLevelPalette

org $0EF570
LoadCustomLevelPalette:
    REP #$30
    LDA !RAM_LevelNum
    BEQ .return
    DEC
    JSR CheckForCustomPalette
    STZ !RAM_LevelNum
  .return:
    SEP #$30
    JSL $05BE8A ; restore code
    RTL

CheckForCustomPalette:
    SEP #$10
    PHB : PHK : PLB
    REP #$10
    STA $00 : ASL : CLC : ADC $00   ; x3
    TAY
    LDA.w CustomPalettePointers,y
    STA $04
    INY
    LDA.w CustomPalettePointers,y
    BNE .hasCustomPalette
    PLB
    RTS

  .hasCustomPalette:
    PLB
    STA $05
    SEP #$10
    LDY #$00
    STA $08
    LDA [$04],y
    STA $0701,y
    INC $04
    INC $04
    LDA #$0100
    CLC
    ADC $04
    STA $07
  - LDA [$04],y : STA $0703|!addr,y
    LDA [$07],y : STA $0803|!addr,y
    INY #2
    BNE -
    RTS

;=======================================================================

org $0EF600
; 24-bit pointers to each level's custom palette.
;  If a pointer is $000000, the level does not have a custom palette.
CustomPalettePointers:
    for i = 0..$200 : dl $000000 : endfor