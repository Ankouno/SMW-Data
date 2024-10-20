; Implements code for scrolling Layer 3.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!RAM_L3SettingsA        =   $145E|!addr
    ; 1 byte, for various bypass settings. Format: yyyyyosb

!RAM_L3HScroll          =   !RAM_L3SettingsA+1  ; ($145F)
    ; 1 byte, for the Layer 3 horizontal scroll setting.
    ;  NOTE: LM initially crams both the horizontal and vertical scroll setting in this address, in the foramt vvvvhhhh.
    ;        The fifth bit of each comes from $7FC01C.
!RAM_L3SettingsB        =   $7FC01A
    ; 1 byte, for various bypass settings. Format: t---scxx
!RAM_L3ExtraBits        =   !RAM_L3SettingsB+2  ; ($7FC01C)
    ; 1 byte, for holding extra bits of the initial Y position and horizontal/vertical scroll settings.
    
!RAM_L3VScroll          =   $1460|!addr
    ; 1 byte, for the Layer 3 vertical scroll setting.

!RAM_L3_OffsetX         =   $146A|!addr
    ; 2 bytes, for the Layer 3 X position prior to applying horizontal scrolling.
!RAM_L3_OffsetY         =   $146C|!addr
    ; 2 bytes, for the Layer 3 Y position prior to applying vertical scrolling.

!RAM_L3_NextX           =   $1B78|!addr
    ; 2 bytes, for next frame's Layer 3 X position when using the scroll sync fix.
!RAM_L3_NextY           =   $1B7A|!addr
    ; 2 bytes, for next frame's Layer 3 X position when using the scroll sync fix.

!RAM_InteractiveL23Init =   $0BE6|!addr
    ; 2 bytes. Seems to be used as first-time flags for Layer 2/3 interaction:
    ;  h------- vi------
    ;   h = when using an interactive Layer 2: first-time flag for horizontal L3 autoscroll
    ;   v = when using an interactive Layer 2: first-time flag for vertical L3 autoscroll
    ;   i = first-time flag for an interactive Layer 2 OR Layer 3
    ;  b bit is set on level load, h+v are set on level init if the level has an interactive Layer 2

;=======================================================================

org $00A01F ; INIT: layer 3 setup
    JSL L3Init
    BEQ +
org $00A044 : +

org $05C40C ; MAIN: layer 3 scroll routine
    JSL L3Main
    RTS

org $00A153 ; overworld border
    JSL HandleOverworldLT3

org $0194B6 ; interaction with tile outside of level
    JML HandleInteractionOutsideOfLevel
    RTS
   
;=======================================================================
freecode

L3Init:
    LDA !RAM_L3SettingsA    ; check if advanced bypass is enabled
    LSR
    BCS .advancedBypassEnabled
  .return:
    LDA !RAM_L3SettingsB    ; check if layer 3 tilemap bypassed
    BMI .tilemapBypassed
    LDA $1BE3|!addr   ; restore code
    DEC
    TAX
    INX
    RTL

  .tilemapBypassed:
    LDA #$00    ; treat as a non-tide Layer 3 image
    RTL

  .advancedBypassEnabled:
    LDA !RAM_L3SettingsB
    TAX
    AND #$04    ; check "CGADSUB for Layer 3 (translucent against subscreen)"
    BEQ .disableL3ColorMath
    TSB $40
    BRA .enabledL3ColorMath

  .disableL3ColorMath:
    LDA #$04
    TRB $40
  .enabledL3ColorMath:
    TXA
    AND #$08    ; check "move Layer 3 to subscreen"
    REP #$20
    BEQ .noMoveToSubscreen
    LDA $0D9D|!addr
    AND #$FFFB
    ORA #$0400
    STA $0D9D|!addr
    STA $212C
    STA $212E
  .noMoveToSubscreen:
    TXA
    AND #$0003              ; get initial Layer 3 X position
    XBA
    LSR #2
    CMP #$00C0
    BNE +
    LDA #$0100
  + STA !RAM_L3_OffsetX     ; store initial layer 3 X position
    LDA !RAM_L3ExtraBits-1  ; get extra bits for various settings, in the high byte: hvyyyyyy
    STA $01
    SEP #$20
    LDA !RAM_L3SettingsA    ; get initial Y position bits 0-5
    AND #$F8
    REP #$20                ; add in bits 6-10
    ASL #2
    CMP #$8000
    ROR
    STA !RAM_L3_OffsetY     ; got initial Y position
    LDY !RAM_L3HScroll
    TYA
    AND #$000F              ; get horizontal scroll setting bits 0-4
    BIT $01                 ; add in bit 5
    BPL +
    ORA #$0010
  + ASL                     ; multiply by 2
    TAX
    STX !RAM_L3HScroll      ; got the actual horizontal scroll setting
    LDA.l AutoscrollSpeeds,x
    PHA
    BEQ .initializeHScroll
    LDX #$00                ; initialize using "None" horizontal scrolling if autoscroll is active
  .initializeHScroll:
    JSR (Layer3HScrollPointers,x)   ; scale initial Layer 3 X position by the scroll setting
    TYA
    AND #$00F0              ; get vertical scroll setting bits 0-4
    BIT $01                 ; add in bit 5
    BVC +
    ORA #$0100
  + LSR #3                  ; shift so that the actual setting is only multiplied by 2
    TAX
    STX !RAM_L3VScroll      ; got the actual Layer 3 vertical scroll setting
    LDA.l AutoscrollSpeeds,x
    PHA
    BEQ .initializeVScroll
    TXA
    LDX $1403|!addr         ; initialize using "None" horizontal scroll if autoscrolling is active and tides are not
    BEQ .initializeVScroll
    TAX
  .initializeVScroll:
    JSR (Layer3VScrollPointers,x)   ; scale initial Layer 3 Y position by the scroll setting
    LDA !RAM_L3SettingsA            ; check scroll sync fix flag
    LSR #2
    BCC .noScrollSync
    LDA $22 : STA !RAM_L3_NextX     ; if sync enabled, initialize "next frame" Layer 3 position
    LDA $24 : STA !RAM_L3_NextY
  .noScrollSync:
    LDX $0100
    CPX #$1D        ; check if in the Yoshi's House portion of the credits
    BEQ .credits
    PLA
    BEQ .noAutoscrollHorz
    STA $145A|!addr
    BMI +
    LDA #$0000
  + TAX
    STX $145D
  .noAutoscrollHorz:
    PLA
    BEQ .noAutoscrollVert
    STA $1458|!addr
    BMI +
    LDA #$0000
  + TAX
    STX $145C|!addr
  .noAutoscrollVert:
    LDX $1403|!addr     ; return if using tides
    BNE .noInitRequired
    LDX $5B             ; return if Layer 2 collision is not enabled
    BPL .noInitRequired
    LDA $1413|!addr     ; return if not using any Layer 2 autoscroll
    AND #$F0F0
    BEQ .noInitRequired
    LDA #$8080          ; set first-time flags for layer 2 interaction with autoscrolling
    TSB !RAM_InteractiveL23Init
  .noInitRequired:
    LDX #$00            ; enable layer 3 autoscrolling
    BRA .toggleAutoscroll

  .credits:             ; in Yoshi's House during the credits
    PLA : PLA           ; clean up stack call
    LDX #$01            ; disable layer 3 autoscrolling
  .toggleAutoscroll:
    STX $13D5|!addr
    SEP #$20
    JMP .return

;=======================================================================

HScroll:
  .none
    LDA !RAM_L3_OffsetX
    STA $22
    RTS

  .constant:
    LDA !RAM_L3_OffsetX
    CLC
    ADC $1A
    STA $22
    RTS

  .medium:
    LDA $1A
  .halveScroll:
    LSR
    CLC
    ADC !RAM_L3_OffsetX
    STA $22
    RTS

  .medium2:
    LDA $1A
    LSR
    BRA .halveScroll

  .medium3:
    LDA $1A
    LSR #2
    BRA .halveScroll

  .medium4:
    LDA $1A
    LSR #3
    BRA .halveScroll

  .slow:
    LDA $1A
    LSR #4
    BRA .halveScroll

  .slow2:
    LDA $1A
    LSR #5
    BRA .halveScroll

  
