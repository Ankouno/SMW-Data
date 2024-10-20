; Routine to implement secondary entrance bytes 4/5/6/7

;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

org $05D836
    TYX ; X = secondary entrance byte 3
    JSL LoadSecondaryEntrance

org $03BCE0
LoadSecondaryEntrance:
    JSL $05DC80     ;;; byte 4
    TAY
    AND #$87
    TSB $192A|!addr ; entrance action and slippery flag
    TYA
    AND #$08        ; high bit of level
    LSR #3
    STA $0F
    
    JSL $05DC85     ;;; byte 5
    STA $02         ; with "exit to overworld" flag
    AND #$7F
    STA $04         ; with just relative fg/bg position bit 5 and y bits
    
    JSL $05DC8A     ;;; byte 6
    TAX
    AND #$C0
    STA $13CD|!addr ; facing left, relative fg/bg flag
    TXA
    AND #$20        ; water level flag
    ASL
    TSB $192A|!addr
    
    LDX $0E
    LDA $06FC00,x   ;;; secondary header, byte 6
    AND #$80        ; relative BG to FG flag
    TSB $04

    LDA $06FE00,x   ;;; secondary header, byte 7
    AND #$3F        ; BG height
    TSB $13CD|!addr

    TYA             ;;; going back to byte 4
    BIT #$40        ; branch if "position method 2" is clear
    BEQ .notNewPosition
    AND #$30        ; bits 4/5 of X position
    ASL #3
    STA $94
    ROL
    STA $95
    LDA $01         ; bits 0-3 of X position
    LSR
    AND #$70
    TSB $94
    LDA $00         ; bits 0-3 of Y position
    ASL #4
    STA $96
    LDA $02         ; bits 4-9 of Y position
    AND #$3F
    STA $97
  .notNewPosition:
    LDA $02         ; branch if "exit to overworld" bit is set
    BMI .exitToOverworld
    LDA $00         ; else shift BB/FF bits down for later code
    LSR #4
    STA $02
    RTL

  .exitToOverworld:
    LDA #$0C
    STA $0100|!addr
    STZ $0DAE|!addr
    STZ $0DAF|!addr
    STZ $0DB0|!addr
    TYA
    BIT #$10        ; if bit 4 set, teleport mario on the overworld
    BEQ .noTeleport
    LDA $00         ; set location index from byte 2
    STA $1DF6|!addr
    INC $1B9C|!addr
    TYA
  .noTeleport:
    BIT #$20        ; if bit 5 set, activate event
    BEQ .noEventBase
    LDA $01         ; set event base from byte 3
    STA $1DEA|!addr
    TYA
  .noEventBase:
    AND #$07
    CMP #$07        ; exit to overworld without event if action is "switch players"
    BNE .noSwitchPlayers
    LDA #$80
  .noSwitchPlayers:
    STA $0DD5|!addr ; store process to run on overworld
    ASL
    BEQ .noEvent    ; indicate event should activate if applicable
    INC $13CE|!addr
    INC $1DE9|!addr
  .noEvent:
    PLX
    PLA
    PLB
    PLX
    PLA
    SEP #$30
    JML $0093F7

;=======================================================================
; Getter functions for each of the six secondary entrance bytes.
org $0DE190
GetSecondaryEntranceByte1:  ; $0DE190
    LDA.l $05F800,x
    STA $0E
    RTL

GetSecondaryEntranceByte2:  ; $0DE197
    LDA.l $05FA00,x
    STA $00
    RTL

GetSecondaryEntranceByte3:  ; $0DE19F
    LDA.l $05FC00,x
    STA $01
    RTL

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF

Version:
    db "LM" : dw $0100


    
org $05DC80
GetSecondaryEntranceByte4:  ; $05DC80
    LDA.l $05FE00,x
    RTL

GetSecondaryEntranceByte5:  ; $05DC85
    autoclean LDA.l Byte5,x
    RTL

GetSecondaryEntranceByte6:  ; $05DC8A
    autoclean LDA.l Byte6,x
    RTL

;=======================================================================

freedata
Byte5:

freedata
Byte6: