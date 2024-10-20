; Fix for an issue with castle destructions across a overworld boundary.
;=======================================================================
if read1($00FFD5) == $23
    sa1rom
endif
;======================================================================= 

org $04E6C5
    autoclean JSL FixCastleDestructionRAM
    
org $04EEF1
    JSL FixCastleDestructionVRAM
    
;======================================================================= 

freecode
FixCastleDestructionRAM:
    SEP #$20
    CLC
    ADC #$10
    REP #$20
    BCC .noCross
    ADC #$01FF
  .noCross:
    RTL

    db $FF,$FF,$FF

FixCastleDestructionVRAM:
    PHA
    AND #$03E0
    CMP #$03E0
    PLA
    BCS .boundaryCross
    ADC #$0020
    RTL

  .boundaryCross:
    ADC #$041F
    RTL

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    
Version:
    db "LM" : dw $0100