HAutoFirstTime:
    LDA #$0080
    TRB !RAM_InteractiveL23Init ; clear first-time flag
    LDA #$0000
    BRA HScroll_auto_gotOffset

HScroll_auto:    ; autoscroll
    LDX $1403|!addr
    BNE AutoscrollTidesH
    LDX $9D
    BNE .return
    LDX $17BD|!addr
    TXA
    TAX
    BPL +
    ORA #$FF00
  + STA $04     ; $04 = horizontal distance Layer 1 has moved this frame
    LDX !RAM_InteractiveL23Init ; check if running horizontal autoscroll for the first time with an interactive L2
    BMI HAutoFirstTime
    LDX $145C|!addr
    TXA
    CLC
    ADC $1458|!addr
    TAX
    STX $145C|!addr
    AND #$FF00
    BPL +
    ORA #$00FF
  + XBA
  .gotOffset:
    CLC
    ADC $22
    CLC
    ADC $04
    STA $22
  .return:
    RTS


SingleScreenTides:
    STZ $26
    BRA GotTidesXOffset

AutoscrollTidesH:
    LDA $5B
    LSR
    BCS SingleScreenTides   ; safeguard so that Layer 3 interaction don't reach outside bounds of the level
    LDX $5E
    DEX
    BEQ SingleScreenTides
    LDA #$0080
    SEC
    SBC $1A
    STA $26
GotTidesXOffset:
    LDX $9D
    BNE .return
    LDX $17BD|!addr
    TXA
    TAX
    BPL +
    ORA #$FF00
  + STA $04
    LDX $145C|!addr
    TXA
    CLC
    ADC $1458|!addr ; add Layer 3 X speed to its position
    TAX
    STX $145C|!addr
    AND #$FF00
    BPL +
    ORA #$00FF
  + XBA
    CLC
    ADC $22
    CLC
    ADC $04         ; add the distance Layer 1 has moved this frame as wall
    STA $22
    TXA
    CLC
    ADC $1458|!addr
    XBA
    TAX
    STX $17BF|!addr ; track how much Layer 3 has moved horizontally this frame
  .return:
    RTS

;=======================================================================

VScroll:
  .none:
    LDA !RAM_L3_OffsetY
    STA $24
    RTS

  .medium:
    LDA $1C
  .halveScroll:
    LSR
    CLC
    ADC !RAM_L3_OffsetY
    STA $24
    RTS

  .medium2:
    LDA $1C
    LSR
    BRA .halveScroll

  .medium3:
    LDA $1C
    LSR #2
    BRA .halveScroll

  .medium4:
    LDA $1C
    LSR #3
    BRA .halveScroll

  .slow:
    LDA $1C
    LSR #4
    BRA .halveScroll

  .slow2:
    LDA $1C
    LSR #5
    BRA .halveScroll


VAutoFirstTime:
    LDA #$0080
    TRB !RAM_InteractiveL23Init+1 ; clear first-time flag
    LDA #$0000
    BRA VScroll_auto_gotOffset

VScroll_auto:   ; autoscroll
    LDX $1403|!addr
    BNE AutoscrollTidesV
    LDX $9D
    BNE .return
    LDX $17BC|!addr
    TXA
    TAX
    BPL +
    ORA #$FF00
  + STA $04     ; $04 = vertical distance Layer 1 has moved this frame
    LDX !RAM_InteractiveL23Init+1 ; check if running vertical autoscroll for the first time with an interactive L2
    BMI VAutoFirstTime
    LDX $145D|!addr ; add Y speed to Layer 3's Y position
    TXA
    CLC
    ADC $145A|!addr
    TAX
    STX $145D|!addr
    AND #$FF00
    BPL +
    ORA #$00FF
  + XBA
  .gotOffset:
    CLC
    ADC $24
    CLC
    ADC $04
    STA $24
  .return:
    RTS


