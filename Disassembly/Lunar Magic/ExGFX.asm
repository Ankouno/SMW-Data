; Code used to retrieve a level/submap's ExGFX files and associated data.
; Also adds a JSL routine at $0FF900 to decompress ExGFX files (except GFX32 and GFX33):
;   Input:
;     A   = 16-bit ExGFX file to decompress
;     $00 = 24-bit pointer to destination
;   Output:
;     X/Y, processer flags preserved
;     A not preserved
;     High byte of A indicates if file was skipped with 007F (00 = skipped, 01 = not skipped).
;=======================================================================
!addr = $0000
!sa1 = 0
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
    !sa1 = 1
endif
;=======================================================================

!enable_SuperGfxBypass  =   1
    ; set when the Super GFX Bypass (or Layer 3 Bypass) has been enabled at least once

!enable_Layer3Bypass    =   1
    ; set when the Layer 3 Bypass has been enabled at least once
    
!enable_MergeOwSlots    =   0
    ; flag for the overworld's "merge FG1/FG2 into SP3/SP4" option being enabled


!RAM_ExGfxListPointer   =   $7FC006
    ; 3 bytes: 24-bit pointer to the level/submap ExGFX list

!RAM_BypassFlag         =   $7FC009
    ; 1 byte: indicates if ExGFX has been bypassed
    ;  0x00 = don't bypass graphics
    ;  0x41 = bypass enabled, with old GFX bypass
    ;  0x42 = bypass enabled, with Super ExGFX Bypass
    ;  0xFF = don't bypass graphics (No-Yoshi intro)

!RAM_LT2Settings        =   $7FC00B
    ; 1 byte, for the Layer 2 tilemap settings. From the table at $0EF310.

!RAM_L3SettingsA        =   $145E|!addr
    ; 2 bytes for various settings mainly related to Layer 3, from the ExGFX list.
    ;  Byte 0: Layer 3 initial Y position bits 0-4 and some additional flags: YYYYyOIB
    ;  Byte 1: Layer 3 scroll settings: vvvvhhhh

!RAM_L3SettingsB        =   $7FC01A
    ; 3 bytes for various settings mainly related to Layer 3, from the ExGFX list.
    ;  Byte 0: Layer 3 bypass settings: t---scxx
    ;  Byte 1: Layer 3 tides act-as setting: ----aaaa
    ;  Byte 2: Layer 3 initial Y position bits 5-10, scroll settings bit 4: HVYYyyyy
    ; These bytes are obtained from the level's ExGFX file IDs.
    ; See https://smwspeedruns.com/Level_Data_Format#ExGFX_Files for details.

!RAM_LevelNum           =   $FE
    ; 16-bit level number, +1. Set to 0000 for the No-Yoshi entrance.

!RAM_OldObjBypassList   =   $FC
!RAM_OldSprBypassList   =   $FD
!RAM_OldAN2BypassFile   =   $FB
    ; 1 byte each: Deprecated addresses related to the old GFX list-based bypass system.
    ;  The first two contain the ID the GFX list to use, +1. 00 indicates the list is not bypassed.
    ;  The AN2 one just contains the file ID directly, +1.

;=======================================================================

org $00AA06 ; set ExGFX files to always be reloaded, even if same ID
    NOP #2
org $00AA47
    NOP #2

org $00AA50 ; loading level ExGFX - add in handling for Layer 3 + AN2
    JSL UploadLayer3AndAN2
    RTS

org $00AA6B ; uploading ExGFX file to VRAM
    JSL GetDecompressedFile

org $0583B8 ; level load - set up ExGFX list pointer
    JSL GetLevelExGfxList
    NOP

org $00A140 ; overworld load - set up ExGFX list pointer
    JSL GetSubmapExGfxList

org $04DBB9 ; overworld load - switching submaps
    JSL UploadSubmapExGfx
    NOP #2

org $049DFD ; swapping between mario and luigi on overworld
    JSL SwapPlayers
    
org $009471 ; loading credits / castle cutscene
    JSL GetCreditsLayer3
    NOP

;=======================================================================

org $0FF15C
Version:
    db "LM" : dw $0103  ; not actually sure if this is the version for this routine or not

