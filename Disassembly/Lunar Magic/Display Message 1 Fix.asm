; Routine to fix the Display Message 1 sprite.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

!enable_SaveAfterIntro  =   0
    ; Flag for the overworld option in Lunar Magic:
    ;  "Save game after intro message even if map start position changed"

!enable_OldSprite19Fix  =   0
    ; Flag for installing LM's old Display Message 1 fix.
    ;  No longer necessary, though.

;=======================================================================

org $05B15D ; disable intro march
    NOP #3

org $01E762
    NOP
    JSL FixSprite19
    NOP

org $03BCA0
FixSprite19:
    LDA $0109
    BEQ .notIntroLevel
    LDA $009EF0         ; initial submap for Mario
    STA $1F11|!addr
    STA $1FB8|!addr
    if !enable_SaveAfterIntro
        JSL $009BC9     ; save routine
    else
        RTL
        dl $009BC9
    endif
  .notIntroLevel:
    RTL
    
if !enable_OldSprite19Fix
    org $00A0A0
        NOP #3
endif