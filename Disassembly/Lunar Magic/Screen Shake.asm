; Updates SMW's screen shake code account for the ExLevel patch's "show bottom row" flag.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!RAM_ExLevelFlags   =   $0BF5

;=======================================================================

org $00A2AF
ExLevelScreenShake:
    REP #$20
    STZ $1888|!addr ; Y offset for shaking
    LDA $1887|!addr ; shake timer
    BEQ .noShake
    DEC $1887|!addr
    AND #$0003
    ASL
    TAY
    LDA Displacements,y
    BIT.w !RAM_ExLevelFlags-1   ; if showing the bottom row of tiles is enabled, shift the screen up 2 pixels
    BVC +
    DEC #2
  + STA $1888|!addr
    CLC
    ADC $1C
    STA $1C
  .noShake:
    SEP #$20

org $00A1CE
Displacements:
    dw $FFFE,$0000,$0002,$0000