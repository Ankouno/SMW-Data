; Implements code for scrolling Layer 2.
;=======================================================================
!addr = $0000
!sa1 = 0
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
    !sa1 = 1
endif
;=======================================================================

!RAM_LevelHeight    =   $13D7|!addr
    ; 2 bytes, from ExLevel patch for holding the height of the level in pixels.

!RAM_HeaderByte8    =   $13CD|!addr
    ; 1 byte, for byte 8 of the secondary header ($06FE00).
    ;   Format: RL-ooooo
    ;    R = Main entrance FG/BG setting relative to player
    ;    L = Face main entrance left
    ;    ooooo = BG height (-1), or relative BG offset (centered at 0x10)

!RAM_L23I_Init      =   $0BE6|!addr
    ; 2 bytes. Seems to be used as first-time flags for Layer 2/3 interaction:
    ;  h------- vi------
    ;   h = when using an interactive Layer 2: first-time flag for horizontal L3 autoscroll
    ;   v = when using an interactive Layer 2: first-time flag for vertical L3 autoscroll
    ;   i = first-time flag for an interactive Layer 2 *OR* Layer 3
    ;  b bit is set on level load, h+v are set on level init if the level has an interactive Layer 2

!RAM_L23I_PrevX         =   $0BE8
!RAM_L23I_PrevY         =   $0BEA
    ; 2 bytes each. Copies of $26 and $28 (Layer 2/3 interaction offset) for the "previous" frame.
    ;  Used to help with syncing the movement of Layer 2/3 with their sprite interaction.

!RAM_L23I_PrevChange    =   $0BEC   ; $17BE/$17BF
    ; 2 bytes. Copy of $17BE/$17BF (distance Layer 2/3 moved) for the "previous" frame.
    ;  Used to help with syncing the movement of Layer 2/3 with their sprite interaction.

!RAM_UnknownB       =   $F9
    ; 1 byte. Unknown purpose.
    ; Set to either 40 or C0 depending on L bit of header byte 8.

;=======================================================================

org $009708 ; level load, primary level header
    JSL LoadPrimaryHeader
    
org $05DA17 ; level load, secondary level header
    JSL LoadSecondaryHeader
    NOP

org $00F871 ; account for the new screen sizes when stopping the screen at the bottom of the level.
    JML ScreenAtBottomOfLevel

org $00F77B ; vertical level, at edge of static scroll region?
    JML GetSomethingInVerticalLevels

org $00F79D ; general Layer 2 scrolling
    JML L2Main

org $05BCA5 ; scroll sprite MAIN
    JML HandleLayer2AutoscrollCollision
    
org $00E966 ; post mario interaction with layer 2, to fix a scroll sync issue with sprites
    JML SpriteSyncFix

;=======================================================================