org $0FF160
GetDecompressedFile:    ; Y = ExGFX file number
    LDA $04,s
    CMP #$0A            ; from $00AA08 (sprite gfx): X = slot index (0-3) for file
    BEQ .sprGfx
    CMP #$4B            ; from $00AA49 (FG/BG gfx): X = slot index (0-3) for file
    BEQ .objGfx         ; otherwise from $00A9CE (nintendo presents)
  .notBypassed:
    TYA
    BRA .decompressFile

  .objGfx:
    LDA !RAM_BypassFlag
    CMP #$42
    BEQ .bypassEnabled
    LDA !RAM_OldObjBypassList
    BEQ .notBypassed
    CPX #$00            ; once done with the bypass list, clear the RAM for the list
    BNE .oldBypassEnabled
    STZ !RAM_OldObjBypassList
    BRA .oldBypassEnabled

  .bypassEnabled:
    CPX #$10                ; (high nibble of X is just used as a flag for checking if the below init has run)
    BCS .alreadyInitialized
    LDX #$17                ; initialize index for new ExGFX system (which uses 8 GFX slots instead of the original 4)
    STX $0F
  .alreadyInitialized:
    TXA : AND #$0F : TAX
    JSR CheckAndDecompressSlot
    LDA $0100|!addr
    CMP #$0C                ; overworld load
    BEQ .overworld
    LDA $0081E2             ;\ 
    CMP #$5C                ;| branch if Map16 VRAM optimization is applied
    BEQ .includeExtraSlots  ;/
  .overworld:
    CPX #$04                ; overworld stops at FG4 slot (and levels pre-optimization at FG3)
    BEQ .doneSlots
  .includeExtraSlots:
    CPX #$02                ; levels with optimization stop at BG3 slot
    BNE .stillMoreSlots
  .doneSlots:
    STZ $0F
  .stillMoreSlots:
    PHB : PHK : PLB
    LDA.w .objVramPointers,x    ; get VRAM pointer for the ExGFX file
    PLB
    STA $2117
    LDY #$FF                ; return Y = FF for the non-vanilla slots
    CPX #$04
    BCC .notVanillaSlot
    TXA : AND #$03 : TAX
    LDY $04,x               ; for the vanilla slots, return Y = the original GFX file number (for the special world handling of GFX01)
  .notVanillaSlot:
    STZ !RAM_OldObjBypassList
    RTL

  .sprBypassed:
    STZ !RAM_OldSprBypassList
    RTL

  .sprGfx:
    TXA
    CLC : ADC #$08      ; 8, 9, A, B (SP1-4)
    JSR CheckAndDecompressSlot  ; check if bypassed, and decompress if so
    BNE .sprBypassed
    LDA !RAM_OldSprBypassList
    BEQ .notBypassed
    CPX #$00
    BNE .oldBypassEnabled
    STZ !RAM_OldSprBypassList
  .oldBypassEnabled:
    JSR GetFileFromOldBypassList
  .decompressFile:  ; A = GFX file to get
    JSR DecompressFile
    RTL

  .objVramPointers: ; VRAM pointers (high byte) for each of the FG/BG ExGFX files
    db $38  ; 0 - LT2 (BG5?) - currently unused
    db $30  ; 1 - LT1 (BG4?) - currently unused
    db $28  ; 2 - BG3 (or FG6)
    db $20  ; 3 - BG2 (or FG5)
    db $18  ; 4 - FG3 (or FG4)
    db $10  ; 5 - BG1 (or FG3)
    db $08  ; 6 - FG2 (or FG2)
    db $00  ; 7 - FG1 (or FG1)


org $0FF780
UploadLayer3AndAN2:
    JSR ExtractExGfxSettingsAndUploadLT3
    JSR UploadLayer3Gfx
    LDA #$00 : JSR CheckAndDecompressSlot   ; check if AN2 is bypassed, and decompress if so
    BNE .bypassedAN2
    LDA !RAM_OldAN2BypassFile
    BEQ .noBypassAN2
    DEC
    JSR DecompressFile
  .bypassedAN2:
    STZ !RAM_OldAN2BypassFile
  .noBypassAN2:
    LDA #$00    ; clear flag to indicate graphics are done reloading
    STA !RAM_BypassFlag
  .restore:
    LDX #$03    ; restore overridden code
  - LDA $04,x
    STA $0105|!addr,x
    DEX
    BPL -
    RTL


