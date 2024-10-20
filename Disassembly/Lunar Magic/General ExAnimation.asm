; Code used for ExAnimation in both levels and the overworld.
;=======================================================================
if read1($00FFD5) == $23
    sa1rom
endif
;=======================================================================

!RAM_UpdateData         =   $7FC0C0
    ; 56 bytes (eight 7-byte tables); container for data about ExAnimation slots updating this frame.

;=======================================================================

org $008A4E     ; reset
    autoclean JSL ResetExAnimation
    NOP

freecode
ResetExAnimation:
    REP #$30
    LDA #$0000
    STA !RAM_UpdateData+(7*0)
    STA !RAM_UpdateData+(7*1)
    STA !RAM_UpdateData+(7*2)
    STA !RAM_UpdateData+(7*3)
    STA !RAM_UpdateData+(7*4)
    STA !RAM_UpdateData+(7*5)
    STA !RAM_UpdateData+(7*6)
    STA !RAM_UpdateData+(7*7)
    LDX #$1FFE
    RTL

  .version:
    db "LM" : dw $0100

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF