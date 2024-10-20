; Code used to manage and upload ExAnimations in levels.
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

!RAM_LevelNum           =   $FE
    ; 16-bit level number, +1. Set to 0000 for No-Yoshi entrance.
    
;;; All of the below are required to be in bank $7F.

!RAM_LevelExAniPtr      =   $7FC000
    ; 3 bytes; 24-bit pointer to level's ExAnimation data. 000000 if none present.

!RAM_GlobalExAniPtr     =   $7FC016
    ; 3 bytes; 24-bit pointer to global ExAnimation data. 000000 if none present.

!RAM_LevelExAniEnd      =   $7FC00C
!RAM_GlobalExAniEnd     =   $7FC00E
    ; 2 bytes each; indicates the ExAnimation slot to stop at.

!RAM_LevelAltExGfxPtr   =   $7FC010
!RAM_GlobalAltExGfxPtr  =   !RAM_LevelAltExGfxPtr+3 ; $7FC013
    ; 3 bytes each; 24-bit pointer to alternate ExGFX files for the level.

!RAM_GlobalFrameMirror  =   $7FC003
    ; 1 byte; mirror of $14. Used to prevent ExAnimation updates if not actually a new frame.

!RAM_LegacyFrameSlot0  =   !RAM_GlobalFrameMirror+1 ; $7FC004
    ; 1 byte; deprecated frame counter for slot 0. No longer used, though still updated.

!RAM_AnimationSettings  =   $7FC00A
    ; 1 byte; animation settings for the current level. Format: ptlg---- (0 = enable, 1 = disable)
    ;   p = SMW's palette animations
    ;   t = SMW's tile animations
    ;   l = Lunar Magic level ExAnimations
    ;   g = Lunar Magic global ExAnimations

!RAM_LegacyFrameCounter =   $7FC019
    ; 1 byte; legacy frame counter, starting at 0 on level load.
    ;  Not used other than being retained.

!RAM_OneshotTriggers    =   $7FC0F8
    ; 4 bytes; bitwise flags for each oneshot ExAnimation trigger

!RAM_CustomTriggers     =   $7FC0FC
    ; 2 bytes; bitwise flags for each custom trigger.

!RAM_ManualFrames       =   $7FC070
    ; 16 bytes (one per manual trigger); frame numbers to show for each manual trigger.

!RAM_SlotFrames         =   $7FC080
    ; 64 bytes (one per slot); local frame counters for each ExAnimation slot.
    ; First half is for level slots, second half is for global slots.

!RAM_UpdateData         =   $7FC0C0
    ; 56 bytes (eight 7-byte tables); container for data about ExAnimation slots updating this frame.
    ;  0 = 16-bit header, for animation type (highest bit) and size (remaining 15 bits).
    ;  2 = 16-bit VRAM destination. For GFX animations, highest bit indicates line (0) vs stacked (1).
    ;  4 = 24-bit source. For palette animations with only one color, the first two bytes here are the direct color.

!RAM_ExecSA1            =   $7FC020
    ; 14 bytes; RAM used exclusively on SA-1 to execute some code for ExAnimation.

;=======================================================================

org $0583AD ; level load
    autoclean JSL LevelExAnimationLoad
    NOP

org $00A5FD ; level init
    JSL LevelExAnimationMain

org $00A2A5 ; level main
    JSL LevelExAnimationMain

org $0095B5 ; credits Yoshi's House
    JSL LevelExAnimationMain

org $00A390 ; uploading animated tiles to VRAM
    JSL LevelExAnimationNMI
    RTS

;=======================================================================

freecode
prot GlobalExAnimationData,LevelExAnimationPointers

LevelExAnimationLoad:       ; initializing ExAnimation during level load
    SEP #$30
    PHB
    LDX #$7F
    PHX : PLB
    LDA #$FF
    STA.w !RAM_LegacyFrameCounter
    STZ.w !RAM_AnimationSettings
    REP #$30
    STZ.w !RAM_OneshotTriggers  ; clean up previous ExAnimation data
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
    STA.w !RAM_GlobalFrameMirror
    LDX.w #$003E
  - STA.w !RAM_SlotFrames,x
    DEX #2
    BPL -
    LDA !RAM_LevelNum
    BEQ .noYoshiEntrance
    DEC
    TAX
    LDA.l LevelAnimationSettings,x
    AND #$00FF
    ORA.w !RAM_AnimationSettings
    STA.w !RAM_AnimationSettings
    BRA SetUpGlobalExAnimation 

  .noYoshiEntrance:
    LDA #$0010      ; disable global ExAnimations
    TSB.w !RAM_AnimationSettings
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
    ADC $00 ; x3
    TAX
    LDA.l !LM_AltExGfxPointers,x   : STA.w !RAM_GlobalAltExGfxPtr
    LDA.l !LM_AltExGfxPointers+1,x : STA.w !RAM_GlobalAltExGfxPtr+1
    BRA SetUpLevelExAnimation

  .disableGlobalExAnimation:
    STZ.w !RAM_GlobalExAniPtr
    STZ.w !RAM_GlobalExAniPtr+1
    STZ.w !RAM_GlobalExAniEnd
    LDA #$0010      ; disable global ExAnimations
    TSB.w !RAM_AnimationSettings
SetUpLevelExAnimation:
    LDA !RAM_LevelNum
    BEQ .disableLevelExAnimation    ; disable level ExAni in No-Yoshi intro
    DEC
    ASL
    CLC
    ADC !RAM_LevelNum
    DEC
    TAX
    LDA LevelExAnimationPointers+1,x
    BEQ .disableLevelExAnimation
    STA $01
    STA.w !RAM_LevelExAniPtr+1
    LDA.l LevelExAnimationPointers,x
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
    STA.w !RAM_LevelExAniPtr    ; move pointer to the slot data
    LDA [$00]
    TAX
    AND #$00FF                  ; get number of ExAnimation slots used (0 = no slots)
    BEQ .disableLevelExAnimation
    ASL
    STA.w !RAM_LevelExAniEnd    ; store maximum index for last ExAnimation in the list
    TXA
    XBA
    AND #$00FF
    STA $00
    ASL
    ADC $00
    TAX
    LDA.l !LM_AltExGfxPointers,x   : STA.w !RAM_LevelAltExGfxPtr
    LDA.l !LM_AltExGfxPointers+1,x : STA.w !RAM_LevelAltExGfxPtr+1
    BRA SetUpVanillaAnimations

  .disableLevelExAnimation:
    STZ.w !RAM_LevelExAniPtr
    STZ.w !RAM_LevelExAniPtr+1
    STZ.w !RAM_LevelExAniEnd
    LDA #$0020      ; disable level ExAnimations
    TSB.w !RAM_AnimationSettings
SetUpVanillaAnimations:
    PLB
    STZ $0D80|!addr ; clean vanilla animations
    STZ $0D7E|!addr
    STZ $0D7C|!addr
    SEP #$30
    STZ $1933|!addr
    RTL

LoadVersion:
    db "LM" : dw $0101

    db $FF,$FF,$FF

;=======================================================================

macro upload_exanimation(slot, ...)
    LDA.l !RAM_UpdateData+(7*<slot>)+0
    BEQ ?skip
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
    if sizeof(...) > 0  ; if second parameter provided, make sure A = 0 on exit
      ?done:
        LDA #$0000
    else
        CLC
        LDA #$1801 : STA.b $4320
      ?done:
    endif
  ?skip:
endmacro

LevelExAnimationNMI:    ; upload animations to VRAM/CGRAM
    STZ $4326
    REP #$20
    LDA #$4300
    TCD
    LDY #$80            ; this first part is basically a copy of the original routine from $00A390
    STY $2115
    LDA #$1801
    STA.b $4320
    LDX #$7E
    STX.b $4324
    LDX #$04
    LDA $0D80|!addr     ; first vanilla animated tile
    BEQ .skipVanillaTileA
    STA $2116
    LDA $0D7A|!addr
    STA.b $4322
    STY.b $4325
    STX $420B
  .skipVanillaTileA:
    LDA $0D7E|!addr     ; second vanilla animated tile
    BEQ .skipVanillaTileB
    STA $2116
    LDA $0D78|!addr
    STA.b $4322
    STY.b $4325
    STX $420B
  .skipVanillaTileB:
    LDA $0D7C|!addr     ; third vanilla animated tile
    BEQ .skipVanillaTileC
    STA $2116
    CMP #$0800
    BEQ .uploadBerry
    LDA $0D76|!addr
    STA.b $4322
    BRA .uploadVanillaTileC

  .uploadBerry:         ; berries upload in two halves
    LDA $0D76|!addr
    STA.b $4322
    LDY #$40
    STY.b $4325
    STX $420B
    LDA #$0900
    STA $2116
  .uploadVanillaTileC:
    STY.b $4325
    STX $420B
  .skipVanillaTileC:    ; now to handle LM's ExAnimations
    CLC
    %upload_exanimation(4)
    %upload_exanimation(5)
    %upload_exanimation(6)
    %upload_exanimation(7)
    %upload_exanimation(0)
    %upload_exanimation(1)
    %upload_exanimation(2)
    %upload_exanimation(3, 0)   ; end with A = 0000
    TCD
    SEP #$30
    LDA !RAM_AnimationSettings  ; check for "disable SMW's palette animations" flag
    BMI .skipVanillaPalette
    LDA #$64            ; animate color 64
    STA $2121
    LDA $14
    AND #$1C
    LSR
    TAX
    LDA.w $00B60C,x     ; SMW's color 64 palette animation
    STA $2122
    LDA.w $00B60C+1,x
    STA $2122
  .skipVanillaPalette:
    LDA !RAM_LegacyFrameCounter   ; update legacy frame counter
    LSR #3
    STA !RAM_LegacyFrameSlot0
    RTL

NmiVersion:
    db "LM" : dw $0100

    db $FF,$FF

;=======================================================================

LevelExAnimationMain:   ; get ExAnimation information for current upload
    PHB
    LDX #$7F
    PHX
    PLB
    LDY $14
    CPY.w !RAM_GlobalFrameMirror    ; don't run update multiple times
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
    PLB
    STZ $0D80|!addr                 ; clean vanilla animation data
    STZ $0D7E|!addr
    STZ $0D7C|!addr
    SEP #$30
    RTL

  .newFrame:
    STY.w !RAM_GlobalFrameMirror
    LDA.w !RAM_AnimationSettings
    BIT #$40                        ; check for "disable SMW's tile animations" flag
    BNE .skipVanillaTileAnimations
    JSL $05BB39                     ; original game's routine
    LDA.w !RAM_AnimationSettings
  .skipVanillaTileAnimations:
    AND #$30                        ; check for either LM animation flag
    CMP #$30
    BNE .customAnimationsEnabled
    PLB
    RTL

  .customAnimationsEnabled:
    INC.w !RAM_LegacyFrameCounter
    REP #$20
    STZ.w !RAM_UpdateData+(7*0) ; clean up previous ExAnimation data
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
    BNE .skipLevel
    LDA $14
    AND #$0007
    ASL
    CMP.w !RAM_LevelExAniEnd
    BCS .skipLevel
    TAY
    LDX.w !RAM_LevelExAniPtr+2
    STX $02
    STX $07
    LDA.w !RAM_LevelExAniPtr
    STA $00     ; $00 = 24-bit pointer to slot data offsets
    LDX #$00
    REP #$10
    STZ $0A
  .levelLoop:
    LDA [$00],y
    BEQ .nextLevelSlot
    PHY
    PHX
    CLC
    ADC $00
    STA $05     ; $05 = 24-bit pointer to the current slot's data
    TYA
    LSR
    ADC.w #!RAM_SlotFrames
    STA $08     ; $08 = 16-bit pointer to the current slot's frame in RAM
    JSR UpdateSlot
    PLX
    PLY
  .nextLevelSlot:
    TYA
    CLC
    ADC #$0010
    TAY
    INX
    CPY.w !RAM_LevelExAniEnd
    BCC .levelLoop
  .skipLevel:
    SEP #$30
    PLB
    RTL

; Update ExAnimation slot's RAM:
;   $00 = 24-bit pointer to slot data offsets
;   $05 = 24-bit pointer to the current slot's data
;   $08 = 16-bit pointer to the current slot's frame in RAM
UpdateSlot:
    LDA.l SlotIndices,x   ; get index of ExAnimation slot's data
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
    ORA #$8000          ; set bit to indicate tiles are stacked
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
    LDA.w !RAM_LevelAltExGfxPtr+1,y
    STA.w !RAM_UpdateData+5,x
    LDA.w !RAM_LevelAltExGfxPtr,y
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
  .singleColor:
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
    LDA.w !RAM_LevelAltExGfxPtr+1,y
    STA.w !RAM_UpdateData+5,x
    LDA.w !RAM_LevelAltExGfxPtr,y
    PLY
    CLC
    ADC [$05],y ; = ROM source
    STA.w !RAM_UpdateData+4,x
    RTS


Type_PaletteWorkingNoFade:  ; type: palette + working, stop on fade
    LDA $001493|!addr
    BEQ Type_PaletteWorking
    REP #$30
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
    ADC #$0905|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to color
    PLY
    LDA [$05],y
    STA $000703|!addr,x         ; update palettes
    STA $000905|!addr,x
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
    TAX
    ADC #$0905|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to first color
    PLY
    PHB
    PHA
    LDA [$05],y
    TXY
    TAX
    PHX
    TYA
    ADC #$0703|!addr
    TAY
    LDA $08
    MVN $7E00   ; copy colors from RAM source to $0703
    PLX
    PLY
    LDA $08
    MVN $7E00   ; copy colors from RAM source to $0905
    PLB
    RTS

  .useAltExGfx:
    AND #$00FF
    ASL
    TAX
    ADC #$0905|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to first color
    PLY
    PHB
    PHA
    LDA [$05],y
    PHA
    LDY $0A
    LDA.w !RAM_LevelAltExGfxPtr+2,y
    STA $05
    PLA
    ADC.w !RAM_LevelAltExGfxPtr,y
    TXY
    TAX         ; X = ROM source (low/high byte)
    PHX
    LDA #$0054  ; (MVN)
    STA $03
    LDA $05
    AND #$00FF
    ORA #$6B00  ; (RTL)
    STA $05
    TYA
    ADC #$0703|!addr
    TAY
    LDA $08
    if !sa1
        JSL WriteCodeForSa1
    else
        JSL $000003 ; MVN $00xx : RTL
    endif
    PLX
    PLY
    LDA $08
    if !sa1
        JSL !RAM_ExecSA1
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
    TAX
    ADC #$0905|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to the first color
    ASL $08
    ADC $08
    PHB
    PHA
    TXA
    ADC #$0703|!addr
    ADC $08
    TAX
    LDA $000000,x   ; get last color of rotation in $0703
    PHA
    TXY
    DEX
    INY
    LDA $08
    DEC
    MVP $0000       ; rotate colors in $0703
    PLA
    STA $0001,x     ; store first color in $0703
    PLX
    LDA $0000,x     ; get last color of rotation in $0905
    PHA
    TXY
    DEX
    INY
    LDA $08
    DEC
    MVP $0000       ; rotate colors in $0905
    PLA
    STA $0001,x     ; store first color in $0905
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
    TAX
    ADC #$0905|!addr
    STA.w !RAM_UpdateData+4,y   ; write pointer to the first color
    PHB
    PHA
    TXA
    ADC #$0703|!addr
    TAX
    LDA $000000,x   ; get first color of rotation in $0703
    PHA
    TXY
    INX
    INX
    LDA $08
    MVN $0000       ; rotate colors in $0703
    PLA
    STA $0000,y     ; store last color in $0703
    PLX
    LDA $0000,x     ; get first color of rotation in $0905
    PHA
    TXY
    INX
    INX
    LDA $08
    MVN $0000       ; rotate colors in $0905
    PLA
    STA $0000,y     ; store last color in $0905
    PLB
    RTS


Type_BgColorNoFade:     ; type: palette back area color, stop on fade
    LDA $001493|!addr
    BEQ Type_BgColor
    REP #$30
    RTS

Type_BgColor:           ; type: palette back area color
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
    STA $000903|!addr
    RTS


Trigger_BluePow:    ; trigger: blue P-switch
    LDA $0014AD|!addr
    RTS

Trigger_SilverPow:  ; trigger: silver P-switch
    LDA $0014AE|!addr
    RTS

Trigger_OnOff:      ; trigger: on/off switch
    LDA $0014AF|!addr
    RTS

Trigger_Star:       ; trigger: star power
    LDA $001490|!addr
    RTS


Trigger_Timer:      ; trigger: timer < 100
    LDA $000F31|!addr
    BNE TriggerOff_A
    LDA #$01
    RTS

Trigger_YCoins:      ; trigger: >= 5 Yoshi coins
    LDA $001420|!addr
    CMP #$05
    BCS TriggerOn
    LDA #$00
    RTS

TriggerOn:
    LDA #$01
    RTS

TriggerOff_A:
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


Trigger_TimerOneShot:   ; trigger: timer < 100 one shot
    LDA $000F31|!addr
    BNE DontUpdate
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC TriggerOff_A
    CMP #$FF
    BNE DontUpdate
    SEP #$02
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


