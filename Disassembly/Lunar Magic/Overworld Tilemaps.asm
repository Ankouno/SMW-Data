; Code for LM's core modifications and changes to the overworld tilemaps and events.
;=======================================================================
!addr = $0000
!RAM_OWLevelNums = $7ED000
!RAM_OWLayer1L = $7EC800
!RAM_OWLayer1H = $7FC800
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
    !RAM_OWLevelNums = $40D000
    !RAM_OWLayer1L = $40C800
    !RAM_OWLayer1H = $41C800
endif
;======================================================================= 

!enable_OverworldExpansion  =   0
    ; flag for whether LM's overworld level expansion hijack is applied.

!LM_GetMap16Pointer = $06F540
    ; routine implemented by LM to get a pointer to a Map16 tile's VRAM data

!eventCount = select(!enable_OverworldExpansion, $FF, $78)
    ; number of events to allocate on the overworld.

;======================================================================= 

; add decompression for level number map and Layer 1 high bytes
org $04D7F9
    LDX.w #!RAM_OWLevelNums       : STX $00 ; $00 = 24-bit pointer to level number tilemap
    LDA.b #bank(!RAM_OWLevelNums) : STA $02
    LDX.w #LevelNumberMap         : STX $8A ; $8A = 24-bit pointer to level number source data
    LDA.b #bank(LevelNumberMap)   : STA $8C
    PHP
    PHK
    PER (+)-1
    PEA.w $01804D-1   ; (RTL)
    JML $00B8DE     ; LC_LZ2 decompression
  + PLP
    LDX.w #!RAM_OWLayer1H        : STX $00 ; $00 = 24-bit pointer to high byte of Layer 1 tilemap
    LDA.b #bank(!RAM_OWLayer1H)  : STA $02
    LDX.w #Layer1HighBytes       : STX $8A ; $8A = 24-bit pointer to high byte of Layer 1 source data
    LDA.b #bank(Layer1HighBytes) : STA $8C
    PHP
    PHK
    PER (+)-1
    PEA.w $01804D-1   ; (RTL)
    JML $00B8DE     ; LC_LZ2 decompression
  + PLP
    BRA +
org $04D84F : +

; loading activated events on save file load
org $04DCA5
    JSL LoadActivatedSilentEvents
    CMP #!eventCount

; loading silent Layer 2 event after beating a level
org $04E9F7
    autoclean JSL LoadSilentEvent
    NOP

; revealing Layer 1 tile
org $04EDDD
    autoclean JSL GetLayer1TileVramData

; destruction event - update code to use new tables, + GetMap16Vram function
org $04EEC3
    JSL GetVramDataForDestruction
    NOP
    autoclean LDA.l DestructionVramHeaders,x
org $04EEDC
    BMI NotCastle   ; update branch to skip over castle top handling when tile is not a castle
org $04EEE1
    NOP             ; TAY; no longer needed since pointer in $0A already has the specific Map16 tile
org $04EF27
    LDA $02         ; castle top: move to next row for bottom tile
    SEP #$20
    ADC #$10
    REP #$20
    BCC +
    ADC #$01FF
  + PHX
    TAX
    JSL GetLayer1TileVramData
    PLX
  NotCastle:    ; ($04EF3B)

; increase maximum number of events from 0x6E to 0x78 (0xFF with event expansion)
org $04D859
    db !eventCount

; update Layer 1 event tile pointers
org $04DA74 : autoclean dl Layer1EventPositions
org $04EC8C : dl Layer1EventPositions
org $04ECBA : dl Layer1EventPositions
org $04ECC5 : dl Layer1EventPositions
org $04ED97 : dl Layer1EventPositions
org $04EDBE : dl Layer1EventPositions

; update Layer 1 event VRAM header pointer
org $04EDB8 : autoclean dl Layer1EventVram

; update Layer 2 tilemap pointers
org $04DC79 : db bank(Layer2TilemapTiles)
org $04DC72 : dw Layer2TilemapTiles
org $04DC8D : dw Layer2TilemapProps ; needs to have same bank byte

; update Layer 2 event tilemap pointers
org $04DD4A : db bank(Layer2EventTilemapProps)
org $04DD45 : dw Layer2EventTilemapProps

org $04EAF5 : autoclean dl Layer2EventTilemapTiles
org $04E4B0 : db bank(Layer2EventTilemapTiles)
org $04E4BB : dw Layer2EventTilemapTiles

; update Layer 2 event data pointers
org $04E49F : autoclean dl Layer2Events
org $04E4A4 : dl Layer2Events+2
org $04E709 : dl Layer2Events
org $04E710 : dl Layer2Events+2
org $04EE5A : dl Layer2Events
org $04EE3F : dl Layer2Events+2

; if overworld expansion is enabled, move event dividers to freespace.
;  else, the original location is still used ($04E359)
org $04E471 : autoclean dl Layer2EventDividers
org $04E478 : dl Layer2EventDividers+2
org $04E6DE : dl Layer2EventDividers
org $04E6E5 : dl Layer2EventDividers+2

; update Layer 1 destruction event tables
org $04E67C : autoclean dl DestructionEvents
org $04E69C : autoclean dl DestructionPositions

;== misc fixes
; disable an unused feature from the original game when revealing tile 54
org $04DA98
    db $80

; fix y position of overworld bowser sprite
org $04F646
    dw $0000


;======================================================================= 

freecode
prot SilentEventDividers,SilentEventTiles,SilentEventTileTypes,SilentEventPositions

