; Code to update the overworld star warps and pipes.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!warpCount  =   $36
    ; Maximum warp ID to allocate.

;=======================================================================

org $048509
    autoclean JSL CheckForWarp
    RTS

org $048566
    JSL GetWarpDestination

;=======================================================================

freecode
prot SourceX

CheckForWarp:
    LDY $0DB3|!addr
    LDA $1F11|!addr,y
    STA $01
    STZ $00
    LDY $0DD6|!addr
    REP #$30
    LDX.w #!warpCount
  .warpLoop:
    DEX #2
    BMI .starNotFound
    LDA.l WarpSourceX,x
    EOR $00
    CMP #$0200
    BCS .warpLoop
    CMP $1F1F|!addr,y
    BNE .warpLoop
    LDA.l WarpSourceY,x
    CMP $1F21|!addr,y
    BNE .warpLoop
    TXA
    LSR
    SEP #$32
    STA $1DF6|!addr
    RTL

  .starNotFound:
    SEP #$30
    RTL

    db $FF,$FF
    
  .version:
    db "LM" : dw $0110


GetWarpDestination:
    LDY $0DD6|!addr
    LDX $1DF6|!addr
    REP #$30
    TXA
    ASL
    TAX
    LDA.l WarpDestX,x
    PHA
    AND #$01FF
    STA $1F17|!addr,y
    LSR #4
    STA $1F1F|!addr,y
    LDA.l WarpDestY,x
    STA $1F19|!addr,y
    LSR #4
    STA $1F21|!addr,y
    PLA
    LSR
    XBA
    AND #$000F
    RTL

;=======================================================================

if !warpCount > $36
    freecode
else
    org $048431
endif

WarpSourceX:
    for i = 0..!warpCount : dw $0000 : endfor

WarpSourceY:
    for i = 0..!warpCount : dw $0000 : endfor

WarpDestX:
    for i = 0..!warpCount : dw $0000 : endfor

WarpDestY:
    for i = 0..!warpCount : dw $0000 : endfor