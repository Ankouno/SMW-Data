; Code used by LM to implement the "show save prompt" overworld level flag.
;=======================================================================
!addr = $0000
!RAM_OWLevelNums = $7ED000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
    !RAM_OWLevelNums = $40D000
endif
;=======================================================================

!enable_SeparatePlayerPositions     =   0
    ; flag for the overworld option in Lunar Magic:
    ;  "Save Luigi's map position in saved games instead of saving a copy of Mario's"

;=======================================================================

; checking whether to open a save prompt after beating a level
org $048F8A
    JSL CheckForSavePrompt
    NOP
  TileCheckLoop:

org $049001 ; fix branch for the original routine's tile loop
    BPL TileCheckLoop

if !enable_SeparatePlayerPositions
    org $048F9F
        BRA +
    org $048FDC : +
else
    org $048F9F
        REP #$30
endif

;=======================================================================

org $03BA10
CheckForSavePrompt: ; $04 = index to level tile the player is on
    PHP
    REP #$30
    LDX $04
    LDA !RAM_OWLevelNums,x
    AND #$00FF
    TAX
    LDA $1EA2|!addr,x
    AND #$0010
    BNE .savePromptFlagEnabled
    LDA #$0001
    BEQ .unused
    LDA $13C1|!addr ; restore code
  .return:
    LDX #$0007
    PLP
    RTL

  .savePromptFlagEnabled:
    LDA #$0080
    BRA .return

  .unused:      ; seems to be some unused second flag for the save prompt?
    LDA #$00FF
    BRA .return