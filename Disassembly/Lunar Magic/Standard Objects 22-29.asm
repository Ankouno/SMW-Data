; Patch to implement objects 22-29.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!RAM_OldObjBypassList   =   $FC
!RAM_OldSprBypassList   =   $FD
!RAM_OldAN2BypassFile   =   $FB
    ; 1 byte each: Deprecated addresses related to the old GFX list-based bypass system.
    ;  The first two contain the ID the GFX list to use, +1. 00 indicates the list is not bypassed.
    ;  The AN2 one just contains the file ID directly, +1.

!RAM_ExLevelHeight      =   $13D7|!addr
    ; 2 bytes, from ExLevel patch: height of the level, in pixels.

!RAM_DM16Flags          =   $7FC060
    ; 16 bytes; bitwise flags for each direct Map16 slot

!RAM_Unknown            =   $FA
    ; this one is unknown. set alongside the AN2 file.

;=======================================================================

org $0DE8FD
    dl Object22 ; direct map16 page 0
    dl Object23 ; direct map16 page 1
    dl Object24 ; deprecated FG/BG/SP graphics system
    dl Object25 ; deprecated AN2 graphics system
    dl Object26 ; music bypass
    dl Object27 ; direct map16 objects on pages 00-3F
    dl Object28 ; time limit bypass
    dl Object29 ; direct map16 objects on pages 40-7F
    
;=======================================================================

org $0DF08A
Object22:       ; Object 22: Direct Map16 on page 0
    LDA #$00
    BRA +
Object23:       ; Object 23: Direct Map16 on page 1
    LDA #$01
  + STA $01
    LDY #$00
WriteSingleMap16:   ; Subroutine used to write a single-tile direct Map16 object. 01 = high byte of tile number
    LDA [$65],y
    INY
    STA $00         ; $00 = low byte of tile number
    LDA $59
    AND #$0F
    STA $02         ; $02 = width
    LDA $59 
    LSR #4
    STA $03         ; $03 = height
  .multiScreen:     ; alternate entry for single-tile objects with an 8-bit width/height
    TYA
    CLC
    ADC $65
    STA $65         ; update object data pointer
    BCC +
    INC $66
  + JSR BackupMap16Pointers
    LDX $02
    LDY $57
  .tileLoop:
    LDA $01 : STA [$6E],y   ;\ write map16 tile
    LDA $00 : STA [$6B],y   ;/
    INY
    TYA
    AND #$0F
    BNE +
    JSR MoveRightOneScreen
  + DEX
    BPL .tileLoop
    JSR RestoreMap16Pointers
    JSR MoveToNextRow
    LDX $02
    DEC $03
    BPL .tileLoop
    RTS

;=======================================================================

org $0DF0E0
Object24:       ; Object 24: Deprecated FG/BG/SP graphics system
    LDA $57 : STA !RAM_OldSprBypassList
    LDA $59 : STA !RAM_OldObjBypassList
    RTS
    
org $0DF0F0
Object25:       ; Object 25: Deprecated AN2 graphics system
    LDA $57 : STA !RAM_Unknown
    LDA $59 : STA !RAM_OldAN2BypassFile
    RTS


org $0DF130
Object26:       ; Object 26: Music bypass
    LDA $57     ; for some reason the bypass is applied twice, no idea why
    BEQ .noBypass1
    DEC
    STA $0DDA|!addr
  .noBypass1:
    LDA $59
    BEQ .noBypass2
    DEC
    STA $0DDA|!addr
  .noBypass2:
    RTS

;=======================================================================

org $0DF150
Object27:       ; Object 27: Direct Map16 object on pages 00-3F
    LDY #$01
    LDA [$65]   ; check bits 6/7 of the fourth byte, branch if non-zero (not a single-tile Map16 object)
    BIT #$C0
    BNE WriteMultiMap16
    STA $01     ; else, it's the high byte of the map16 tile to be written
    JMP WriteSingleMap16

;=======================================================================

org $0DF160
Object28:       ; Object 28: time limit bypass
    LDA $59     ; force reset flag
    AND #$80
    BNE .forceResetTime
    LDA $141A|!addr     ; return if not first time entering level
    BNE .ret
  .forceResetTime:
    LDA $57     ; ones digit
    AND #$0F
    STA $0F33|!addr
    LDA $57     ; tens digit
    LSR #4
    STA $0F32|!addr
    LDA $59     ; hundreds digit
    AND #$0F
    STA $0F31|!addr
  .ret:
    RTS

;=======================================================================

