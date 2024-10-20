; Hijack to decompress graphics files as 4bpp isntead of 3bpp.
;  Plus a bunch of hotfixes for various issues in the code that result from that change.
;=======================================================================
if read1($00FFD5) == $23
    sa1rom
endif
;=======================================================================

; Update the main decompression routine to output 4bpp instead of its weird 3bpp conversion
org $00AACD
  Loop4bpp:
    LDX #$10
  - LDA [$00]
    STA $2118
    INC $00
    INC $00
    NOP
    DEX
    BNE -
    DEY
    BPL Loop4bpp
    SEP #$20
    RTS


; Hotfix for the loading screen messages (MARIO START! / GAME OVER / TIME UP! / BONUS GAME).
;  They shift their graphics slightly depending on the message, but do so with the assumption they're 3bpp.
;  So LM just converts the now-4bpp graphics back to 3bpp for it.
org $00A82D
    JSL LoadingScreenHotfix

  ; Skip the original code to decompress GFX00 as well
  org $00A873
    BRA +
    NOP #2
  org $00A8BA : +

  org $0EFC00
  LoadingScreenHotfix:
    JSL $00BA28 ; decompress GFX0F
    PHP
    REP #$30
    PHA : PHX : PHY
    LDX #$0000
    LDY #$0000
  .tileLoop:
    LDA #$0008  ; copy bitplanes 0/1 as-is
    STA $0A
  .bp01loop:
    LDA [$00],y
    PHY
    TXY
    STA [$00],y
    PLY
    INY #2
    INX #2
    DEC $0A
    BNE .bp01loop
    LDA #$0008  ; copy only bitplane 2; bitplane 3 is lost
    STA $0A
    SEP #$20
  .bp23loop:
    LDA [$00],y
    PHY
    TXY
    STA [$00],y
    PLY
    INY #2
    INX
    DEC $0A
    BNE .bp23loop
    REP #$20
    CPY #$1000
    BNE .tileLoop
    PLY : PLX : PLA
    PLP
    RTL


; Hotfix for the background tilemaps during the enemy portion of the credits,
;  to prevent it from blowing up due to getting overwritten when decompressing the sprite GFX files.
org $0095E9
FixCredits:
    JML .backupBGTilemap
  .returnA:
    JSR $00ABED ; restore code - load palette
    JML .restoreBGTilemap
    NOP #2
  .returnB:


  org $0EFC50
  .backupBGTilemap:
    PHP
    REP #$30
    PHA : PHX : PHY
    LDX #$0000
  - LDA $7EB900,x : STA $7E2000,x
    INX #2
    CPX #$0400
    BNE -
    PLY : PLX : PLA
    PLP
    REP #$20
    LDA.w #.returnA
    PHA
    SEP #$30
    JML $00A9DA ; restore code - upload sprite GFX files

  org $0EFC80
  .restoreBGTilemap:
    PHP
    REP #$30
    PHA : PHX : PHY
    LDX #$0000
  - LDA $7E2000,x : STA $7EB900,x
    INX #2
    CPX #$0400
    BNE -
    PLY : PLX : PLA
    PLP
    JSL $05809E ; restore code - upload Map16 data to VRAM
    REP #$20
    LDA.w #.returnB
    PHA
    SEP #$20
    JML $00A5F9 ; restore code - handle animated tiles


; Disable some original game code to shift GFX08/1E's colors to the right half of the palette on the overworld
org $00AA8D  ; not sure why LM doesn't just do a BRA over the relevant code but w/e
    db $32
org $00AA91
    db $32

; Fix overworld animated tiles to index as 4bpp instead of 3bpp.
org $0480BD
    db $10
org $0480D0
    RTS

; Update RAM pointers to the overworld animated tile data
org $048000
  dw $B700,$B720,$B740
org $048006
  dw $B500,$B520,$B540,$B560,$B580,$B5A0,$B5C0,$B5E0
  dw $B600,$B620,$B640,$B660,$B680,$B6A0,$B6C0,$B6E0
  dw $B700,$B720,$B740,$B760,$B780,$B7A0,$B7C0,$B7E0
  dw $B800,$B820,$B840,$B860,$B880,$B8A0,$B8C0,$B8E0
  dw $B900,$B920,$B940,$B960,$B980,$B9A0,$B9C0,$B9E0
  dw $BA00,$BA20,$BA40,$BA60,$BA80,$BAA0,$BAC0,$BAE0
  dw $BB00,$BB20,$BB40,$BB60,$BB80,$BBA0,$BBC0,$BBE0
  dw $BC00,$BC20,$BC40,$BC60,$BC80,$BCA0,$BCC0,$BCE0