VScroll_constant:       ; constant vscroll - also handles tides?
    LDX $1403|!addr     ; branch if tides
    BNE GetTidesYOffset
    LDA !RAM_L3_OffsetY
    CLC
    ADC $1C
    STA $24
    RTS
    
AutoscrollTidesV:
    BIT $190D|!addr     ; only run once (not twice) if sprites have Layer 3 interaction disabled
    BVS .calculateInteractionOffset
    JSR .calculateInteractionOffset
    PEI ($24)
    LDA !RAM_L3_OffsetY
    PHA
    LDX $145D|!addr
    PHX
    JSR .calculateInteractionOffset ; second call seems to be a sync fix for sprites,
    PLX                             ;  to calculate the Layer 3 offset an extra frame in advance?
    STX $145D|!addr
    PLA
    STA !RAM_L3_OffsetY
    PLA
    STA $24
    RTS
  
  .calculateInteractionOffset:
    LDX $9D
    BNE GetTidesYOffset
    LDX $145D|!addr ; add Y speed to Layer 3's base position
    TXA
    CLC
    ADC $145A|!addr
    TAX
    STX $145D|!addr
    AND #$FF00
    BPL +
    ORA #$00FF
  + XBA
    CLC
    ADC !RAM_L3_OffsetY
    STA !RAM_L3_OffsetY
GetTidesYOffset:    ; tides "loop" the Layer 3 tilemap at its top/bottom
    LDA !RAM_L3_OffsetY
    CLC
    ADC $1C
    BMI .topEdge    ; above layer 3 = use 0000
    CMP #$0118
    BCC .notAtEdge  ; within layer 3 = use current position
  .bottomEdge:      ; below layer 3 = use position at bottom of level
    STA $02
    AND #$000F      ; loop the bottom 16 pixels of Layer 3
    EOR #$0008
    CLC
    ADC #$0108
    STA $24
    LDA $5B         ; get height of level
    LSR
    LDA $13D7|!addr
    BCC +
    LDA $5E
    AND #$FF00
  + SEC
    SBC #$0100
    BMI .return     ; return if level is less than 2 screens tall, because the vanilla routine can handle that
    CMP #$0100
    BCC .return
    CMP $02         ; cap interaction offset at the current Y offset
    BCC .gotInteractionPosition
  .setPositionAtYOffset: ; (sets $28 = !RAM_L3_OffsetY)
    LDA $02
  .gotInteractionPosition:
    SEC
    SBC $1C
    STA $28
    RTS

  .notAtEdge:
    STA $24
    BRA .gotInteractionPosition

  .topEdge:         ; layer 3 is below the screen's position - fix Layer 3 position at 0000 (above tides)
    STZ $24
    STA $02
    LDA !RAM_L3SettingsA   ; branch if "make outside of level act like air instead of water" flag us set
    AND #$0004             ;  continue with updating the interaction offset
    BNE .setPositionAtYOffset
  .return:
    RTS


HScroll_fast:
    TSC
    CMP #$3000
    LDA $1A
    BCS .sa1
    LDX #$05
    STA $4204
    STX $4206
    XBA : XBA
    CLC
    ADC !RAM_L3_OffsetX
    ADC $4214
    STA $22
    RTS

  .sa1:
    LDX #$01
    STX $2250
    LDX #$05
    REP #$31
    STA $2251
    STX $2253
    ADC !RAM_L3_OffsetX
    ADC $2306
    STA $22
    SEP #$10
    RTS


VScroll_fast:
    TSC
    CMP #$3000
    LDA $1C
    BCS .sa1
    LDX #$05
    STA $4204
    STX $4206
    XBA
    XBA
    CLC
    ADC !RAM_L3_OffsetY
    ADC $4214
    STA $24
    RTS

  .sa1:
    LDX #$01
    STX $2250
    LDX #$05
    REP #$31
    STA $2251
    STX $2253
    ADC !RAM_L3_OffsetY
    ADC $2306
    STA $24
    SEP #$10
    RTS

;=======================================================================