org $0DF1C0
WriteMultiMap16:    ; routine for writing object 27 when using either multiple tiles, multi-screen, or conditional direct map16
    TAX
    AND #$3F
  .alt:             ; alternate entry for object 29; X = byte 4 of object, A = high byte of base map16 number
    XBA
    LDA [$65],y
    INY
    REP #$20
    STA $00     ; $00 = 16-bit base map16 number (top-left of selection)
    STA $04     ; $04 = 16-bit current map16 tile
    STA $06     ; $06 = 16-bit row base map16 number (left side of selection)
    SEP #$20
    LDA $59
    AND #$0F
    STA $02     ; $02 = width (4-bit)
    LDA $59
    LSR #4
    STA $03     ; $03 = height (4-bit)
    TXA
    BPL .multiTileNoRepeat
    ASL #2
    LDA [$65],y
    INY
    TAX
    BCC .multiTileObject    ; branch if not using a multi-screen height/width
    LDA [$65],y
    INY
    STA $03     ; $03 = height (8-bit)
    LDA $59
    AND #$7F
    STA $02     ; $02 = width (7-bit)
    LDA $59
    BPL .notConditional
    JSR ConditionalDM16
  .notConditional:
    TXA
    BNE .multiTileObject
    JMP WriteSingleMap16_multiScreen    ; if height/width of map16 selection is 0, just reuse the single map16 handler


  .multiTileNoRepeat:   ; object is multi-tile with no repeats (height/width of selection is also height/width of object)
    LDA $59
    TAX
  .multiTileObject:     ; object is multi-tile; X = height/width of map16 selection
    AND #$0F 
    STA $08 ; $08 = width of map16 selection
    STA $0A ; $0A = remaining width
    TXA
    LSR #4
    STA $09 ; $09 = height of map16 selection
    STA $5A ; $5A = remaining height
    TYA
    CLC
    ADC $65
    STA $65 ; update object data pointer
    BCC +
    INC $66
  + JSR BackupMap16Pointers
    LDX $02
    LDY $57
  .tileLoop:
    LDA $05 : STA [$6E],y   ; write map16 tile
    LDA $04 : STA [$6B],y
    DEX
    BMI .nextObjectRow
    INC
    DEC $0A
    BPL .noRepeatMap16Row
    LDA $08 ; reached end of map16 selection, loop back to left side
    STA $0A
    LDA $06
  .noRepeatMap16Row:
    STA $04
    INY
    TYA
    AND #$0F
    BNE .tileLoop
    JSR MoveRightOneScreen
    BRA .tileLoop

  .nextObjectRow:
    LDA $08     ; reset map16 selection width
    STA $0A
    DEC $5A
    BMI .repeatMap16Col
    REP #$21
    LDA $06     ; move to next map16 selection row
    ADC #$0010
  .haveNextRow:
    STA $04
    STA $06
    JSR RestoreMap16Pointers
    JSR MoveToNextRow
    LDX $02
    DEC $03
    BPL .tileLoop
    RTS

  .repeatMap16Col:  ; reached vertical end of map16 selection, loop back to top
    LDA $09
    STA $5A
    REP #$20
    LDA $00
    BRA .haveNextRow

Version1:

;=======================================================================

org $0DF290
ConditionalDM16:    ; subroutine to handle conditional direct Map16
    LDA [$65],y
    INY
    PHY
    PHX
    TAY
    AND #$07
    TAX
    TYA
    LSR #3
    AND #$0F
    PHA
    PHB : PHK : PLB
    LDA.w .bitTable,x
    PLB
    PLX
    AND $7FC060,x   ; check dm16 flag
    BNE .flagIsSet
    TYA
    BMI .return     ; flag is off; if using the add 0x100 flag, return to just draw the normal tile
    PLA             ;  else, continuing below to return the object early so it gets skipped entirely
    PLA
    CLC
    ADC $65
    STA $65         ; update object data pointer
    BCC +
    INC $66
  + PLA ; pull return pointer to terminate the object's code early
    PLA
    RTS

  .flagIsSet:
    TYA
    BPL .return
    INC $01 ; if set to do so, add 0x100 to the map16 tile
    INC $05
    INC $07
  .return:
    PLX
    PLY
    RTS

  .bitTable:
    db $01,$02,$04,$08,$10,$20,$40,$80

;=======================================================================

org $0DFEA0
BackupMap16Pointers:    ; preserves the Map16 pointer information in $0B-$0F
    REP #$20
    LDA $6B : STA $0C
    LDA $6E : STA $0E
    SEP #$20
    LDA $1BA1|!addr
    STA $0B
    RTS

RestoreMap16Pointers:   ; restores the Map16 pointer information from $0B-$0F
    REP #$20
    LDA $0C : STA $6B
    LDA $0E : STA $6E
    SEP #$20
    LDA $0B
    STA $1BA1|!addr
    RTS

org $0DFED0
MoveRightOneScreen: ; increments the map16 pointers to the screen on the right
    LDA $57
    AND #$F0
    TAY
    LDA $5B : LSR
    BCC .horz
  .vert:
    INC $6C     ; vertical levels just move to the next 0x100 byte block
    INC $6F
    RTS

  .horz:
    REP #$21    ; horizontal levels add the level height to its pointer
    LDA $6B
    ADC !RAM_ExLevelHeight
    STA $6B
    LDA $6E
    CLC : ADC !RAM_ExLevelHeight
    STA $6E
    SEP #$20
    INC $1BA1|!addr
    RTS


org $0DFF10
MoveToNextRow:      ; increments the map16 pointers to the next row (accounting for screen boundaries)
    LDA $57
    CLC : ADC #$10
    STA $57
    TAY
    BCS .nextScreen
    RTS

  .nextScreen:
    LDA $5B
    LSR
    BCC .horz
  .vert:
    INC $6C : INC $6C   ; vertical levels increment in blocks of 0x200
    INC $6F : INC $6F
    INC $1BA1|!addr
    JSR BackupMap16Pointers
    RTS

  .horz:
    INC $6C             ; horizontal levels increment in blocks of 0x100
    INC $6F
    JSR BackupMap16Pointers
    RTS

Version2:
    db "LM" : dw $0110

;=======================================================================

org $0DFF50
Object29:       ; Object 29: Direct Map16 object on pages 00-3F
    LDY #$01
    LDA [$65]   ; check bits 6/7 of the fourth byte, branch if non-zero (not a single-tile Map16 object)
    BIT #$C0
    BNE .notSingle
    ORA #$40    ; else, it's the high byte of the map16 tile to be written (+0x40)
    STA $01
    JMP WriteSingleMap16

  .notSingle:   ; using either multiple tiles, multi-screen, or conditional direct map16
    TAX
    AND #$3F
    ORA #$40
    JMP WriteMultiMap16_alt