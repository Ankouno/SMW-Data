; LM's modified system for fetching message box text.
; For the most part fixed in the ROM into the empty space at $03BB90, $03BC7F, and $03BE80,
;  but the actual message data is dynamically located in a single large table.

;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

; Translevel numbers for each of the "special message" levels.
!ysp    =   $14
!gsp    =   $08
!rsp    =   $3F
!bsp    =   $45
!yh     =   $28

!enable_OverworldExpansion  =   0
    ; flag for whether LM's overworld level expansion hijack is applied.

;=======================================================================

org $05B1A3
    JSL Main
    JMP +
org $05B250 : +

org $03BB90
Main:
    LDY $1426|!addr
    CPY #$03
    BEQ .yoshiMessage
    LDX $13BF|!addr
    CPX #!yh
    BEQ .yoshiHouse
    DEY
    BNE .gotMessage
    CPX #!ysp
    BEQ .switchPalace
    INY
    CPX #!bsp
    BEQ .switchPalace
    INY
    CPX #!rsp
    BEQ .switchPalace
    INY
    CPX #!gsp
    BNE .msg1
  .switchPalace:
    JSR DrawSwitchBlocks
  .msg1:
    LDY #$00
    BRA .gotMessage

  .yoshiMessage:
    LDX #$00
    LDY #$01
    BRA .gotMessage

  .yoshiHouse:
    LDY #$00
    LDA $187A|!addr
    BEQ .gotMessage
    INY
  .gotMessage:
    REP #$30
    TXA     ; X = ((translevel * 2) + message ID) * 2
    ASL
    STA $00
    TYA
    if !enable_OverworldExpansion
        ; overworld expansion enabled - message pointers are direct 24-bit pointers
        ADC $00
        STA $00
        ASL
        ADC $00
        TAX
        autoclean LDA.l MessagePointers,x   : STA $04   ; $04 = 24-bit message data pointer
                  LDA.l MessagePointers+1,x : STA $05
        PHB
        PEA $7F7F : PLB : PLB
        LDY.w $7F837B
        LDX #$000E
        STZ $02
      .MessageLoop:
        PHB : PHK : PLB
        LDA.w LineVramHeaders,x
        PLB
        STA.w $7F837D,y
        LDA #$2300
        STA.w $7F837F,y
        PHX
        LDX #$0012
        LDA #$391F  ; blank tile
      .LineLoop:
        BIT $02
        BMI .gotCharacter
        SEP #$20
        LDA [$04]
        CMP #$FE    ; end-of-message character
        BNE .notEoM
        STA $03
        LDA #$1F    ; blank tile
      .notEoM:
        REP #$20
        INC $04
      .gotCharacter:
        STA.w $7F8381,y
        INY #2
        DEX
        BNE .LineLoop
        INY #4
        PLX
        DEX #2
        BPL .MessageLoop
    else
        ; no overworld expansion - message pointers are 16-bit offsets
        CLC : ADC $00
        ASL
        TAX
        PHB : PHK : PLB
        LDA.w MessagePointers,x     ; $00 = 16-bit message data pointer
        STA $00
        PEA $7F7F : PLB : PLB
        LDA.w $7F837B
        TAY
        LDX #$000E  ; total number of lines to display in the message box
        STZ $02
      .MessageLoop:
        PHB : PHK : PLB
        LDA.w LineVramHeaders,x
        PLB
        STA.w $7F837D,y
        LDA #$2300
        STA.w $7F837F,y
        PHX
        SEP #$20
        LDA #$12
        STA $02
        LDX $00
      .LineLoop:
        LDA #$1F    ; blank tile
        BIT $03
        BMI .gotCharacter
        autoclean LDA.l MessageData,x
        INX
        CMP #$FE    ; end-of-message character
        BNE .gotCharacter
        STA $03
        LDA #$1F    ; blank tile
      .gotCharacter:
        STA.w $7F8381,y
        LDA #$39
        STA.w $7F8382,y
        INY #2
        DEC $02
        BNE .LineLoop
        STX $00
        REP #$20
        INY #4
        PLX
        DEX #2
        BPL .MessageLoop
    endif
    LDA #$00FF
    STA.w $7F837D,y
    TYA
    STA.w $7F837B
    PLB
    STZ $22
    STZ $24
    SEP #$30
    LDA #$01
    STA $13D5|!addr
    RTL


DrawSwitchBlocks:
    PHX
    TYX
    INX
    STX $13D2|!addr
    DEX
    TXA
    ASL #4
    TAX
    STZ $00
    REP #$20
    LDY #$1C
  .tilemapLoop:
    LDA.w $05B29B,x
    STA $0202|!addr,y
    PHX
    LDX $00
    LDA.w $05B2DB,x
    STA $0200|!addr,y
    PLX
    INX #2
    INC $00
    INC $00
    DEY #4
    BPL .tilemapLoop
    STZ $0400|!addr
    SEP #$20
    PLX
    RTS

LineVramHeaders:
    db $51,$A7  ; line 8
    db $51,$87  ; line 7
    db $51,$67  ; line 6
    db $51,$47  ; line 5
    db $51,$27  ; line 4
    db $51,$07  ; line 3
    db $50,$E7  ; line 2
    db $50,$C7  ; line 1

if !enable_OverworldExpansion
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF

    Version:
        db "LM" : dw $0110  ; not sure why LM only includes this with the overworld expansion patch
endif

;=======================================================================

if !enable_OverworldExpansion
    freedata
    prot MessageData
    MessagePointers:
        for i = 0..256 : dl MessageData,MessageData : endfor
else
    org $03BE80
    MessagePointers:
        for i = 0..96 : dw $0000,$0000 : endfor
endif

;=======================================================================

freedata
MessageData:
    db "...",$FE    ; $FE = EoM