; implements bytes 5/7/8 of the secondary level header.
; for whatever reason, byte 6 ($06FA00) is not actually stored into RAM anywhere.
;  it is instead handled directly as part of the routine jumped to at $05DA17.
;  (notably, the "auto-set number of screens" flag from it is purely metadata)
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!RAM_HeaderByte8    =   $13CD|!addr
    ; 1 byte, to hold byte 8 of the header ($06FE00)

;=======================================================================

org $05D97D
    JSL GetSecondaryHeader
    
org $05DD30
GetSecondaryHeader:
    LSR
    STA $192A|!addr
    TYX
    LDA.l HeaderByte7,x ;;; byte 7 (high Y position bits, Layer 1 offset)
    STA $04
    LDA.l HeaderByte8,x ;;; byte 8 (bg height, face left, Layer 2 relative to Layer 1)
    STA !RAM_HeaderByte8
    LDA.w HeaderByte5,y ;;; byte 5 (slippery, water, X/Y position 2, high X position bits, smart spawn, sprite spawn range)
    TAX
    AND #$C0
    TSB $192A|!addr     ; set water/slippery flags
    TXA
    BIT #$20
    BEQ .return         ; return if using position method 1
    AND #$18
    ASL #4
    STA $94             ; bits 7/8 of x pos
    ROL
    STA $95

    LDA.w $05F200,y     ;;; byte 2 (Layer 3 setting, entrance action, low X position bits)
    ASL #4
    AND #$70
    TSB $94             ; bits 4-6 of x pos

    LDA.w $05F000,y     ;;; byte 1 (Layer 2 scroll setting, low Y position bits)
    ASL #4
    STA $96             ; y position
    LDA $04
    AND #$3F
    STA $97
  .return:
    RTL
  
    db $FF,$FF,$FF,$FF,$FF,$FF

  .version:
    db "LM" : dw $0111

;=======================================================================

org $05DE00
HeaderByte5:
    for i = 0..$200 : db $00 : endfor
    
org $06FA00
HeaderByte6:
    for i = 0..$200 : db $00 : endfor
    
org $06FC00
HeaderByte7:
    for i = 0..$200 : db $00 : endfor
    
org $06FE00
HeaderByte8:
    for i = 0..$200 : db $00 : endfor