org $0FF7D0
CheckLT2:                       ; deprecated feature to treat LT3 ExGFX file as an LT2 slot
    SEP #$30
    LDA !RAM_LT2Settings        ; enabled if bit 0 is set
    LSR
    BCC .ret
    LDA #$01 : JSR CheckAndDecompressSlot
  .ret:
    RTS


org $0FF7F0
GetLevelExGfxList:  ; A = level number
    PHP
    REP #$30
    LDA !RAM_LevelNum   ; if loading No-Yoshi entrance, return without loading ExGFX
    BEQ .skipGfx
    DEC
    ASL #5
    TAX
    autoclean LDA.l LevExGfxList,x  ; load AN2 byte
    PHA
    TXA
    CLC
    ADC.w #LevExGfxList       : STA !RAM_ExGfxListPointer   ; set pointer to the level's ExGFX list
    SEP #$20
    LDA.b #bank(LevExGfxList) : STA !RAM_ExGfxListPointer+2
    PLA : PLA
    ASL
    LDA #$41
    ADC #$00
    STA !RAM_BypassFlag ; = 0x41 or 0x42 depending on if Super GFX Bypass is enabled
    JSR CheckLT2
    BRA .return

  .skipGfx:
    SEP #$20
    LDA #$FF
    STA !RAM_BypassFlag
  .return:
    PLP
    LDA $1925|!addr
    CMP #$09
    RTL


org $0FF840
CheckAndDecompressSlot:     ; A = 8-bit index of slot in the ExGFX list (not x2). returns whether file was bypassed in zero flag
    PHA
    LDA !RAM_BypassFlag
    CMP #$42
    BEQ .bypassEnabled
    PLA
    LDA #$00
    RTS

  .bypassEnabled:
    PLA
DecompressSlot:             ; A = 8-bit index of slot in the ExGFX list (not x2)
    PHX
    PHY
    PHP
    ASL
    TAY
    REP #$30
    LDA !RAM_ExGfxListPointer   : STA $8A
    LDA !RAM_ExGfxListPointer+1 : STA $8B
    LDA [$8A],y
    AND #$0FFF
    JSR DecompressAndCheckLT2
    PLP
    PLY
    PLX
    LDA #$01
    RTS

unused_0FF86F:  ; orphaned code...?
    ADC $8A
    TAX
    LDA !RAM_ExGfxListPointer,x


org $0FF8A0
GetFileFromOldBypassList:   ; Subroutine to get a GFX file from the old list-based GFX Bypass system
    PHX                     ;  Input: A = old graphics bypass list ID, X = which of the four slots to get
    PHP                     ;  Returns: A = ID of graphics file
    REP #$30
    AND #$00FF
    DEC
    ASL #2
    STA $8A
    TXA
    CLC : ADC $8A
    TAX
    LDA.l OldGfxLists,x
    PLP
    PLX
    RTS


DecompressFile:             ; decompresses GFX file in A to $7EAD00
    XBA
    STZ $00                 ;\ 
    LDA #$AD : STA $01      ;| = $7EAD00
    LDA #$7E : STA $02      ;/
    LDA #$00
    XBA
  .jsl:
    JSL DecompressExGfxFile
    RTS

DecompressAndCheckLT2:      ; A = 16-bit GFX file ID, Y = slot index
    STZ $00
    LDX #$7EAD : STX $01    ; = $7EAD00
    CPY #$0002              ; if not LT3 slot, branch to decompress as normal
    BNE DecompressFile_jsl
    TAX
    LDA !RAM_LT2Settings    ; if set to use as an "LT2" file, decompress to $7F2000 instead (deprecated)
    LSR
    TXA
    BCC DecompressFile_jsl
    LDX #$7F20 : STX $01    ; = $7F2000
    BRA DecompressFile_jsl


