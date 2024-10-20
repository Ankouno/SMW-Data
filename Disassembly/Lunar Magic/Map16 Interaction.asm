; Code added by Lunar Magic to handle Map16 interaction.
; Handles both retrieving the Acts-Like setting for a tile,
;  as well as calling the custom block interaction point handlers.

;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

org $00F4DD
    JSL MarioInteraction

org $019533
    JSL SpriteInteraction

org $02961A
    JSL CapeInteraction

org $02A6EB
    JSL FireballInteraction

;=======================================================================
 
org $06F600
    NOP #2  ; unused?

UseVanillaInteraction:  ; unhandled interaction point.
    TYA
Mode7ActsLike:      ; in a Mode 7 room.
    JML $00F545     ; swap to the the vanilla acts-like routine.
    NOP

GetActsLike:        ;;; Subroutine to get a Map16 tile's "acts-like" setting.
    LDY $0D9B|!addr ; Returns $03 = 16-bit tile number, $1693 = low byte, Y = high bit
    BPL .normalLevel
    PLY : PLY
    BRA Mode7ActsLike
    NOP #6

  .normalLevel:     ; in a normal level.
    XBA
    LDA $1693|!addr
    PHX
    REP #$30
  .getActsLike:     ; recursively search through the acts-like settings until
    TAY             ;  a setting in the range of 000-1FF is found (i.e. a vanilla tile).
    ASL
    TAX
    BMI .pages40to7F
  .pages00to3F
    autoclean LDA.l ActsLikePages00to3F,x   ; pages 00-3F
    CMP #$0200
    BCS .getActsLike
  .done:
    STY $03
    SEP #$30
    PLX
    STA $1693|!addr
    XBA 
    TAY
    LDA $08,s
    RTS

  .pages40to7F:
    autoclean LDA.l ActsLikePages40to7F,x   ; pages 40-7F
    CMP #$0200
    BCS .getActsLike
    BRA .done

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

  .version:
    db "LM" : dw $0111

;=======================================================================

org $06F660
MarioInteraction:       ;;; Routine to handle Mario interaction with custom tiles.
    JSR GetActsLike
    CMP #$8C            ; $00EC8A - Head (MarioBelow)
    BEQ .MarioBelow
    CMP #$4C            ; $00ED4A - On foot (MarioAbove)
    BEQ .MarioAbove
    CMP #$26            ; $00EC24 - Side (MarioSide)
    BEQ .MarioSide
    CMP #$EB            ; $00EDE9 - Off foot (TopCorner)
    BEQ .TopCorner
    CMP #$B1            ; $00EBAF - Center (BodyInside)
    BEQ .BodyInside
    CMP #$3C            ; $00EC3A - Center (HeadInside)
    BEQ .HeadInside
    JMP UseVanillaInteraction

; The below are intended to be implemented by a tool.
; See GPS's source code for how it implements them.
org $06F690
  .MarioBelow:              ; $06F690
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .MarioAbove:              ; $06F6A0
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .MarioSide:               ; $06F6B0
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .TopCorner:               ; $06F6C0
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .BodyInside:              ; $06F6D0
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .HeadInside:              ; $06F6E0
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .UnusedOffset1:           ; $06F6F0
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org $06F700
SpriteInteraction:      ;;; Routine to handle sprite interaction with custom tiles.
    JSR GetActsLike
    CMP #$71            ; $01926F - Vertical block interaction (extra check?)
    BEQ .SpriteV
    CMP #$57            ; $019155 - Sprite buoyancy, layer 1
    BEQ .SpriteH
    CMP #$D2            ; $0192D0 - Vertical block interaction
    BEQ .SpriteV
    CMP #$93            ; $019291 - Horizontal block interaction
    BEQ .SpriteH
    CMP #$7F            ; $01917D - Sprite buoyancy, layer 2
    BEQ .SpriteH
    JMP UseVanillaInteraction
    ; GPS also inserts another check for $019280 - Horizontal block interaction (stationary carryable sprites)

; The below are intended to be implemented by a tool.
; See GPS's source code for how it implements them.
org $06F720
  .SpriteV:                 ; $06F720
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .SpriteH:                 ; $06F730
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .UnusedOffset2:           ; $06F740
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .UnusedOffset3:           ; $06F750
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org $06F760
CapeInteraction:        ;;; Routine to handle capespin interaction with custom tiles.
    JSR GetActsLike
    CMP #$09            ; $029507 - MarioCape
    BEQ .MarioCape
    JMP UseVanillaInteraction
    
; The below are intended to be implemented by a tool.
; See GPS's source code for how it implements them.
org $06F780
  .MarioCape:               ; $06F780
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
  .UnusedOffset4:           ; $06F790
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org $06F7A0
FireballInteraction:    ;;; Routine to handle fireball interaction with custom tiles.
    JSR GetActsLike
    CMP #$DA            ; $029FD8 - MarioFireball
    BEQ .MarioFireball
    JMP UseVanillaInteraction
    
; The below are intended to be implemented by a tool.
; See GPS's source code for how it implements them.
org $06F7C0
  .MarioFireball:           ; $06F7C0
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP
    JMP UseVanillaInteraction : NOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GPS also adds two more interaction points for WallFeet and WallBody,
;  at $06F7D0 and $06F7E0 respectively, which originate from $00EB37 and $00EFE8.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

freedata align
ActsLikePages00to3F:    ; read3($06F624)
    for i = $0000..$3FFF : dw $0000 : endfor

freedata align
ActsLikePages40to7F:    ; read3($06F63A)
    for i = $4000..$7FFF : dw $0000 : endfor