Trigger_YCoinsOneShot:      ; trigger: >= 5 Yoshi coins one shot
    LDA $001420
    CMP #$05
    BCC DontUpdate
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC TriggerOff_B
    CMP #$FF
    BNE DontUpdate
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
    AND.w !RAM_OneshotTriggers
    BEQ OneShotNotTriggered
    TAX
    LDA ($08)   ; = current frame
    CMP [$05]   ; = number of frames
    BCC TriggerOff_B
    CMP #$FF
    BEQ TriggerOff_B
    LDA #$FF
    STA ($08)
    TXA
    EOR.w !RAM_OneshotTriggers
    STA.w !RAM_OneshotTriggers
OneShotNotTriggered:
    PLA     ; Pull return address to early-return the slot.
    REP #$30
    PLA
    TYX
    RTS

TriggerOff_B:
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
    BCC TriggerOff_B
    CMP #$FF
    BEQ TriggerOff_B
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
    BCC TriggerOff_B
    CMP #$FF
    BEQ TriggerOff_B
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
    BCC TriggerOff_B
    CMP #$FF
    BEQ TriggerOff_B
    LDA #$FF
    STA ($08)
    TXA
    EOR.w !RAM_OneshotTriggers+3
    STA.w !RAM_OneshotTriggers+3
    BRA OneShotNotTriggered

SlotIndices:        ; Indices to each ExAnimation slot's data.
    db $00,$07,$0E,$15,$1C,$23,$2A,$31

BitTable:           ; Bit table, used for one-shot triggers.
    db $01,$02,$04,$08,$10,$20,$40,$80

VramUploadSizes:    ; Upload sizes for each of the 8x8 upload types.
    dw $0000                    ; (none)
    dw $0020,$0040,$0060,$0080  ; lines
    dw $00A0,$00C0,$00E0,$0100
    dw $0180,$0200,$0280,$0300
    dw $0380,$0400
    dw $0010                    ; single 2bpp
    dw $0020,$0040,$0080        ; 8x16, 16x16, 16x32



TypePointers:       ; Pointers to the routines for each ExAnimation type.
    dw NotUsed                      ; Not Used
    dw Type_Line                    ; 1 8x8: line
    dw Type_Line                    ; 2 8x8s: line
    dw Type_Line                    ; 3 8x8s: line
    dw Type_Line                    ; 4 8x8s: line
    dw Type_Line                    ; 5 8x8s: line
    dw Type_Line                    ; 6 8x8s: line
    dw Type_Line                    ; 7 8x8s: line
    dw Type_Line                    ; 8 8x8s: line
    dw Type_Line                    ; 0x0C 8x8s: line
    dw Type_Line                    ; 0x10 8x8s: line
    dw Type_Line                    ; 0x14 8x8s: line
    dw Type_Line                    ; 0x18 8x8s: line
    dw Type_Line                    ; 0x1C 8x8s: line
    dw Type_Line                    ; 0x20 8x8s: line
    dw Type_Line                    ; 1 8x8 2bpp
    dw Type_Stacked                 ; 2 8x8s: stacked
    dw Type_Stacked                 ; 4 8x8s: 16x16
    dw Type_Stacked                 ; 8 8x8s: 32x16
    dw Type_Palette                 ; Palette
    dw Type_PaletteWorking          ; Palette + Working
    dw Type_PaletteWorkingNoFade    ; Palette + Working, Stop on Fade
    dw Type_BgColor                 ; Palette Back Area Color
    dw Type_BgColorNoFade           ; Palette Back Area Color, Stop on Fade
    dw Type_PaletteR                ; Palette Rotate Right
    dw Type_PaletteRRev             ; Palette Rotate Right, Rev on Trigger
    dw Type_PaletteL                ; Palette Rotate Left
    dw Type_PaletteLRev             ; Palette Rotate Left, Rev on Trigger

