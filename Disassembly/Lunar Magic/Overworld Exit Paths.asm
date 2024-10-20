; Code to reallocate the overworld exit paths for additional exits.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!exitCount  =   $0D
    ; Maximum warp ID to allocate.

;=======================================================================

org $049A35
    autoclean JSL HandleOverworldPathExit
    RTS

;=======================================================================

freecode
prot PathSourceData

HandleOverworldPathExit:
    LDY $0DD6|!addr
    REP #$30
    LDA.w #!exitCount
    STA $02
    LDX.w #!exitCount*5
  .searchLoop:
    LDA $1F19|!addr,y
    CMP PathSourceData+0,x
    BNE .skip
    LDA $1F17|!addr,y
    CMP PathSourceData+2,x
    BNE .skip
    LDA PathSourceData+4,x
    AND #$00FF
    CMP $13C3|!addr
    BNE .skip
  .found:
    LDA PathDestData,x
    STA $1F19|!addr,y
    LDA PathDestData+2,x
    STA $1F17|!addr,y
    LDA PathDestData+4,x
    AND #$00FF
    STA $13C3|!addr
    LDA $02
    ASL
    TAX
    LDA PathDestTilePosition,x
    AND #$00FF
    STA $1F21|!addr,y
    LDA PathDestTilePosition+1,x
    AND #$00FF
    STA $1F1F|!addr,y
    BRA .return

  .skip:
    DEC $02
    DEX #5
    BPL .searchLoop
  .return:
    SEP #$30
    RTL

  .version:
    db "LM" : dw $0100

;=======================================================================

freedata
; [X position], [Y position], [submap] - based on $049964
PathSourceData:
    for i = 0..!exitCount : dw $0000,$0000 : db $00 : endfor

; [X position], [Y position], [submap] - based on $0499AA
PathDestData:
    for i = 0..!exitCount : dw $0000,$0000 : db $00 : endfor

; [X position * 10], [Y position * 10] - based on $0499F0
PathDestTilePosition:
    for i = 0..!exitCount : db $00,$00 : endfor