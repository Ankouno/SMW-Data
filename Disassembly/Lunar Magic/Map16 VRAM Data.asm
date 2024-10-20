; Routine added by Lunar Magic to calculate the pointer to a Map16 tile's VRAM data.
; Input:
;   A/X/Y in 16-bit
;   A = Map16 tile, x2
; Output:
;   Y/$0B = xx00 where xx is bank byte of Map16 data pointer
;   A     = lower 16-bits of Map16 data pointer (store to $0A to get the full 24-bit pointer)
;
; Summary of the routine's logic:
;  Vanilla (page 00-01):
;   Handled the original way, via a pointer table for every tile at $0FBE.
;   This data is indexed by the Map16 tiles times 2, and points to the data within bank $0D.
;    (on the overworld, it points within bank $05)
;  
;  Tileset-specific (page 02):
;   Enabled if $06F547 is non-zero (specifically if equal to $06).
;   Math to find a tile's data is a bit weird:
;    Start by getting a value of [0ttttbbb bbbbb000], where tttt = tileset, bbbbbbbb = low byte of tile number
;    Then add [(read1($06F58A)<<16|read2($06F586))+$1000].
;  
;  Custom map16 (page 03-7F):
;   Multiply tile number by 8. Depending on the page number, add the following:
;    02-0F: read1($06F557)<<16|(read2($06F553)+$1800&$FFFF)
;    10-1F: read1($06F560)<<16|(read2($06F55C)+$8000&$FFFF)
;    20-2F: read1($06F56B)<<16|read2($06F567)+1
;    30-3F: read1($06F574)<<16|(read2($06F570)+$8000&$FFFF)+1
;    40-4F: read1($06F598)<<16|read2($06F594)
;    50-5F: read1($06F5A1)<<16|(read2($06F59D)+$8000&$FFFF)
;    60-6F: read1($06F5AC)<<16|read2($06F5A8)+1
;    70-7F: read1($06F5B5)<<16|(read2($06F5B1)+$8000&$FFFF)+1
;  
;  Map16 data itself is basically direct VRAM data. Each 8x8 tile gets two bytes: tile number, yxpccctt.
;  Tiles are ordered top-left, bottom-left, top-right, bottom-right, so there are 8 bytes total per tile.

!enable_TilesetSpecificMap16    =   0

;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

org $058A65     ; horizontal Layer 1 (unused if Map16 VRAM optimization installed)
    JSL GetMap16VramPointer

org $058B45     ; vertical Layer 1 (except if Map16 VRAM optimization installed) + overworld load
    JSL GetMap16VramPointer

org $058C33     ; horizontal Layer 2 (unused if Map16 VRAM optimization installed)
    JSL GetMap16VramPointer

org $058D2A     ; vertical Layer 2 (unused if Map16 VRAM optimization installed)
    JSL GetMap16VramPointer

org $00C17A     ; map16 change, single tile
    JSL GetVramPointerForTileChange
    NOP

org $00C25C     ; map16 change, Yoshi coin
    JSL GetVramPointerForTileChange
    NOP

org $04DCFA     ; switching submaps on overworld
    JSL GetVramPointerForSubmapSwitch

; there are some additional calls to this routine in LM's other hijacks as well

;=======================================================================

org $06F540
GetMap16VramPointer:            ; A = tile number, x2
    CMP #$0400
    BCC .vanilla
    if !enable_TilesetSpecificMap16
        CMP #$0600
    else
        CMP #$0000
    endif
    BCC .page_2_tileset_specific
    ASL
    BCS .page_4X_to_7X
    ASL
    BCS .page_2X_to_3X
    BMI .page_1X
  .page_0X:
    ADC #$878C      ; Pointer for page 02-0F (+0 for carry, +1800).
    LDY #$1000
    STY $0B
    RTL

  .page_1X:
    ADC #$0000      ; Pointer for page 10-1F (+0 for carry, +8000).
    LDY #$1300
    STY $0B
    RTL

  .page_2X_to_3X:
    BMI .page_3X
  .page_2X:
    ADC #$7FFF      ; Pointer for page 20-2F (+1 for carry).
    LDY #$1400
    STY $0B
    RTL

  .page_3X:
    ADC #$7FFF      ; Pointer for page 30-3F (+1 for carry, +8000).
    LDY #$0000
    STY $0B
    RTL

  .page_2_tileset_specific: ; tile is on page 2 (tileset-specific). Deprecated, but LM inserts this even if not enabled.
    STA $0
    LDA $1930|!addr
    AND #$0F00
    ASL
    ADC $0B
    ASL #2
    ADC #$A810          ; Pointer to tileset-specific table (+0 for carry, +1800).
    LDY #$1400          ;  0x800 bytes per tileset, as needed.
    STY $0B
    RTL

  .page_4X_to_7X:       ; Tile on page 40-7F.
    ASL
    BCS .page_6X_to_7X
    BMI .page_5X
  .page_4X:
    ADC #$0000          ; Pointer for page 40-4F (+0 for carry).
    LDY #$0000
    STY $0B
    RTL

  .page_5X:
    ADC #$8000          ; Pointer for page 50-5F (+0 for carry, +8000).
    LDY #$0000
    STY $0B
    RTL

  .page_6X_to_7X:       ; Tile is on page 60-7F.
    BMI .page_7X
  .page_6X:
    ADC #$FFFF          ; Pointer for page 60-6F (+1 for carry).
    LDY #$0000
    STY $0B
    RTL

  .page_7X:
    ADC #$FFFF          ; Pointer for page 70-7F (+1 for carry, +8000).
    LDY #$1500
    STY $0B
    RTL



  .vanilla:             ; Tile is on page 0/1.
    TAY
    LDA $1930|!addr     ; Determine the bank the Map16 data is contained in.
    CMP #$1000          ; If the FG/BG tileset number is less than 10 (levels),
    BCC .gotVanillaPointer
  .overworld:
    LDA #$0500  ; overworld Map16: $05D000
    BRA .return
  .level:
    LDA #$0D00  ; level Map16: $0D8000
  .gotVanillaPointer:
    STA $0B
    LDA $0FBE|!addr,y
    RTL


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetVramPointerForTileChange:    ; $06F5D0: Alternative entry, storing pointer to $05 instead of $0B.
    REP #$20                    ;  Used by the tile generation routine at $00BEB0.
    TYA
    PEI ($0B)
    PHK
    PER (+)-1
    BRL GetMap16VramPointer
  + LDY $0B
    STY $05
    PLY
    STY $0B
    RTL

GetVramPointerForSubmapSwitch:  ; $06F5E4: Alternative entry, storing the pointer to $65 instead of $0B.
    ASL                         ;  Used by the overworld for Layer 1 when switching submaps.
    PHK
    PER (+)-1
    BRL GetMap16VramPointer
  + LDY $0B
    STY $66
    STA $65
    LDY #$0000
    RTL
    
    db $FF,$FF,$FF,$FF,$FF,$FF
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Version:
    db "LM" : dw $0110