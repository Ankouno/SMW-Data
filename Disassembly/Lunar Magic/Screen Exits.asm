; Expands the screen exit settings to also load from $19D8.
;=======================================================================
!addr = $0000
if read1($00FFD5) == $23
    sa1rom
    !addr = $6000
endif
;=======================================================================

org $05D7CE
    JSL ParseScreenExit
    
org $05DC50
ParseScreenExit:        ; Input: X = screen number. Output: A = high byte of destination level.
    LDA $19D8|!addr,x   ; New high byte of screen exit: HHHHwush
    BIT #$04            ;  u bit = flag for whether to use the new system (1) or original (0)
    BEQ .vanilla
    PHA
    PHA
    AND #$02            ;  s bit = flag for secondary exit
    LSR
    STA $1B93|!addr
    PLA
    AND #$08            ;  w bit = water *OR* midway flag
    ASL #3
    STA $192A|!addr
    PLA
    LSR                 ; HHHHh = high byte of destination level
    PHP
    LSR #3
    PLP
    ROL
    RTL

  .vanilla:         ; vanilla system: destination level high bit is based on whether current level is 0xx or 1xx
    STZ $192A|!addr
    LDA $13BF|!addr
    CMP #$25
    LDA #$00
    ROL
    RTL

;=======================================================================

org $05DBC2     ; fix the bonus game and Yoshi Wings, to account for the modified system
    JSL $03BB00
    NOP #2

org $03BB00
    STA $19B8|!addr,x
    STZ $19D8|!addr,x
    STZ $1B93|!addr
    INC $141A|!addr
    RTL