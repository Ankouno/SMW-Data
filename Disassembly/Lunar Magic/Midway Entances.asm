; implements expanded midway entrance system

;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

org $05D979     ; level entrance
    JSL HandleScreenExitToMidway

org $05D9E3     ; specifically loading midway entrance from the overworld
    autoclean JSL LoadMidwayEntrance
    
;=======================================================================

freecode
prot MidwayByte1

LoadMidwayEntrance:     ; Input: A = byte 3 of the secondary header (MMMMffbb)
    LSR #4              ; Output: Carry flag indicates if the entrance settings from the secondary header should be skipped (for screen exits).
    REP #$11
    PHA
    LDX $0E
    LDA MidwayByte1,x   ;;; byte 1 (IWHMYAAA)
    TAY
    AND #$10            ; append bit 4 of screen number for entrance to the pushed value from before
    ORA $01,s
    STA $01,s
    TYA
    BIT #$20            ; return if "separate midway entrance" is unchecked
    BEQ .return
    AND #$08
    LSR #3
    STA $95
    TYA
    AND #$C7
    STA $192A|!addr     ; slippery + water flags and entrance action
    
    LDA MidwayByte2,x   ;;; byte 2 (yyyyxxxx)
    TAY
    AND #$F0            ; X position
    STA $96
    TYA
    ASL #4
    STA $94             ; Y position

    LDA $06FC00,x       ;;; secondary header byte 7 (OFYYYYYY)
    AND #$80
    STA $04             ; 'set bg relative to fg' flag
    LDA $06FE00,x       ;;; secondary header byte 8 (RL-ooooo)
    AND #$3F
    STA $13CD|!addr     ; bg height

    LDA MidwayByte4,x   ;;; byte 4 (-FYYYYYY)
    AND #$7F
    TSB $04
    AND #$3F
    STA $97             ; high Y position

    LDA #$00
    XBA
    LDA MidwayByte3,x   ;;; byte 3 (RLE-ffbb)
    STA $02
    BIT #$20            ; if bit 5 (E) is set, redirect to other level
    BNE .redirect
    TAY
    AND #$03
    TAX
    LDA $05D70C,x       ; get BG initial position
    STA $20
    TYA
    AND #$0C
    LSR #2
    TAX
    LDA $05D708,x       ; get FG initial position
    STA $1C
    TYA
    AND #$C0
    TSB $13CD|!addr     ; merge "bg relative to player" and "face left" bits (R/L) into background height,
    SEC                 ;  so that it's identical to byte 8 of the secondary level header
  .return:
    PLA
    RTL

  .redirect:            ; midway is redirected to other level
    LDA $141A|!addr
    CLC
    BNE .return         ; if not entering from the overworld, return without taking the redirect
    STZ $192A|!addr     ; otherwise, clear midway entrance flag and re-run entrance loading routine with the new level
    STY $0E
    LDA $02
    AND #$01
    STA $0F
    PLX
    PLX
    JML $05D8B7

    db $FF,$FF,$FF,$FF,$FF,$FF

  .version:
    db "LM" : dw $0110

;=======================================================================

HandleScreenExitToMidway:
    BIT $192A|!addr         ; return if the flag to load the midway entrance isn't set
    BVC .notMidway
    PHA
    LDA $141A|!addr         ; return if not coming from a screen exit
    BEQ .return
    LDA.w $05F400,y         ; (secondary level header byte 3 - MMMMffbb)
    JSL LoadMidwayEntrance  ; load the midway entrance
    LDY $0E
    BCC .return             ; if a midway was actually loaded, return and skip over the rest of the secondary header handling
    PLX
    PLX
    STA $01
    JML $05D9A1

  .return:
    PLA
  .notMidway:
    AND #$38    ; restore code
    LSR #2
    RTL
    
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

  .version:
    db "LM" : dw $0110

;=======================================================================

freedata
MidwayByte1:
    for i = 0..$200 : db $00 : endfor
MidwayByte2:
    for i = 0..$200 : db $00 : endfor
MidwayByte3:
    for i = 0..$200 : db $00 : endfor
MidwayByte4:
    for i = 0..$200 : db $00 : endfor