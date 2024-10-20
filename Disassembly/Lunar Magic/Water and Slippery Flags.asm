; Routine used to transfer the water/slippery flags from $192A to $85/$86 on level load.
;  After execution, the two flags are cleared from $192A.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

org $00A6CC
    JSL GetWaterSlipFlags
    
org $05DD00
GetWaterSlipFlags:
    BIT $192A|!addr
    BPL .noSlip
    LDA #$80
    STA $86
  .noSlip:
    BVC .noWater
    LDA #$01
    STA $85
  .noWater:
    LDA #$C0
    TRB $192A|!addr
    REP #$20
    LDA $1C
    CMP $06
    SEP #$20
    RTL