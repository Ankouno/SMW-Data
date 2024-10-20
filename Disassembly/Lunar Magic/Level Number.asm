; Code added by Lunar Magic to set up the level number in both $010B and $FE.
; Also handles the high byte of the level number on entry from the overworld.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!RAM_LevelNum       =   $FE
    ; 16-bit level number, +1. Set to 0000 for No-Yoshi entrance.

!RAM_HeaderByte8    =   $13CD|!addr
    ; Secondary header byte 8, from $06FE00.

;=======================================================================

org $05D8B1		; entering level from overworld
    JSL GetLevelHighByte
	
org $05D8E2     ; loading normal level
    JSL TrackLevelNumber

org $00A6B8     ; loading no-Yoshi entrance
    JSL LoadingNoYoshi

;=========================================

org $05DCD0
GetLevelHighByte:
    TAY
    LDA $0109|!addr ; if loading a special level (e.g. intro), use vanilla behavior (based on submap ID)
    BEQ .noOverride
    TYA
    BEQ .return
    LDA #$01
  .return:
    RTL

  .noOverride:  	; get high bit based on translevel ID; 00-24 = 000-024, 25-5F = 101-13B
    TAY
    LDA $13BF|!addr
    CMP #$25
    BCC .below100
    SBC #$24
    INY
  .below100:
    STA $17BB|!addr
    STA $0E
    TYA
    RTL


org $0EF550
TrackLevelNumber:
    LDA $0E
    STA $010B|!addr
    INC
    STA !RAM_LevelNum
    DEC
    ASL
    TAY
    RTL

org $0EF560
LoadingNoYoshi:
    STZ !RAM_HeaderByte8
    STZ !RAM_LevelNum
    STZ !RAM_LevelNum+1
    STY $76     ; restore code
    STY $89
    RTL