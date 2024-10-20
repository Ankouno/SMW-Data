; Implements support for secret exits 2/3.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

org $04E5F1 ; A = $0DD5 = how level was exited, 01/02/03/04 = the four exits of the level
    JSL GetEventToActivate
    NOP #3

org $05DCB0
GetEventToActivate:
    BEQ .return
    CMP #$05
    BCS .return
    DEC
    ADC $1DEA|!addr
    STA $1DEA|!addr ; update level's event for the secret exits
  .return:
    RTL

    db $FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    
  .version:
    db "LM" : dw $0110