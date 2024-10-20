; Patch to implement Extended Objects 1, 2, and 3 (screen jumps and extended screen exits)
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================
; $0A = byte 1
; $0B = byte 2
; $59 = byte 3
; $65 currently points to byte 4

org $0583C7
    JSL ResetBlockPos

org $0DA10F+3
    dl ScreenJump           ; 01
    dl ExtScreenExit        ; 02
    dl ScreenJump_Vertical  ; 03

;=======================================================================

org $0DE1B0
ExtScreenExit:  ;; extended object 02 (extended screen exit)
    LDA $0A
    AND #$1F    ; screen number
    TAX
    REP #$20
    LDA [$65]   ; destination level + flags
    INC $65
    INC $65
    SEP #$20
    STA $19B8|!addr,x
    XBA
    STA $19D8|!addr,x
    RTS
    
    db $FF,$FF,$FF,$FF,$FF
  
  .version:
    db "LM" : $0100

;=======================================================================

org $0DE1D0
ScreenJump:     ;; extended object 01 (screen jump)
    LDA $0B
    ASL         ; vertical page (00-0F)
    STA $8B
    LDA $0A
    AND #$1F    ; horizontal page (00-1F)
  .storeScreen:
    STA $1928|!addr
    STA $1BA1|!addr
    RTS

.Vertical:      ;; extended object 03 (vertical screen jump)
    LDA $0A
    AND #$1F    ; vertical page (00-1F)
    ASL
    STA $8B
    LDA $0B     ; horizontal page (00-0F)
    BRA .storeScreen

    db $FF

  .version:
    db "LM" : $0100

;=======================================================================

org $0DE1F0
ResetBlockPos:  ; clear the block index in RAM.
    STZ $8A
    STZ $8B
    LDA [$65]
    RTL

    db $FF,$FF,$FF,$FF,$FF
    
  .version:
    db "LM" : $0100