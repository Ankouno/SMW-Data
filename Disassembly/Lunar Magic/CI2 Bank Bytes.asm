; Routine to add bank bytes to the Chocolate Island 2 pointers.
;=======================================================================
if read1($00FFD5) == $23
    sa1rom
endif
;=======================================================================

org $05DB5B
    JSL ChocolateIsland2BankBytes
    ; ExLevel also hijacks right after this

org $0DE210
ChocolateIsland2BankBytes:
    STA $68
    SEP #$20
    STZ $1D
    STZ $21
    TXA
    LSR
    TAX
    LDA .layer1,x : STA $67
    LDA .layer2,x : STA $6A
    LDA .sprite,x : STA $D0
    RTL

    db $FF,$FF,$FF

  .layer1:
    db $06,$06,$06  ; room 3
    db $06,$06,$06  ; room 1
    db $06,$06,$06  ; room 2

  .layer2:
    db $7F,$7F,$7F  ; room 3
    db $7F,$7F,$7F  ; room 1
    db $7F,$7F,$7F  ; room 2

  .sprite:
    db $07,$07,$07  ; room 3
    db $07,$07,$07  ; room 1
    db $07,$07,$07  ; room 2

  .version:
    db "LM" : dw $0100