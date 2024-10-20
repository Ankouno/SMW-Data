; Implements LM's improved level name system.
;=======================================================================
if read1($00FFD5) == $23
    sa1rom
endif
;=======================================================================

!enable_OverworldExpansion  =   0
    ; flag for whether LM's overworld level expansion hijack is applied.

;=======================================================================

org $049549
    JSL $03BB20
    NOP #6
    
org $03BB20     ; (A = 16-bit translevel number, from $7ED000)
    STA $02     ; multiply level number by 19 (maximum length of level name string) 
    ASL #4
    STA $00
    LDA $02
    ASL
    CLC
    ADC $02
    ADC $00
    TAX
    PHB
    PEA $7F7F
    PLB : PLB
    LDA.w $7F837B
    TAY
    CLC : ADC #$0026
    STA $02
    CLC : ADC #$0004
    STA.w $7F837B
    LDA #$2500
    STA.w $7F837B+4,y
    LDA #$8B50
    STA.w $7F837B+2,y
    SEP #$20
  .nameLoop:
    autoclean LDA.l LevelNames,x
    STA.w $7F837B+6,y
    LDA #$39                ; yxpccctt
    STA.w $7F837B+7,y
    INY #2
    INX
    CPY $02
    BCC .nameLoop
    LDA #$FF
    STA.w $7F8381,y
    REP #$20
    PLB
    RTL


freedata
LevelNames:
    if !enable_OverworldExpansion
        for i = 0..256 : db "                   " : endfor
    else
        for i = 0..96  : db "                   " : endfor
    endif