Layer3HScrollPointers:
    dw HScroll_none         ; None (also used as init for autoscroll settings)
    dw HScroll_constant     ; Constant
    dw HScroll_medium       ; Medium
    dw HScroll_medium2      ; Medium 2
    dw HScroll_slow         ; Slow
    dw HScroll_fast         ; Fast
    dw HScroll_auto         ; Auto-Scroll Up/Left Slow
    dw HScroll_auto         ; Auto-Scroll Up/Left Medium
    dw HScroll_auto         ; Auto-Scroll Up/Left Fast
    dw HScroll_auto         ; Auto-Scroll Up/Left Fast 2
    dw HScroll_auto         ; Auto-Scroll Down/Right Slow
    dw HScroll_auto         ; Auto-Scroll Down/Right Medium
    dw HScroll_auto         ; Auto-Scroll Down/Right Fast
    dw HScroll_auto         ; Auto-Scroll Down/Right Fast 2
    dw HScroll_auto         ; Auto-Scroll Down/Right Fast 3
    dw HScroll_auto         ; Auto-Scroll Down/Right Fast 4
    dw HScroll_auto         ; Auto-Scroll Up/Left Fast 3
    dw HScroll_auto         ; Auto-Scroll Up/Left Fast 4
    dw HScroll_constant     ; (unused 1)
    dw HScroll_constant     ; (unused 2)
    dw HScroll_constant     ; (unused 3)
    dw HScroll_constant     ; (unused 4)
    dw HScroll_constant     ; (unused 5)
    dw HScroll_constant     ; (unused 6)
    dw HScroll_medium3      ; Medium 3
    dw HScroll_medium4      ; Medium 4
    dw HScroll_slow2        ; Slow 2
    dw HScroll_constant     ; (unused 7)
    dw HScroll_constant     ; (unused 8)
    dw HScroll_constant     ; (unused 9)
    dw HScroll_constant     ; (unused A)
    dw HScroll_constant     ; (unused B)

Layer3VScrollPointers:
    dw VScroll_none         ; None (also used as init for autoscroll settings if tides are not active)
    dw VScroll_constant     ; Constant
    dw VScroll_medium       ; Medium
    dw VScroll_medium2      ; Medium 2
    dw VScroll_slow         ; Slow
    dw VScroll_fast         ; Fast
    dw VScroll_auto         ; Auto-Scroll Up/Left Slow
    dw VScroll_auto         ; Auto-Scroll Up/Left Medium
    dw VScroll_auto         ; Auto-Scroll Up/Left Fast
    dw VScroll_auto         ; Auto-Scroll Up/Left Fast 2
    dw VScroll_auto         ; Auto-Scroll Down/Right Slow
    dw VScroll_auto         ; Auto-Scroll Down/Right Medium
    dw VScroll_auto         ; Auto-Scroll Down/Right Fast
    dw VScroll_auto         ; Auto-Scroll Down/Right Fast 2
    dw VScroll_auto         ; Auto-Scroll Down/Right Fast 3
    dw VScroll_auto         ; Auto-Scroll Down/Right Fast 4
    dw VScroll_auto         ; Auto-Scroll Up/Left Fast 3
    dw VScroll_auto         ; Auto-Scroll Up/Left Fast 4
    dw VScroll_constant     ; (unused 1)
    dw VScroll_constant     ; (unused 2)
    dw VScroll_constant     ; (unused 3)
    dw VScroll_constant     ; (unused 4)
    dw VScroll_constant     ; (unused 5)
    dw VScroll_constant     ; (unused 6)
    dw VScroll_medium3      ; Medium 3
    dw VScroll_medium4      ; Medium 4
    dw VScroll_slow2        ; Slow 2
    dw VScroll_constant     ; (unused 7)
    dw VScroll_constant     ; (unused 8)
    dw VScroll_constant     ; (unused 9)
    dw VScroll_constant     ; (unused A)
    dw VScroll_constant     ; (unused B)