org $0FF900
DecompressExGfxFile:    ; Routine to decompress a GFX file to a specified location in RAM.
    PHX
    PHY
    PHP
    REP #$30
    CMP #$0100
    BCS .getExGfx2
    CMP #$0080
    BCS .getExGfx1
    CMP #$007F
    BEQ .skipGfx
  .getVanillaGfx:   ; GFX 00-31
    TAX
    SEP #$30
    LDA.l $00B992,x : STA $8A
    LDA.l $00B9C4,x : STA $8B
    LDA.l $00B9F6,x : STA $8C
    BRA .gotPointer

  .getExGfx2:       ; ExGFX 100-FFF
    SEC
    SBC #$0100
    STA $8A
    ASL
    CLC
    ADC $8A ; x3
    TAX
    autoclean LDA.l ExGfxPointersB,x   : STA $8A
              LDA.l ExGfxPointersB+1,x : STA $8B
    BRA .gotPointer

  .getExGfx1:       ; ExGFX 80-FF
    AND #$007F
    STA $8A
    ASL
    CLC
    ADC $8A ; x3
    TAX
    LDA.l ExGfxPointersA,x   : STA $8A
    LDA.l ExGfxPointersA+1,x : STA $8B
  .gotPointer:
    SEP #$30
    PHK
    PER (+)-1
    PHB
    PHY
    JML $00BA47 ; decompress file
  + REP #$30
    LDA #$0100
  .skipGfx:
    PLP
    PLY
    PLX
    RTL


org $0FF9C0
GetCreditsLayer3:
    PHP
    JSR UploadLayer3Gfx_notOverworld
    PLP
    LDX $13C6|!addr
    LDA #$18
    RTL


