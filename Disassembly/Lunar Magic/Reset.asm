; Code to clean ExAnimation data on reset.
;=======================================================================
if read1($00FFD5) == $23
    sa1rom
endif
;=======================================================================

!RAM_UpdateData         =   $7FC0C0
    ; 56 bytes (eight 7-byte tables); container for data about ExAnimation slots updating this frame.

;=======================================================================

org $008A4E         ; cleaning RAM on reset
    autoclean JSL ResetExAnimation
    NOP

freecode
ResetExAnimation:   ; clean up ExAnimation data as well
    REP #$30
    LDA #$0000
    STA.l !RAM_UpdateData+(7*0)
    STA.l !RAM_UpdateData+(7*1)
    STA.l !RAM_UpdateData+(7*2)
    STA.l !RAM_UpdateData+(7*3)
    STA.l !RAM_UpdateData+(7*4)
    STA.l !RAM_UpdateData+(7*5)
    STA.l !RAM_UpdateData+(7*6)
    STA.l !RAM_UpdateData+(7*7)
    LDX #$1FFE      ; (restore code)
    RTL

  .version:
    db "LM" : dw $0100

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF