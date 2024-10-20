; Code used to manage and upload ExAnimations on the overworld.
;=======================================================================
!addr = $0000
!sa1 = 0
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
    !sa1 = 1
endif
;=======================================================================

!LM_AltExGfxPointers    =   $03BCC0
    ; Four 24-bit pointers to ExGFX60-63.

;;; All of the below are required to be in bank $7F.

!RAM_SubmapExAniPtr     =   $7FC000
    ; 3 bytes; 24-bit pointer to submap's ExAnimation data. 000000 if none present.

!RAM_GlobalExAniPtr     =   $7FC016
    ; 3 bytes; 24-bit pointer to global ExAnimation data. 000000 if none present.

!RAM_SubmapExAniEnd     =   $7FC00C
!RAM_GlobalExAniEnd     =   $7FC00E
    ; 2 bytes each; indicates the ExAnimation slot to stop at.

!RAM_SubmapAltExGfxPtr   =   $7FC010
!RAM_GlobalAltExGfxPtr  =   !RAM_SubmapAltExGfxPtr+3 ; $7FC013
    ; 3 bytes each; 24-bit pointer to alternate ExGFX files for the submap.

!RAM_GlobalFrameMirror  =   $7FC003
    ; 1 byte; mirror of $14. Used to prevent ExAnimation updates if not actually a new frame.

!RAM_UpdatedVanillaTiles =   $7FC004
    ; 1 byte; used as a flag to indicate whether SMW's original overworld tiles have been updated,
    ;   and need to be re-uploaded to VRAM.

!RAM_AnimationSettings  =   $7FC00A
    ; 1 byte; animation settings for the current submap. Format: ptsg---- (0 = enable, 1 = disable)
    ;   p = SMW's palette animations
    ;   t = SMW's tile animations
    ;   s = Lunar Magic submap ExAnimations
    ;   g = Lunar Magic global ExAnimations
    ; Note: does not have a bit for the lightning animation checkbox. That is handled at $04F709.

!RAM_OneshotTriggers    =   $7FC0F8
    ; 4 bytes; bitwise flags for each oneshot ExAnimation trigger

!RAM_CustomTriggers     =   $7FC0FC
    ; 2 bytes; bitwise flags for each custom trigger.

!RAM_ManualFrames       =   $7FC070
    ; 16 bytes (one per manual trigger); frame numbers to show for each manual trigger.

!RAM_SlotFrames         =   $7FC080
    ; 64 bytes (one per slot); local frame counters for each ExAnimation slot.
    ; First half is for submap slots, second half is for global slots.

!RAM_UpdateData         =   $7FC0C0
    ; 56 bytes (eight 7-byte tables); container for data about ExAnimation slots updating this frame.
    ;  0 = 16-bit header, for animation type (highest bit) and size (remaining 15 bits).
    ;  2 = 16-bit VRAM destination. For GFX animations, highest bit indicates line (0) vs stacked (1).
    ;  4 = 24-bit source. For palette animations with only one color, the first two bytes here are the direct color.

!RAM_ExecSA1            =   $7FC020
    ; 14 bytes; RAM used exclusively on SA-1 to execute some code for ExAnimation.

;=======================================================================

org $048086     ; overworld load
    autoclean JSL OverworldExAnimationLoad
    RTS

org $00A4E3     ; uploading overworld animations
    JSL OverworldExAnimationNmi
    RTS

org $0480E0     ; updating animation data
    JSL OverworldExAnimationMain
    RTS

;=======================================================================

freecode
prot SubmapAnimationSettings,GlobalExAnimationData,SubmapExAnimationPointers
OverworldExAnimationLoad:   ; initializing ExAnimation during overworld load
    SEP #$30
    LDX $0DB3|!addr
    LDY $1F11|!addr,x
    PHB
    LDX #$7F
    PHX
    PLB
    LDA #$FF
    STA.w !RAM_GlobalFrameMirror
    STZ.w !RAM_UpdatedVanillaTiles
    STZ.w !RAM_AnimationSettings
    REP #$30
    STY $03
    STZ.w !RAM_OneshotTriggers ; clean up previous ExAnimation data
    STZ.w !RAM_OneshotTriggers+2
    STZ.w !RAM_UpdateData+(7*0)
    STZ.w !RAM_UpdateData+(7*1)
    STZ.w !RAM_UpdateData+(7*2)
    STZ.w !RAM_UpdateData+(7*3)
    STZ.w !RAM_UpdateData+(7*4)
    STZ.w !RAM_UpdateData+(7*5)
    STZ.w !RAM_UpdateData+(7*6)
    STZ.w !RAM_UpdateData+(7*7)
    LDA #$FFFF
    LDX #$003E
  - STA.w !RAM_SlotFrames,x
    DEX #2
    BPL -
    LDX $03 ; = submap ID
    LDA SubmapAnimationSettings,x
    AND #$00FF
    ORA.w !RAM_AnimationSettings
    STA.w !RAM_AnimationSettings
SetUpGlobalExAnimation:
    LDA.w #bank(GlobalExAnimationData)<<8 ; if 0000, no global ExAnimation data
    BEQ .disableGlobalExAnimation
    STA $01
    STA.w !RAM_GlobalExAniPtr+1
    LDA.w #GlobalExAnimationData
    STA $00
    LDY #$0002      ; initialize custom triggers
    LDA.w !RAM_CustomTriggers
    AND [$00],y
    INY #2
    ORA [$00],y
    STA.w !RAM_CustomTriggers
    INY #2          ; initialize manual triggers
    LDA [$00],y
    LDX #$0000
    INY #2
  .initManualLoop:
    LSR
    BCC .skipManualTrigger
    SEP #$20
    PHA
    LDA [$00],y
    STA.w !RAM_ManualFrames,x
    PLA
    REP #$20
    INY
  .skipManualTrigger:
    INX
    CPX #$0010
    BCC .initManualLoop
    TYA
    CLC
    ADC $00
    STA.w !RAM_GlobalExAniPtr   ; move pointer to the slot data
    LDA [$00]
    TAX
    AND #$00FF                  ; get number of ExAnimation slots used (0 = no slots)
    BEQ .disableGlobalExAnimation
    ASL
    STA.w !RAM_GlobalExAniEnd   ; store maximum index for ExAnimation data
    TXA
    XBA
    AND #$00FF
    STA $00
    ASL
    ADC $00
    TAX
    LDA.l !LM_AltExGfxPointers,x   : STA.w !RAM_GlobalAltExGfxPtr
    LDA.l !LM_AltExGfxPointers+1,x : STA.w !RAM_GlobalAltExGfxPtr+1
    BRA SetUpSubmapExAnimation

  .disableGlobalExAnimation:
    STZ.w !RAM_GlobalExAniPtr
    STZ.w !RAM_GlobalExAniPtr+1
    STZ.w !RAM_GlobalExAniEnd
    LDA #$0010
    TSB.w !RAM_AnimationSettings
SetUpSubmapExAnimation:
    LDA $03
    ASL
    ADC $03
    TAX
    LDA SubmapExAnimationPointers+1,x
    BEQ .disableSubmapExAnimation
    STA $01
    STA.w !RAM_SubmapExAniPtr+1
    LDA SubmapExAnimationPointers,x
    STA $00
    LDY #$0002      ; initialize custom triggers
    LDA.w !RAM_CustomTriggers
    AND [$00],y
    INY #2
    ORA [$00],y
    STA.w !RAM_CustomTriggers
    INY #2          ; initialize manual triggers
    LDA [$00],y
    LDX #$0000
    INY #2
  .initManualLoop:
    LSR
    BCC .skipManualTrigger
    SEP #$20
    PHA
    LDA [$00],y
    STA.w !RAM_ManualFrames,x
    PLA
    REP #$20
    INY
  .skipManualTrigger:
    INX
    CPX #$0010
    BCC .initManualLoop
    TYA
    CLC
    ADC $00
    STA.w !RAM_SubmapExAniPtr   ; move pointer to the slot data
    LDA [$00]
    TAX
    AND #$00FF                  ; get number of ExAnimation slots used (0 = no slots)
    BEQ .disableSubmapExAnimation
    ASL
    STA.w !RAM_SubmapExAniEnd   ; store maximum index for ExAnimation data
    TXA
    XBA
    AND #$00FF
    STA $00
    ASL
    ADC $00
    TAX
    LDA.l !LM_AltExGfxPointers,x   : STA.w !RAM_SubmapAltExGfxPtr
    LDA.l !LM_AltExGfxPointers+1,x : STA.w !RAM_SubmapAltExGfxPtr+1
    BRA SetUpVanillaAnimations

  .disableSubmapExAnimation:
    STZ.w !RAM_SubmapExAniPtr
    STZ.w !RAM_SubmapExAniPtr+1
    STZ.w !RAM_SubmapExAniEnd
    LDA #$0020
    TSB.w !RAM_AnimationSettings
SetUpVanillaAnimations:
    SEP #$30
    LDA.w !RAM_AnimationSettings
    PLB
    BIT #$40
    BNE .doneVanillaTileAnimation
    REP #$30
    STZ $03
    STZ $05
    PHK
    PER .doneVanillaTileAnimation-1
    PEA.w $048414-1     ; (RTL)
    JML $04808C         ; initialize vanilla water animation
  .doneVanillaTileAnimation:
    LDA.l !RAM_AnimationSettings
    PHA
    ORA #$C0            ; prevent vanilla animations from being initialized multiple times?
    STA.l !RAM_AnimationSettings
InitializeExAnimations:
    STZ $14
  .initLoop:               ; initialize first frame of each ExAnimation
    JSL OverworldExAnimationMain
    REP #$20
    LDA.l !RAM_UpdateData+(7*0) ; check if any slot for this frame is being used
    ORA.l !RAM_UpdateData+(7*1)
    ORA.l !RAM_UpdateData+(7*2)
    ORA.l !RAM_UpdateData+(7*3)
    ORA.l !RAM_UpdateData+(7*4)
    ORA.l !RAM_UpdateData+(7*5)
    ORA.l !RAM_UpdateData+(7*6)
    ORA.l !RAM_UpdateData+(7*7)
    SEP #$20
    BEQ .nextFrame
    LDA $0100
    CMP #$0C
    BEQ .overworldLoad
  .switchingPlayers:    ; (game mode 07)
  - BIT $4212           ; wait for next v-blank
    BMI -
  - BIT $4212
    BPL -
    LDA #$80            ; activate force blank
    STA $2100
    JSL OverworldExAnimationNmi
    LDA $0DAE|!addr
    STA $2100
    BRA .nextFrame

  .overworldLoad:
    JSL OverworldExAnimationNmi
  .nextFrame:
    INC $14
    LDA $14
    CMP #$08
    BCC .initLoop
    PLA
    STA.l !RAM_AnimationSettings
    RTL

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF

LoadVersion:
    db "LM" : dw $0101

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF

;=======================================================================

macro upload_exanimation(slot, ...)
    LDA.l !RAM_UpdateData+(7*<slot>)+0
    BEQ ?done
    BMI ?palette
  ?tile:
    TAY
    STA.b $4325
    LDA.l !RAM_UpdateData+(7*<slot>)+4 : STA.b $4322  ; source
    LDA.l !RAM_UpdateData+(7*<slot>)+5 : STA.b $4323
    LDA.l !RAM_UpdateData+(7*<slot>)+2 : STA $2116    ; destination
    STX $420B
    BPL ?done   ; branch if uploading strip of tiles (not 16x16)
    ADC #$0100  ; upload second half
    STA $2116
    STY.b $4325
    STX $420B
    BRA ?done

  ?palette:
    ASL
    STA.b $4325
    LDA.l !RAM_UpdateData+(7*<slot>)+4 : STA.b $4322
    LDA.l !RAM_UpdateData+(7*<slot>)+5 : STA.b $4323
    LDA.l !RAM_UpdateData+(7*<slot>)+2 : TAY : STY $2121
    LDA #$2200 : STA.b $4320
    STX $420B
    if sizeof(...) == 0
      CLC
      LDA #$1801 : STA.b $4320
    endif
  ?done:
endmacro

OverworldExAnimationNmi:    ; upload animations to VRAM/CGRAM
    PHD
    REP #$20
    LDA #$4300
    TCD
    LDX #$80
    STX $2115
    LDA #$1801
    STA.b $4320
    LDX #$04
    LDA.l !RAM_UpdatedVanillaTiles-1
    BPL .skipVanillaTileUpdate
    LDA #$0750  ; from $00A4EA
    STA $2116
    LDA #$0AF6
    STA.b $4322
    STZ.b $4324
    LDA #$0160
    STA.b $4325
    STX $420B
  .skipVanillaTileUpdate:
    CLC
    %upload_exanimation(4)
    %upload_exanimation(5)
    %upload_exanimation(6)
    %upload_exanimation(7)
    %upload_exanimation(0)
    %upload_exanimation(1)
    %upload_exanimation(2)
    %upload_exanimation(3, 0)
    PLD
    SEP #$30
    LDA.l !RAM_AnimationSettings
    BMI .skipVanillaPaletteUpdate
    LDA #$6D
    STA $2121   ; from $00A41E
    LDA $14
    AND #$1C
    LSR
    TAX
    LDA.w $00B60C,x : STA $2122     ; yellow level
    LDA.w $00B60D,x : STA $2122
    LDA #$7D
    STA $2121
    LDA.w $00B61C,x : STA $2122     ; red level
    LDA.w $00B61D,x : STA $2122
  .skipVanillaPaletteUpdate:
    RTL

NmiVersion:
    db "LM" : dw $0100

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF

;=======================================================================

OverworldExAnimationMain:   ; get ExAnimation information for current upload
    PHB
    LDX #$7F
    PHX
    PLB
    LDY $14
    CPY.w !RAM_GlobalFrameMirror
    BNE .newFrame
    REP #$20
    STZ.w !RAM_UpdateData+(7*0)     ; clean exanimation data
    STZ.w !RAM_UpdateData+(7*1)
    STZ.w !RAM_UpdateData+(7*2)
    STZ.w !RAM_UpdateData+(7*3)
    STZ.w !RAM_UpdateData+(7*4)
    STZ.w !RAM_UpdateData+(7*5)
    STZ.w !RAM_UpdateData+(7*6)
    STZ.w !RAM_UpdateData+(7*7)
    SEP #$30
    STZ.w !RAM_UpdatedVanillaTiles
    PLB
    STZ $09
    RTL

  .newFrame:
    STY.w !RAM_GlobalFrameMirror
    LDA.w !RAM_AnimationSettings
    BIT #$40
    BNE .skipVanillaTileAnimations
    LDA #$80
    STA.w !RAM_UpdatedVanillaTiles
    LDA $01,S
    PHB
    PHA
    PLB
    PHK
    PER .doneVanillaTileAnimation-1
    PEA.w $048414-1     ; (RTL)
    LDA $14             ; run vanilla animations (restore code from $0480E0)
    AND #$07
    BNE .skipWaterAnimation
    JML $0480E6
  .skipWaterAnimation:
    JML $048123
  .doneVanillaTileAnimation:
    PLB
    LDA.w !RAM_AnimationSettings
  .skipVanillaTileAnimations:
    AND #$30
    CMP #$30
    BNE .customAnimationsEnabled
    PLB
    STZ $09
    RTL

  .customAnimationsEnabled:
    REP #$20
    STZ.w !RAM_UpdateData+(7*0)
    STZ.w !RAM_UpdateData+(7*1)
    STZ.w !RAM_UpdateData+(7*2)
    STZ.w !RAM_UpdateData+(7*3)
    STZ.w !RAM_UpdateData+(7*4)
    STZ.w !RAM_UpdateData+(7*5)
    STZ.w !RAM_UpdateData+(7*6)
    STZ.w !RAM_UpdateData+(7*7)
    BIT #$0010
    BNE .skipGlobal
    LDA $14
    AND #$0007
    ASL
    CMP.w !RAM_GlobalExAniEnd
    BCS .doneGlobal
    TAY
    LDX.w !RAM_GlobalExAniPtr+2
    STX $02
    STX $07
    LDA.w !RAM_GlobalExAniPtr
    STA $00     ; $00 = 24-bit pointer to slot indices
    LDX #$03
    REP #$10
    STX $0A     ; $0A = offset from the level alternate ExGFX pointer to the global one
    INX
  .globalLoop:
    LDA [$00],y
    BEQ .nextGlobalSlot
    PHY
    PHX
    CLC
    ADC $00
    STA $05     ; $05 = 24-bit pointer to the current slot's data
    TYA
    LSR
    ADC.w #!RAM_SlotFrames+$20
    STA $08     ; $08 = 16-bit pointer to the slot's frame in RAM
    JSR UpdateSlot
    PLX
    PLY
  .nextGlobalSlot:
    TYA
    CLC
    ADC #$0010
    TAY
    INX
    CPY.w !RAM_GlobalExAniEnd
    BCC .globalLoop
  .doneGlobal:
    LDA.w !RAM_AnimationSettings
    SEP #$10
  .skipGlobal:
    BIT #$0020
    BNE .skipSubmap
    LDA $14
    AND #$0007
    ASL
    CMP.w !RAM_SubmapExAniEnd
    BCS .skipSubmap
    TAY
    LDX.w !RAM_SubmapExAniPtr+2
    STX $02
    STX $07
    LDA.w !RAM_SubmapExAniPtr
    STA $00     ; $00 = 24-bit pointer to slot data offsets
    LDX #$00
    REP #$10
    STZ $0A
  .submapLoop:
    LDA [$00],y
    BEQ .nextSubmapSlot
    PHY
    PHX
    CLC
    ADC $00
    STA $05     ; $05 = 24-bit pointer to the current slot's data
    TYA
    LSR
    ADC.w #!RAM_SlotFrames
    STA $08
    JSR UpdateSlot
    PLX
    PLY
  .nextSubmapSlot:
    TYA
    CLC
    ADC #$0010
    TAY
    INX
    CPY.w !RAM_SubmapExAniEnd
    BCC .submapLoop
  .skipSubmap:
    SEP #$30
    PLB
    STZ $09
    RTL

; Update ExAnimation slot's RAM:
;   $00 = 24-bit pointer to slot data offsets
;   $05 = 24-bit pointer to the current slot's data
;   $08 = 16-bit pointer to the current slot's frame in RAM
UpdateSlot:
    LDA.l SlotIndices,x
    TAY
    LDA [$05]   ; low byte = type, high byte = trigger
    INC $05
    INC $05     ; $05 = points at number of frames
    SEP #$30
    ASL
    TAX
    JMP (TypePointers,x)

NotUsed:                ; empty type/trigger
    RTS


Type_Stacked:           ; type: 8x16, 16x16, 32x16
    JSR Type_Line
    LDA.w !RAM_UpdateData+2,x
    ORA #$8000           ; set bit to indicate tiles are stacked
    STA.w !RAM_UpdateData+2,x
    RTS

Type_Line:              ; type: 8x8 line
    XBA
    BEQ .noTrigger
    ASL
    PHX
    TAX
    JSR (TriggerPointers,x)
    BEQ .off
  .on:
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC +
    LDA #$FF
  + INC
    STA ($08)
    CLC
    ADC [$05]
    INC
    PLX
    BRA .getVramData

  .off:
    PLX
  .noTrigger:
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC +
    LDA #$FF
  + INC
    STA ($08)
  .getVramData:
    REP #$30
    AND #$00FF
    INC
    ASL
    PHA
    LDA.l VramUploadSizes,x
    TYX
    STA.w !RAM_UpdateData+0,x
    INC $05
    LDA [$05]   ; = VRAM destination (high bit set = use alternate ExGFX)
    BMI .useAltExGfx
    STA.w !RAM_UpdateData+2,x
    LDA #$7E00
    STA.w !RAM_UpdateData+5,x
    PLY
    LDA [$05],y ; = RAM source
    STA.w !RAM_UpdateData+4,x
    RTS

  .useAltExGfx:
    AND #$7FFF
    STA.w !RAM_UpdateData+2,x
    LDY $0A
    LDA.w !RAM_SubmapAltExGfxPtr+1,y
    STA.w !RAM_UpdateData+5,x
    LDA.w !RAM_SubmapAltExGfxPtr,y
    PLY
    CLC
    ADC [$05],y ; = ROM source
    STA.w !RAM_UpdateData+4,x
    RTS


Type_Palette:           ; type: palette (no working)
    XBA
    BEQ .noTrigger
    ASL
    PHX
    TAX
    JSR (TriggerPointers,x)
    BEQ .off
  .on:
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC +
    LDA #$FF
  + INC
    STA ($08)
    CLC
    ADC [$05]
    INC
    PLX
    BRA .getCgramData

  .off:
    PLX
  .noTrigger:
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC +
    LDA #$FF
  + INC
    STA ($08)
  .getCgramData:
    REP #$30
    AND #$00FF
    INC
    ASL
    PHA
    INC $05
    LDA [$05]   ; = palette destination (low byte) + number of colors (high byte)
    TAX
    STA.w !RAM_UpdateData+2,y
    AND #$7F00
    BNE .multiColor
  .singleColor
    LDA #$8001
    STA.w !RAM_UpdateData+0,y   ; mark as single color
    LDA $06
    STA.w !RAM_UpdateData+5,y   ; write color directly
    PLA
    ADC $05
    STA.w !RAM_UpdateData+4,y
    RTS

  .multiColor:
    XBA
    INC
    ORA #$8000
    STA.w !RAM_UpdateData+0,y   ; write number of colors
    TXA
    BMI .useAltExGfx
    TYX
    LDA #$7E00
    STA.w !RAM_UpdateData+5,x
    PLY
    LDA [$05],y ; = RAM source
    STA.w !RAM_UpdateData+4,x
    RTS

  .useAltExGfx:
    TYX
    LDY $0A
    LDA.w !RAM_SubmapAltExGfxPtr+1,y
    STA.w !RAM_UpdateData+5,x
    LDA.w !RAM_SubmapAltExGfxPtr,y
    PLY
    CLC
    ADC [$05],y ; = ROM source
    STA.w !RAM_UpdateData+4,x
    RTS


Type_PaletteWorking:        ; type: palette + working
    XBA
    BEQ .noTrigger
    ASL
    PHX
    TAX
    JSR (TriggerPointers,x)
    BEQ .off
  .on:
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC +
    LDA #$FF
  + INC
    STA ($08)
    CLC
    ADC [$05]
    INC
    PLX
    BRA .updatePalette

  .off:
    PLX
  .noTrigger:
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC +
    LDA #$FF
  + INC
    STA ($08)
  .updatePalette:
    REP #$30
    AND #$00FF
    INC
    ASL
    PHA
    INC $05
    LDA [$05]   ; = palette destination (low byte) + number of colors (high byte)
    TAX
    STA.w !RAM_UpdateData+2,y
    AND #$7F00
    BNE .multiColor
  .singleColor:
    LDA #$8001
    STA.w !RAM_UpdateData+0,y   ; mark as single color
    TXA
    AND #$00FF
    STA.w !RAM_UpdateData+5,y   ; (write 00 via high byte)
    ASL
    TAX
    ADC #$0703|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to color
    PLY
    LDA [$05],y
    STA $000703|!addr,x         ; update palette
    RTS

  .multiColor:
    XBA
    STA.w !RAM_UpdateData+5,y   ; (write 00 via high byte)
    INC
    ORA #$8000
    STA.w !RAM_UpdateData+0,y   ; write number of colors
    ASL
    DEC
    STA $08
    TXA
    BMI .useAltExGfx
    AND #$00FF
    ASL
    ADC #$0703|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to first color
    PLY
    PHB
    PHA
    LDA [$05],y
    TAX
    PLY
    LDA $08
    MVN $7E00   ; copy colors from RAM source to $0703
    PLB
    RTS

  .useAltExGfx:
    AND #$00FF
    ASL
    ADC #$0703|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to first color
    PLY
    PHB
    PHA
    LDA [$05],y
    PHA
    LDY $0A
    LDA.w !RAM_SubmapAltExGfxPtr+2,y
    STA $05
    PLA
    ADC.w !RAM_SubmapAltExGfxPtr,y
    TAX         ; X = ROM source (low/high byte)
    LDA #$0054  ; (MVN)
    STA $03
    LDA $05
    AND #$00FF
    ORA #$6B00  ; (RTL)
    STA $05
    PLY
    LDA $08
    if !sa1
        JSL WriteCodeForSa1
    else
        JSL $000003 ; MVN $00xx : RTL
    endif
    PLB
    RTS


Type_PaletteRRev:       ; type: palette rotate right, reverse on trigger
    XBA
    BEQ Type_PaletteR_noTrigger
    ASL
    PHX
    TAX
    JSR (TriggerPointers,x)
    BEQ Type_PaletteR_on
    BRL Type_PaletteL_on

Type_PaletteR:          ; type: palette rotate right
    XBA
    BEQ .noTrigger
    ASL
    PHX
    TAX
    JSR (TriggerPointers,x)
    BNE .on
  .off: ; do nothing when off
    PLX
    REP #$30
    RTS

  .on:
    PLX
  .noTrigger:
    LDA ($08)   ; = current frame (palette rotations use as "delay" timer)
    INC
    CMP [$05]   ; = number of frames
    BCS .rotate
    STA ($08)
    REP #$30
    RTS

  .rotate:
    LDA #$FF
    STA ($08)
    REP #$30
    INC $05
    LDA [$05]   ; = palette destination (low byte) + number of colors (high byte)
    TAX
    STA.w !RAM_UpdateData+2,y
    AND #$7F00
    XBA
    STA.w !RAM_UpdateData+5,y
    STA $08
    INC
    ORA #$8000
    STA.w !RAM_UpdateData+0,y   ; write number of colors
    TXA
    AND #$00FF
    ASL
    ADC #$0703|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to the first color
    ASL $08
    ADC $08
    PHB
    TAX
    LDA $000000,x   ; get last color of rotation
    PHA
    TXY
    DEX
    INY
    LDA $08
    DEC
    MVP $0000       ; rotate colors in $0703
    PLA
    STA $0001,x
    PLB
    RTS


Type_PaletteLRev:       ; type: palette rotate left, reverse on trigger
    XBA
    BEQ Type_PaletteL_noTrigger
    ASL
    PHX
    TAX
    JSR (TriggerPointers,x)
    BEQ Type_PaletteL_on
    BRL Type_PaletteR_on

Type_PaletteL:          ; type: palette rotate left
    XBA
    BEQ .noTrigger
    ASL
    PHX
    TAX
    JSR (TriggerPointers,x)
    BNE .on
  .off: ; do nothing when off
    PLX
    REP #$30
    RTS

  .on:
    PLX
  .noTrigger:
    LDA ($08)   ; = current frame (palette rotations use as "delay" timer)
    INC
    CMP [$05]   ; = number of frames
    BCS .rotate
    STA ($08)
    REP #$30
    RTS

  .rotate:
    LDA #$FF
    STA ($08)
    REP #$30
    INC $05
    LDA [$05]   ; = palette destination (low byte) + number of colors (high byte)
    TAX
    STA.w !RAM_UpdateData+2,y
    AND #$7F00
    XBA
    STA.w !RAM_UpdateData+5,y
    INC
    ORA #$8000
    STA.w !RAM_UpdateData+0,y   ; write number of colors
    DEC
    ASL
    DEC
    STA $08
    TXA
    AND #$00FF
    ASL
    ADC #$0703|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to the first color
    PHB
    TAX
    LDA $000000,x   ; get first color of rotation
    PHA
    TXY
    INX
    INX
    LDA $08
    MVN $0000       ; rotate colors
    PLA
    STA $0000,y     ; store last color
    PLB
    RTS


Type_BgColor:           ; type: palette back area color [do not use]
    XBA
    BEQ .noTrigger
    ASL
    PHX
    TAX
    JSR (TriggerPointers,x)
    BEQ .off
  .on:
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC +
    LDA #$FF
  + INC
    STA ($08)
    CLC
    ADC [$05]
    INC
    PLX
    BRA .updatePalette

  .off:
    PLX
  .noTrigger:
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC +
    LDA #$FF
  + INC
    STA ($08)
  .updatePalette:
    REP #$30
    AND #$00FF
    INC
    ASL
    INC
    TAY
    LDA [$05],y
    STA $000701|!addr
    RTS
    
    
Trigger_EventManual8:
    LDA.w !RAM_ManualFrames+8
CheckEventManual:   ; use manual trigger's frame as event to check
    TAX
    AND #$07
    PHA
    TXA
    LSR #3
    TAX
    LDA $001F02|!addr,x
    PLX
    AND.l BitTableReversed,x
    RTS

Trigger_EventManual9:
    LDA.w !RAM_ManualFrames+9
    BRA CheckEventManual

Trigger_EventManualA:
    LDA.w !RAM_ManualFrames+$A
    BRA CheckEventManual
    
Trigger_EventManualB:
    LDA.w !RAM_ManualFrames+$B
    BRA CheckEventManual
    
Trigger_EventManualC:
    LDA.w !RAM_ManualFrames+$C
    BRA CheckEventManual
    
Trigger_EventManualD:
    LDA.w !RAM_ManualFrames+$D
    BRA CheckEventManual
    
Trigger_EventManualE:
    LDA.w !RAM_ManualFrames+$E
    BRA CheckEventManual
    
Trigger_EventManualF:
    LDA.w !RAM_ManualFrames+$F
    BRA CheckEventManual
    

UnusedTriggerOn:    ; not currently used
    LDA #$01
    RTS
    
UnusedTriggerOff:   ; not currently used
    LDA #$00
    RTS


Trigger_Custom0:
    LDA #$01
    AND.w !RAM_CustomTriggers
    RTS

Trigger_Custom1:
    LDA #$02
    AND.w !RAM_CustomTriggers
    RTS

Trigger_Custom2:
    LDA #$04
    AND.w !RAM_CustomTriggers
    RTS

Trigger_Custom3:
    LDA #$08
    AND.w !RAM_CustomTriggers
    RTS

Trigger_Custom4:
    LDA #$10
    AND.w !RAM_CustomTriggers
    RTS

Trigger_Custom5:
    LDA #$20
    AND.w !RAM_CustomTriggers
    RTS

Trigger_Custom6:
    LDA #$40
    AND.w !RAM_CustomTriggers
    RTS

Trigger_Custom7:
    LDA #$80
    AND.w !RAM_CustomTriggers
    RTS
    
Trigger_Custom8:
    LDA #$01
    AND.w !RAM_CustomTriggers+1
    RTS
    
Trigger_Custom9:
    LDA #$02
    AND.w !RAM_CustomTriggers+1
    RTS
    
Trigger_CustomA:
    LDA #$04
    AND.w !RAM_CustomTriggers+1
    RTS
    
Trigger_CustomB:
    LDA #$08
    AND.w !RAM_CustomTriggers+1
    RTS
    
Trigger_CustomC:
    LDA #$10
    AND.w !RAM_CustomTriggers+1
    RTS
    
Trigger_CustomD:
    LDA #$20
    AND.w !RAM_CustomTriggers+1
    RTS
    
Trigger_CustomE:
    LDA #$40
    AND.w !RAM_CustomTriggers+1
    RTS
    
Trigger_CustomF:
    LDA #$80
    AND.w !RAM_CustomTriggers+1
    RTS


Trigger_Manual0:
    LDA.w !RAM_ManualFrames+0
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_Manual1:
    LDA.w !RAM_ManualFrames+1
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_Manual2:
    LDA.w !RAM_ManualFrames+2
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_Manual3:
    LDA.w !RAM_ManualFrames+3
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_Manual4:
    LDA.w !RAM_ManualFrames+4
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_Manual5:
    LDA.w !RAM_ManualFrames+5
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_Manual6:
    LDA.w !RAM_ManualFrames+6
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_Manual7:
    LDA.w !RAM_ManualFrames+7
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

DontUpdate: ; Used by one shot and manual triggers to prevent updates when not required.
    PLA     ; Pull return address to early-return the slot.
    REP #$30
    PLA
    TYX
    RTS


Trigger_Manual8:
    LDA.w !RAM_ManualFrames+8
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_Manual9:
    LDA.w !RAM_ManualFrames+9
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_ManualA:
    LDA.w !RAM_ManualFrames+$A
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_ManualB:
    LDA.w !RAM_ManualFrames+$B
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_ManualC:
    LDA.w !RAM_ManualFrames+$C
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_ManualD:
    LDA.w !RAM_ManualFrames+$D
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_ManualE:
    LDA.w !RAM_ManualFrames+$E
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS

Trigger_ManualF:
    LDA.w !RAM_ManualFrames+$F
    CMP ($08)
    BEQ DontUpdate
    DEC
    STA ($08)
    SEP #$02
    RTS


Trigger_PrecisionPalette:   ; trigger: precision timer palette rotate
    LDA #$07    ; modify to use frame counter of first slot in group
    TRB $08
    LDA #$01
    RTS


Trigger_OneShot0:
    LSR
    AND #$07
    TAX
    LDA.l BitTable,x
    AND.w !RAM_OneshotTriggers+0
    BEQ OneShotNotTriggered
    TAX
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC TriggerOff
    CMP #$FF
    BEQ TriggerOff
    LDA #$FF
    STA ($08)
    TXA
    EOR.w !RAM_OneshotTriggers+0
    STA.w !RAM_OneshotTriggers+0
OneShotNotTriggered:
    PLA     ; Pull return address to early-return the slot.
    REP #$30
    PLA
    TYX
    RTS

TriggerOff:
    LDA #$00
    RTS

Trigger_OneShot1:
    LSR
    AND #$07
    TAX
    LDA.l BitTable,x
    AND.w !RAM_OneshotTriggers+1
    BEQ OneShotNotTriggered
    TAX
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC TriggerOff
    CMP #$FF
    BEQ TriggerOff
    LDA #$FF
    STA ($08)
    TXA
    EOR.w !RAM_OneshotTriggers+1
    STA.w !RAM_OneshotTriggers+1
    BRA OneShotNotTriggered

Trigger_OneShot2:
    LSR
    AND #$07
    TAX
    LDA.l BitTable,x
    AND.w !RAM_OneshotTriggers+2
    BEQ OneShotNotTriggered
    TAX
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC TriggerOff
    CMP #$FF
    BEQ TriggerOff
    LDA #$FF
    STA ($08)
    TXA
    EOR.w !RAM_OneshotTriggers+2
    STA.w !RAM_OneshotTriggers+2
    BRA OneShotNotTriggered

Trigger_OneShot3:
    LSR
    AND #$07
    TAX
    LDA.l BitTable,x
    AND.w !RAM_OneshotTriggers+3
    BEQ OneShotNotTriggered
    TAX
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC TriggerOff
    CMP #$FF
    BEQ TriggerOff
    LDA #$FF
    STA ($08)
    TXA
    EOR.w !RAM_OneshotTriggers+3
    STA.w !RAM_OneshotTriggers+3
    BRA OneShotNotTriggered

SlotIndices:        ; Indices to each ExAnimation slot's data.
    db $00,$07,$0E,$15,$1C,$23,$2A,$31

BitTableReversed:    ; Bit tables.
    db $80,$40,$20,$10,$08,$04,$02
BitTable:
    db $01,$02,$04,$08,$10,$20,$40,$80

VramUploadSizes:        ; Upload sizes for each of the 8x8 upload types.
    dw $0000                    ; (none)
    dw $0020,$0040,$0060,$0080  ; lines
    dw $00A0,$00C0,$00E0,$0100
    dw $0180,$0200,$0280,$0300
    dw $0380,$0400
    dw $0010                    ; single 2bpp
    dw $0020,$0040,$0080        ; 8x16, 16x16, 16x32

TypePointers:       ; Pointers to the routines for each ExAnimation type.
    dw NotUsed              ; Not Used
    dw Type_Line            ; 1 8x8: line
    dw Type_Line            ; 2 8x8s: line
    dw Type_Line            ; 3 8x8s: line
    dw Type_Line            ; 4 8x8s: line
    dw Type_Line            ; 5 8x8s: line
    dw Type_Line            ; 6 8x8s: line
    dw Type_Line            ; 7 8x8s: line
    dw Type_Line            ; 8 8x8s: line
    dw Type_Line            ; 0x0C 8x8s: line
    dw Type_Line            ; 0x10 8x8s: line
    dw Type_Line            ; 0x14 8x8s: line
    dw Type_Line            ; 0x18 8x8s: line
    dw Type_Line            ; 0x1C 8x8s: line
    dw Type_Line            ; 0x20 8x8s: line
    dw Type_Line            ; 1 8x8 2bpp
    dw Type_Stacked         ; 2 8x8s: stacked
    dw Type_Stacked         ; 4 8x8s: 16x16
    dw Type_Stacked         ; 8 8x8s: 32x16
    dw Type_Palette         ; Palette
    dw Type_PaletteWorking  ; Palette + Working
    dw Type_PaletteWorking  ; Palette + Working [Do Not Use]
    dw Type_BgColor         ; Palette Back Area Color [Do Not Use]
    dw Type_BgColor         ; Palette Back Area Color [Do Not Use]
    dw Type_PaletteR        ; Palette Rotate Right
    dw Type_PaletteRRev     ; Palette Rotate Right, Rev on Trigger
    dw Type_PaletteL        ; Palette Rotate Left
    dw Type_PaletteLRev     ; Palette Rotate Left, Rev on Trigger

