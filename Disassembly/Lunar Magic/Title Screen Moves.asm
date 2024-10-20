; Code for the modified title screen moves data format.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!enable_Recording       =   0
    ; flag for whether or not to include the recording ASM

;== used regardless of if recording is enabled
!RAM_DataPosition       =   $7FFFFE
    ; 2 bytes for current index to the input data, when playing back

;== only used if recording is enabled
!RAM_RecordingData      =   $7F0000
    ; Data block used to store the recorded input data. No fixed size.

!RAM_RecordingPosition  =   $7FFFF8
    ; 2 bytes, for current index to the input data, when recording
    
!RAM_PreviousInput      =   $7FFFFA
    ; 2 bytes, for last frame's input.

!RAM_IsRecording        =   $7FFFFC
    ; 1 byte, to track if recording has already started. Set to #$42 if so.

;=======================================================================

org $009C6F ; game mode 07 (title screen moves)
    autoclean JSL GetInput
    CMP #$FF
    BEQ .reset
    JMP $00A1DA

  .reset:
    LDY #$02
    STY $0100|!addr
    RTS
    
;=======================================================================

freecode
prot InputData

GetInput:
    PHP
    REP #$20
    LDX $1DF4|!addr
    BNE .doneInit
    LDA #$0000
    STA.l !RAM_DataPosition
    LDX #$01
    STX $1DF4|!addr
  .doneInit:
    REP #$10
    LDA.l !RAM_DataPosition
    TAX
    SEP #$20
    DEC $1DF5|!addr
    BNE .notNextInput
    LDA InputData+2,x   ; get timer for input
    STA $1DF5|!addr
    INX #3
    REP #$20
    TXA
    STA.l !RAM_DataPosition
    SEP #$20
  .notNextInput:
    LDA InputData-3,x
    CMP #$FF            ; byte 1 being FF indicates end of data
    BEQ .return
    STA $15
    AND #$3F
    STA $16
    LDA InputData-2,x
    TAY
    ASL #4
    AND #$C0
    ORA $16
    STA $16
    TYA
    AND #$B0
    STA $17
    TYA
    ASL
    AND #$80
    STA $18
  .return:
    PLP
    RTL


freedata
; Data format:
;  Byte 0: |bySs^v<>| stored to $15, [Ss^v<>] copied to $16.
;  Byte 1: |aAlrby--| [alr] stored to $17, [by] stored to $16, [A] stored to $18.
;  Byte 2: timer
InputData:
    db $FF

;=======================================================================

if !enable_Recording
    org $00A1DA ; game mode 14 (normal level)
        autoclean JSL RecordInputs
        BEQ +
        RTS
        NOP #3
      +
      
    org $05D79B ; level load
        JSL StartRecording
        NOP #2
        
    freecode
    RecordInputs:
        PHP
        LDA $15
        STA.l !RAM_PreviousInput+1 ; holding byetUDLR (b = A or B, y = X or Y)
        LDA $16
        AND #$C0
        LSR #4
        STA.l !RAM_PreviousInput    ; pressed ----by-- (y = X or Y)
        LDA $17
        AND #$B0
        ORA.l !RAM_PreviousInput    ; holding a-lr----
        STA.l !RAM_PreviousInput
        LDA $18
        AND #$80
        LSR
        ORA.l !RAM_PreviousInput    ; pressed -A------
        STA.l !RAM_PreviousInput
        REP #$30
        LDA #$0042
        CMP.l !RAM_IsRecording
        BEQ .alreadyRecording
      .initRecording:
        STA.l !RAM_IsRecording
        LDA #$0000
        TAX
        BRA .startedRecording

      .alreadyRecording:
        LDA.l !RAM_RecordingPosition
        TAX
        SEP #$20
        LDA.l !RAM_RecordingData,x
        CMP.l !RAM_PreviousInput+1
        BNE .recordNewInput
        LDA.l !RAM_RecordingData+1,x
        CMP.l !RAM_PreviousInput
        BNE .recordNewInput
        LDA.l !RAM_RecordingData+2,x
        BEQ .recordNewInput ; safeguard for input timer > 255
        INC
        STA.l !RAM_RecordingData+2,x ; input hasn't changed, add 1 frame to timer
        BRA .notEndOfData

      .recordNewInput:
        INX #3
        REP #$20
        TXA
      .startedRecording:
        STA.l !RAM_RecordingPosition ; update recording pointer
        SEP #$20
        LDA.l !RAM_PreviousInput+1   ; store the input's data
        STA.l !RAM_RecordingData,x
        LDA.l !RAM_PreviousInput
        STA.l !RAM_RecordingData+1,x
        LDA #$01
        STA.l !RAM_RecordingData+2,x ; initialize timer to 1 frame
        LDA #$FF
        STA.l !RAM_RecordingData+3,x ; end sentinel
      .notEndOfData:
        PLP
        LDA $1426|!addr ; restore code
        BEQ .return
        PHA
        JSL $05B10C
        PLA
        CMP #$00
      .return:
        RTL


    StartRecording:
        PHP
        REP #$20
        LDA #$0000  ; initialize recording flag
        STA.l !RAM_IsRecording
        PLP
        STZ $13CF|!addr ; restore code
        LDA $1B95|!addr
        RTL

elseif read1($00A1DA) == $22
    ; unpatch recording ASM, restore original code
    autoclean read3($00A1DA+1)
    
    org $00A1DA
        LDA $1426|!addr
        BEQ +
        JSL $05B10C
        RTS
    +

    org $05D79B
        STZ $13CF|!addr
        LDA $1B95|!addr
endif