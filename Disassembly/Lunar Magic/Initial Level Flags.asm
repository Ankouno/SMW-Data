; Loads the initial level flags for the overworld upon the creation of a new save file.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!enable_OverworldExpansion  =   0
    ; flag for whether LM's overworld level expansion hijack is applied.
    
;=======================================================================

org $009F19
    JSL GetInitFlags

org $05DD80
GetInitFlags:
    PHP
    REP #$30
    LDX #$005E
  - LDA.l InitFlags,x
    STA.l $1F49|!addr,x
    DEX #2
    BPL -
    PLP
    RTL

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

  .version:
    db "LM" : dw $0110

;=======================================================================

if !enable_OverworldExpansion
    org $03BE80
    InitFlags:
        for i = 0..256 : db $00 : endfor
else
    org $05DDA0
    InitFlags:
        for i = 0..96  : db $00 : endfor
endif