AutoscrollSpeeds:
    dw $0000     ; None
    dw $0000     ; Constant
    dw $0000     ; Medium
    dw $0000     ; Medium 2
    dw $0000     ; Slow
    dw $0000     ; Fast
    dw $0040     ; Auto-Scroll Up/Left Slow
    dw $0080     ; Auto-Scroll Up/Left Medium
    dw $0100     ; Auto-Scroll Up/Left Fast
    dw $0200     ; Auto-Scroll Up/Left Fast 2
    dw $FFC0     ; Auto-Scroll Down/Right Slow
    dw $FF80     ; Auto-Scroll Down/Right Medium
    dw $FF00     ; Auto-Scroll Down/Right Fast
    dw $FE00     ; Auto-Scroll Down/Right Fast 2
    dw $FD00     ; Auto-Scroll Down/Right Fast 3
    dw $FC00     ; Auto-Scroll Down/Right Fast 4
    dw $0300     ; Auto-Scroll Up/Left Fast 3
    dw $0400     ; Auto-Scroll Up/Left Fast 4
    dw $0000     ; (unused 1)
    dw $0000     ; (unused 2)
    dw $0000     ; (unused 3)
    dw $0000     ; (unused 4)
    dw $0000     ; (unused 5)
    dw $0000     ; (unused 6)
    dw $0000     ; Medium 3
    dw $0000     ; Medium 4
    dw $0000     ; Slow 2
    dw $0000     ; (unused 7)
    dw $0000     ; (unused 8)
    dw $0000     ; (unused 9)
    dw $0000     ; (unused A)
    dw $0000     ; (unused B)

;=======================================================================

L3Main:
    LDA $1931|!addr         ; disable Layer 3 scrolling in Mode 7 rooms
    BMI .vanilla
    LDA !RAM_L3SettingsA    ; check if Layer 3 advanced bypass has been enabled
    LSR
    BCS .advancedBypassEnabled
  .vanilla:
    PLA         ; remove the return address from the JSL to this routine
    PLA
    PLA
    LDA $1403|!addr   ; restore code
    BEQ .noTides
    JML $05C494
  .noTides:
    JML $05C414

  .advancedBypassEnabled:
    LSR
    REP #$20
    LDX !RAM_L3HScroll
    BCS .fixSync    ; check flag for "enable Layer 3 scroll sync fix"
    BEQ .noHScroll
    JSR (Layer3HScrollPointers,x)
  .noHScroll:
    LDX !RAM_L3VScroll
    BEQ .noVScroll
    JSR (Layer3VScrollPointers,x)
  .noVScroll:
    SEP #$20
    RTL

  .fixSync:
    BEQ .noHScrollSync
    LDA !RAM_L3_NextX       ; update current X position with the next-frame X position
    STA $22
    PHA
    JSR (Layer3HScrollPointers,x)
    LDA $22
    STA !RAM_L3_NextX       ; update next-frame X position
    PLA
    STA $22
  .noHScrollSync:
    LDX !RAM_L3VScroll
    BEQ .noVScrollSync
    LDA !RAM_L3_NextY       ; update current Y position with the next-frame Y position
    STA $24
    PHA
    JSR (Layer3VScrollPointers,x)
    LDA $24
    STA !RAM_L3_NextY       ; update next-frame Y position
    PLA
    STA $24
  .noVScrollSync:
    SEP #$20
    RTL
    
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF

;=======================================================================

HandleOverworldLT3:     ; if using a custom Layer 3 on the overworld, skip loading the default OW border
    LDA !RAM_L3SettingsB
    BMI .tilemapBypassed
    LDA #$06    ; restore code - vanilla Layer 3
    STA $12
    RTL

  .tilemapBypassed:
    REP #$21
    PLA         ; shift return address to skip the LoadScrnImage call
    ADC #$0003
    PHA
    SEP #$20
    RTL

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF

;=======================================================================

HandleInteractionOutsideOfLevel:  ; get acts-like for tiles outside of the level
    STZ $1694|!addr
    LDA !RAM_L3SettingsA    ; check "make sprites beyond level boundaries interact with air instead of water" flag
    AND #$04
    BEQ .water
    LDA #$25
  .water:
    STA $1693|!addr
    LDA #$00
    JML $0194BA ; return

    db $20,$20,$20,$20,$20,$20,$20
;=======================================================================

Version:
    db "LM" : dw $0104