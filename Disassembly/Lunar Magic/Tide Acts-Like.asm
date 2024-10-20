; Code added by LM v3.10 to add an acts-like setting to tides.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!RAM_ActsLikeSetting    =   $7FC01B
    ; 1 byte, for the Layer 3 acts-like setting (0-F).

!RAM_ExLevelHeight      =   $13D7|!addr
    ; 2 bytes, from ExLevel patch: height of the level, in pixels.

;=======================================================================

org $00A045
    autoclean JSL TideActsLike
    RTS

freecode
TideActsLike:
    PEI ($08)
    PEI ($0A)
    PEI ($0C)
    PEI ($0E)
    PEI ($D8)
    LDA !RAM_ActsLikeSetting
    AND #$0F
    STA $0B
    ASL
    TAX
    LDA #$7E
    STA $03
    INC
    STA $06
    REP #$30
    LDA #$C800
    STA $01             ; $01 = $7EC800
    STA $04             ; $04 = $7FC800
    LDA ActsLikeSettings,x
    STA $07             ; $07 = low byte of acts-like ($08 = same)
    STA $08
    SEP #$20
    XBA
    STA $0A             ; $09 = high byte of acts-like ($0A = same)

    LDA $5B
    LSR
    BCC .horizontal
  .vertical:
    LDA #$02
    TSB $5B
    REP #$30
    LDX #$0D00
    JSR WriteTilesVert
    JSR GetTopRow
    BEQ .return
    JSR WriteTilesVert
  .return:
    PLA
    STA $D8
    PLA
    STA $0E
    PLA
    STA $0C
    PLA
    STA $0A
    PLA
    STA $08
    SEP #$30
    LDA #$80
    TSB $5B
    RTL

  .horizontal:
    LDA $05DA8A         ; check if ExLevel patch is applied
    CMP #$22
    BEQ .exLevel
    REP #$30
    LDX #$0058
    JSR WriteTilesHorz
    JSR GetTopRow
    BEQ .return
    JSR WriteTilesHorz
    BRA .return

  .exLevel:
    LDA $0C28!addr : STA $03    ; $03 = 24-bit pointer to low byte of the Map16 data for subscreen 01 of Layer 3
    LDA $0C88!addr : STA $06    ; $06 = 24-bit pointer to high byte
    REP #$30
    LDA $0C26!addr : STA $01
    LDA $0C86!addr : STA $04
    LDA !RAM_ExLevelHeight      ; if the level is not at least two subscreens tall (only occurs in the unfinished modes 1D/1E/1F),
    CMP #$0110                  ;  then return without actually giving the tides any interaction
    BCC .return
    SBC #$0100
    LSR
    TAX
    JSR WriteTilesExLevel
    JSR GetTopRow
    BEQ .return
    JSR WriteTilesExLevel
    BRA .return


ActsLikeSettings:   ; Map16 tiles for each of the acts-like settings.
    dw $0000    ; Water
    dw $0005    ; Lava
    dw $0005    ; Mario lava
    dw $0005    ; Cave lava
    dw $0130    ; Solid
    dw $0200    ; Tile 200
    dw $0201    ; Tile 201
    dw $0202    ; Tile 202
    dw $0203    ; Tile 203
    dw $0204    ; Tile 204
    dw $0205    ; Tile 205
    dw $0206    ; Tile 206
    dw $0207    ; Tile 207
    dw $0208    ; Tile 208
    dw $0209    ; Tile 209
    dw $020A    ; Tile 20A


GetTopRow:      ; gets tile for the top row of settings that need two distinct acts-like settings (i.e. lava).
    LDA $0B     ; returns the tile number in X, else returns 0.
    AND #$00FF
    CMP #$0001
    BEQ .lava
    CMP #$0003
    BEQ .caveLava
    LDX #$0000
    RTS
 .lava:
    LDA #$0404  ; lava: top is tile 0004
 .return:
    STA $07
    LDX #$0008
    RTS

 .caveLava:
    LDA #$0101  ; cava lava: top is tile 0159
    STA $09
    LDA #$5959
    BRA .return


WriteTilesVert:
    LDY #$1E00
  .loop:
    LDA $07
    STA [$01],y
    LDA $09
    BEQ +
    STA [$04],y
  + INY #2
    DEX
    BNE .loop:
    RTS

WriteTilesHorz:
    LDA #$0010
    LDY #$1C00
    STA $0E
    STY $D8
    STX $0C
    CLC
  .loop:
    LDA $07
    STA [$01],y
    LDA $09
    BEQ +
    STA [$04],y
  + INY #2
    DEX
    BNE .loop
    LDA $D8
    ADC #$01B0
    STA $D8
    TAY
    LDX $0C
    DEC $0E
    BNE .loop
    RTS

WriteTilesExLevel:  ; repeats the 2 tiles from $07/$09 and $08/$0A for the number of rows specified by X, starting at subscreen 01 of the level.
    LDY #$0100
    STY $D8
    STX $0C
  .loop:
    LDA $07
    STA [$01],y
    LDA $09
    BEQ +
    STA [$04],y
  + INY #2
    DEX
    BNE .loop
    LDA $D8
    CLC
    ADC !RAM_ExLevelHeight
    STA $D8
    TAY
    ADC $01
    BCS .ret
    ADC !RAM_ExLevelHeight
    BEQ +
    BCS .ret
  + LDX $0C
    BRA .loop
    
 .ret:
    RTS

    db $20,$20,$20,$20,$20,$20,$20
    db $20,$20,$20,$20,$20,$20,$20,$20

Version:
    db "LM" : dw $0100