freecode
LoadSecondaryHeader:
    SEP #$30
    REP #$11
    LDX $0E                 ; $0E = lavel number
    LDA $06FA00,x           ; (secondary header byte 6 - sHcvvvvv)
    BPL .notSeparateHVRates ; branch if not using separate Layer 2 horizontal/vertical scroll rates
    ADC #$40                ; carry flag = bit 5 of horizontal scroll setting
    AND #$1F
    STA $1414|!addr         ; set Layer 2 vertical scroll setting
    LDA $05F000,x           ; (secondary header byte 1 - hhhhyyyy)
    ROR
    LSR #3
    STA $1413               ; set Layer 2 horizontal scroll setting
  .notSeparateHVRates:
    SEP #$10
    REP #$20
    LDA #$8000              ; set flag for interactive layer 2/3 by default
    TSB $5A
    LSR
    STA !RAM_InteractiveL23Init ; set first-time flag for layer 2/3 interaction
    LDA $1413|!addr
    ASL
    TAX
    XBA
    TAY
    LDA.l AutoscrollSpeeds,x    ; get autoscroll X speed
    STA $144A|!addr
    STZ $1452|!addr
    BMI .autoscrollRight
    LDA #$0000
  .autoscrollRight:
    TAX
    STX $1443|!addr         ; track if horizontal scroll setting was "right slow" or "right medium"? all other values store 00 here
    TYX
    LDA.l AutoscrollSpeeds,x    ; get autoscroll Y speed
    STA $144C|!addr
    BMI .autoscrollDown
    LDA #$0000
  .autoscrollDown:
    TAX
    STX $1445|!addr         ; track if vertical scroll setting was "down slow" or "down medium"? all other values store 00 here
    LDA $5B
    LSR
    BCS .verticalLevel
  .horizontalLevel:
    LDA !RAM_LevelHeight
    SEC
    SBC #$00F0
    BIT $0BF4|!addr         ; if "show bottom row of level" flag is set, add an additional block
    BVC .noBottomRow
    CLC
    ADC #$000F
  .noBottomRow:
    STA $06                 ; $06 = Y position of bottom screen of level
    STZ $1E
    LDX !RAM_HeaderByte8    ; check if "set BG relative to FG only" flag is set
    BMI RelativeFGBG
  .return:
    LDA #$0000  ; clear high byte of A
    SEP #$30    ; restore code
    LDA $13BF|!addr
    RTL

  .verticalLevel:
    LDX $5F
    TXA
    DEC
    XBA
    BIT $0BF4|!addr     ; (vertical levels don't use the "show bottom row of level" flag)
    BRA .noBottomRow
    CLC
    ADC #$001F
    BRA .noBottomRow


RelativeFGBG:
    SEP #$30
    STZ $1412|!addr     ; temporarily disable vertical scrolling while the layer positions are adjusted
    STZ $1C             ; $1C = used to prevent a vertical scrolling issue when the camera is centered and Mario is on yoshi
    LDY $187A|!addr     ;       will be either 00 (no risk), 10 (at risk if not at bottom of level), or 20 (at risk)
    BEQ .noYoshiOffset  
    LDY #$04
    LDA [$65],y         ; (<- primary level header byte 5, to extract the vertical scroll setting bits)
    AND #$30
    CMP #$30
    BEQ .noYoshiOffset
    STA $1C
  .noYoshiOffset:
    LDA $02             ; = secondary header byte 3 (fg/bg offset)
    ASL #4
    BIT $04             ; = secondary header byte 7 (for bit 5 of fg/bg offset)
    REP #$21
    AND #$00F0
    BVC .notCentered    ; branch if fg/bg offset is positive (= mario above the screen)
    ORA #$FF00
    CMP #$FF90          ; = [FG= -70] = dead center on Mario
    CLC
    BEQ .centered
  .notCentered:
    STZ $1C
  .centered:
    BIT $0BF4           ; if "show bottom row of level" flag is set, subtract Y from offset
    BVC +               ; (this is due to SMW actually normally offsetting the screen's position upwards by a single pixel)
    DEC
  + ADC $96             ; we now have the Y position that the Layer 1 camera should be initialized to
    BMI .topOfScreen    ; if would be above the screen, store Y = 0
    LDY $1C
    BEQ .gotInitL1YPos  ; if not at risk of the center-of-screen-riding-Yoshi scroll issue, store Y position
    CPY #$20
    BNE .freeVScroll
    CMP $06
    BEQ .gotInitL1YPos  ; if at vscroll is set to lock at the bottom of the level and Mario is at the bottom of the level, store Y position
  .freeVScroll:
    SEC
    SBC #$0008          ; at risk of center-of-screen-riding-Yoshi issue, so offset the center of the screen up by half a tile to avoid it
    BPL .gotInitL1YPos
  .topOfScreen:
    LDA #$0000
  .gotInitL1YPos:
    STA $1C             ; finally got the initial Layer 1 Y position
    
    TXY                 ; = secondary header byte 8 (RL-ooooo) in horizontal levels, or $5F in vertical
    LDA $1414|!addr     ; = Layer 2 vertical scroll setting
    ASL
    TAX
    LDA $5B
    LSR
    TYA
    BIT $03             ; = secondary header byte 7 (to check the "BG relative to FG" flag)
    BMI RelativeLayer2
NonRelativeLayer2:      ;; Layer 2 is not set to be relative to the FG - calculate position using a given height.
    AND #$001F          ; A = BG height
    BCS .vertical       ; carry = flag for horizontal vs vertical level
  .horizontal:
    SEC
    SBC #$000E          ; subtract the height of the screen (15 tiles)
    BIT $0BF4|!addr     ; if bottom row enabled, add an additional tile
    BVC +
    INC
  + ASL #4
    STA $20             ; got the base Layer 2 Y position
    TXY
    BNE .vScrollHorzLayer2
    BRL LoadSecondaryHeader_return

  .vScrollHorzLayer2:   ; Layer 2 has a vertical scroll rate setting (in X), so we need to account for that as well
    LDA !RAM_LevelHeight                ; get position of screen at bottom of level
    SEC
    SBC #$00F0
    BIT $0BF4|!addr                     ; if bottom row enabled, add an additional tile
    BVC .gotBottomOfLevel
    CLC
    ADC #$0010
  .gotBottomOfLevel:
    JSR (CalculateScroll_Pointers,x)    ; get the distance Layer 2 will have moved when the screen is at the bottom of the level
    EOR #$FFFF
    SEC
    ADC $20                             ; subtract from the base Layer 2 position
    STA $1417|!addr                     ; got the position Layer 2 should have at the bottom of the level
    TYX
    LDA $1C
    JSR (CalculateScroll_Pointers,x)    ; get the position Layer 2 should be at if it was offset from the top of the level
    CLC
    ADC $1417|!addr                     ; add to the position from the bottom of the level
    STA $20                             ; got the final Layer 2 Y position
    BRL LoadSecondaryHeader_return

  .vertical:
    SBC #$000E          ; subtract the height of the screen (15 tiles) 
    BIT $0BF4|!addr     ; (vertical levels don't use the "show bottom row of level" flag)
    BRA +
    INC
  + ASL #4
    STA $20             ; got the base Layer 2 Y position
    TXY
    BNE .vScrollVertLayer2
    BRL LoadSecondaryHeader_return

  .vScrollVertLayer2:   ; Layer 2 has a vertical scroll rate setting (in X), so we need to account for that as well
    LDA $5E             ; get position of screen at bottom of level
    AND #$FF00
    SEC
    SBC #$0100
    BIT $0BF4|!addr     ; (vertical levels don't use the "show bottom row of level" flag)
    BRA .gotBottomOfLevel
    CLC
    ADC #$0020
    BRA .gotBottomOfLevel


RelativeLayer2:         ;; Layer 2 is set to be relative to the FG.
    ASL #4              ; A contains relative offset setting (00-1F)
    BIT #$0100
    BEQ .positive
    ORA #$FF00
    CMP #$FF00
    BNE .negative
    LDA #$0000
    BRA .zero

  .positive:            ; <- offset is +00 to +F0 (A = 0000-00F0)
    AND #$00F0
  .negative:            ; <- offset is -10 to -F0 (A = FF10-FFF0)
    CLC
    ADC $1C
  .zero:                ; <- don't apply offset (BG relative to 0, not FG)
    STA $20
    LDA $1C
    JSR (CalculateScroll_Pointers,x)    ; apply scroll rate to Layer 1's Y position
    EOR #$FFFF
    SEC
    ADC $20             ; subtract from Layer 2's base Y position
    STA $1417|!addr     ; store offset
    BRL LoadSecondaryHeader_return


FastVScrollSA1:
    PEA.w L2Main_offsetVScroll-1    ; push return address
    BRA CalculateFastScroll
  
FastHScrollSA1:
    PEA.w L2Main_gotHScroll-1       ; push return address
CalculateFastScroll:
    PHA
    TSC
    CMP #$3000
    PLA
    BCS .sa1
    LDX #$05    ; fast  = 1.2x rate
    STA $4204
    STX $4206
    XBA : XBA : CLC : CLC ; waste time
    SEP #$00
    ADC $4214
    RTS

  .sa1:
    LDX #$01
    STX $2250
    LDX #$05
    REP #$31
    STA $2251
    STX $2253
    SEP #$10
    ADC $2306
    RTS

FastHScrollSNES:
    LDX #$05
    STA $4204
    STX $4206
    XBA : XBA : CLC : CLC ; waste time
    SEP #$00
    ADC $4214
    JMP L2Main_gotHScroll

FastVScrollSNES:
    LDX #$05
    STA $4204
    STX $4206
    CLC : CLC ; waste time
    CLC
    ADC $1417|!addr
    CLC
    ADC $4214
    JMP L2Main_gotVScroll

CalculateScroll:
  .slow2:
    LSR
  .slow:
    LSR
  .medium4:
    LSR
  .medium3:
    LSR
  .medium2:
    LSR
  .medium:
    LSR
  .constant:
    RTS

  .Pointers:
    dw .constant            ; None
    dw .constant            ; Constant
    dw .medium              ; Medium
    dw .slow                ; Slow
    dw .medium2             ; Medium 2
    dw .medium3             ; Medium 3
    dw .medium4             ; Medium 4
    dw .slow2               ; Slow 2
    dw CalculateFastScroll  ; Fast
    dw .constant            ; (unused 1)
    dw .constant            ; (unused 2)
    dw .constant            ; (unused 3)
    dw .constant            ; (unused 4)
    dw .constant            ; (unused 5)
    dw .constant            ; (unused 6)
    dw .constant            ; (unused 7)
    dw .constant            ; Auto-Scroll Up/Left Slow
    dw .constant            ; Auto-Scroll Up/Left Medium
    dw .constant            ; Auto-Scroll Up/Left Fast
    dw .constant            ; Auto-Scroll Up/Left Fast 2
    dw .constant            ; Auto-Scroll Up/Left Fast 3
    dw .constant            ; Auto-Scroll Up/Left Fast 4
    dw .constant            ; Auto-Scroll Down/Right Slow
    dw .constant            ; Auto-Scroll Down/Right Medium
    dw .constant            ; Auto-Scroll Down/Right Fast
    dw .constant            ; Auto-Scroll Down/Right Fast 2
    dw .constant            ; Auto-Scroll Down/Right Fast 3
    dw .constant            ; Auto-Scroll Down/Right Fast 4
    dw .constant            ; (unused 8)
    dw .constant            ; (unused 9)
    dw .constant            ; (unused A)
    dw .constant            ; (unused B)

AutoscrollSpeeds:
    dw $0000 ; None
    dw $0000 ; Constant
    dw $0000 ; Medium
    dw $0000 ; Slow
    dw $0000 ; Medium 2
    dw $0000 ; Medium 3
    dw $0000 ; Medium 4
    dw $0000 ; Slow 2
    dw $0000 ; Fast
    dw $0000 ; (unused 1)
    dw $0000 ; (unused 2)
    dw $0000 ; (unused 3)
    dw $0000 ; (unused 4)
    dw $0000 ; (unused 5)
    dw $0000 ; (unused 6)
    dw $0000 ; (unused 7)
    dw $0040 ; Auto-Scroll Up/Left Slow
    dw $0080 ; Auto-Scroll Up/Left Medium
    dw $0100 ; Auto-Scroll Up/Left Fast
    dw $0200 ; Auto-Scroll Up/Left Fast 2
    dw $0300 ; Auto-Scroll Up/Left Fast 3
    dw $0400 ; Auto-Scroll Up/Left Fast 4
    dw $FFC0 ; Auto-Scroll Down/Right Slow
    dw $FF80 ; Auto-Scroll Down/Right Medium
    dw $FF00 ; Auto-Scroll Down/Right Fast
    dw $FE00 ; Auto-Scroll Down/Right Fast 2
    dw $FD00 ; Auto-Scroll Down/Right Fast 3
    dw $FC00 ; Auto-Scroll Down/Right Fast 4
    dw $0000 ; (unused 8)
    dw $0000 ; (unused 9)
    dw $0000 ; (unused A)
    dw $0000 ; (unused B)

    db $00,$00,$00,$00,$00,$00,$00,$00,$00

LoadSecondaryHeader_version:
    db "LM" : dw $0101

;=======================================================================
; not entirely sure what this code is doing

LoadPrimaryHeader:
    LDA [$65]   ; get number of screens in the level
    AND #$1F
    INC
    STA $5E
    LDA #$40    ; handle "face entrance left" flag.
    BIT !RAM_HeaderByte8
    STZ !RAM_HeaderByte8
    BVC .noFaceLeft
    STZ $76
    PHP
    LDA #$C0
    PLP
  .noFaceLeft:
    STA !RAM_UnknownB   ; = set 40 or C0 depending on if entrance faces left?
    BPL .nonRelativeFgBg
  .relativeFgBg:
    REP #$21
    LDA #$0080      ; reset the static scroll region of the screen for some reason?
    STA $142A|!addr
    PLA
    ADC #$0003
    PHA
    SEP #$20
  .return:
    RTL

  .nonRelativeFgBg:
    LDA $1414|!addr ; return if not using vertical Layer 2 autoscroll
    CMP #$10
    BCC .return
    REP #$20
    LDA $20         ; get offset of Layer 2 from Layer 1
    SBC $1C
    STA $1417|!addr
    BRA .relativeFgBg

    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00

  .version:
    db "LM" : dw $0103

;=======================================================================

ScreenAtBottomOfLevel:  ; Handle capping the screen's Y position at the bottom of the level.
    LDA $02             ;  Based on the existing code at $00F881, except accounting for the new screen sizes.
    SEC
    SBC #$FFFA
    EOR #$FFFA
    ASL
    LDA $02
    BCS +
    LDA #$FFFA
  + CLC
    ADC $1C
    CMP $04 ; $04 = Y position of screen at the bottom of the level
    BPL .notAtBottom
    LDA $04
  .notAtBottom:
    JML $00F89D

    db $00,$00

;=======================================================================

GetSomethingInVerticalLevels:   ; not sure what this is for?
    SEC
    SBC $142C|!addr,y
    BEQ L2Main              ; branch only if player is at the edge of static scroll region?
    JML $00F77F             ; return to normal routine

    db $00,$00

  .version:
    db "LM" : dw $0100

;=======================================================================

L2Main:     ; routine to update Layer 2's position based on the scroll settings
    LDA $1413|!addr
    ASL
    TAX     ; X = Layer 2 horizontal scroll setting (x2)
    XBA
    TAY     ; Y = Layer 2 vertical scroll setting (x2)
    LDA $1A
    JMP (.Layer2HScrollPointers,x)

  .hScroll:
  ..slow2:
    LSR
  ..slow:
    LSR
  ..medium4:
    LSR
  ..medium3:
    LSR
  ..medium2:
    LSR
  ..medium:
    LSR
  .gotHScroll:
    STA $1E
  .hScroll_none:
    TYX
    LDA $1C
    JMP (.Layer2VScrollPointers,x)

  .vScroll:
  ..slow2:
    LSR
  ..slow:
    LSR
  ..medium4:
    LSR
  ..medium3:
    LSR
  ..medium2:
    LSR
  ..medium:
    LSR
  ..constant:
    CLC
  .offsetVScroll:
    ADC $1417|!addr
  .gotVScroll:
    STA $20
  .vScroll_none:
    JML $00F7C2 ; return


  .offsetHScroll:
    ADC $1452|!addr
    BRA .gotHScroll

  .autoscrollHorz:
    LDX $5B
    BPL +
    LDX $1403|!addr ; if layer 2 has collision (tides), this math has already been done elsewhere
    BEQ .offsetHScroll
  + LDX $9D
    BNE .offsetHScroll
    LDX $1443|!addr ; update autoscroll X position using its X speed
    TXA
    CLC
    ADC $144A|!addr
    TAX
    STX $1443|!addr
    AND #$FF00
    BPL +
    ORA #$00FF
  + XBA
    CLC
    ADC $1452|!addr
    STA $1452|!addr
    CLC
    ADC $1A
    BRA .gotHScroll


  .autoscrollVert:
    LDX $5B
    BPL +
    LDX $1403|!addr ; if layer 2 has collision, this math has already been done
    BEQ .vScroll_constant
  + LDX $9D
    BNE .vScroll_constant
    LDX $1445|!addr ; update autoscroll Y position using its Y speed
    TXA
    CLC
    ADC $144C|!addr
    TAX
    STX $1445|!addr
    AND #$FF00
    BPL +
    ORA #$00FF
  + XBA
    CLC
    ADC $1417|!addr
    STA $1417|!addr
    CLC
    ADC $1C
    BRA .gotVScroll



  .Layer2HScrollPointers:
    dw .hScroll_none        ; None
    dw .gotHScroll          ; Constant
    dw .hScroll_medium      ; Medium
    dw .hScroll_slow        ; Slow
    dw .hScroll_medium2     ; Medium 2
    dw .hScroll_medium3     ; Medium 3
    dw .hScroll_medium4     ; Medium 4
    dw .hScroll_slow2       ; Slow 2
    if !sa1
      dw FastHScrollSA1     ; Fast
    else
      dw FastHScrollSNES    ; Fast
    endif
    dw .hScroll_none        ; (unused 1)
    dw .hScroll_none        ; (unused 2)
    dw .hScroll_none        ; (unused 3)
    dw .hScroll_none        ; (unused 4)
    dw .hScroll_none        ; (unused 5)
    dw .hScroll_none        ; (unused 6)
    dw .hScroll_none        ; (unused 7)
    dw .autoscrollHorz      ; Auto-Scroll Up/Left Slow
    dw .autoscrollHorz      ; Auto-Scroll Up/Left Medium
    dw .autoscrollHorz      ; Auto-Scroll Up/Left Fast
    dw .autoscrollHorz      ; Auto-Scroll Up/Left Fast 2
    dw .autoscrollHorz      ; Auto-Scroll Up/Left Fast 3
    dw .autoscrollHorz      ; Auto-Scroll Up/Left Fast 4
    dw .autoscrollHorz      ; Auto-Scroll Down/Right Slow
    dw .autoscrollHorz      ; Auto-Scroll Down/Right Medium
    dw .autoscrollHorz      ; Auto-Scroll Down/Right Fast
    dw .autoscrollHorz      ; Auto-Scroll Down/Right Fast 2
    dw .autoscrollHorz      ; Auto-Scroll Down/Right Fast 3
    dw .autoscrollHorz      ; Auto-Scroll Down/Right Fast 4
    dw .autoscrollHorz      ; (unused 8)
    dw .autoscrollHorz      ; (unused 9)
    dw .autoscrollHorz      ; (unused A)
    dw .autoscrollHorz      ; (unused B)


  .Layer2VScrollPointers:
    dw .vScroll_none        ; None
    dw .vScroll_constant    ; Constant
    dw .vScroll_medium      ; Medium
    dw .vScroll_slow        ; Slow
    dw .vScroll_medium2     ; Medium 2
    dw .vScroll_medium3     ; Medium 3
    dw .vScroll_medium4     ; Medium 4
    dw .vScroll_slow2       ; Slow 2
    if !sa1
      dw FastVScrollSA1     ; Fast
    else
      dw FastVScrollSNES    ; Fast
    endif
    dw .vScroll_none        ; (unused 1)
    dw .vScroll_none        ; (unused 2)
    dw .vScroll_none        ; (unused 3)
    dw .vScroll_none        ; (unused 4)
    dw .vScroll_none        ; (unused 5)
    dw .vScroll_none        ; (unused 6)
    dw .vScroll_none        ; (unused 7)
    dw .autoscrollVert      ; Auto-Scroll Up/Left Slow
    dw .autoscrollVert      ; Auto-Scroll Up/Left Medium
    dw .autoscrollVert      ; Auto-Scroll Up/Left Fast
    dw .autoscrollVert      ; Auto-Scroll Up/Left Fast 2
    dw .autoscrollVert      ; Auto-Scroll Up/Left Fast 3
    dw .autoscrollVert      ; Auto-Scroll Up/Left Fast 4
    dw .autoscrollVert      ; Auto-Scroll Down/Right Slow
    dw .autoscrollVert      ; Auto-Scroll Down/Right Medium
    dw .autoscrollVert      ; Auto-Scroll Down/Right Fast
    dw .autoscrollVert      ; Auto-Scroll Down/Right Fast 2
    dw .autoscrollVert      ; Auto-Scroll Down/Right Fast 3
    dw .autoscrollVert      ; Auto-Scroll Down/Right Fast 4
    dw .autoscrollVert      ; (unused 8)
    dw .autoscrollVert      ; (unused 9)
    dw .autoscrollVert      ; (unused A)
    dw .autoscrollVert      ; (unused B)

    db $00
    
  .version:
    db "LM" : dw $0101

;=======================================================================

HandleLayer2AutoscrollCollision:    ; handle moving Mario with Layer 2's autoscroll
    LDA $143F|!addr
    BNE .ScrollSpriteActive         ; if a scroll sprite is active, it gets priority
    LDA $1413|!addr
    CMP #$10
    BCS .checkHorizontalAutoscroll
    LDA $1414|!addr
    CMP #$10
    BCS .checkVerticalAutoscroll
  .return:
    JML $05BC49         ; no autoscroll active

  .ScrollSpriteActive:  ; restore code
    LDY $9D
    BNE .return
    LDX #$04
    STX $1456|!addr
    JML $05BCB4

  .checkHorizontalAutoscroll:
    LDA $5B
    BPL .return         ; return if no Layer 2 collision
    LDA $9D
    ORA $1403|!addr
    ORA $1493|!addr
    BNE .return         ; return if screen frozen, tides are active, or level is ending
  .Layer2HorizontalAutoscroll:
    REP #$21
    LDX $1443|!addr     ; update autoscroll X position using its X speed
    TXA
    ADC $144A|!addr
    TAX
    STX $1443|!addr
    AND #$FF00
    BPL +
    ORA #$00FF
  + XBA
    REP #$11
    TAX
    ADC $1452|!addr
    STA $1452|!addr
    TXA
    CLC
    ADC $1466|!addr
    STA $1466|!addr
    SEP #$30
    LDA $1414|!addr
    CMP #$10
    BCS .Layer2VerticalAutoscroll
    REP #$20
    BRA .addScreenShake

  .checkVerticalAutoscroll:
    LDA $5B
    BPL .return2        ; return if no Layer 2 collision
    LDA $9D
    ORA $1403|!addr
    ORA $1493|!addr
    BNE .return2        ; return if screen frozen, tides are active, or level is ending
  .Layer2VerticalAutoscroll:
    REP #$21
    LDX $1445|!addr     ; update autoscroll Y position using its Y speed
    TXA
    ADC $144C|!addr
    TAX
    STX $1445|!addr
    AND #$FF00
    BPL +
    ORA #$00FF
  + XBA
    REP #$11
    TAX
    ADC $1417|!addr
    STA $1417|!addr
    TXA
    CLC
    ADC $1468|!addr
    STA $1468|!addr
  .addScreenShake:
    LDA $20         ; account for screen shake in the Y position as well
    CLC
    ADC $1888|!addr
    STA $20
    SEP #$30
  .return2:
    JML $05BC49
    
    db $00,$00,$00
    
  .version:
    db "LM" : dw $0100

;=======================================================================

SpriteSyncFix:      ; Routine to fix a scroll sync issue with sprites
    REP #$30
    LDA $94         ; restore code (undo interaction offset)
    SEC : SBC $26
    STA $94
    LDA $96
    SEC : SBC $28
    STA $96
    LDX !RAM_L23I_PrevChange : LDA $17BE    ; swap in previous Layer 2/3 offset change for sprites
    STA !RAM_L23I_PrevChange : STX $17BE
    LDX !RAM_L23I_PrevX                     ; swap in previous Layer 2/3 offset for sprites
    LDY !RAM_L23I_PrevY
    LDA $26 : STA !RAM_L23I_PrevX
    LDA $28 : STA !RAM_L23I_PrevY
    BIT !RAM_InteractiveL23Init             ; if this is the first time running this routine in the level, 
    BVS .firstTime                          ;  previous X/Y have not been initialized so don't swap in
    STX $26
    STY $28
  .return:
    SEP #$30
    JML $00E978

  .firstTime:
    LDA #$4000
    TRB !RAM_InteractiveL23Init
    STZ $17BE
    BRA .return

    db $00,$00,$00,$00,$00,$00
    
  .version:
    db "LM" : dw $0110