LoadSilentEvent:    ; load silent event data for a single event in A
    PHP
    REP #$30
    PHY
    AND #$00FF
    ASL
    TAX
    LDY #$0004
  - LDA SilentEventDividers,x
    STA $0002,y     ; $06 = start index, $04 = end index
    INX #2
    DEY #2
    BNE -
    SEC
    SBC $06
    BEQ .return
    TAY             ; Y = length
    LDX $06         ; X = starting index
  .eventLoop:
    LDA SilentEventTiles,x
    STA $00
    LDA SilentEventPositions,x
    STA $04
    PHX
    TXA
    LSR
    TAX
    SEP #$20
    LDA SilentEventTileTypes,x
    AND #$01
    BEQ .layer1
  .layer2:
    LDA $09,S
    CMP #$AB        ; skip tile if called from $04DAA9 (overworld reload, not from save file load)
    BEQ .nextTile
    PHY
    PHP
    LDY $00
    PHK
    PER (+)-1
    PEA.w $048414-1   ; (RTL)
    JML $04E4A9     ; load Layer 2 event tile into the tilemap
  + PLP
    PLY
    BRA .nextTile

  .layer1:
    LDX $04         ; write Layer 1 tile
    LDA $00 : STA !RAM_OWLayer1L,x
    LDA $01 : STA !RAM_OWLayer1H,x
  .nextTile:
    REP #$20
    PLX
    INX #2
    DEY #2
    BNE .eventLoop
  .return:
    PLY
    PLP
    RTL


LoadActivatedSilentEvents:  ; load silent event tiles on save file load
    LDA $0F
    AND #$07
    TAX
    LDA $0F
    LSR #3
    TAY
    LDA $1F02|!addr,y
    AND.l .bitTable,x
    BEQ .notBeaten
    LDA $0F
    JSL LoadSilentEvent
  .notBeaten:
    INC $0F
    LDA $0F
    RTL

  .bitTable:
    db $80,$40,$20,$10,$08,$04,$02,$01
    
  .version:
    db "LM" : dw $0101

;======================================================================= 

freecode
GetLayer1TileVramData:  ; gets a 24-bit pointer in $0A to the VRAM data for the tile at the position in X.
    SEP #$20
    LDA !RAM_OWLayer1H,x
    XBA
    LDA !RAM_OWLayer1L,x
    REP #$20
    ASL
    JSL !LM_GetMap16Pointer ; get pointer to tile's VRAM data
    STA $0A
    LDY #$0000
    RTL

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

GetVramDataForDestruction:
    AND #$00FF  ; A = $13D1 (index of destruction event)
    ASL
    TAX
    LDA DestructionPositions,x
    STA $02
    PHX
    TAX
    JSL GetLayer1TileVramData
    PLX
    RTL

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    
  .version:
    db "LM" : dw $0100

;======================================================================= 
; asar doesn't currently support autocleaning some of these blocks,
;  so it's going to warn you about freespace leaks. asar devs pls fix

freedata
Layer1HighBytes:        ; new table for the high bytes of Layer 1, compressed with LC_LZ2.
    db $E7,$FF,$00
    db $E7,$FF,$00
    db $FF

;===

freedata
Layer2TilemapTiles:     ; the base tilemap (tiles) for Layer 2, compressed with LC_LZ2. based on $04A533.
    db $FF
Layer2TilemapProps:     ; the base tilemap (YXPPCCCT) for Layer 2, compressed with LC_LZ2. based on $04C02B.
    db $FF

;===

freedata
LevelNumberMap:         ; translevel numbers + exit path directions for each tile, compressed with LC_LZ2. decompressed to $7ED000.
    db $FF

;===

freedata
Layer1EventPositions:   ; locations for the primary Layer 1 event tiles. based on $04D85D.
    for i = 0..!eventCount : dw $0000 : endfor

freedata
Layer1EventVram:        ; first two bytes of the VRAM header for the above tiles. based on $04D93D.
    for i = 0..!eventCount : db $00,$00 : endfor

;===

freedata
Layer2EventTilemapProps:    ; the event tilemap YXPPCCCT, compressed with LC_LZ2. based on $0C8D00.
    db $FF

freedata
Layer2EventTilemapTiles:    ; the event tilemap, uncompressed. based on $0C8000.
    for i = 0..0 : db $00 : endfor

freedata
Layer2Events:           ; the actual event data. based on $04DD8D.
    dw $0000,$0000      ; (source, dest)
    ;...

if !enable_OverworldExpansion
    freedata
else
    org $04E359
endif
Layer2EventDividers:    ; event dividers; (event) = base offset to event data. based on $04E359.
    for i = 0..!eventCount+1 : dw $0000 : endfor

;===

freedata
SilentEventDividers:    ; silent event dividers; (event) = base offset to event data. replacement system for $04E8E4
    for i = 0..79 : dw $0000 : endfor          ; (event+1) - (event) = number of tiles in event

freedata
SilentEventTiles:       ; silent event tiles. based on $04E994, but now using dividers.
    dw $0000 ;...

freedata
SilentEventTileTypes:   ; silent event tile type; 00 = layer 1, 01 = layer 2. based on $04E910, but now using dividers.
    db $00 ;...

freedata
SilentEventPositions:   ; 16-bit positions for the silent event tiles. based on $04E93C, but now using dividers.
    dw $0000 ;...

;===

freedata
DestructionEvents:         ; events that destroy a level tile. based on $04E5D6.
    for i = 0..24 : db $00 : endfor

freedata
DestructionPositions:      ; positions of the tiles for each event in the above table. based on $04E5B6.
    for i = 0..24 : dw $0000 : endfor

freedata
DestructionVramHeaders:    ; first two bytes of the VRAM header for each destruction in the above tables. based on $04E587.
    for i = 0..24 : db $00,$00 : endfor