org $0FF9E0
UploadLayer3Gfx:
    LDA $0100|!addr
    CMP #$12    ; loading level
    BEQ .notOverworld
    CMP #$0C    ; loading overworld
    BEQ .checkOverworldMerge
    CMP #$04    ; loading title screen
    BEQ .notOverworld
    RTS

  .checkOverworldMerge:
    if !enable_MergeOwSlots
        BNE .notOverworld   ; (effectively NOP #2)
    else
        BEQ .notOverworld   ; (effectively a BRA)
    endif
    LDA #$77
    STA $210B   ; update FG1/FG2 VRAM address
  .notOverworld:
    if !enable_SuperGfxBypass
        CLC
    else
        RTS
    endif
    LDA !RAM_BypassFlag
    TAX
    LDA !RAM_ExGfxListPointer              : PHA : STA $8A
    REP #$20 : LDA !RAM_ExGfxListPointer+1 : PHA : STA $8B
    CPX #$42
    BEQ .bypassEnabled
    CPX #$41
    BEQ .bypassEnabled
  .layer3BypassDisabled:
    LDA.w #VanillaL3Files-$18 : STA !RAM_ExGfxListPointer
    SEP #$20 : PHK : PLA      : STA !RAM_ExGfxListPointer+2
    BRA .gotExGfxListPointer

  .bypassEnabled:
    LDA [$8A]
    ASL
    BPL .layer3BypassDisabled
    SEP #$20
  .gotExGfxListPointer:
    LDX #$03
  .loop:
    TXA
    CLC : ADC #$0C  ; C, D, E, F (LG1-4)
    JSR DecompressSlot
    XBA
    BEQ .skipSlot   ; skip slot if file is 7F
    REP #$20
    PHX
    TXA : ASL : TAX
    PHB : PHK : PLB
    LDA.w L3VramPointers,x
    PLB
    STA $2116
    LDA #$AD00 : STA $4322 ; -source = $7EAD00
    LDA #$0800 : STA $4325 ; -size = 0x800 bytes
    LDX #$80   : STX $2115
    LDA #$1801 : STA $4320 ; -control = write 2 bytes to $2118 (VRAM)
    LDX #$7E   : STX $4324
    LDX #$04   : STX $420B
    SEP #$20
    PLX
  .skipSlot:
    DEX
    BPL .loop
    REP #$20
    PLA : STA !RAM_ExGfxListPointer+1
    SEP #$20
    PLA : STA !RAM_ExGfxListPointer
    RTS

L3VramPointers: ; VRAM addresses for each Layer 3 ExGFX file, reverse order
    dw $4C00,$4800,$4400,$4000

VanillaL3Files: ; default GFX files used for the original game's Layer 3
    dw $002B,$002A,$0029,$0028


org $0FFAB0
GetSubmapExGfxList:
    STA $20 ; restore code
    TXA
    ASL #4
    CLC : ADC.w #OwExGfxList
    STA !RAM_ExGfxListPointer   ; set pointer to the submap's ExGFX list
    SEP #$20
    LDA.b #bank(OwExGfxList)
    STA !RAM_ExGfxListPointer+2
    LDA #$42 : STA !RAM_BypassFlag
    LDA #$00 : STA !RAM_LT2Settings
    RTL


org $0FFAF0
SwapPlayers:    ; check whether the overworld need to be reloaded when swapping players
    LDA $1F11|!addr
    CMP $1F12|!addr
    BEQ .sameSubmap
    LDA #$0C    ; mario/luigi are on different submaps; reload overworld
    STA $0100|!addr
  .sameSubmap:
    JML $05DBF2 ; restore code


org $0FFB20
UploadSubmapExGfx:
    if !sa1
        TSC
        XBA
    else
        BRA .snes   ; don't need to swap off SA-1 core
    endif
    CMP #$30
    BCC .snes       ; alternative SA-1 detector? branches if stack pointer is less than 0x3000
    REP #$20        ; invoke SNES
    LDA.w #.snes
    STA $0183
    SEP #$20
    PHK : PLA
    STA $0185
    LDA #$D0
    STA $2209
  - LDA $018A
    BEQ -
    STZ $018A
    RTL

  .snes:
    STZ $0703|!addr
    STZ $0803|!addr
    LDX $0DB3|!addr
    LDY $1F11|!addr,x
    REP #$20
    TYA
    ASL #5
    CLC : ADC.w #OwExGfxList : STA !RAM_ExGfxListPointer
    SEP #$20
    LDA.b #bank(OwExGfxList)   : STA !RAM_ExGfxListPointer+2
    STZ $4200
    LDX #$09
    TXA
    CLC : ADC #$02
    JSR DecompressSlot  ; decompress SP1 file
    XBA
    BEQ .skipSP1        ; skip slot if file was 7F
    REP #$30
    TXA : ASL : TAX
    PHB : PHK : PLB
    LDA.w ExGfxVramPointers,x
    PLB
    TAX
    CLC
    ADC #$0160              ; VRAM offset for skipping over Mario's DMA area, row 2
    PHA
    TXA
    ADC #$0060              ; VRAM offset for skipping over Mario's DMA area, row 1
    TAX
    LDY #$ADC0              ; $7EADC0 (skip tiles 00-05)
    LDA #$0140              ; 0x140 bytes (tiles 06-0F)
    JSR UploadGfxData
    LDY #$AFC0 : STY $4322  ; $7EAFC0 (skip tiles 10-15)
    LDX #$0D40 : STX $4325  ; 0xD40 bytes (tiles 16-FF)
    PLX
    STX $2116
    STA $420B
    SEP #$10
  .skipSP1:
    LDX #$08    ; uploading all of the remaining FG/BG/SP GFX slots other than SP1
  .fileLoop:
    TXA
    CLC : ADC #$02
    JSR DecompressSlot
    XBA
    BEQ .skipSlot
    REP #$30
    PHX
    TXA : ASL : TAX
    PHB : PHK : PLB
    LDA.w ExGfxVramPointers,x
    PLB
    TAX
    LDY #$AD00  ; $7EAD00
    LDA #$1000  ; 0x1000 bytes
    JSR UploadGfxData
    PLX
    SEP #$10
  .skipSlot:
    DEX
    CPX #$01
    BNE .fileLoop
    if !enable_Layer3Bypass
        SEC
    else
        CLC
    endif
    BCC .uploadLayer3
    BRL .getAN2
    
  .uploadLayer3:
    LDA !RAM_ExGfxListPointer   : PHA : STA $8A
    REP #$20
    LDA !RAM_ExGfxListPointer+1 : PHA : STA $8B
    LDA [$8A]
    ASL
    BMI .bypassLayer3Enabled
    LDA #VanillaL3Files-$18 : STA !RAM_ExGfxListPointer
    SEP #$20 : PHK : PLA    : STA !RAM_ExGfxListPointer+2
  .bypassLayer3Enabled:
    LDY #$1C            ; LG2
    REP #$30
    LDX #$7EAD          ; $7EAD00
    JSR .decompressSlot
    LDY #$0018          ; LG4
    LDX #$7EB5          ; $7EB500
    JSR .decompressSlot
    PHB : PHK : PLB
    LDA.w L3VramPointers+4  ; VRAM address for LG2
    TAX
    LDA.w L3VramPointers+0  ; VRAM address for LG4
    PLB
    PHA
    LDY #$AD00          ; $7EAD00
    LDA #$0800          ; 0x800 bytes
    JSR UploadGfxData   ; upload LG2
    LDY #$0800          ; 0x800 bytes
    STY $4325
    PLX
    STX $2116
    STA $420B           ; upload LG4
    REP #$20
    LDY #$001E          ; LG1
    LDX #$7EAD          ; $7EAD00
    JSR .decompressSlot
    LDY #$001A          ; LG3
    LDX #$7EB5          ; $7EB500
    JSR .decompressSlot
    PHB : PHK : PLB
    LDA.w L3VramPointers+6  ; VRAM address for LG1
    TAX
    LDA.w L3VramPointers+2  ; VRAM address for LG3
    PLB
    PHA
    LDY #$AD00          ; $7EAD00
    LDA #$0800          ; 0x800 bytes
    JSR UploadGfxData   ; upload LG1
    LDY #$0800          ; 0x800 bytes
    STY $4325
    PLX
    STX $2116
    STA $420B           ; upload LG3
    REP #$20
    PLA : STA !RAM_ExGfxListPointer+1
    SEP #$30
    PLA : STA !RAM_ExGfxListPointer
  .getAN2
    LDA #$00 : JSR DecompressSlot   ; decompress AN2 file
    PHK
    PER (+)-1
    PEA.w $048413   ; (RTL)
    JML $048086     ; animate overworld water
  + PHK
    PER .uploadPalette-1
    PEA.w $048413   ; (RTL)
    JML $0480E0     ; handle other overworld tile animations
  .uploadPalette:
    REP #$30
    LDA #$0200  ; -size = 0x200 bytes
    LDY #$0703  ; -source = $7E0703 (palette data)
    STA $4325
    STY $4322
    LDA #$2200  ; -destination = $2122 (CGRAM)
    STA $4320
    SEP #$20
    STZ $4324
    LDA #$04
    JSR WaitForVblank   ; wait for next v-blank
    STZ $2121
    STA $420B   ; upload palette
    SEP #$30
    LDA #$81
  - BIT $4212   ; wait for v-blank to end
    BMI -
    STA $4200   ; enable NMI + auto-joypad read
    RTL

  .decompressSlot:  ; X = RAM address to decompress to, A = slot to decompress (x2)
    LDA !RAM_ExGfxListPointer   : STA $8A
    LDA !RAM_ExGfxListPointer+1 : STA $8B
    LDA [$8A],y
    AND #$0FFF
    STZ $00
    STX $01
    JSL DecompressExGfxFile
    RTS


UploadGfxData:  ; A = size, Y = source, X = VRAM destination; returns 8-bit A
    STA $4325
    STY $4322
    LDA #$1801
    STA $4320
    SEP #$20
    LDA #$7E
    STA $4324
    LDA #$04
    XBA
    LDA #$80
  - BIT $4212   ; wait for current V-blank to end
    BMI -
  - BIT $4212   ; wait for next V-blank to start
    BPL -
    STX $2116
    STA $2115   ; 2 byte increment
    XBA
    STA $420B
    RTS

WaitForVblank:  ; subroutine to wait until next v-blank
  - BIT $4212   ; wait for current v-blank to end
    BMI -
  - BIT $4212   ; wait for next v-blank to start
    BPL -
    RTS

ExGfxVramPointers:  ; VRAM pointers to each of the ExGFX files
    dw $2800    ; BG3
    dw $2000    ; BG2
    dw $1800    ; FG3
    dw $1000    ; BG1
    dw $0800    ; FG2
    dw $0000    ; FG1
    dw $7800    ; SP4
    dw $7000    ; SP3
    dw $6800    ; SP2
    dw $6000    ; SP1


org $0FFD80
ExtractExGfxSettingsAndUploadLT3:   ; routine to extract settings from the high nibble of the ExGFX file slots, as well as upload LT3
    LDA !RAM_BypassFlag
    CMP #$42
    BEQ .getSettings
    CMP #$41
    BEQ .getSettings
    REP #$20
    STZ !RAM_L3SettingsA
    LDA #$0000
    STA !RAM_L3SettingsB
    STA !RAM_L3SettingsB+1
    SEP #$20
    RTS

  .getSettings:
    PHY
    LDA !RAM_ExGfxListPointer   : STA $8A
    REP #$20
    LDA !RAM_ExGfxListPointer+1 : STA $8B
    SEP #$20
    LDY #$17
    LDA [$8A],y                 ; get SP1 slot: ----SCXX
    LSR #4
    STA !RAM_L3SettingsB
    DEY #2
    JSR ExtractTwoExGfxSettings ; get SP2/SP3 slots: HVYYyyyy
    STA !RAM_L3SettingsB+2
    LDY #$07
    JSR ExtractTwoExGfxSettings ; get BG2/BG3 slots: ----AAAA
    STA !RAM_L3SettingsB+1
    LDY #$1F
    JSR ExtractTwoExGfxSettings ; get LG2/LG1 slots: vvvvhhhh
    XBA
    DEY #2
    JSR ExtractTwoExGfxSettings ; get LG4/LG3 slots: YYYYyOIB
    LDY #$02
    REP #$30
    STA !RAM_L3SettingsA        ; = vvvvhhhh YYYYyOIB
    LDA [$8A]                   ; get AN2 slot: G3T?----
    ASL #2
    BMI .layer3TilemapBypassEnabled
    SEP #$30
    PLY
    RTS

  .layer3TilemapBypassEnabled:
    LDA [$8A],y     ; get LT3 slot
    TAX
    AND #$0FFF
    CMP #$007F      ; skip file
    BEQ .doneLT3
    TXA             ; extra data handling, from LT3 slot: DDFF----
    XBA
    LSR #3
    TAX
    AND #$0006      ; get FF bits (size), x2
    TAY
    TXA
    LSR #2
    AND #$0006      ; get DD bits (destination), x2
    TAX
    PHB : PHK : PLB
    LDA.w LT3DestinationOffsets,x
    STA $00
    LDA.w LT3Sizes,y
    LDY.w LT3DestinationVram,x
    LDX.w L3VramPointers+6  ; = 0x4000 (LG1), used to preserve status bar tilemap
    PLB
    CMP #$1001
    BCC .under4kb       ; only the 0x2000 size continues below
    SBC $00
    PHX
    PHY
    PHA
    PEI ($00)
    LDA #$1000          ; -size = 0x1000
    LDY #$BD00          ; -source = $7EBD00 (the original LT3 tilemap, i.e. status bar)
    JSR UploadLT3       ; preserve original status bar tilemap in VRAM
    SEP #$30
    LDA #$01 : JSR DecompressSlot   ; decompress LT3 file
    REP #$31
    PLA
    ADC #$AD00          ; -source = $7EAD00 + offset
    TAY
    PLA                 ; -size = the tilemap's size - offset
    PLX                 ; -dest = the vram destination for the specified offset
    JSR UploadLT3       ; upload the Layer 3 tilemap
    REP #$30
    LDA #$1000          ; -size = 0x1000
    STA $4325
    PLA
    STA $2116           ; -source = VRAM 0x4000 (the status bar tilemap preserved earlier)
    LDA $2139           ; (dummy read)
    LDA #$3981          ; -control = read from VRAM -> WRAM
    LDY #$BD00          ; -destination = $7EBD00
    JSR RetrieveLT3     ; store the status bar tilemap back into RAM (original game's code will actually upload it to VRAM later)
    BRA .doneLT3

  .under4kb:
    SEC
    SBC $00
    PHY
    PHA
    PEI ($00)
    SEP #$30
    LDA #$01 : JSR DecompressSlot   ; decompress LT3 file
    REP #$31
    PLA
    ADC #$AD00          ; -source = $7EAD00 + offset
    TAY
    PLA                 ; -size = the tilemap's size - offset
    PLX                 ; -dest = the vram destination for the specified offset
    JSR UploadLT3       ; upload the whole tilemap
  .doneLT3:
    SEP #$30
    LDA !RAM_L3SettingsB    ; set flag to indicate LT3 tilemap in use
    ORA #$80
    STA !RAM_L3SettingsB
    PLY
    RTS


ExtractTwoExGfxSettings:    ; extracts the high nibble of two consecutive ExGFX slots (b, a) and returns result in A (%bbbbaaaa)
    LDA [$8A],y
    AND #$F0
    STA $00
    DEY #2
    LDA [$8A],y
    LSR #4
    ORA $00
    RTS


UploadLT3:      ; Subroutine to upload an LT3 file to VRAM
    STA $4325   ;  A = 16-bit size
    STX $2116   ;  X = 16-bit VRAM address
    LDA #$1801
RetrieveLT3:    ; Alternate entry used to retrieve LT3 data out of VRAM
    STA $4320   ;  A = 16-bit, control settings + PPU reg
    STY $4322   ;  Y = 16-bit source address
    SEP #$20
    LDA #$7E
    STA $4324
    LDA #$80
    STA $2115
    LDA #$04
    STA $420B
    RTS

LT3Sizes:
    dw $2000,$1000,$0800,$0000
LT3DestinationVram:
    dw $50A0,$5000,$5080,$5800
LT3DestinationOffsets:
    dw $0140,$0000,$0100,$0000

;=======================================================================

org $0FF200
; deprecated table from LM's old list-based graphics bypass system. Each row here is a set of 4 GFX files.
OldGfxLists:
    for i = 0..$FF : db $00,$00,$00,$00 : endfor

org $0FF600
; 24-bit pointers to ExGFX80-FF
ExGfxPointersA:
    for i = $80..$100   : dl $000000 : endfor

freedata
; 24-bit pointers to ExGFX100-FFF
ExGfxPointersB:
    for i = $100..$1000 : dl $000000 : endfor

;=======================================================================

freedata
; 16-bit IDs for each of the level's ExGFX files
LevExGfxList:
    for i = 0..$200
        dw $007F,$007F              ; AN2, LT3
        dw $007F,$007F              ; BG3, BG2
        dw $007F,$007F,$007F,$007F  ; FG3, BG1, FG2, FG1
        dw $007F,$007F,$007F,$007F  ; SP4, SP3, SP2, SP1
        dw $002B,$002A,$0029,$0028  ; LG4, LG3, LG2, LG1
    endfor
    ; Some of these files encode additional data.
    ;  See https://smwspeedruns.com/Level_Data_Format#ExGFX_Files

; 16-bit IDs for each of the submap's ExGFX files
OwExGfxList:
    for i = 0..7
        if !enable_MergeOwSlots
            dw $0014,$007F                          ; AN2, LT3
            dw $007F,$007F                          ; (unused?)
            dw $007F,$007F,$001E,$001D,$001C,$001D  ; FG6, FG5, FG4, FG3, FG2, FG1
            dw $000F,$0010                          ; SP2, SP1
            dw $002B,$002A,$0029,$0028              ; LG4, LG3, LG2, LG1
        else
            dw $0014,$007F              ; AN2, LT3
            dw $007F,$007F              ; (unused FG6, FG5)
            dw $001E,$001D,$001C,$001D  ; FG4, FG3, FG2, FG1
            dw $001D,$001C,$000F,$0010  ; SP4, SP3, SP2, SP1
            dw $002B,$002A,$0029,$0028  ; LG4, LG3, LG2, LG1
        endif
    endfor

; unknown extra GFX list, seems to be unused?
UnknownList:
    dw $007F,$007F
    dw $007F,$007F
    dw $007F,$007F,$007F,$007F
    dw $FFFF,$007F,$007F,$007F
    dw $002B,$002A,$0029,$0028