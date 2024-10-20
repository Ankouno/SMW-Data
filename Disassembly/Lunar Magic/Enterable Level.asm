; Code used by Lunar Magic to implement the "no entry if level beaten" overworld level flag
;=======================================================================
!addr = $0000
!RAM_OWLevelNums = $7ED000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
    !RAM_OWLevelNums = $40D000
endif
;=======================================================================


org $049199
    JSL CheckEnterableLevel
    
org $03BA50
CheckEnterableLevel:
    PHP
    REP #$30
    LDA $04 : PHA
    JSR GetPlayerTileIndex  ; get the tile index the player is on
    LDX $04
    PLA : STA $04
    LDA !RAM_OWLevelNums,x  ; get level number
    AND #$00FF
    TAX
    LDA $1EA2|!addr,x       ; allow entry if level not beaten yet
    AND #$0080
    BEQ .entryAllowed
    LDA $1EA2|!addr,x       ; allow entry if level does not have "no entry if level beaten" flag set
    AND #$0020
    BEQ .entryAllowed
    LDA #$00FF
    BRA .return

  .entryAllowed:
    LDA $13C1|!addr
  .return:
    PLP
    CMP #$81
    RTL
    
    
GetPlayerTileIndex:             ; (this routine is mostly identical to the one at $049885)
    PHP
    SEP #$10
    REP #$20
    LDA $00 : PHA               ; preserve $00/$02
    LDA $02 : PHA
    LDX $0DD6|!addr             ; X = current player (0 or 4)
    LDA $1F1F|!addr,x : STA $00 ; $00 = xpos
    LDA $1F21|!addr,x : STA $02 ; $02 = ypos
    TXA
    LSR #2                      ; X = current player (0 or 1)
    TAX
    LDA $00                     ; For position [---Xxxxx], [--YYyyyy]
    AND #$000F                  ; $04 = [-----YYX yyyyxxxx]
    STA $04
    LDA $00
    AND #$0010
    ASL #4
    ADC $04
    STA $04
    LDA $02
    ASL #4
    AND #$00FF
    ADC $04
    STA $04
    LDA $02
    AND #$0010
    BEQ .bottomHalf
    LDA $04
    CLC : ADC #$0200
    STA $04
  .bottomHalf:
    LDA $1F11|!addr,x
    AND #$00FF
    BEQ .onMainMap
    LDA $04
    CLC : ADC #$0400
    STA $04
 .onMainMap:
    PLA : STA $02               ; restore $00/$02
    PLA : STA $00
    PLP
    RTS