TriggerPointers:    ; Pointers to the routines for each ExAnimation trigger. Return 0 = off, 1 = on.
    dw NotUsed                      ; None
    dw Trigger_BluePow              ; Blue p-switch
    dw Trigger_SilverPow            ; Silver p-switch
    dw Trigger_OnOff                ; On/Off
    dw Trigger_Star                 ; Star power
    dw Trigger_Timer                ; Timer < 100
    dw Trigger_TimerOneShot         ; Timer < 100 one shot
    dw Trigger_YCoins               ; >= 5 Yoshi coins
    dw Trigger_YCoinsOneShot        ; >= 5 Yoshi coins one shot
    dw NotUsed                      ; (unused)
    dw NotUsed                      ; (unused)
    dw NotUsed                      ; (unused)
    dw NotUsed                      ; (unused)
    dw NotUsed                      ; (unused)
    dw NotUsed                      ; (unused)
    dw Trigger_PrecisionPalette     ; Precision timer palette rotate
    dw Trigger_Manual0              ; Manual 0
    dw Trigger_Manual1              ; Manual 1
    dw Trigger_Manual2              ; Manual 2
    dw Trigger_Manual3              ; Manual 3
    dw Trigger_Manual4              ; Manual 4
    dw Trigger_Manual5              ; Manual 5
    dw Trigger_Manual6              ; Manual 6
    dw Trigger_Manual7              ; Manual 7
    dw Trigger_Manual8              ; Manual 8
    dw Trigger_Manual9              ; Manual 9
    dw Trigger_ManualA              ; Manual A
    dw Trigger_ManualB              ; Manual B
    dw Trigger_ManualC              ; Manual C
    dw Trigger_ManualD              ; Manual D
    dw Trigger_ManualE              ; Manual E
    dw Trigger_ManualF              ; Manual F
    dw Trigger_Custom0              ; Custom 0
    dw Trigger_Custom1              ; Custom 1
    dw Trigger_Custom2              ; Custom 2
    dw Trigger_Custom3              ; Custom 3
    dw Trigger_Custom4              ; Custom 4
    dw Trigger_Custom5              ; Custom 5
    dw Trigger_Custom6              ; Custom 6
    dw Trigger_Custom7              ; Custom 7
    dw Trigger_Custom8              ; Custom 8
    dw Trigger_Custom9              ; Custom 9
    dw Trigger_CustomA              ; Custom A
    dw Trigger_CustomB              ; Custom B
    dw Trigger_CustomC              ; Custom C
    dw Trigger_CustomD              ; Custom D
    dw Trigger_CustomE              ; Custom E
    dw Trigger_CustomF              ; Custom F
    dw Trigger_OneShot0             ; One shot 0
    dw Trigger_OneShot0             ; One shot 1
    dw Trigger_OneShot0             ; One shot 2
    dw Trigger_OneShot0             ; One shot 3
    dw Trigger_OneShot0             ; One shot 4
    dw Trigger_OneShot0             ; One shot 5
    dw Trigger_OneShot0             ; One shot 6
    dw Trigger_OneShot0             ; One shot 7
    dw Trigger_OneShot1             ; One shot 8
    dw Trigger_OneShot1             ; One shot 9
    dw Trigger_OneShot1             ; One shot A
    dw Trigger_OneShot1             ; One shot B
    dw Trigger_OneShot1             ; One shot C
    dw Trigger_OneShot1             ; One shot D
    dw Trigger_OneShot1             ; One shot E
    dw Trigger_OneShot1             ; One shot F
    dw Trigger_OneShot2             ; One shot 10
    dw Trigger_OneShot2             ; One shot 11
    dw Trigger_OneShot2             ; One shot 12
    dw Trigger_OneShot2             ; One shot 13
    dw Trigger_OneShot2             ; One shot 14
    dw Trigger_OneShot2             ; One shot 15
    dw Trigger_OneShot2             ; One shot 16
    dw Trigger_OneShot2             ; One shot 17
    dw Trigger_OneShot3             ; One shot 18
    dw Trigger_OneShot3             ; One shot 19
    dw Trigger_OneShot3             ; One shot 1A
    dw Trigger_OneShot3             ; One shot 1B
    dw Trigger_OneShot3             ; One shot 1C
    dw Trigger_OneShot3             ; One shot 1D
    dw Trigger_OneShot3             ; One shot 1E
    dw Trigger_OneShot3             ; One shot 1F

MainVersion:
    db "LM" : dw $0102

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF

;=======================================================================

if !sa1
    ; Extra routine exclusive to SA-1 for moving a four byte code from $7E0003 to $7FC020.
    ;  Used to copy palettes from the alternate ExGFX file to $0703/$0905.
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

org $03FE00
; Flags for disabling ExAnimations in each level, from LM's "Edit Animation Settings" dialog.
LevelAnimationSettings:
    for i = 0..$200 : db $00 : endfor

;=======================================================================

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
; 24-bit pointers to each level's ExAnimation data. If upper 16-bits = 0000, level does not have any.
; Format for the actual data is identical to the global animation data above.
LevelExAnimationPointers:
    for i = 0..$200 : dl $000000 : endfor