TriggerPointers:    ; Pointers to the routines for each ExAnimation trigger. Return 0 = off, 1 = on.
    dw NotUsed                  ; None
    dw Trigger_EventManual8     ; Event Manual 8
    dw Trigger_EventManual9     ; Event Manual 9
    dw Trigger_EventManualA     ; Event Manual A
    dw Trigger_EventManualB     ; Event Manual B
    dw Trigger_EventManualC     ; Event Manual C
    dw Trigger_EventManualD     ; Event Manual D
    dw Trigger_EventManualE     ; Event Manual E
    dw Trigger_EventManualF     ; Event Manual F
    dw NotUsed                  ; (unused)
    dw NotUsed                  ; (unused)
    dw NotUsed                  ; (unused)
    dw NotUsed                  ; (unused)
    dw NotUsed                  ; (unused)
    dw NotUsed                  ; (unused)
    dw Trigger_PrecisionPalette ; Precision Timer Palette Rotate
    dw Trigger_Manual0          ; Manual 0
    dw Trigger_Manual1          ; Manual 1
    dw Trigger_Manual2          ; Manual 2
    dw Trigger_Manual3          ; Manual 3
    dw Trigger_Manual4          ; Manual 4
    dw Trigger_Manual5          ; Manual 5
    dw Trigger_Manual6          ; Manual 6
    dw Trigger_Manual7          ; Manual 7
    dw Trigger_Manual8          ; Manual 8
    dw Trigger_Manual9          ; Manual 9
    dw Trigger_ManualA          ; Manual A
    dw Trigger_ManualB          ; Manual B
    dw Trigger_ManualC          ; Manual C
    dw Trigger_ManualD          ; Manual D
    dw Trigger_ManualE          ; Manual E
    dw Trigger_ManualF          ; Manual F
    dw Trigger_Custom0          ; Custom 0
    dw Trigger_Custom1          ; Custom 1
    dw Trigger_Custom2          ; Custom 2
    dw Trigger_Custom3          ; Custom 3
    dw Trigger_Custom4          ; Custom 4
    dw Trigger_Custom5          ; Custom 5
    dw Trigger_Custom6          ; Custom 6
    dw Trigger_Custom7          ; Custom 7
    dw Trigger_Custom8          ; Custom 8
    dw Trigger_Custom9          ; Custom 9
    dw Trigger_CustomA          ; Custom A
    dw Trigger_CustomB          ; Custom B
    dw Trigger_CustomC          ; Custom C
    dw Trigger_CustomD          ; Custom D
    dw Trigger_CustomE          ; Custom E
    dw Trigger_CustomF          ; Custom F
    dw Trigger_OneShot0         ; One shot 0
    dw Trigger_OneShot0         ; One shot 1
    dw Trigger_OneShot0         ; One shot 2
    dw Trigger_OneShot0         ; One shot 3
    dw Trigger_OneShot0         ; One shot 4
    dw Trigger_OneShot0         ; One shot 5
    dw Trigger_OneShot0         ; One shot 6
    dw Trigger_OneShot0         ; One shot 7
    dw Trigger_OneShot1         ; One shot 8
    dw Trigger_OneShot1         ; One shot 9
    dw Trigger_OneShot1         ; One shot A
    dw Trigger_OneShot1         ; One shot B
    dw Trigger_OneShot1         ; One shot C
    dw Trigger_OneShot1         ; One shot D
    dw Trigger_OneShot1         ; One shot E
    dw Trigger_OneShot1         ; One shot F
    dw Trigger_OneShot2         ; One shot 10
    dw Trigger_OneShot2         ; One shot 11
    dw Trigger_OneShot2         ; One shot 12
    dw Trigger_OneShot2         ; One shot 13
    dw Trigger_OneShot2         ; One shot 14
    dw Trigger_OneShot2         ; One shot 15
    dw Trigger_OneShot2         ; One shot 16
    dw Trigger_OneShot2         ; One shot 17
    dw Trigger_OneShot3         ; One shot 18
    dw Trigger_OneShot3         ; One shot 19
    dw Trigger_OneShot3         ; One shot 1A
    dw Trigger_OneShot3         ; One shot 1B
    dw Trigger_OneShot3         ; One shot 1C
    dw Trigger_OneShot3         ; One shot 1D
    dw Trigger_OneShot3         ; One shot 1E
    dw Trigger_OneShot3         ; One shot 1F

MainVersion:
    db "LM" : dw $0101

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF

;=======================================================================

if !sa1
    ; Extra routine exclusive to SA-1 for moving a four byte code from $7E0003 to $7FC020.
    ;  Used to copy palettes from the alternate ExGFX file to $0703.
    ;  Not sure why it needs to do this copy, though.
    WriteCodeForSa1:
        LDA $03 : STA.w !RAM_ExecSA1    ; MVN $00xx : RTL
        LDA $05 : STA.w !RAM_ExecSA1+2
        LDA $08
        JML !RAM_ExecSA1

      .version:
        db "LM" : dw $0100

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF
endif

;=======================================================================

freedata
; Flags for disabling ExAnimations in each submap, from LM's "Edit Animation Settings" dialog.
SubmapAnimationSettings:
    for i = 0..$200 : db $00 : endfor

freedata
; Global ExAnimation data.
GlobalExAnimationData:
    db $00                              ; 0: Highest used slot, plus 1
    db $00                              ; 1: Alternate ExGFX file number
    dw %0000000000000000                ; 2: Which custom triggers start uninitialized
    dw %0000000000000000                ; 4: Initial states for custom triggers specified above
    dw %0000000000000000                ; 6: Which manual triggers are initialized
    ; for i = 0..X : db $00 : endfor    ; frame numbers for each of the specified manual triggers
    ; for i = 0..X : dw $0000 : endfor  ; indices to each animation slot, from this position

    ; ExAnimation slots have the following format:
    ;  db $00                           ; 0: Type
    ;  db $00                           ; 1: Trigger
    ;  db $00                           ; 2: Number of frames, minus 1
    ;  dw $0000                         ; 3: VRAM/CGRAM destination. For palettes, high byte is color count (-1).
    ;  for i = 1..X : dw $0000 : endfor ; 5: Address of source data for each frame, or direct color if single color.

freedata
; 24-bit pointers to each submap's ExAnimation data. If upper 16-bits = 0000, submap does not have any.
; Format for the actual data is identical to the global animation data above.
SubmapExAnimationPointers:
    for i = 0..$200 : dl $000000 : endfor