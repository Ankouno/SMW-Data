; This routine gets various settings related to the Layer 2 background tilemap.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!RAM_LT2Settings    =   $7FC00B
    ; 1 byte, for the Layer 2 tilemap settings. Format: bbBBVFDT
    ;   V    = flag to indicate a vanilla BG tilemap is being used.
    ;   D    = flag to indicate a custom BG tilemap is being used. (neither V nor D indicates object tilemap)
    ;   F    = flag to indicate the usage of the high nibble, when using a tilemap
    ;   BB   = When F bit is set: Map16 bank to use
    ;   bbBB = When F bit is clear: High byte for all BG Map16 tiles (deprecated).
    ;   T    = Deprecated bit used to enable a feature that would allow the ExGFX file defined for the LT3 slot
    ;           to be loaded as a Layer 2 background (effectively, turning it into an "LT2" slot).
    ;           As of v3.31, this feature is no longer supported and should not be used.

;=======================================================================

org $05803B
    JML GetLayer2TilemapSettings

org $058DA4
    JSL GetBGMap16Page
    NOP

;=======================================================================

org $0EF510
GetLayer2TilemapSettings:   ; A = $6A (bank byte of Layer 2 data)
    SEC
    SBC #$7F
    BNE .getSettings        ; if the bank byte is $7F (RAM), continue below. else, branch
    STA !RAM_LT2Settings    ;  (this seems to be a deprecated feature relating to loading a Layer 2 tilemap through an ExGFX slot)
    JML $05803F

  .getSettings:     ; tilemap is not in RAM
    LDX $0E
    LDA.l Layer2TilemapSettings,x
    STA !RAM_LT2Settings
    BIT #%00001010  ; if either bit 1 or 3 set, treat BG as a tilemap background
    BNE .tilemap
  .object:          ;= object Layer 2
    JML $058074     ; return to load object data

  .tilemap:         ;= tilemap Layer 2
    BIT #%00000100  ; if bit 2 is set...
    BNE .noForceHighByte
    LSR #4          ; ...set high byte of all tiles to the setting's high nibble
    LDX #$01FF
  - STA $7EBD00,x
    STA $7EBF00,x
    DEX
    BPL -
  .noForceHighByte:
    JML $058064     ; return to load tilemap
    
    db $FF,$FF,$FF

  .version:
    db "LM" : dw $0103

;=======================================================================

org $0EFD00
GetBGMap16Page:     ; returns $0A = 24-bit pointer to the level's Map16 page
    PHP
    REP #$30
    LDX #$0000
    LDY #$01B0
    LDA !RAM_LT2Settings
    BIT #$0004
    BEQ .vanilla    ; if bit 2 (F bit) is clear, vanilla tilemap system is used
    AND #$00F0
    LSR #3
    STA $0A
    LSR
    CLC : ADC $0A
    TAX             ; X = high nibble of the layer 2 settings, x3
    LDY #$0200
  .vanilla:
    STY $05
    PHB
    PHK
    PLB
    LDA.w PagePointers,x   : STA $0A
    LDA.w PagePointers+1,x : STA $0B
    PLB
    PLP
    LDA $1928|!addr
    RTL

;=======================================================================

org $0EF310
Layer2TilemapSettings:
    for i = 0..$200 : db $08 : endfor

org $0EFD50
PagePointers:
    dl $000000      ; pages 80-8F (vanilla)
    dl $000000      ; pages 90-9F
    dl $000000      ; pages A0-AF
    dl $000000      ; pages B0-BF
    dl $000000      ; pages C0-CF
    dl $000000      ; pages D0-DF
    dl $000000      ; pages E0-EF
    dl $000000      ; pages F0-FF

  .unused:          ; Seem to be unused additional pointers for high nibbles 8-F
    dl $000000
    dl $000000
    dl $000000
    dl $000000
    dl $000000
    dl $000000
    dl $000000
    dl $000000