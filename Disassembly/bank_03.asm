.BANK3

DATA_038000:                    ;$038000    | Sound effects for Mario bouncing off a Rex or killing it with star power.
    db $13,$14,$15,$16,$17,$18,$19



DATA_038007:                    ;$038007    | X speeds to add to the football's speed when bouncing off each slope type (see $15B8 for the order).
    db $F0,$F8,$FC,$00,$04,$08,$10

DATA_03800E:                    ;$03800E    | Y speeds to randomly give the football when bouncing.
    db $A0,$D0,$C0,$D0

    ; Football misc RAM:
    ; $1540 - Timer for waiting to be kicked by a Puntin' Chuck after spawn.
    ; $1602 - Animation frame. Always 0.
    
Football:                       ;-----------| Football MAIN
    JSL GenericSprGfxRt2        ;$038012    | Draw a 16x16 sprite.
    LDA $9D                     ;$038016    |\ Return if game frozen.
    BNE Return038086            ;$038018    |/
    JSR SubOffscreen0Bnk3       ;$03801A    | Process offscreen from -$40 to +$30.
    JSL SprSprPMarioSprRts      ;$03801D    | Process interaction with Mario and other sprites.
    LDA.w $1540,X               ;$038021    |\ 
    BEQ CODE_03802D             ;$038024    ||
    DEC A                       ;$038026    || If not waiting to be kicked by a Chuck, update X/Y position, apply gravity, and process interaction with blocks.
    BNE CODE_038031             ;$038027    || If it was just kicked, also display a contact sprite.
    JSL DispContactSpr          ;$038029    ||
CODE_03802D:                    ;           ||
    JSL UpdateSpritePos         ;$03802D    |/
CODE_038031:                    ;           |
    LDA.w $1588,X               ;$038031    |\ 
    AND.b #$03                  ;$038034    ||
    BEQ CODE_03803F             ;$038036    ||
    LDA $B6,X                   ;$038038    || If the sprite hits a wall, invert its X speed.
    EOR.b #$FF                  ;$03803A    ||
    INC A                       ;$03803C    ||
    STA $B6,X                   ;$03803D    |/
CODE_03803F:                    ;           |
    LDA.w $1588,X               ;$03803F    |\ 
    AND.b #$08                  ;$038042    || If the sprite hits a ceiling, clear its Y speed.
    BEQ CODE_038048             ;$038044    ||
    STZ $AA,X                   ;$038046    |/
CODE_038048:                    ;           |
    LDA.w $1588,X               ;$038048    |\ 
    AND.b #$04                  ;$03804B    ||
    BEQ Return038086            ;$03804D    || Return if not hitting the ground, or still waiting to be kicked.
    LDA.w $1540,X               ;$03804F    ||
    BNE Return038086            ;$038052    |/
    LDA.w $15F6,X               ;$038054    |\ 
    EOR.b #$40                  ;$038057    || Horizontally flip the sprite.
    STA.w $15F6,X               ;$038059    |/
    JSL GetRand                 ;$03805C    |\ 
    AND.b #$03                  ;$038060    ||
    TAY                         ;$038062    || Give random Y speed.
    LDA.w DATA_03800E,Y         ;$038063    ||
    STA $AA,X                   ;$038066    |/
    LDY.w $15B8,X               ;$038068    |\ 
    INY                         ;$03806B    ||
    INY                         ;$03806C    ||
    INY                         ;$03806D    || Add an X speed depending on the type of slope the football is bouncing off of.
    LDA.w DATA_038007,Y         ;$03806E    ||
    CLC                         ;$038071    ||
    ADC $B6,X                   ;$038072    ||
    BPL CODE_03807E             ;$038074    ||
    CMP.b #$E0                  ;$038076    ||\\ Maximum X speed leftwards (1).
    BCS CODE_038084             ;$038078    |||
    LDA.b #$E0                  ;$03807A    |||| Maximum X speed leftwards (2).
    BRA CODE_038084             ;$03807C    |||
CODE_03807E:                    ;           |||
    CMP.b #$20                  ;$03807E    |||| Maximum X speed rightwards (1).
    BCC CODE_038084             ;$038080    |||
    LDA.b #$20                  ;$038082    ||// Maximum X speed rightwards (2).
CODE_038084:                    ;           ||
    STA $B6,X                   ;$038084    |/
Return038086:                   ;           |
    RTS                         ;$038086    |





    ; Big Boo Boss misc RAM:
    ; $C2   - Phase pointer.
    ;          0 = stopped before fading in, 1 = fading in, 2 = floating around (visible),
    ;          3 = hurt, 4 = fading out, 5 = floating around (invisible), 6 = dying
    ; $151C - Direction of horizontal acceleration. Even = left, odd = right
    ; $1528 - Direction of vertical acceleration. Even = down, odd = up
    ; $1534 - Counter for the number of hits the boss has taken.
    ; $1540 - Phase timer for phase 3 and 5, as well as a timer for switching palettes during fade in/out.
    ; $1570 - Frame counter when waiting to fade back in.
    ; $157C - Horizontal direction the sprite is facing. 0 = right, 1 = left.
    ; $15AC - Timer for turning around.
    ; $1602 - Animation frame.
    ;          0 = normal, 1/2 = turning, 3 = eyes covered
    
BigBooBoss:                     ;-----------| Big Boo Boss MAIN
    JSL CODE_038398             ;$038087    | Draw GFX.
    JSL CODE_038239             ;$03808B    | Handle the palette fade effect.
    LDA.w $14C8,X               ;$03808F    |\ 
    BNE CODE_0380A2             ;$038092    || If no longer in existence, end the level.
    INC.w $13C6                 ;$038094    ||
    LDA.b #$FF                  ;$038097    ||\ Set end timer.
    STA.w $1493                 ;$038099    ||/
    LDA.b #$0B                  ;$03809C    ||\ SFX/music played after beating a Big Boo Boss.
    STA.w $1DFB                 ;$03809E    ||/
    RTS                         ;$0380A1    |/

CODE_0380A2:                    ;```````````| Big Boo is still alive.
    CMP.b #$08                  ;$0380A2    |\ 
    BNE Return0380D4            ;$0380A4    || Return if dying or game frozen.
    LDA $9D                     ;$0380A6    ||
    BNE Return0380D4            ;$0380A8    |/
    LDA $C2,X                   ;$0380AA    |
    JSL ExecutePtr              ;$0380AC    |

BooBossPtrs:                    ;$0380B0    | Big Boo Boss phase pointers.
    dw CODE_0380BE              ; 0 - Stopped before fading in
    dw CODE_0380D5              ; 1 - Fading in
    dw CODE_038119              ; 2 - Floating around (visible)
    dw CODE_03818B              ; 3 - Hurt
    dw CODE_0381BC              ; 4 - Fading out
    dw CODE_038106              ; 5 - Floating around (invisible)
    dw CODE_0381D3              ; 6 - Dying



CODE_0380BE:                    ;-----------| Big Boo Boss phase 0 - Stopped before fading in.
    LDA.b #$03                  ;$0380BE    |\ Animation frame for pausing before fading in.
    STA.w $1602,X               ;$0380C0    |/
    INC.w $1570,X               ;$0380C3    |\ 
    LDA.w $1570,X               ;$0380C6    || Return if not time to start fading in.
    CMP.b #$90                  ;$0380C9    ||
    BNE Return0380D4            ;$0380CB    |/
    LDA.b #$08                  ;$0380CD    |\ Prep timer for fading in.
    STA.w $1540,X               ;$0380CF    |/
    INC $C2,X                   ;$0380D2    |
Return0380D4:                   ;           |
    RTS                         ;$0380D4    |



CODE_0380D5:                    ;-----------| Big Boo Boss phase 1 - Fading in
    LDA.w $1540,X               ;$0380D5    |\ Return if not time to increment the change the palette.
    BNE Return0380F9            ;$0380D8    |/
    LDA.b #$08                  ;$0380DA    |\\ How quickly the palette changes when fading in.
    STA.w $1540,X               ;$0380DC    |/
    INC.w $190B                 ;$0380DF    |\ 
    LDA.w $190B                 ;$0380E2    ||
    CMP.b #$02                  ;$0380E5    || Handle incrementing the palette index.
    BNE CODE_0380EE             ;$0380E7    ||
    LDY.b #$10                  ;$0380E9    ||\ SFX for the Big Boo Boss reappearing.
    STY.w $1DF9                 ;$0380EB    |//
CODE_0380EE:                    ;           |
    CMP.b #$07                  ;$0380EE    |\ Return if not done fading.
    BNE Return0380F9            ;$0380F0    |/
    INC $C2,X                   ;$0380F2    | Increment phase pointer.
    LDA.b #$40                  ;$0380F4    |\ Unused?
    STA.w $1540,X               ;$0380F6    |/
Return0380F9:                   ;           |
    RTS                         ;$0380F9    |



DATA_0380FA:                    ;$0380FA    | X accelerations for the Big Boo Boss.
    db $FF,$01

DATA_0380FC:                    ;$0380FC    | Max X speeds for the Big Boo Boss.
    db $F0,$10

DATA_0380FE:                    ;$0380FE    | Max Y speeds for the Big Boo Boss.
    db $0C,$F4

DATA_038100:                    ;$038100    | Y accelerations for the Big Boo Boss.
    db $01,$FF

DATA_038102:                    ;$038102    | Animation frames for the Big Boo Boss's turning animation.
    db $01,$02,$02,$01

CODE_038106:                    ;-----------| Big Boo Boss phase 5 - Floating around (while invisible)
    LDA.w $1540,X               ;$038106    |\ 
    BNE CODE_038112             ;$038109    || If done floating around, return to phase 0.
    STZ $C2,X                   ;$03810B    ||
    LDA.b #$40                  ;$03810D    ||| Initial frame counter value for waiting to fade back in (this is dumb, Nintendo).
    STA.w $1570,X               ;$03810F    |/
CODE_038112:                    ;           |
    LDA.b #$03                  ;$038112    |\ Animation frame for the Boo while floating around.
    STA.w $1602,X               ;$038114    |/
    BRA CODE_03811F             ;$038117    |


CODE_038119:                    ;-----------| Big Boo Boss phase 2 - Floating around (while visible)
    STZ.w $1602,X               ;$038119    | Use animation frame 0.
    JSR CODE_0381E4             ;$03811C    | Process interaction with thrown sprites.
CODE_03811F:                    ;           |
    LDA.w $15AC,X               ;$03811F    |\ 
    BNE CODE_038132             ;$038122    ||
    JSR SubHorzPosBnk3          ;$038124    ||
    TYA                         ;$038127    || If not already turning, check whether the Boo needs to turn towards Mario.
    CMP.w $157C,X               ;$038128    ||
    BEQ CODE_03814A             ;$03812B    ||
    LDA.b #$1F                  ;$03812D    ||\\ How long it takes the Big Boo Boss to turn.
    STA.w $15AC,X               ;$03812F    ||/
CODE_038132:                    ;           ||
    CMP.b #$10                  ;$038132    ||\ 
    BNE CODE_038140             ;$038134    |||
    PHA                         ;$038136    |||
    LDA.w $157C,X               ;$038137    ||| If the boss is currently in the middle of a turn, actually invert his direction.
    EOR.b #$01                  ;$03813A    |||
    STA.w $157C,X               ;$03813C    |||
    PLA                         ;$03813F    ||/
CODE_038140:                    ;           ||
    LSR                         ;$038140    ||\ 
    LSR                         ;$038141    |||
    LSR                         ;$038142    ||| Get animation frame for the turning animation.
    TAY                         ;$038143    |||
    LDA.w DATA_038102,Y         ;$038144    |||
    STA.w $1602,X               ;$038147    |//
CODE_03814A:                    ;           |
    LDA $14                     ;$03814A    |\ 
    AND.b #$07                  ;$03814C    ||
    BNE CODE_038166             ;$03814E    ||
    LDA.w $151C,X               ;$038150    ||
    AND.b #$01                  ;$038153    || Every 8 frames, update X speed.
    TAY                         ;$038155    ||
    LDA $B6,X                   ;$038156    || If at the max X speed in the current direction,
    CLC                         ;$038158    ||  invert the direction of horizontal acceleration.
    ADC.w DATA_0380FA,Y         ;$038159    ||
    STA $B6,X                   ;$03815C    ||
    CMP.w DATA_0380FC,Y         ;$03815E    ||
    BNE CODE_038166             ;$038161    ||
    INC.w $151C,X               ;$038163    |/
CODE_038166:                    ;           |
    LDA $14                     ;$038166    |\ 
    AND.b #$07                  ;$038168    ||
    BNE CODE_038182             ;$03816A    ||
    LDA.w $1528,X               ;$03816C    ||
    AND.b #$01                  ;$03816F    || Every 8 frames, update Y speed.
    TAY                         ;$038171    ||
    LDA $AA,X                   ;$038172    || If at the max Y speed in the current direction,
    CLC                         ;$038174    ||  invert the direction of vertical acceleration.
    ADC.w DATA_038100,Y         ;$038175    ||
    STA $AA,X                   ;$038178    ||
    CMP.w DATA_0380FE,Y         ;$03817A    ||
    BNE CODE_038182             ;$03817D    ||
    INC.w $1528,X               ;$03817F    |/
CODE_038182:                    ;           |
    JSL UpdateXPosNoGrvty       ;$038182    | Update X position.
    JSL UpdateYPosNoGrvty       ;$038186    | Update Y position.
    RTS                         ;$03818A    |



CODE_03818B:                    ;-----------| Big Boo Boss phase 3 - Hurt
    LDA.w $1540,X               ;$03818B    |\ Branch if not done with the hurt animation.
    BNE CODE_0381AE             ;$03818E    |/
    INC $C2,X                   ;$038190    | Increment phase pointer to 4 (fade out).
    LDA.b #$08                  ;$038192    |\ Prep timer for fading out.
    STA.w $1540,X               ;$038194    |/
    JSL LoadSpriteTables        ;$038197    | Reload Tweaker bits...?
    INC.w $1534,X               ;$03819B    |\ 
    LDA.w $1534,X               ;$03819E    || Return if the boss hasn't been killed.
    CMP.b #$03                  ;$0381A1    ||| Amount of HP the Big Boo Boss has.
    BNE Return0381AD            ;$0381A3    |/
    LDA.b #$06                  ;$0381A5    |\ Switch phase point to 6 (dying).
    STA $C2,X                   ;$0381A7    |/
    JSL KillMostSprites         ;$0381A9    | Make other sprites poof in a cloud of smoke.
Return0381AD:                   ;           |
    RTS                         ;$0381AD    |

CODE_0381AE:                    ;```````````| Not done with the hurt animation.
    AND.b #$0E                  ;$0381AE    |\ 
    EOR.w $15F6,X               ;$0381B0    || Make the boss flash palettes.
    STA.w $15F6,X               ;$0381B3    |/
    LDA.b #$03                  ;$0381B6    |\\ Animation frame for the Big Boo Boss's hurt animation.
    STA.w $1602,X               ;$0381B8    |/
    RTS                         ;$0381BB    |



CODE_0381BC:                    ;-----------| Big Boo Boss phase 4 - Fading out
    LDA.w $1540,X               ;$0381BC    |\ Return if not time to increment the change the palette.
    BNE Return0381D2            ;$0381BF    |/
    LDA.b #$08                  ;$0381C1    |\\ How quickly the palette changes when fading in.
    STA.w $1540,X               ;$0381C3    |/
    DEC.w $190B                 ;$0381C6    |\ Decrement the palette index, and return if not done doing so.
    BNE Return0381D2            ;$0381C9    |/
    INC $C2,X                   ;$0381CB    | Increment phase pointer to 5 (floating around, invisible). 
    LDA.b #$C0                  ;$0381CD    |\\ How long the Big Boo floats around while invisible.
    STA.w $1540,X               ;$0381CF    |/
Return0381D2:                   ;           |
    RTS                         ;$0381D2    |



CODE_0381D3:                    ;-----------| Big Boo Boss phase 6 - Dying
    LDA.b #$02                  ;$0381D3    |\ Set sprite status as 02 (falling offscreen).
    STA.w $14C8,X               ;$0381D5    |/
    STZ $B6,X                   ;$0381D8    | Clear X speed.
    LDA.b #$D0                  ;$0381DA    |\\ How quickly the Big Boo Boss falls after dying.
    STA $AA,X                   ;$0381DC    |/
    LDA.b #$23                  ;$0381DE    |\ SFX for the Big Boo Boss dying.
    STA.w $1DF9                 ;$0381E0    |/
    RTS                         ;$0381E3    |



CODE_0381E4:                    ;-----------| Subroutine to handle interaction between the Big Boo Boss and thrown sprites.
    LDY.b #$0B                  ;$0381E4    |\ 
CODE_0381E6:                    ;           ||
    LDA.w $14C8,Y               ;$0381E6    ||
    CMP.b #$09                  ;$0381E9    ||
    BEQ CODE_0381F5             ;$0381EB    ||
    CMP.b #$0A                  ;$0381ED    || Find a sprite either in state 9 (carryable) or state A (thrown).
    BEQ CODE_0381F5             ;$0381EF    ||
CODE_0381F1:                    ;           ||
    DEY                         ;$0381F1    ||
    BPL CODE_0381E6             ;$0381F2    ||
    RTS                         ;$0381F4    |/
CODE_0381F5:                    ;           |
    PHX                         ;$0381F5    |
    TYX                         ;$0381F6    |
    JSL GetSpriteClippingB      ;$0381F7    |\ 
    PLX                         ;$0381FB    || Continue searching for a sprite if not in contact.
    JSL GetSpriteClippingA      ;$0381FC    ||  Else, continue below to hurt the boss.
    JSL CheckForContact         ;$038200    ||
    BCC CODE_0381F1             ;$038204    |/
    LDA.b #$03                  ;$038206    |\ Switch to the hurt animation phase.
    STA $C2,X                   ;$038208    |/
    LDA.b #$40                  ;$03820A    |\\ How long the Big Boo Boss stays hurt for.
    STA.w $1540,X               ;$03820C    |/
    PHX                         ;$03820F    |
    TYX                         ;$038210    |\ Erase the thrown sprite. 
    STZ.w $14C8,X               ;$038211    |/
    LDA $E4,X                   ;$038214    |\ 
    STA $9A                     ;$038216    ||
    LDA.w $14E0,X               ;$038218    ||
    STA $9B                     ;$03821B    ||
    LDA $D8,X                   ;$03821D    ||
    STA $98                     ;$03821F    ||
    LDA.w $14D4,X               ;$038221    || Create shatter particles at the sprite's position.
    STA $99                     ;$038224    ||
    PHB                         ;$038226    ||
    LDA.b #$02                  ;$038227    ||
    PHA                         ;$038229    ||
    PLB                         ;$03822A    ||
    LDA.b #$FF                  ;$03822B    ||
    JSL ShatterBlock            ;$03822D    ||
    PLB                         ;$038231    ||
    PLX                         ;$038232    |/
    LDA.b #$28                  ;$038233    |\ SFX for hurting the Big Boo Boss.
    STA.w $1DFC                 ;$038235    |/
    RTS                         ;$038238    |



CODE_038239:                    ;-----------| Routine to handle the palette fade effect for the Big Boo Boss and reappearing ghosts.
    LDY.b #$24                  ;$038239    |\\ Disable color math on sprites.
    STY $40                     ;$03823B    ||/
    LDA.w $190B                 ;$03823D    || 
    CMP.b #$08                  ;$038240    || Get index to the current palette,
    DEC A                       ;$038242    ||  and enable color math if not at the full palette.
    BCS CODE_03824A             ;$038243    ||
    LDY.b #$34                  ;$038245    ||\ Enable color math on sprites.
    STY $40                     ;$038247    ||/
    INC A                       ;$038249    ||
CODE_03824A:                    ;           ||
    ASL                         ;$03824A    ||
    ASL                         ;$03824B    ||
    ASL                         ;$03824C    ||
    ASL                         ;$03824D    ||
    TAX                         ;$03824E    |/
    STZ $00                     ;$03824F    |
    LDY.w $0681                 ;$038251    |\ 
CODE_038254:                    ;           ||
    LDA.l BooBossPals,X         ;$038254    ||
    STA.w $0684,Y               ;$038258    ||
    INY                         ;$03825B    || Transfer the colors to the palette upload table in RAM.
    INX                         ;$03825C    ||
    INC $00                     ;$03825D    ||
    LDA $00                     ;$03825F    ||
    CMP.b #$10                  ;$038261    ||
    BNE CODE_038254             ;$038263    |/
    LDX.w $0681                 ;$038265    |\ 
    LDA.b #$10                  ;$038268    ||
    STA.w $0682,X               ;$03826A    || Set transfer as 16 bytes starting at palette F (i.e. full palette F).
    LDA.b #$F0                  ;$03826D    ||
    STA.w $0683,X               ;$03826F    |/
    STZ.w $0694,X               ;$038272    |
    TXA                         ;$038275    |
    CLC                         ;$038276    |\ 
    ADC.b #$12                  ;$038277    || Update the palette transfer index for any additional changes.
    STA.w $0681                 ;$038279    |/
    LDX.w $15E9                 ;$03827C    |
    RTL                         ;$03827F    |





BigBooDispX:                    ;$038280    | X position offsets for each of the Big Boo's tiles.
    db $08,$08,$20,$00,$00,$00,$00,$10
    db $10,$10,$10,$20,$20,$20,$20,$30
    db $30,$30,$30,$FD
    db $0C,$0C,$27,$00,$00,$00,$00,$10
    db $10,$10,$10,$1F,$20,$20,$1F,$2E
    db $2E,$2C,$2C,$FB
    db $12,$12,$30,$00,$00,$00,$00,$10
    db $10,$10,$10,$1F,$20,$20,$1F,$2E
    db $2E,$2E,$2E,$F8
    db $11,$FF,$08,$08,$00,$00,$00,$00
    db $10,$10,$10,$10,$20,$20,$20,$20
    db $30,$30,$30,$30

BigBooDispY:                    ;$0382D0    | Y position offsets for each of the Big Boo's tiles.
    db $12,$22,$18,$00,$10,$20,$30,$00
    db $10,$20,$30,$00,$10,$20,$30,$00
    db $10,$20,$30,$18
    db $16,$16,$12,$22,$00,$10,$20,$30
    db $00,$10,$20,$30,$00,$10,$20,$30
    db $00,$10,$20,$30

BigBooTiles:                    ;$0382F8    | Sprite tilemap for the Big Boo.
    db $C0,$E0,$E8,$80,$A0,$A0,$80,$82
    db $A2,$A2,$82,$84,$A4,$C4,$E4,$86
    db $A6,$C6,$E6,$E8
    db $C0,$E0,$E8,$80,$A0,$A0,$80,$82
    db $A2,$A2,$82,$84,$A4,$C4,$E4,$86
    db $A6,$C6,$E6,$E8
    db $C0,$E0,$E8,$80,$A0,$A0,$80,$82
    db $A2,$A2,$82,$84,$A4,$A4,$84,$86
    db $A6,$A6,$86,$E8
    db $E8,$E8,$C2,$E2,$80,$A0,$A0,$80
    db $82,$A2,$A2,$82,$84,$A4,$C4,$E4
    db $86,$A6,$C6,$E6

BigBooGfxProp:                  ;$038348    | YXPPCCCT settings for each of the Big Boo's tiles.
    db $00,$00,$40,$00,$00,$80,$80,$00
    db $00,$80,$80,$00,$00,$00,$00,$00
    db $00,$00,$00,$00
    db $00,$00,$40,$00,$00,$80,$80,$00
    db $00,$80,$80,$00,$00,$00,$00,$00
    db $00,$00,$00,$00
    db $00,$00,$40,$00,$00,$80,$80,$00
    db $00,$80,$80,$00,$00,$80,$80,$00
    db $00,$80,$80,$00
    db $00,$40,$00,$00,$00,$00,$80,$80
    db $00,$00,$80,$80,$00,$00,$00,$00
    db $00,$00,$00,$00

CODE_038398:                    ;-----------| Big Boo / normal Boo GFX routine.
    PHB                         ;$038398    |
    PHK                         ;$038399    |
    PLB                         ;$03839A    |
    JSR CODE_0383A0             ;$03839B    |
    PLB                         ;$03839E    |
    RTL                         ;$03839F    |

CODE_0383A0:
    LDA $9E,X                   ;$0383A0    |\ 
    CMP.b #$37                  ;$0383A2    || Branch if not the small Boo (i.e. Big Boo / Big Boo Boss).
    BNE CODE_0383C2             ;$0383A4    |/
    LDA.b #$00                  ;$0383A6    |\\ Animation frame when stationary.
    LDY $C2,X                   ;$0383A8    ||
    BEQ CODE_0383BA             ;$0383AA    ||
    LDA.b #$06                  ;$0383AC    ||| Animation frame when moving.
    LDY.w $1558,X               ;$0383AE    ||\ 
    BEQ CODE_0383BA             ;$0383B1    |||
    TYA                         ;$0383B3    |||
    AND.b #$04                  ;$0383B4    |||
    LSR                         ;$0383B6    ||| Animate the 'tongue out' animation if applicable (frames 2/3).
    LSR                         ;$0383B7    |||
    ADC.b #$02                  ;$0383B8    |||
CODE_0383BA:                    ;           |||
    STA.w $1602,X               ;$0383BA    |//
    JSL GenericSprGfxRt2        ;$0383BD    | Draw a 16x16.
    RTS                         ;$0383C1    |


CODE_0383C2:                    ;```````````| Big Boo / Big Boo Boss GFX routine.
    JSR GetDrawInfoBnk3         ;$0383C2    |
    LDA.w $1602,X               ;$0383C5    |\ 
    STA $06                     ;$0383C8    ||
    ASL                         ;$0383CA    ||
    ASL                         ;$0383CB    || $06 = animation frame
    STA $03                     ;$0383CC    || $03 = animation frame, x4
    ASL                         ;$0383CE    || $02 = animation frame, x20
    ASL                         ;$0383CF    ||
    ADC $03                     ;$0383D0    || $04 = horizontal direction
    STA $02                     ;$0383D2    || $05 = base YXPPCCCT
    LDA.w $157C,X               ;$0383D4    ||
    STA $04                     ;$0383D7    ||
    LDA.w $15F6,X               ;$0383D9    ||
    STA $05                     ;$0383DC    ||
    LDX.b #$00                  ;$0383DE    |/
CODE_0383E0:                    ;```````````| Big Boo tile loop.
    PHX                         ;$0383E0    |
    LDX $02                     ;$0383E1    |\ 
    LDA.w BigBooTiles,X         ;$0383E3    || Store tile number to OAM.
    STA.w $0302,Y               ;$0383E6    |/
    LDA $04                     ;$0383E9    |\ 
    LSR                         ;$0383EB    ||
    LDA.w BigBooGfxProp,X       ;$0383EC    ||
    ORA $05                     ;$0383EF    ||
    BCS CODE_0383F5             ;$0383F1    || Store YXPPCCCT to OAM.
    EOR.b #$40                  ;$0383F3    ||
CODE_0383F5:                    ;           ||
    ORA $64                     ;$0383F5    ||
    STA.w $0303,Y               ;$0383F7    |/
    LDA.w BigBooDispX,X         ;$0383FA    |\ 
    BCS CODE_038405             ;$0383FD    ||
    EOR.b #$FF                  ;$0383FF    ||
    INC A                       ;$038401    ||
    CLC                         ;$038402    ||
    ADC.b #$28                  ;$038403    || Store X position to OAM. If facing left, invert and offset the position.
CODE_038405:                    ;           ||
    CLC                         ;$038405    ||
    ADC $00                     ;$038406    ||
    STA.w $0300,Y               ;$038408    |/
    PLX                         ;$03840B    |
    PHX                         ;$03840C    |
    LDA $06                     ;$03840D    |\ 
    CMP.b #$03                  ;$03840F    ||
    BCC CODE_038418             ;$038411    ||
    TXA                         ;$038413    ||
    CLC                         ;$038414    ||
    ADC.b #$14                  ;$038415    ||
    TAX                         ;$038417    || Store Y position to OAM. If using frame 3, increment the index...?
CODE_038418:                    ;           ||
    LDA $01                     ;$038418    ||
    CLC                         ;$03841A    ||
    ADC.w BigBooDispY,X         ;$03841B    ||
    STA.w $0301,Y               ;$03841E    |/
    PLX                         ;$038421    |
    INY                         ;$038422    |\ 
    INY                         ;$038423    ||
    INY                         ;$038424    ||
    INY                         ;$038425    || Loop for 20 tiles.
    INC $02                     ;$038426    ||
    INX                         ;$038428    ||
    CPX.b #$14                  ;$038429    ||
    BNE CODE_0383E0             ;$03842B    |/
    LDX.w $15E9                 ;$03842D    |
    LDA.w $1602,X               ;$038430    |\ 
    CMP.b #$03                  ;$038433    ||
    BNE CODE_03844B             ;$038435    ||
    LDA.w $1558,X               ;$038437    ||
    BEQ CODE_03844B             ;$03843A    || If the Boo has its eyes covered and $1558 is set (normal Big Boo is peeking out),
    LDY.w $15EA,X               ;$03843C    ||  shift the hands down a few pixels.
    LDA.w $0301,Y               ;$03843F    ||
    CLC                         ;$038442    ||
    ADC.b #$05                  ;$038443    ||| How far the Big Boo's hands move down when it's peeking from behind them.
    STA.w $0301,Y               ;$038445    ||
    STA.w $0305,Y               ;$038448    |/
CODE_03844B:                    ;           |
    LDA.b #$13                  ;$03844B    |\ 
    LDY.b #$02                  ;$03844D    || Upload 20 16x16 tiles.
    JSL FinishOAMWrite          ;$03844F    |/
    RTS                         ;$038453    |





    ; Falling grey platform misc RAM:
    ; $1528 - Unused, but would make Mario move horizontally on the platform.
    ; $1540 - Timer set after initially landing, to prevent the platform from immediately accelerating as it falls.
    
GreyFallingPlat:                ;-----------| Grey falling platform MAIN
    JSR CODE_038492             ;$038454    | Draw GFX.
    LDA $9D                     ;$038457    |\ Return if game frozen.
    BNE Return038489            ;$038459    |/
    JSR SubOffscreen0Bnk3       ;$03845B    | Process offscreen from -$40 to +$30.
    LDA $AA,X                   ;$03845E    |\ Branch if not already falling.
    BEQ CODE_038476             ;$038460    |/
    LDA.w $1540,X               ;$038462    |\ Branch if Mario just landed and the platform should wait before accelerating.
    BNE CODE_038472             ;$038465    |/
    LDA $AA,X                   ;$038467    |\ 
    CMP.b #$40                  ;$038469    ||| Max falling speed for the platform.
    BPL CODE_038472             ;$03846B    ||
    CLC                         ;$03846D    ||
    ADC.b #$02                  ;$03846E    ||| Falling acceleration for the platform.
    STA $AA,X                   ;$038470    |/
CODE_038472:                    ;           |
    JSL UpdateYPosNoGrvty       ;$038472    | Update Y position.
CODE_038476:                    ;           |
    JSL InvisBlkMainRt          ;$038476    |\ Make solid, and return if not in contact with Mario.
    BCC Return038489            ;$03847A    |/
    LDA $AA,X                   ;$03847C    |\ Return if already falling.
    BNE Return038489            ;$03847E    |/
    LDA.b #$03                  ;$038480    |\ Set initial falling Y speed.
    STA $AA,X                   ;$038482    |/
    LDA.b #$18                  ;$038484    |\ Set timer to wait before accelerating.
    STA.w $1540,X               ;$038486    |/
Return038489:                   ;           |
    RTS                         ;$038489    |



FallingPlatDispX:               ;$033848A   | X displacements for each tile of the falling gray platform.
    db $00,$10,$20,$30

FallingPlatTiles:               ;$03848E    | Tile numbers for each tile of the falling gray platform.
    db $60,$61,$61,$62

CODE_038492:                    ;-----------| Falling gray platform GFX routine.
    JSR GetDrawInfoBnk3         ;$038492    |
    PHX                         ;$038495    |
    LDX.b #$03                  ;$038496    |
CODE_038498:                    ;           |
    LDA $00                     ;$038498    |\ 
    CLC                         ;$03849A    || Upload X position to OAM.
    ADC.w FallingPlatDispX,X    ;$03849B    ||
    STA.w $0300,Y               ;$03849E    |/
    LDA $01                     ;$0384A1    |\ Upload Y position to OAM.
    STA.w $0301,Y               ;$0384A3    |/
    LDA.w FallingPlatTiles,X    ;$0384A6    |\ Upload tile number to OAM.
    STA.w $0302,Y               ;$0384A9    |/
    LDA.b #$03                  ;$0384AC    |\ 
    ORA $64                     ;$0384AE    || Uplaod YXPPCCCT to OAM.
    STA.w $0303,Y               ;$0384B0    |/
    INY                         ;$0384B3    |\ 
    INY                         ;$0384B4    ||
    INY                         ;$0384B5    || Loop for all of the tiles.
    INY                         ;$0384B6    ||
    DEX                         ;$0384B7    ||
    BPL CODE_038498             ;$0384B8    |/
    PLX                         ;$0384BA    |
    LDY.b #$02                  ;$0384BB    |\ 
    LDA.b #$03                  ;$0384BD    || Upload 4 16x16 tiles.
    JSL FinishOAMWrite          ;$0384BF    |/
    RTS                         ;$0384C3    |





BlurpMaxSpeedY:                 ;$0384C4    | Max Y speeds for the Blurp and Swooper.
    db $04,$FC

BlurpSpeedX:                    ;$0384C6    | X speeds for the Blurp.
    db $08,$F8

BlurpAccelY:                    ;$0384C8    | Y accelerations for the Blurp and Swooper.
    db $01,$FF

    ; Blurp misc RAM:
    ; $C2   - Direciton of vertical acceleration. Even = down, odd = up.
    ; $157C - Horizontal direction the sprite is facing.
    
Blurp:                          ;-----------| Blurp MAIN
    JSL GenericSprGfxRt2        ;$0384CA    | Draw a 16x16 sprite.
    LDY.w $15EA,X               ;$0384CE    |
    LDA.w $14                   ;$0384D1    |\ 
    LSR                         ;$0384D4    ||
    LSR                         ;$0384D5    ||
    LSR                         ;$0384D6    ||
    CLC                         ;$0384D7    ||
    ADC.w $15E9                 ;$0384D8    || Animate the Blurp's swimming motion.
    LSR                         ;$0384DB    ||
    LDA.b #$A2                  ;$0384DC    ||| Tile A to use for the Blurp.
    BCC CODE_0384E2             ;$0384DE    ||
    LDA.b #$EC                  ;$0384E0    ||| Tile B to use for the Blurp.
CODE_0384E2:                    ;           ||
    STA.w $0302,Y               ;$0384E2    |/
    LDA.w $14C8,X               ;$0384E5    |\ 
    CMP.b #$08                  ;$0384E8    ||
    BEQ CODE_0384F5             ;$0384EA    ||
CODE_0384EC:                    ;           || If dead, flip the sprite upside down and return.
    LDA.w $0303,Y               ;           ||
    ORA.b #$80                  ;$0384EF    ||
    STA.w $0303,Y               ;$0384F1    ||
    RTS                         ;$0384F4    |/

CODE_0384F5:                    ;```````````| Not dead.
    LDA $9D                     ;$0384F5    |\ Return if game frozen.
    BNE Return03852A            ;$0384F7    |/
    JSR SubOffscreen0Bnk3       ;$0384F9    | Process offscreen from -$40 to +$30.
    LDA $14                     ;$0384FC    |\ 
    AND.b #$03                  ;$0384FE    ||
    BNE CODE_038516             ;$038500    ||
    LDA $C2,X                   ;$038502    ||
    AND.b #$01                  ;$038504    ||
    TAY                         ;$038506    || Every 4 frames, update Y speed.
    LDA $AA,X                   ;$038507    || If at the max speed in a particular direction, invert its direction of movement.
    CLC                         ;$038509    ||
    ADC.w BlurpAccelY,Y         ;$03850A    ||
    STA $AA,X                   ;$03850D    ||
    CMP.w BlurpMaxSpeedY,Y      ;$03850F    ||
    BNE CODE_038516             ;$038512    ||
    INC $C2,X                   ;$038514    |/
CODE_038516:                    ;           |
    LDY.w $157C,X               ;$038516    |\ 
    LDA.w BlurpSpeedX,Y         ;$038519    || Store X speed in the direction the Blurp is facing.
    STA $B6,X                   ;$03851C    |/
    JSL UpdateXPosNoGrvty       ;$03851E    | Update X position.
    JSL UpdateYPosNoGrvty       ;$038522    | Update Y position.
    JSL SprSprPMarioSprRts      ;$038526    | Process interaction with Mario and other sprites.
Return03852A:                   ;           |
    RTS                         ;$03852A    |





PorcuPuffAccel:                 ;$03852B    | X accelerations for the Porcu-Puffer.
    db $01,$FF

PorcuPuffMaxSpeed:              ;$03852D    | Max X speeds for the Porcu-Puffer.
    db $10,$F0

    ; Porcupuffer misc RAM:
    ; $157C - Horizontal direction the sprite is facing.
    
PorcuPuffer:                    ;-----------| Porcu-Puffer MAIN
    JSR CODE_0385A3             ;$03852F    | Draw graphics.
    LDA $9D                     ;$038532    |\ 
    BNE Return038586            ;$038534    ||
    LDA.w $14C8,X               ;$038536    || Return if game frozen or sprite dead.
    CMP.b #$08                  ;$038539    ||
    BNE Return038586            ;$03853B    |/
    JSR SubOffscreen0Bnk3       ;$03853D    | Process offscreen from -$40 to +$30.
    JSL SprSprPMarioSprRts      ;$038540    | Process interaction with Mario and sprites.
    JSR SubHorzPosBnk3          ;$038544    |\\ 
    TYA                         ;$038547    |||
    STA.w $157C,X               ;$038548    |||
    LDA $14                     ;$03854B    |||
    AND.b #$03                  ;$03854D    |||
    BNE CODE_03855E             ;$03854F    ||| Apply X acceleration if not at max.
    LDA $B6,X                   ;$038551    |||
    CMP.w PorcuPuffMaxSpeed,Y   ;$038553    |||
    BEQ CODE_03855E             ;$038556    |||
    CLC                         ;$038558    |||
    ADC.w PorcuPuffAccel,Y      ;$038559    |||
    STA $B6,X                   ;$03855C    ||/
CODE_03855E:                    ;           ||
    LDA $B6,X                   ;$03855E    ||\ 
    PHA                         ;$038560    |||
    LDA.w $17BD                 ;$038561    |||
    ASL                         ;$038564    |||
    ASL                         ;$038565    ||| Move with the screen.
    ASL                         ;$038566    |||
    CLC                         ;$038567    |||
    ADC $B6,X                   ;$038568    |||
    STA $B6,X                   ;$03856A    ||/
    JSL UpdateXPosNoGrvty       ;$03856C    || Update X position.
    PLA                         ;$038570    ||
    STA $B6,X                   ;$038571    |/
    JSL CODE_019138             ;$038573    | Process interaction with blocks.
    LDY.b #$04                  ;$038577    |\\ Y speed to give the Porcu-Puffer when out of water (falling).
    LDA.w $164A,X               ;$038579    ||
    BEQ CODE_038580             ;$03857C    ||
    LDY.b #$FC                  ;$03857E    ||| Y speed to give the Porcu-Puffer when in water (rising).
CODE_038580:                    ;           ||
    STY $AA,X                   ;$038580    |/
    JSL UpdateYPosNoGrvty       ;$038582    | Update Y position.
Return038586:                   ;           |
    RTS                         ;$038586    |


PocruPufferDispX:               ;$038587    | X displacements for each of the Porcu-Puffer's tiles.
    db $F8,$08,$F8,$08
    db $08,$F8,$08,$F8

PocruPufferDispY:               ;$03858F    | Y displacements for each of the Porcu-Puffer's tiles.
    db $F8,$F8,$08,$08

PocruPufferTiles:               ;$038593    | Tile numbers for the Porcu-Puffer.
    db $86,$C0,$A6,$C2
    db $86,$C0,$A6,$8A

PocruPufferGfxProp:             ;$03859B    | YXPPCCCT for the Porcu-Puffer.
    db $0D,$0D,$0D,$0D
    db $4D,$4D,$4D,$4D

CODE_0385A3:                    ;-----------| Porcu-Puffer GFX routine.
    JSR GetDrawInfoBnk3         ;$0385A3    |
    LDA $14                     ;$0385A6    |\ 
    AND.b #$04                  ;$0385A8    || $03 = Animation index
    STA $03                     ;$0385AA    |/
    LDA.w $157C,X               ;$0385AC    |\ $02 = X flip
    STA $02                     ;$0385AF    |/
    PHX                         ;$0385B1    |
    LDX.b #$03                  ;$0385B2    |
CODE_0385B4:                    ;           |
    LDA $01                     ;$0385B4    |\ 
    CLC                         ;$0385B6    || Store Y position to OAM.
    ADC.w PocruPufferDispY,X    ;$0385B7    ||
    STA.w $0301,Y               ;$0385BA    |/
    PHX                         ;$0385BD    |
    LDA $02                     ;$0385BE    |\ 
    BNE CODE_0385C6             ;$0385C0    ||
    TXA                         ;$0385C2    ||
    ORA.b #$04                  ;$0385C3    ||
    TAX                         ;$0385C5    ||
CODE_0385C6:                    ;           || Store X position to OAM.
    LDA $00                     ;$0385C6    ||
    CLC                         ;$0385C8    ||
    ADC.w PocruPufferDispX,X    ;$0385C9    ||
    STA.w $0300,Y               ;$0385CC    |/
    LDA.w PocruPufferGfxProp,X  ;$0385CF    |\ 
    ORA $64                     ;$0385D2    || Store YXPPCCCCT.
    STA.w $0303,Y               ;$0385D4    |/
    PLA                         ;$0385D7    |\ 
    PHA                         ;$0385D8    ||
    ORA $03                     ;$0385D9    || Store tile number.
    TAX                         ;$0385DB    ||
    LDA.w PocruPufferTiles,X    ;$0385DC    ||
    STA.w $0302,Y               ;$0385DF    |/
    PLX                         ;$0385E2    |
    INY                         ;$0385E3    |\ 
    INY                         ;$0385E4    ||
    INY                         ;$0385E5    || Loop for all of the tiles.
    INY                         ;$0385E6    ||
    DEX                         ;$0385E7    ||
    BPL CODE_0385B4             ;$0385E8    |/
    PLX                         ;$0385EA    |
    LDY.b #$02                  ;$0385EB    |\ 
    LDA.b #$03                  ;$0385ED    || Upload 4 16x16 tiles.
    JSL FinishOAMWrite          ;$0385EF    |/
    RTS                         ;$0385F3    |





FlyingBlockSpeedY:              ;$0385F4    | Y speeds for the flying turnblock platform.
    db $08,$F8

    ; Flying Grey Turnblocks misc RAM:
    ; $151C - Value indicating whether the platform flies up first (00) or down first (10)
    ; $1528 - Number of pixels moved horizontally in the frame.
    ; $1534 - Extra timer for changing the direction of vertical movement. $1602 is only decremented every odd even tick of this address.
    ; $157C - Direction of vertical movement. Even = down, odd = up.
    ; $1602 - Timer for changing the direction of vertical movement.
    
FlyingTurnBlocks:               ;-----------| Flying Grey Turnblocks MAIN
    JSR CODE_0386A8             ;$0385F6    | Draw GFX.
    LDA $9D                     ;$0385F9    |\ Return if game frozen.
    BNE Return038675            ;$0385FB    |/
    LDA.w $1B9A                 ;$0385FD    |\ 
    BEQ CODE_038629             ;$038600    || Handle Y speed if the platform has been started.
    LDA.w $1534,X               ;$038602    ||\ 
    INC.w $1534,X               ;$038605    |||
    AND.b #$01                  ;$038608    |||
    BNE CODE_03861E             ;$03860A    |||
    DEC.w $1602,X               ;$03860C    ||| If time to change direction, do so.
    LDA.w $1602,X               ;$03860F    |||
    CMP.b #$FF                  ;$038612    |||
    BNE CODE_03861E             ;$038614    |||
    LDA.b #$FF                  ;$038616    |||
    STA.w $1602,X               ;$038618    |||
    INC.w $157C,X               ;$03861B    ||/
CODE_03861E:                    ;           ||
    LDA.w $157C,X               ;$03861E    ||\ 
    AND.b #$01                  ;$038621    |||
    TAY                         ;$038623    ||| Set Y speed.
    LDA.w FlyingBlockSpeedY,Y   ;$038624    |||
    STA $AA,X                   ;$038627    |//
CODE_038629:                    ;           |
    LDA $AA,X                   ;$038629    |\ 
    PHA                         ;$03862B    ||
    LDY.w $151C,X               ;$03862C    ||
    BNE CODE_038636             ;$03862F    ||
    EOR.b #$FF                  ;$038631    || Update Y position.
    INC A                       ;$038633    ||  If the platform was spawned at an odd X position, invert its direction of movement.
    STA $AA,X                   ;$038634    ||
CODE_038636:                    ;           ||
    JSL UpdateYPosNoGrvty       ;$038636    ||
    PLA                         ;$03863A    ||
    STA $AA,X                   ;$03863B    |/
    LDA.w $1B9A                 ;$03863D    |\ Store X speed.
    STA $B6,X                   ;$038640    |/
    JSL UpdateXPosNoGrvty       ;$038642    | Update X position.
    STA.w $1528,X               ;$038646    |\ 
    JSL InvisBlkMainRt          ;$038649    || Make the platform solid, and return if Mario isn't on the platform.
    BCC Return038675            ;$03864D    |/
    LDA.w $1B9A                 ;$03864F    |\ Return if the platform hasn't already been started.
    BNE Return038675            ;$038652    |/
    LDA.b #$08                  ;$038654    |\\ X speed the flying grey platform flies at.
    STA.w $1B9A                 ;$038656    |/
    LDA.b #$7F                  ;$038659    |\ Set initial timer until the platform turns around.
    STA.w $1602,X               ;$03865B    |/
    LDY.b #$09                  ;$03865E    |\ 
CODE_038660:                    ;           ||
    CPY.w $15E9                 ;$038660    ||
    BEQ CODE_03866C             ;$038663    ||
    LDA.w $009E,Y               ;$038665    ||
    CMP.b #$C1                  ;$038668    ||
    BEQ CODE_038670             ;$03866A    || Find a second platform and start it up too.
CODE_03866C:                    ;           ||  (note that any more platforms will immediately reverse direction).
    DEY                         ;$03866C    ||
    BPL CODE_038660             ;$03866D    ||
    INY                         ;$03866F    ||] Note: this line should probably be changed to an RTS.
CODE_038670:                    ;           ||
    LDA.b #$7F                  ;$038670    ||
    STA.w $1602,Y               ;$038672    |/
Return038675:                   ;           |
    RTS                         ;$038675    |



ForestPlatDispX:                ;$038676    | X offsets for the Flying Grey Turnblocks.
    db $00,$10,$20,$F2,$2E
    db $00,$10,$20,$FA,$2E

ForestPlatDispY:                ;$038680    | Y offsets for the Flying Grey Turnblocks.
    db $00,$00,$00,$F6,$F6
    db $00,$00,$00,$FE,$FE

ForestPlatTiles:                ;$03868A    | Tile numbers for the Flying Grey Turnblocks.
    db $40,$40,$40,$C6,$C6
    db $40,$40,$40,$5D,$5D

ForestPlatGfxProp:              ;$038694    | YXPPCCCT for the Flying Grey Turnblocks.
    db $32,$32,$32,$72,$32
    db $32,$32,$32,$72,$32

ForestPlatTileSize:             ;$03869E    | Tile sizes for the Flying Grey Turnblocks.
    db $02,$02,$02,$02,$02
    db $02,$02,$02,$00,$00

CODE_0386A8:                    ;-----------| Flying Grey Turnblocks GFX routine
    JSR GetDrawInfoBnk3         ;$0386A8    |
    LDY.w $15EA,X               ;$0386AB    |
    LDA $14                     ;$0386AE    |\ 
    LSR                         ;$0386B0    ||
    AND.b #$04                  ;$0386B1    ||
    BEQ CODE_0386B6             ;$0386B3    || $02 = Animation index to the above tables (for animating the wings).
    INC A                       ;$0386B5    ||
CODE_0386B6:                    ;           ||
    STA $02                     ;$0386B6    |/
    PHX                         ;$0386B8    |
    LDX.b #$04                  ;$0386B9    |
CODE_0386BB:                    ;           |
    STX $06                     ;$0386BB    |
    TXA                         ;$0386BD    |
    CLC                         ;$0386BE    |
    ADC $02                     ;$0386BF    |
    TAX                         ;$0386C1    |
    LDA $00                     ;$0386C2    |\ 
    CLC                         ;$0386C4    || Store X position to OAM.
    ADC.w ForestPlatDispX,X     ;$0386C5    ||
    STA.w $0300,Y               ;$0386C8    |/
    LDA $01                     ;$0386CB    |\ 
    CLC                         ;$0386CD    || Store Y position to OAM.
    ADC.w ForestPlatDispY,X     ;$0386CE    ||
    STA.w $0301,Y               ;$0386D1    |/
    LDA.w ForestPlatTiles,X     ;$0386D4    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$0386D7    |/
    LDA.w ForestPlatGfxProp,X   ;$0386DA    |\ Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$0386DD    |/
    PHY                         ;$0386E0    |
    TYA                         ;$0386E1    |\ 
    LSR                         ;$0386E2    ||
    LSR                         ;$0386E3    || Store size to OAM.
    TAY                         ;$0386E4    ||
    LDA.w ForestPlatTileSize,X  ;$0386E5    ||
    STA.w $0460,Y               ;$0386E8    |/
    PLY                         ;$0386EB    |
    INY                         ;$0386EC    |\ 
    INY                         ;$0386ED    ||
    INY                         ;$0386EE    ||
    INY                         ;$0386EF    || Loop for all of the tiles.
    LDX $06                     ;$0386F0    ||
    DEX                         ;$0386F2    ||
    BPL CODE_0386BB             ;$0386F3    |/
    PLX                         ;$0386F5    |
    LDY.b #$FF                  ;$0386F6    |\ 
    LDA.b #$04                  ;$0386F8    || Upload 5 manually-sized tiles.
    JSL FinishOAMWrite          ;$0386FA    |/
    RTS                         ;$0386FE    |





    ; Grey lava platform misc RAM:
    ; $1528 - Always 0, but would move Mario horizontally when standing on the platform if non-zero.
    ; $1540 - Timer for sinking the platform.

GrayLavaPlatform:               ;-----------| Grey lava platform MAIN
    JSR CODE_03873A             ;$0386FF    | Draw GFX.
    LDA $9D                     ;$038702    |\ Return if game frozen.
    BNE Return038733            ;$038704    |/
    JSR SubOffscreen0Bnk3       ;$038706    | Process offscreen from -$40 to +$30.
    LDA.w $1540,X               ;$038709    |\ 
    DEC A                       ;$03870C    || Branch if not done sinking.
    BNE CODE_03871B             ;$03870D    |/
    LDY.w $161A,X               ;$03870F    |\ 
    LDA.b #$00                  ;$038712    || Erase the sprite.
    STA.w $1938,Y               ;$038714    ||
    STZ.w $14C8,X               ;$038717    |/
    RTS                         ;$03871A    |

CODE_03871B:                    ;```````````| Not done sinking (or hasn't started yet).
    JSL UpdateYPosNoGrvty       ;$03871B    | Update Y position.
    JSL InvisBlkMainRt          ;$03871F    |\ Make the platform solid and return if Mario isn't on it.
    BCC Return038733            ;$038723    |/
    LDA.w $1540,X               ;$038725    |\ Return if the platform has already started sinking.
    BNE Return038733            ;$038728    |/
    LDA.b #$06                  ;$03872A    |\\ Y speed the lava platform sinks with.
    STA $AA,X                   ;$03872C    |/
    LDA.b #$40                  ;$03872E    |\\ How long the lava platform takes to sink.
    STA.w $1540,X               ;$038730    |/
Return038733:                   ;           |
    RTS                         ;$038733    |


LavaPlatTiles:                  ;$038734    | Tile numbers for the grey lava platform.
    db $85,$86,$85

DATA_038737:                    ;$038737    | YXPPCCCT for the grey lava platform.
    db $43,$03,$03

CODE_03873A:                    ;-----------| Grey lava platform GFX routine
    JSR GetDrawInfoBnk3         ;$03873A    |
    PHX                         ;$03873D    |
    LDX.b #$02                  ;$03873E    |
CODE_038740:                    ;           |
    LDA $00                     ;$038740    |\ 
    STA.w $0300,Y               ;$038742    ||
    CLC                         ;$038745    || Store X position to OAM.
    ADC.b #$10                  ;$038746    ||
    STA $00                     ;$038748    |/
    LDA $01                     ;$03874A    |\ Store Y position to OAM.
    STA.w $0301,Y               ;$03874C    |/
    LDA.w LavaPlatTiles,X       ;$03874F    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$038752    |/
    LDA.w DATA_038737,X         ;$038755    |\ 
    ORA $64                     ;$038758    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03875A    |/
    INY                         ;$03875D    |\ 
    INY                         ;$03875E    ||
    INY                         ;$03875F    || Loop for all of the tiles.
    INY                         ;$038760    ||
    DEX                         ;$038761    ||
    BPL CODE_038740             ;$038762    |/
    PLX                         ;$038764    |
    LDY.b #$02                  ;$038765    |\ 
    LDA.b #$02                  ;$038767    || Upload 3 16x16 tiles.
    JSL FinishOAMWrite          ;$038769    |/
    RTS                         ;$03876D    |





MegaMoleSpeed:                  ;           |
    db $10,$F0

    ; Mega Mole misc RAM:
    ; $151C - Horizontal direction the sprite is facing.
    ; $1540 - Timer set when the mole walks of a ledge, so that it can actually clear the ledge before it starts falling (i.e. don't clip through the corner).
    ; $154C - Timer set while Mario is standing on the mole, to prevent him from being hurt by it.
    ; $157C - Horizontal direction the sprite is moving.
    ; $15AC - Timer for turning around.
    
MegaMole:                       ;-----------| Mega Mole MAIN
    JSR MegaMoleGfxRt           ;$038770    | Draw GFX.
    LDA.w $14C8,X               ;$038773    |\ 
    CMP.b #$08                  ;$038776    || Return if dead.
    BNE Return038733            ;$038778    |/
    JSR SubOffscreen3Bnk3       ;$03877A    | Process offscreen from -$50 to +$60.
    LDY.w $157C,X               ;$03877D    |\ 
    LDA.w MegaMoleSpeed,Y       ;$038780    || Store X speed.
    STA $B6,X                   ;$038783    |/
    LDA $9D                     ;$038785    |\ Return if game frozen.
    BNE Return038733            ;$038787    |/
    LDA.w $1588,X               ;$038789    |
    AND.b #$04                  ;$03878C    |
    PHA                         ;$03878E    |
    JSL UpdateSpritePos         ;$03878F    | Update X/Y position, apply gravity, and process interaction with blocks.
    JSL SprSprInteract          ;$038793    | Process interaction with other sprites.
    LDA.w $1588,X               ;$038797    |\ 
    AND.b #$04                  ;$03879A    ||
    BEQ MegaMoleInAir           ;$03879C    || If the Mega Mole is on the ground, clear Y speed and branch.
    STZ $AA,X                   ;$03879E    ||
    PLA                         ;$0387A0    ||
    BRA MegaMoleOnGround        ;$0387A1    |/
MegaMoleInAir:                  ;```````````| Mole is in the air.
    PLA                         ;$0387A3    |\ 
    BEQ MegaMoleWasInAir        ;$0387A4    || If the mole was previously on the ground, set the timer to wait before actually falling.
    LDA.b #$0A                  ;$0387A6    ||
    STA.w $1540,X               ;$0387A8    |/
MegaMoleWasInAir:               ;           |
    LDA.w $1540,X               ;$0387AB    |\ 
    BEQ MegaMoleOnGround        ;$0387AE    || If the mole has just walked of a ledge, clear Y speed for a bit before actually falling.
    STZ $AA,X                   ;$0387B0    |/
MegaMoleOnGround:               ;```````````| Mole is on the ground.
    LDY.w $15AC,X               ;$0387B2    |\ 
    LDA.w $1588,X               ;$0387B5    ||
    AND.b #$03                  ;$0387B8    ||
    BEQ CODE_0387CD             ;$0387BA    ||
    CPY.b #$00                  ;$0387BC    ||
    BNE CODE_0387C5             ;$0387BE    || If the mole just hit a wall, turn it around (if it's not already in the process of turning).
    LDA.b #$10                  ;$0387C0    ||
    STA.w $15AC,X               ;$0387C2    ||
CODE_0387C5:                    ;           ||
    LDA.w $157C,X               ;$0387C5    ||
    EOR.b #$01                  ;$0387C8    ||
    STA.w $157C,X               ;$0387CA    |/
CODE_0387CD:                    ;           |
    CPY.b #$00                  ;$0387CD    |\ 
    BNE CODE_0387D7             ;$0387CF    || Only actually update the direction the mole is facing when the it finishes turning.
    LDA.w $157C,X               ;$0387D1    ||
    STA.w $151C,X               ;$0387D4    |/
CODE_0387D7:                    ;           |
    JSL MarioSprInteract        ;$0387D7    |\ Process interaction with Mario, and return if not in contact.
    BCC Return03882A            ;$0387DB    |/
    JSR SubVertPosBnk3          ;$0387DD    |\ 
    LDA $0E                     ;$0387E0    || Branch if less than 18 pixels above the mole, to hurt Mario.
    CMP.b #$D8                  ;$0387E2    ||
    BPL MegaMoleContact         ;$0387E4    |/
    LDA $7D                     ;$0387E6    |\ Return if moving upwards.
    BMI Return03882A            ;$0387E8    |/
    LDA.b #$01                  ;$0387EA    |\ Set flag for being on a sprite.
    STA.w $1471                 ;$0387EC    |/
    LDA.b #$06                  ;$0387EF    |\ Set timer to prevent Mario from being hurt by the mole.
    STA.w $154C,X               ;$0387F1    |/
    STZ $7D                     ;$0387F4    | Clear Mario's Y speed.
    LDA.b #$D6                  ;$0387F6    |\ 
    LDY.w $187A                 ;$0387F8    ||
    BEQ MegaMoleNoYoshi         ;$0387FB    ||
    LDA.b #$C6                  ;$0387FD    ||
MegaMoleNoYoshi:                ;           ||
    CLC                         ;$0387FF    || Offset Mario on top of the sprite.
    ADC $D8,X                   ;$038800    ||
    STA $96                     ;$038802    ||
    LDA.w $14D4,X               ;$038804    ||
    ADC.b #$FF                  ;$038807    ||
    STA $97                     ;$038809    |/
    LDY.b #$00                  ;$03880B    |\ 
    LDA.w $1491                 ;$03880D    ||
    BPL CODE_038813             ;$038810    ||
    DEY                         ;$038812    ||
CODE_038813:                    ;           ||
    CLC                         ;$038813    || Move Mario horizontally with the sprite.
    ADC $94                     ;$038814    ||
    STA $94                     ;$038816    ||
    TYA                         ;$038818    ||
    ADC $95                     ;$038819    ||
    STA $95                     ;$03881B    |/
    RTS                         ;$03881D    |

MegaMoleContact:
    LDA.w $154C,X               ;$03881E    |\ 
    ORA.w $15D0,X               ;$038821    || Hurt Mario, unless Mario is on top of it or it's on Yoshi's tongue.
    BNE Return03882A            ;$038824    ||
    JSL HurtMario               ;$038826    |/
Return03882A:                   ;           |
    RTS                         ;$03882A    |


MegaMoleTileDispX:              ;$03882B    | X offsets for each tile of the Mega Mole, indexed by its direction.
    db $00,$10,$00,$10
    db $10,$00,$10,$00

MegaMoleTileDispY:              ;$038823    | Y offsets for each tile of the Mega Mole.
    db $F0,$F0,$00,$00

MegaMoleTiles:                  ;$038827    | Tile numbers for each tile of the Mega Mole's walking animation.
    db $C6,$C8,$E6,$E8
    db $CA,$CC,$EA,$EC

MegaMoleGfxRt:                  ;-----------| Mega Mole GFX routine
    JSR GetDrawInfoBnk3         ;$03883F    |
    LDA.w $151C,X               ;$038842    |\ $02 = horizontal direciton
    STA $02                     ;$038845    |/
    LDA $14                     ;$038847    |\ 
    LSR                         ;$038849    ||
    LSR                         ;$03884A    ||
    NOP                         ;$03884B    ||
    CLC                         ;$03884C    || $03 = animation frame (x4)
    ADC.w $15E9                 ;$03884D    ||
    AND.b #$01                  ;$038850    ||
    ASL                         ;$038852    ||
    ASL                         ;$038853    ||
    STA $03                     ;$038854    |/
    PHX                         ;$038856    |
    LDX.b #$03                  ;$038857    |
MegaMoleGfxLoopSt:              ;           |
    PHX                         ;$038859    |
    LDA $02                     ;$03885A    |\ 
    BNE MegaMoleFaceLeft        ;$03885C    ||
    INX                         ;$03885E    ||
    INX                         ;$03885F    ||
    INX                         ;$038860    ||
    INX                         ;$038861    || Store X position to OAM.
MegaMoleFaceLeft:               ;           ||
    LDA $00                     ;$038862    ||
    CLC                         ;$038864    ||
    ADC.w MegaMoleTileDispX,X   ;$038865    ||
    STA.w $0300,Y               ;$038868    |/
    PLX                         ;$03886B    |
    LDA $01                     ;$03886C    |\ 
    CLC                         ;$03886E    || Store Y position to OAM.
    ADC.w MegaMoleTileDispY,X   ;$03886F    ||
    STA.w $0301,Y               ;$038872    |/
    PHX                         ;$038875    |
    TXA                         ;$038876    |\ 
    CLC                         ;$038877    ||
    ADC $03                     ;$038878    || Store tile number to OAM.
    TAX                         ;$03887A    ||
    LDA.w MegaMoleTiles,X       ;$03887B    ||
    STA.w $0302,Y               ;$03887E    |/
    LDA.b #$01                  ;$038881    |\ 
    LDX $02                     ;$038883    ||
    BNE MegaMoleGfxNoFlip       ;$038885    ||
    ORA.b #$40                  ;$038887    || Store YXPPCCCT to OAM.
MegaMoleGfxNoFlip:              ;           ||
    ORA $64                     ;$038889    ||
    STA.w $0303,Y               ;$03888B    |/
    PLX                         ;$03888E    |
    INY                         ;$03888F    |\ 
    INY                         ;$038890    ||
    INY                         ;$038891    || Loop for all of the tiles.
    INY                         ;$038892    ||
    DEX                         ;$038893    ||
    BPL MegaMoleGfxLoopSt       ;$038894    |/
    PLX                         ;$038896    |
    LDY.b #$02                  ;$038897    |\ 
    LDA.b #$03                  ;$038899    || Upload 4 16x16 tiles.
    JSL FinishOAMWrite          ;$03889B    |/
    RTS                         ;$03889F    |





BatTiles:                       ;           |
    db $AE,$C0,$E8

    ; Swooper misc RAM:
    ; $C2   - Phase pointer.
    ;          0 = waiting to swoop, 1 = swooping, 2 = flying straight
    ; $151C - Direction of vertical acceleration in phase 2. Even = down, odd = up.
    ; $157C - Horizontal direction the sprite is facing.
    ; $1602 - Animation frame.
    ;          0 = waiting on the ceiling, 1/2 = flying

Swooper:                        ;-----------| Swooper MAIN
    JSL GenericSprGfxRt2        ;$0388A3    | Draw a 16x16 sprite.
    LDY.w $15EA,X               ;$0388A7    |
    PHX                         ;$0388AA    |
    LDA.w $1602,X               ;$0388AB    |\ 
    TAX                         ;$0388AE    || Change the tile number stored to OAM.
    LDA.w BatTiles,X            ;$0388AF    ||
    STA.w $0302,Y               ;$0388B2    |/
    PLX                         ;$0388B5    |
    LDA.w $14C8,X               ;$0388B6    |\ 
    CMP.b #$08                  ;$0388B9    || If dead, flip the sprite upside down and return.
    BEQ CODE_0388C0             ;$0388BB    ||
    JMP CODE_0384EC             ;$0388BD    |/
CODE_0388C0:                    ;```````````| Not dead.
    LDA $9D                     ;$0388C0    |\ Return if game frozen.
    BNE Return0388DF            ;$0388C2    |/
    JSR SubOffscreen0Bnk3       ;$0388C4    | Process offscreen from -$40 to +$30.
    JSL SprSprPMarioSprRts      ;$0388C7    | Process interaction with Mario and other sprties.
    JSL UpdateXPosNoGrvty       ;$0388CB    | Update X position.
    JSL UpdateYPosNoGrvty       ;$0388CF    | Update Y position.
    LDA $C2,X                   ;$0388D3    |
    JSL ExecutePtr              ;$0388D5    |

SwooperPtrs:                    ;$0388D9    | Swooper phase pointers.
    dw CODE_0388E4              ; 0 - Waiting to swoop
    dw CODE_038905              ; 1 - Swooping
    dw CODE_038936              ; 2 - Flying straight

Return0388DF:
    RTS                         ;$0388DF    |



DATA_0388E0:                    ;$0388E0    | Max X speeds for the Swooper.
    db $10,$F0

DATA_0388E2:                    ;$0388E2    | X accelerations for the Swooper.
    db $01,$FF



CODE_0388E4:                    ;-----------| Swooper phase 0 - Waiting to swoop
    LDA.w $15A0,X               ;$0388E4    |\ Return if horizontally offscreen.
    BNE Return038904            ;$0388E7    |/
    JSR SubHorzPosBnk3          ;$0388E9    |\ 
    LDA $0F                     ;$0388EC    ||
    CLC                         ;$0388EE    || Return if Mario isn't within 5 tiles of the sprite.
    ADC.b #$50                  ;$0388EF    ||
    CMP.b #$A0                  ;$0388F1    ||
    BCS Return038904            ;$0388F3    |/
    INC $C2,X                   ;$0388F5    | Increment phase pointer.
    TYA                         ;$0388F7    |\ Fly towards Mario. 
    STA.w $157C,X               ;$0388F8    |/
    LDA.b #$20                  ;$0388FB    |\\ Initial Y speed when the Swooper swoops.
    STA $AA,X                   ;$0388FD    |/
    LDA.b #$26                  ;$0388FF    |\ SFX for the swooper swooping.
    STA.w $1DFC                 ;$038901    |/
Return038904:                   ;           |
    RTS                         ;$038904    |



CODE_038905:                    ;-----------| Swooper phase 1 - Swooping
    LDA $13                     ;$038905    |\ 
    AND.b #$03                  ;$038907    ||
    BNE CODE_038915             ;$038909    ||
    LDA $AA,X                   ;$03890B    || Every 4 frames, decrease Y speed by 1.
    BEQ CODE_038915             ;$03890D    ||  If the sprite no longer has any Y speed, increment phase pointer.
    DEC $AA,X                   ;$03890F    ||
    BNE CODE_038915             ;$038911    ||
    INC $C2,X                   ;$038913    |/
CODE_038915:                    ;           |
    LDA $13                     ;$038915    |\ 
    AND.b #$03                  ;$038917    ||
    BNE CODE_03892B             ;$038919    ||
    LDY.w $157C,X               ;$03891B    ||
    LDA $B6,X                   ;$03891E    || Ever 4 frames, accelerate horizontally if not moving at the max speed yet.
    CMP.w DATA_0388E0,Y         ;$038920    ||
    BEQ CODE_03892B             ;$038923    ||
    CLC                         ;$038925    ||
    ADC.w DATA_0388E2,Y         ;$038926    ||
    STA $B6,X                   ;$038929    |/
CODE_03892B:                    ;           |
    LDA $14                     ;$03892B    |\ 
    AND.b #$04                  ;$03892D    ||
    LSR                         ;$03892F    || Animate the Swooper's flight.
    LSR                         ;$038930    ||
    INC A                       ;$038931    ||
    STA.w $1602,X               ;$038932    |/
    RTS                         ;$038935    |



CODE_038936:                    ;-----------| Swooper phase 2 - Flying straight
    LDA $13                     ;$038936    |\ 
    AND.b #$01                  ;$038938    ||
    BNE CODE_038952             ;$03893A    ||
    LDA.w $151C,X               ;$03893C    ||
    AND.b #$01                  ;$03893F    ||
    TAY                         ;$038941    || Handle the Swooper's "flapping" movement every other frame.
    LDA $AA,X                   ;$038942    ||  If at the max Y speed in a particular direction, invert its direction of vertical acceleration.
    CLC                         ;$038944    ||
    ADC.w BlurpAccelY,Y         ;$038945    ||
    STA $AA,X                   ;$038948    ||
    CMP.w BlurpMaxSpeedY,Y      ;$03894A    ||
    BNE CODE_038952             ;$03894D    ||
    INC.w $151C,X               ;$03894F    |/
CODE_038952:                    ;           |
    BRA CODE_038915             ;$038952    | Handle animation and X speed.





DATA_038954:                    ;$038954    | Max X speeds down slopes for the sliding blue Koopa.
    db $20,$E0

DATA_038956:                    ;$038956    | X accelerations down slopes for the sliding blue Koopa.
    db $02,$FE

    ; Sliding Blue Koopa misc RAM:
    ; $1540 - Timer set briefly on spawn, to prevent the Koopa from immediately falling.
    ; $1558 - Timer after the Koopa stops to wait before turning into a normal Koopa.
    ; $157C - Horizontal direction the sprite is facing.
    
SlidingKoopa:                   ;-----------| Sliding blue Koopa MAIN
    LDA.b #$00                  ;$038958    |\ 
    LDY $B6,X                   ;$03895A    ||
    BEQ CODE_038964             ;$03895C    ||
    BPL CODE_038961             ;$03895E    || Update direction based on X speed.
    INC A                       ;$038960    ||
CODE_038961:                    ;           ||
    STA.w $157C,X               ;$038961    |/
CODE_038964:                    ;           |
    JSL GenericSprGfxRt2        ;$038964    |
    LDY.w $15EA,X               ;$038968    |
    LDA.w $1558,X               ;$03896B    |\ 
    CMP.b #$01                  ;$03896E    ||
    BNE CODE_038983             ;$038970    ||
    LDA.w $157C,X               ;$038972    || If done sliding, turn into a normal blue Koopa.
    PHA                         ;$038975    ||
    LDA.b #$02                  ;$038976    |||| Sprite the sliding blue Koopa turns into when it touches the ground.
    STA $9E,X                   ;$038978    ||
    JSL InitSpriteTables        ;$03897A    ||
    PLA                         ;$03897E    ||
    STA.w $157C,X               ;$03897F    |/
    SEC                         ;$038982    |\ 
CODE_038983:                    ;           ||
    LDA.b #$86                  ;$038983    ||| Tile to use for the sliding blue Koopa while sliding.
    BCC CODE_038989             ;$038985    ||
    LDA.b #$E0                  ;$038987    ||| Tile to use for the sliding blue Koopa when it's about to turn into a normal Koopa.
CODE_038989:                    ;           ||
    STA.w $0302,Y               ;$038989    |/
    LDA.w $14C8,X               ;$03898C    |\ 
    CMP.b #$08                  ;$03898F    || Return if dead.
    BNE Return0389FE            ;$038991    |/
    JSR SubOffscreen0Bnk3       ;$038993    | Process offscreen from -$40 to +$30.
    JSL SprSprPMarioSprRts      ;$038996    | Process interaction with Mario and other sprites.
    LDA $9D                     ;$03899A    |\ 
    ORA.w $1540,X               ;$03899C    || Return if game frozen or the Koopa has stopped.
    ORA.w $1558,X               ;$03899F    ||
    BNE Return0389FE            ;$0389A2    |/
    JSL UpdateSpritePos         ;$0389A4    | Update X/Y position, apply gravity, and process interaction with blocks.
    LDA.w $1588,X               ;$0389A8    |\ 
    AND.b #$04                  ;$0389AB    || Return if not on the ground.
    BEQ Return0389FE            ;$0389AD    |/
    JSR CODE_0389FF             ;$0389AF    | Handle spawning the friction smoke.
    LDY.b #$00                  ;$0389B2    |\ 
    LDA $B6,X                   ;$0389B4    ||
    BEQ CODE_0389CC             ;$0389B6    ||
    BPL CODE_0389BD             ;$0389B8    ||
    EOR.b #$FF                  ;$0389BA    ||
    INC A                       ;$0389BC    ||
CODE_0389BD:                    ;           ||
    STA $00                     ;$0389BD    || Calculate Y speed for the blue Koopa based on the type of slope it's on and its current X speed.
    LDA.w $15B8,X               ;$0389BF    ||  Normally, it always tries to move the sprite in a 45-degree angle downwards, unless sliding up a slope.
    BEQ CODE_0389CC             ;$0389C2    ||
    LDY $00                     ;$0389C4    ||
    EOR $B6,X                   ;$0389C6    ||
    BPL CODE_0389CC             ;$0389C8    ||
    LDY.b #$D0                  ;$0389CA    ||| Y speed to give the blue Koopa when sliding up a slope.
CODE_0389CC:                    ;           ||
    STY $AA,X                   ;$0389CC    |/
    LDA $13                     ;$0389CE    |\ 
    AND.b #$01                  ;$0389D0    || Return every odd frame.
    BNE Return0389FE            ;$0389D2    |/
    LDA.w $15B8,X               ;$0389D4    |\ Branch if not on flat ground.
    BNE CODE_0389EC             ;$0389D7    |/
    LDA $B6,X                   ;$0389D9    |\ 
    BNE CODE_0389E3             ;$0389DB    || If the Koopa has come to a stop, set its timer for returning to normal.
    LDA.b #$20                  ;$0389DD    ||
    STA.w $1558,X               ;$0389DF    |/
    RTS                         ;$0389E2    |

CODE_0389E3:                    ;```````````| Not stationary.
    BPL CODE_0389E9             ;$0389E3    |\ 
    INC $B6,X                   ;$0389E5    ||
    INC $B6,X                   ;$0389E7    || Apply friction.
CODE_0389E9:                    ;           ||
    DEC $B6,X                   ;$0389E9    |/
    RTS                         ;$0389EB    |

CODE_0389EC:                    ;```````````| Not on flat ground; apply X acceleration.
    ASL                         ;$0389EC    |\ 
    ROL                         ;$0389ED    ||
    AND.b #$01                  ;$0389EE    ||
    TAY                         ;$0389F0    ||
    LDA $B6,X                   ;$0389F1    || Accelerate, if not already at the max X speed.
    CMP.w DATA_038954,Y         ;$0389F3    ||
    BEQ Return0389FE            ;$0389F6    ||
    CLC                         ;$0389F8    ||
    ADC.w DATA_038956,Y         ;$0389F9    ||
    STA $B6,X                   ;$0389FC    |/
Return0389FE:                   ;           |
    RTS                         ;$0389FE    |


CODE_0389FF:                    ;```````````| Subroutine for the sliding blue Koopa to generate friction smoke.
    LDA $B6,X                   ;$0389FF    |\ 
    BEQ Return038A20            ;$038A01    ||
    LDA $13                     ;$038A03    ||
    AND.b #$03                  ;$038A05    || Return if:
    BNE Return038A20            ;$038A07    || - Not moving
    LDA.b #$04                  ;$038A09    || - Not a frame to generate smoke
    STA $00                     ;$038A0B    || - Offscreen
    LDA.b #$0A                  ;$038A0D    ||
    STA $01                     ;$038A0F    ||
    JSR IsSprOffScreenBnk3      ;$038A11    ||
    BNE Return038A20            ;$038A14    |/
    LDY.b #$03                  ;$038A16    |\ 
CODE_038A18:                    ;           ||
    LDA.w $17C0,Y               ;$038A18    ||
    BEQ CODE_038A21             ;$038A1B    || Find an empty smoke sprite slot and return if none found.
    DEY                         ;$038A1D    ||
    BPL CODE_038A18             ;$038A1E    ||
Return038A20:                   ;           ||
    RTS                         ;$038A20    |/
CODE_038A21:                    ;           |
    LDA.b #$03                  ;$038A21    |\\ Smoke sprite to spawn (friction smoke).
    STA.w $17C0,Y               ;$038A23    |/
    LDA $E4,X                   ;$038A26    |\ 
    CLC                         ;$038A28    ||
    ADC $00                     ;$038A29    ||
    STA.w $17C8,Y               ;$038A2B    || Spawn a the Koopa's position.
    LDA $D8,X                   ;$038A2E    ||
    CLC                         ;$038A30    ||
    ADC $01                     ;$038A31    ||
    STA.w $17C4,Y               ;$038A33    |/
    LDA.b #$13                  ;$038A36    |\ Set initial timer for the smoke.
    STA.w $17CC,Y               ;$038A38    |/
    RTS                         ;$038A3B    |





    ; Bowser statue misc RAM:
    ; $C2   - Statue type. 0 = normal, 1/3 = fire, 2 = jumping
    ; $1540 - Timer for the jumping statue, to wait before jumping.
    ; $1602 - Animation frame.
    ;          0 = normal, 1 = jumping

BowserStatue:                   ;-----------| Bowser statue MAIN
    JSR BowserStatueGfx         ;$038A3C    | Draw GFX.
    LDA $9D                     ;$038A3F    |\ Return if game frozen.
    BNE Return038A68            ;$038A41    |/
    JSR SubOffscreen0Bnk3       ;$038A43    | Process offscreen from -$40 to +$30.
    LDA $C2,X                   ;$038A46    |
    JSL ExecutePtr              ;$038A48    |

BowserStatuePtrs:               ;$038A4C    | Bowser statue pointers.
    dw CODE_038A57              ; 0 - Normal
    dw CODE_038A54              ; 1 - Fire-breathing
    dw CODE_038A69              ; 2 - Jumping
    dw CODE_038A54              ; 3 - Fire-breathing


CODE_038A54:                    ;-----------| Bowser Statue type 1/3 - Fire
    JSR CODE_038ACB             ;$038A54    | Spawn fireballs.

CODE_038A57:                    ;```````````| Bowser Statue type 0 - Normal
    JSL InvisBlkMainRt          ;$038A57    | Make solid.
    JSL UpdateSpritePos         ;$038A5B    | Update X/Y position, apply gravity, and process interaction with blocks.
    LDA.w $1588,X               ;$038A5F    |\ 
    AND.b #$04                  ;$038A62    || If touching the ground, clear the statue's Y speed.
    BEQ Return038A68            ;$038A64    ||
    STZ $AA,X                   ;$038A66    |/
Return038A68:                   ;           |
    RTS                         ;$038A68    |

CODE_038A69:                    ;-----------| Bowser Statue type 2 - Jumping
    ASL.w $167A,X               ;$038A69    |\ 
    LSR.w $167A,X               ;$038A6C    || Process interaction with Mario, and hurt him if in contact.
    JSL MarioSprInteract        ;$038A6F    |/
    STZ.w $1602,X               ;$038A73    |\ 
    LDA $AA,X                   ;$038A76    ||
    CMP.b #$10                  ;$038A78    || Animate the statue's jump.
    BPL CODE_038A7F             ;$038A7A    ||
    INC.w $1602,X               ;$038A7C    |/
CODE_038A7F:                    ;           |
    JSL UpdateSpritePos         ;$038A7F    | Update X/Y position, apply gravity, and process interaction with blocks.
    LDA.w $1588,X               ;$038A83    |\ 
    AND.b #$03                  ;$038A86    ||
    BEQ CODE_038A99             ;$038A88    ||
    LDA $B6,X                   ;$038A8A    ||
    EOR.b #$FF                  ;$038A8C    || If hitting the side of a block, turn the statue around.
    INC A                       ;$038A8E    ||
    STA $B6,X                   ;$038A8F    ||
    LDA.w $157C,X               ;$038A91    ||
    EOR.b #$01                  ;$038A94    ||
    STA.w $157C,X               ;$038A96    |/
CODE_038A99:                    ;           |
    LDA.w $1588,X               ;$038A99    |\ 
    AND.b #$04                  ;$038A9C    || Return if not hitting the ground.
    BEQ Return038AC6            ;$038A9E    |/
    LDA.b #$10                  ;$038AA0    |\\ Y speed for the Bowser statue while on the ground.
    STA $AA,X                   ;$038AA2    |/
    STZ $B6,X                   ;$038AA4    | Clear X speed.
    LDA.w $1540,X               ;$038AA6    |\ Branch if the statue's "waiting to jump" timer hasn't been set yet.
    BEQ CODE_038AC1             ;$038AA9    |/
    DEC A                       ;$038AAB    |\ Return if not time to jump.
    BNE Return038AC6            ;$038AAC    |/
    LDA.b #$C0                  ;$038AAE    |\\ Y speed to give the Bowser Statue when jumping.
    STA $AA,X                   ;$038AB0    |/
    JSR SubHorzPosBnk3          ;$038AB2    |\ 
    TYA                         ;$038AB5    ||
    STA.w $157C,X               ;$038AB6    || Jump towards Mario.
    LDA.w BwsrStatueSpeed,Y     ;$038AB9    ||
    STA $B6,X                   ;$038ABC    |/
    RTS                         ;$038ABE    |

BwsrStatueSpeed:                ;$038ABF    | X speeds for the jumping Bowser statue.
    db $10,$F0

CODE_038AC1:                    ;```````````| Need to set the Bowser Statue's "waiting to jump" timer.
    LDA.b #$30                  ;$038AC1    |\\ How long the statue waits on the ground before jumping.
    STA.w $1540,X               ;$038AC3    |/
Return038AC6:                   ;           |
    RTS                         ;$038AC6    |



BwserFireDispXLo:               ;$038AC7    | X offsets (lo) for fireballs spawned by the Bowser statue.
    db $10,$F0

BwserFireDispXHi:               ;$038AC9    | X offsets (hi) for fireballs spawned by the Bowser statue.
    db $00,$FF

CODE_038ACB:                    ;-----------| Routine to generate fireballs for the fire Bowser statue.
    TXA                         ;$038ACB    |\ 
    ASL                         ;$038ACC    ||
    ASL                         ;$038ACD    || Return if not a frame to shoot a fireball.
    ADC $13                     ;$038ACE    ||
    AND.b #$7F                  ;$038AD0    ||
    BNE Return038B24            ;$038AD2    |/
    JSL FindFreeSprSlot         ;$038AD4    |\ Return if a sprite slot can't be found.
    BMI Return038B24            ;$038AD8    |/
    LDA.b #$17                  ;$038ADA    |\ SFX for the Bowser statue shooting a fireball.
    STA.w $1DFC                 ;$038ADC    |/
    LDA.b #$08                  ;$038ADF    |\ 
    STA.w $14C8,Y               ;$038AE1    ||
    LDA.b #$B3                  ;$038AE4    ||| Sprite spawned by the Bowser statue (fireball).
    STA.w $009E,Y               ;$038AE6    |/
    LDA $E4,X                   ;$038AE9    |\ 
    STA $00                     ;$038AEB    ||
    LDA.w $14E0,X               ;$038AED    ||
    STA $01                     ;$038AF0    ||
    PHX                         ;$038AF2    ||
    LDA.w $157C,X               ;$038AF3    ||
    TAX                         ;$038AF6    || Spawn at the statue's X position, offset to the side.
    LDA $00                     ;$038AF7    ||
    CLC                         ;$038AF9    ||
    ADC.w BwserFireDispXLo,X    ;$038AFA    ||
    STA.w $00E4,Y               ;$038AFD    ||
    LDA $01                     ;$038B00    ||
    ADC.w BwserFireDispXHi,X    ;$038B02    ||
    STA.w $14E0,Y               ;$038B05    |/
    TYX                         ;$038B08    |
    JSL InitSpriteTables        ;$038B09    |
    PLX                         ;$038B0D    |
    LDA $D8,X                   ;$038B0E    |\ 
    SEC                         ;$038B10    ||
    SBC.b #$02                  ;$038B11    ||
    STA.w $00D8,Y               ;$038B13    || Spawn tat the statue's Y position.
    LDA.w $14D4,X               ;$038B16    ||
    SBC.b #$00                  ;$038B19    ||
    STA.w $14D4,Y               ;$038B1B    |/
    LDA.w $157C,X               ;$038B1E    |\ Face the fireball the same direction as the statue.
    STA.w $157C,Y               ;$038B21    |/
Return038B24:                   ;           |
    RTS                         ;$038B24    |



BwsrStatueDispX:                ;$038B25    | X offsets for each tile in the Bowser statue.
    db $08,$F8,$00                          ; Right
    db $00,$08,$00                          ; Left

BwsrStatueDispY:                ;$038B2B    | Y offsets for each tile in the Bowser statue.
    db $10,$F8,$00

BwsrStatueTiles:                ;$038B2E    | Tile numbers for each tile in the Bowser statue.
    db $56,$30,$41                          ; Normal (last tile unused)
    db $56,$30,$35                          ; Jumping

BwsrStatueTileSize:             ;$038B34    | Tile size for each tile in the Bowser statue.
    db $00,$02,$02

BwsrStatueGfxProp:              ;$038B37    | YXPPCCCT for each tile in the Bowser statue.
    db $00,$00,$00                          ; Right
    db $40,$40,$40                          ; Left

BowserStatueGfx:                ;-----------| Bowser Statue GFX routine
    JSR GetDrawInfoBnk3         ;$038B3D    |
    LDA.w $1602,X               ;$038B40    |\ $04 = animation frame
    STA $04                     ;$038B43    |/
    EOR.b #$01                  ;$038B45    |\ 
    DEC A                       ;$038B47    || $03 = value indicating how many tiles to draw. 00 (2 tiles) for normal frame, FF (3 tiles) for jumping.
    STA $03                     ;$038B48    |/
    LDA.w $15F6,X               ;$038B4A    |\ $05 = base YXPPCCCT
    STA $05                     ;$038B4D    |/
    LDA.w $157C,X               ;$038B4F    |\ $02 = horizontal direction
    STA $02                     ;$038B52    |/
    PHX                         ;$038B54    |
    LDX.b #$02                  ;$038B55    |
CODE_038B57:                    ;```````````| Tile loop.
    PHX                         ;$038B57    |
    LDA $02                     ;$038B58    |\ 
    BNE CODE_038B5F             ;$038B5A    ||
    INX                         ;$038B5C    ||
    INX                         ;$038B5D    ||
    INX                         ;$038B5E    || Store X position to OAM.
CODE_038B5F:                    ;           ||
    LDA $00                     ;$038B5F    ||
    CLC                         ;$038B61    ||
    ADC.w BwsrStatueDispX,X     ;$038B62    ||
    STA.w $0300,Y               ;$038B65    |/
    LDA.w BwsrStatueGfxProp,X   ;$038B68    |\ 
    ORA $05                     ;$038B6B    || Store YXPPCCCT to OAM.
    ORA $64                     ;$038B6D    ||
    STA.w $0303,Y               ;$038B6F    |/
    PLX                         ;$038B72    |
    LDA $01                     ;$038B73    |\ 
    CLC                         ;$038B75    || Store Y positin to OAM.
    ADC.w BwsrStatueDispY,X     ;$038B76    ||
    STA.w $0301,Y               ;$038B79    |/
    PHX                         ;$038B7C    |
    LDA $04                     ;$038B7D    |\ 
    BEQ CODE_038B84             ;$038B7F    ||
    INX                         ;$038B81    ||
    INX                         ;$038B82    || Store tile number to OAM.
    INX                         ;$038B83    ||
CODE_038B84:                    ;           ||
    LDA.w BwsrStatueTiles,X     ;$038B84    ||
    STA.w $0302,Y               ;$038B87    |/
    PLX                         ;$038B8A    |
    PHY                         ;$038B8B    |
    TYA                         ;$038B8C    |\ 
    LSR                         ;$038B8D    ||
    LSR                         ;$038B8E    || Store tile size to OAM.
    TAY                         ;$038B8F    ||
    LDA.w BwsrStatueTileSize,X  ;$038B90    ||
    STA.w $0460,Y               ;$038B93    |/
    PLY                         ;$038B96    |
    INY                         ;$038B97    |\ 
    INY                         ;$038B98    ||
    INY                         ;$038B99    ||
    INY                         ;$038B9A    || Loop for all of the tiles.
    DEX                         ;$038B9B    ||
    CPX $03                     ;$038B9C    ||
    BNE CODE_038B57             ;$038B9E    |/
    PLX                         ;$038BA0    |
    LDY.b #$FF                  ;$038BA1    |\ 
    LDA.b #$02                  ;$038BA3    || Upload 3 manually-sized tiles.
    JSL FinishOAMWrite          ;$038BA5    |/
    RTS                         ;$038BA9    |





DATA_038BAA:                    ;$038BAA    | Interaction Y positions for the Carrot Top Lift at each X position. This effctively defines the shape of the platform.
    db $20,$20,$20,$20,$20,$20,$20,$20      ; Up-Right platform
    db $20,$20,$20,$20,$20,$20,$20,$20
    db $20,$1F,$1E,$1D,$1C,$1B,$1A,$19
    db $18,$17,$16,$15,$14,$13,$12,$11
    db $10,$0F,$0E,$0D,$0C,$0B,$0A,$09
    db $08,$07,$06,$05,$04,$03,$02,$01
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
    
    db $00,$00,$00,$00,$00,$00,$00,$00      ; Up-Left platform
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $01,$02,$03,$04,$05,$06,$07,$08
    db $09,$0A,$0B,$0C,$0D,$0E,$0F,$10
    db $11,$12,$13,$14,$15,$16,$17,$18
    db $19,$1A,$1B,$1C,$1D,$1E,$1F,$20
    db $20,$20,$20,$20,$20,$20,$20,$20
    db $20,$20,$20,$20,$20,$20,$20,$20

DATA_038C2A:                    ;$038C2A    | Movement speeds for the Carrot Top Lift.
    db $00,$F8,$00,$08

Return038C2E:
    RTS                         ;$038C2E    |

    ; Carrot Top Lift misc RAM:
    ; $C2   - Movement phase. Value mod 4: 0/2 = stationary, 1 = moving left, 3 = moving right
    ; $151C - Previous X position, for determining whether or not Mario is on the platform.
    ; $1540 - Movement timer.
    
CarrotTopLift:                  ;-----------| Carrot Top Lift MAIN
    JSR CarrotTopLiftGfx        ;$038C2F    | Draw GFX.
    LDA $9D                     ;$038C32    |\ Return if game frozen.
    BNE Return038C2E            ;$038C34    |/
    JSR SubOffscreen0Bnk3       ;$038C36    | Process offscreen from -$40 to +$30.
    LDA.w $1540,X               ;$038C39    |\ 
    BNE CODE_038C45             ;$038C3C    ||
    INC $C2,X                   ;$038C3E    || If at the end of a particular movement, increment phase pointer and set timer.
    LDA.b #$80                  ;$038C40    ||
    STA.w $1540,X               ;$038C42    |/
CODE_038C45:                    ;           |
    LDA $C2,X                   ;$038C45    |\ 
    AND.b #$03                  ;$038C47    ||
    TAY                         ;$038C49    || Store X speed for the current movement.
    LDA.w DATA_038C2A,Y         ;$038C4A    ||
    STA $B6,X                   ;$038C4D    |/
    LDA $B6,X                   ;$038C4F    |\ 
    LDY $9E,X                   ;$038C51    ||
    CPY.b #$B8                  ;$038C53    ||
    BEQ CODE_038C5A             ;$038C55    || Store Y speed for the current movement, as equal to the X speed.
    EOR.b #$FF                  ;$038C57    ||  If sprite B8 (up-left), reverse the Y speed.
    INC A                       ;$038C59    ||
CODE_038C5A:                    ;           ||
    STA $AA,X                   ;$038C5A    |/
    JSL UpdateYPosNoGrvty       ;$038C5C    | Update Y position.
    LDA $E4,X                   ;$038C60    |\ Preserve old X position, for moving Mario with the platform.
    STA.w $151C,X               ;$038C62    |/
    JSL UpdateXPosNoGrvty       ;$038C65    | Update X position.
    JSR CODE_038CE4             ;$038C69    |\ 
    JSL GetSpriteClippingA      ;$038C6C    ||
    JSL CheckForContact         ;$038C70    || Return if not in contact with the platform, or Mario is moving upwards.
    BCC Return038CE3            ;$038C74    ||
    LDA $7D                     ;$038C76    ||
    BMI Return038CE3            ;$038C78    |/
    LDA $94                     ;$038C7A    |\ 
    SEC                         ;$038C7C    ||
    SBC.w $151C,X               ;$038C7D    ||
    CLC                         ;$038C80    ||
    ADC.b #$1C                  ;$038C81    ||
    LDY $9E,X                   ;$038C83    || Get index to the Y position table based on Mario's current X position within the platform.
    CPY.b #$B8                  ;$038C85    ||
    BNE CODE_038C8C             ;$038C87    ||
    CLC                         ;$038C89    ||
    ADC.b #$38                  ;$038C8A    ||
CODE_038C8C:                    ;           ||
    TAY                         ;$038C8C    |/
    LDA.w $187A                 ;$038C8D    |\ 
    CMP.b #$01                  ;$038C90    ||
    LDA.b #$20                  ;$038C92    ||
    BCC CODE_038C98             ;$038C94    || Get lower interaction point for Mario's Y position, accounting for whether he's on Yoshi or not.
    LDA.b #$30                  ;$038C96    ||  This point determines whether or not Mario is on top of the platform.
CODE_038C98:                    ;           ||
    CLC                         ;$038C98    ||
    ADC $96                     ;$038C99    ||
    STA $00                     ;$038C9B    |/
    LDA $D8,X                   ;$038C9D    |\ 
    CLC                         ;$038C9F    ||
    ADC.w DATA_038BAA,Y         ;$038CA0    || Return if not in contact with the platform at the current X position.
    CMP $00                     ;$038CA3    ||
    BPL Return038CE3            ;$038CA5    |/
    LDA.w $187A                 ;$038CA7    |\ 
    CMP.b #$01                  ;$038CAA    ||
    LDA.b #$1D                  ;$038CAC    || Get upper interaction point for Mario's Y position, accounting for whether he's on Yoshi or not.
    BCC CODE_038CB2             ;$038CAE    ||  This point indicates where Mario's feet are relative to his position.
    LDA.b #$2D                  ;$038CB0    ||
CODE_038CB2:                    ;           ||
    STA $00                     ;$038CB2    |/
    LDA $D8,X                   ;$038CB4    |\ 
    CLC                         ;$038CB6    ||
    ADC.w DATA_038BAA,Y         ;$038CB7    ||
    PHP                         ;$038CBA    ||
    SEC                         ;$038CBB    ||
    SBC $00                     ;$038CBC    || Move Mario on top of the platform.
    STA $96                     ;$038CBE    ||
    LDA.w $14D4,X               ;$038CC0    ||
    SBC.b #$00                  ;$038CC3    ||
    PLP                         ;$038CC5    ||
    ADC.b #$00                  ;$038CC6    ||
    STA $97                     ;$038CC8    |/
    STZ $7D                     ;$038CCA    | Clear Mario's Y speed.
    LDA.b #$01                  ;$038CCC    |\ Set flag for being on a sprite.
    STA.w $1471                 ;$038CCE    |/
    LDY.b #$00                  ;$038CD1    |\ 
    LDA.w $1491                 ;$038CD3    ||
    BPL CODE_038CD9             ;$038CD6    ||
    DEY                         ;$038CD8    ||
CODE_038CD9:                    ;           ||
    CLC                         ;$038CD9    || Move Mario horizontally with the platform.
    ADC $94                     ;$038CDA    ||
    STA $94                     ;$038CDC    ||
    TYA                         ;$038CDE    ||
    ADC $95                     ;$038CDF    ||
    STA $95                     ;$038CE1    |/
Return038CE3:                   ;           |
    RTS                         ;$038CE3    |



CODE_038CE4:                    ;-----------| Routine for the Carrot Top platform to get Mario's clipping data.
    LDA $94                     ;$038CE4    |\ 
    CLC                         ;$038CE6    ||
    ADC.b #$04                  ;$038CE7    ||
    STA $00                     ;$038CE9    || Get clipping X position.
    LDA $95                     ;$038CEB    ||
    ADC.b #$00                  ;$038CED    ||
    STA $08                     ;$038CEF    |/
    LDA.b #$08                  ;$038CF1    |\ 
    STA $02                     ;$038CF3    || Get interaction area as an 8x8 square.
    STA $03                     ;$038CF5    |/
    LDA.b #$20                  ;$038CF7    |\ 
    LDY.w $187A                 ;$038CF9    ||
    BEQ CODE_038D00             ;$038CFC    ||
    LDA.b #$30                  ;$038CFE    ||
CODE_038D00:                    ;           ||
    CLC                         ;$038D00    || Get clipping Y position.
    ADC $96                     ;$038D01    ||
    STA $01                     ;$038D03    ||
    LDA $97                     ;$038D05    ||
    ADC.b #$00                  ;$038D07    ||
    STA $09                     ;$038D09    |/
    RTS                         ;$038D0B    |



DiagPlatDispX:                  ;$038D0C    | X offsets for each tile of the Carrot Top platform.
    db $10,$00,$10                          ; Down-left
    db $00,$10,$00                          ; Up-left

DiagPlatDispY:                  ;$038D12    | Y offsets for each tile of the Carrot Top platform.
    db $00,$10,$10                          ; Down-left
    db $00,$10,$10                          ; Up-left

DiagPlatTiles2:                 ;$038D18    | Tile numbers for each tile of the Carrot Top platform.
    db $E4,$E0,$E2                          ; Down-left
    db $E4,$E0,$E2                          ; Up-left

DiagPlatGfxProp:                ;$038D1E    | YXPPCCCT for each tile of the Carrot Top platform.
    db $0B,$0B,$0B                          ; Down-left
    db $4B,$4B,$4B                          ; Up-left

CarrotTopLiftGfx:               ;-----------| Carrot Top Lift GFX routine
    JSR GetDrawInfoBnk3         ;$038D24    |
    PHX                         ;$038D27    |
    LDA $9E,X                   ;$038D28    |\ 
    CMP.b #$B8                  ;$038D2A    ||
    LDX.b #$02                  ;$038D2C    || Get index to the above tables, based on which platform this is.
    STX $02                     ;$038D2E    ||
    BCC CODE_038D34             ;$038D30    ||
    LDX.b #$05                  ;$038D32    |/
CODE_038D34:                    ;           |
    LDA $00                     ;$038D34    |\ 
    CLC                         ;$038D36    || Store X position to OAM.
    ADC.w DiagPlatDispX,X       ;$038D37    ||
    STA.w $0300,Y               ;$038D3A    |/
    LDA $01                     ;$038D3D    |\ 
    CLC                         ;$038D3F    || Store Y position to OAM.
    ADC.w DiagPlatDispY,X       ;$038D40    ||
    STA.w $0301,Y               ;$038D43    |/
    LDA.w DiagPlatTiles2,X      ;$038D46    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$038D49    |/
    LDA.w DiagPlatGfxProp,X     ;$038D4C    |\ 
    ORA $64                     ;$038D4F    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$038D51    |/
    INY                         ;$038D54    |\ 
    INY                         ;$038D55    ||
    INY                         ;$038D56    ||
    INY                         ;$038D57    || Loop for all of the tiles.
    DEX                         ;$038D58    ||
    DEC $02                     ;$038D59    ||
    BPL CODE_038D34             ;$038D5B    |/
    PLX                         ;$038D5D    |
    LDY.b #$02                  ;$038D5E    |\ 
    TYA                         ;$038D60    || Upload 3 16x16 tiles.
    JSL FinishOAMWrite          ;$038D61    |/
    RTS                         ;$038D65    |





DATA_038D66:
    db $00,$04,$07,$08,$08,$07,$04,$00
    db $00

    ; Message box misc RAM:
    ; $C2   - Flag for the box having been hit from below.
    ; $1528 - Unused, but would cause Mario to move horizontally when standing on the platform if non-zero.
    ; $1558 - Timer for the bounce animation when hit below.
    ; $157C - Horizontal direction the sprite is facing. Always 0.

InfoBox:                        ;-----------| Message Box MAIN
    JSL InvisBlkMainRt          ;$038D6F    | Make solid.
    JSR SubOffscreen0Bnk3       ;$038D73    | Process offscreen from -$40 to +$30.
    LDA.w $1558,X               ;$038D76    |\ 
    CMP.b #$01                  ;$038D79    || Branch if not time to display the box's message.
    BNE CODE_038D93             ;$038D7B    ||
    LDA.b #$22                  ;$038D7D    ||\ SFX for hitting a message box.
    STA.w $1DFC                 ;$038D7F    ||/
    STZ.w $1558,X               ;$038D82    ||
    STZ $C2,X                   ;$038D85    ||
    LDA $E4,X                   ;$038D87    ||\ 
    LSR                         ;$038D89    |||
    LSR                         ;$038D8A    |||
    LSR                         ;$038D8B    ||| Activate message.
    LSR                         ;$038D8C    |||
    AND.b #$01                  ;$038D8D    |||
    INC A                       ;$038D8F    |||
    STA.w $1426                 ;$038D90    |//
CODE_038D93:                    ;           |
    LDA.w $1558,X               ;$038D93    |\ 
    LSR                         ;$038D96    ||
    TAY                         ;$038D97    ||
    LDA $1C                     ;$038D98    ||
    PHA                         ;$038D9A    ||
    CLC                         ;$038D9B    || If the block was hit and is doing a bounce animation, offset Y position.
    ADC.w DATA_038D66,Y         ;$038D9C    ||
    STA $1C                     ;$038D9F    ||
    LDA $1D                     ;$038DA1    ||
    PHA                         ;$038DA3    ||
    ADC.b #$00                  ;$038DA4    ||
    STA $1D                     ;$038DA6    |/
    JSL GenericSprGfxRt2        ;$038DA8    |\ 
    LDY.w $15EA,X               ;$038DAC    || Draw a 16x16 sprite.
    LDA.b #$C0                  ;$038DAF    ||| Tile the message box uses.
    STA.w $0302,Y               ;$038DB1    |/
    PLA                         ;$038DB4    |\ 
    STA $1D                     ;$038DB5    || Restore Y position.
    PLA                         ;$038DB7    ||
    STA $1C                     ;$038DB8    |/
    RTS                         ;$038DBA    |





    ; Timed lift misc RAM:
    ; $C2   - Flag for whether the platform has been started (10) or not (00).
    ; $1528 - Number of pixels moved in a frame, for moving Mario.
    ; $1570 - Timer for the platform's clock.
    
TimedLift:                      ;-----------| Timed Lift MAIN
    JSR TimedPlatformGfx        ;$038DBB    | Draw GFX.
    LDA $9D                     ;$038DBE    |\ Return if game frozen.
    BNE Return038DEF            ;$038DC0    |/
    JSR SubOffscreen0Bnk3       ;$038DC2    | Process offscreen from -$40 to +$30.
    LDA $13                     ;$038DC5    |\ 
    AND.b #$00                  ;$038DC7    ||
    BNE CODE_038DD7             ;$038DC9    ||
    LDA $C2,X                   ;$038DCB    || If the platform has started moving, decrement the timer each frame.
    BEQ CODE_038DD7             ;$038DCD    ||
    LDA.w $1570,X               ;$038DCF    ||
    BEQ CODE_038DD7             ;$038DD2    ||
    DEC.w $1570,X               ;$038DD4    |/
CODE_038DD7:                    ;           |
    LDA.w $1570,X               ;$038DD7    |\ Branch if the platform hasn't fallen yet.
    BEQ CODE_038DF0             ;$038DDA    |/
    JSL UpdateXPosNoGrvty       ;$038DDC    | Update X position.
    STA.w $1528,X               ;$038DE0    |\ 
    JSL InvisBlkMainRt          ;$038DE3    || Make solid and return if Mario isn't on the platform.
    BCC Return038DEF            ;$038DE7    |/
    LDA.b #$10                  ;$038DE9    |\\ X speed to give the timed platform once started.
    STA $B6,X                   ;$038DEB    ||
    STA $C2,X                   ;$038DED    |/
Return038DEF:                   ;           |
    RTS                         ;$038DEF    |

CODE_038DF0:                    ;```````````| Platform's timer has run out, make it fall.
    JSL UpdateSpritePos         ;$038DF0    | Update X/Y position and apply gravity.
    LDA.w $1491                 ;$038DF4    |\ 
    STA.w $1528,X               ;$038DF7    || Make solid.
    JSL InvisBlkMainRt          ;$038DFA    |/
    RTS                         ;$038DFE    |



TimedPlatDispX:                 ;$038DFF    | X offsets for each tile in the timed platform.
    db $00,$10,$0C

TimedPlatDispY:                 ;$038E02    | Y offsets for each tile in the timed platform.
    db $00,$00,$04

TimedPlatTiles:                 ;$038E05    | Tile numbers for each tile in the timed platform.
    db $C4,$C4,$00                          ; Last byte unused (it's the number's tile).

TimedPlatGfxProp:               ;$038E08    | YXPPCCCT for each tile in the timed platform.
    db $0B,$4B,$0B

TimedPlatTileSize:              ;$038E0B    | Size for each tile in the timed platform.
    db $02,$02,$00

TimedPlatNumTiles:              ;$038E0E    | Tile numbers for each of the numbers on the timed platform.
    db $B6,$B5,$B4,$B3

TimedPlatformGfx:               ;-----------| Timed Platform GFX routine
    JSR GetDrawInfoBnk3         ;$038E12    |
    LDA.w $1570,X               ;$038E15    |\ 
    PHX                         ;$038E18    ||
    PHA                         ;$038E19    ||
    LSR                         ;$038E1A    ||
    LSR                         ;$038E1B    ||
    LSR                         ;$038E1C    || $02 = Tile for the number on the platform.
    LSR                         ;$038E1D    ||
    LSR                         ;$038E1E    ||
    LSR                         ;$038E1F    ||
    TAX                         ;$038E20    ||
    LDA.w TimedPlatNumTiles,X   ;$038E21    ||
    STA $02                     ;$038E24    |/
    LDX.b #$02                  ;$038E26    |\ 
    PLA                         ;$038E28    ||
    CMP.b #$08                  ;$038E29    || Get number of tiles to upload; if the timer has run out, don't draw the number.
    BCS CODE_038E2E             ;$038E2B    ||
    DEX                         ;$038E2D    |/
CODE_038E2E:                    ;```````````| Tile loop.
    LDA $00                     ;$038E2E    |\ 
    CLC                         ;$038E30    || Store X position to OAM.
    ADC.w TimedPlatDispX,X      ;$038E31    ||
    STA.w $0300,Y               ;$038E34    |/
    LDA $01                     ;$038E37    |\ 
    CLC                         ;$038E39    || Store Y position to OAM.
    ADC.w TimedPlatDispY,X      ;$038E3A    ||
    STA.w $0301,Y               ;$038E3D    |/
    LDA.w TimedPlatTiles,X      ;$038E40    |\ 
    CPX.b #$02                  ;$038E43    ||
    BNE CODE_038E49             ;$038E45    || Store tile number to OAM.
    LDA $02                     ;$038E47    ||
CODE_038E49:                    ;           ||
    STA.w $0302,Y               ;$038E49    |/
    LDA.w TimedPlatGfxProp,X    ;$038E4C    |\ 
    ORA $64                     ;$038E4F    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$038E51    |/
    PHY                         ;$038E54    |
    TYA                         ;$038E55    |\ 
    LSR                         ;$038E56    ||
    LSR                         ;$038E57    || Store size to OAM.
    TAY                         ;$038E58    ||
    LDA.w TimedPlatTileSize,X   ;$038E59    ||
    STA.w $0460,Y               ;$038E5C    |/
    PLY                         ;$038E5F    |
    INY                         ;$038E60    |\ 
    INY                         ;$038E61    ||
    INY                         ;$038E62    || Loop for all of the tiles.
    INY                         ;$038E63    ||
    DEX                         ;$038E64    ||
    BPL CODE_038E2E             ;$038E65    |/
    PLX                         ;$038E67    |
    LDY.b #$FF                  ;$038E68    |\ 
    LDA.b #$02                  ;$038E6A    || Upload 3 manually-sized tiles.
    JSL FinishOAMWrite          ;$038E6C    |/
    RTS                         ;$038E70    |





GreyMoveBlkSpeed:               ;           |
    db $00,$F0,$00,$10

GreyMoveBlkTiming:              ;           |
    db $40,$50,$40,$50

    ; Castle Block misc RAM:
    ; $C2   - Movement phase. Mod 4: 0/2 = stationary, 1 = left, 2 = right.
    ; $1528 - Number of pixels moved in a frame, for moving Mario.
    ; $1540 - Movement timer.
    ; $1558 - Unused timer set when hit from below, when $C2 is 0.
    ; $1564 - Unused timer set when hit from below.

GreyCastleBlock:                ;-----------| Moving grey castle block MAIN
    JSR CODE_038EB4             ;$038E79    | Draw GFX.
    LDA $9D                     ;$038E7C    |\ Return if game frozen.
    BNE Return038EA7            ;$038E7E    |/
    LDA.w $1540,X               ;$038E80    |\ 
    BNE CODE_038E92             ;$038E83    ||
    INC $C2,X                   ;$038E85    ||
    LDA $C2,X                   ;$038E87    || If at the end of a particular movement, increment phase pointer and set timer.
    AND.b #$03                  ;$038E89    ||
    TAY                         ;$038E8B    ||
    LDA.w GreyMoveBlkTiming,Y   ;$038E8C    ||
    STA.w $1540,X               ;$038E8F    |/
CODE_038E92:                    ;           |
    LDA $C2,X                   ;$038E92    |\ 
    AND.b #$03                  ;$038E94    ||
    TAY                         ;$038E96    || Store X speed.
    LDA.w GreyMoveBlkSpeed,Y    ;$038E97    ||
    STA $B6,X                   ;$038E9A    |/
    JSL UpdateXPosNoGrvty       ;$038E9C    | Update X position.
    STA.w $1528,X               ;$038EA0    |\ Make solid.
    JSL InvisBlkMainRt          ;$038EA3    |/
Return038EA7:                   ;           |
    RTS                         ;$038EA7    |



GreyMoveBlkDispX:               ;$038EA8    | Moving castle block X offsets.
    db $00,$10,$00,$10

GreyMoveBlkDispY:               ;$038EAC    | Moving castle block Y offsets.
    db $00,$00,$10,$10

GreyMoveBlkTiles:               ;$038EB0    | Moving castle block tile numbers.
    db $CC,$CE,$EC,$EE

CODE_038EB4:                    ;-----------| Moving castle block GFX routine.
    JSR GetDrawInfoBnk3         ;$038EB4    |
    PHX                         ;$038EB7    |
    LDX.b #$03                  ;$038EB8    |
CODE_038EBA:                    ;           |
    LDA $00                     ;$038EBA    |\ 
    CLC                         ;$038EBC    || Store X position to OAM.
    ADC.w GreyMoveBlkDispX,X    ;$038EBD    ||
    STA.w $0300,Y               ;$038EC0    |/
    LDA $01                     ;$038EC3    |\ 
    CLC                         ;$038EC5    || Store Y position to OAM.
    ADC.w GreyMoveBlkDispY,X    ;$038EC6    ||
    STA.w $0301,Y               ;$038EC9    |/
    LDA.w GreyMoveBlkTiles,X    ;$038ECC    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$038ECF    |/ 
    LDA.b #$03                  ;$038ED2    |\ 
    ORA $64                     ;$038ED4    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$038ED6    |/
    INY                         ;$038ED9    |\ 
    INY                         ;$038EDA    ||
    INY                         ;$038EDB    || Loop for all tiles.
    INY                         ;$038EDC    ||
    DEX                         ;$038EDD    ||
    BPL CODE_038EBA             ;$038EDE    |/
    PLX                         ;$038EE0    |
    LDY.b #$02                  ;$038EE1    |\ 
    LDA.b #$03                  ;$038EE3    || Upload 4 16x16 tiles.
    JSL FinishOAMWrite          ;$038EE5    |/
    RTS                         ;$038EE9    |





StatueFireSpeed:                ;$038EEA    | X speeds for the statue fireball.
    db $10,$F0

    ; Statue Fireball misc RAM:
    ; $157C - Horizontal direction the sprite is facing.
    
StatueFireball:                 ;-----------| Statue fireball MAIN
    JSR StatueFireballGfx       ;$038EEC    | Draw GFX.
    LDA $9D                     ;$038EEF    |\ Return if game frozen.
    BNE Return038F06            ;$038EF1    |/
    JSR SubOffscreen0Bnk3       ;$038EF3    | Process offscreen from -$40 to +$30.
    JSL MarioSprInteract        ;$038EF6    | Process interaction with Mario.
    LDY.w $157C,X               ;$038EFA    |\ 
    LDA.w StatueFireSpeed,Y     ;$038EFD    || Store X speed.
    STA $B6,X                   ;$038F00    |/
    JSL UpdateXPosNoGrvty       ;$038F02    | Update X position.
Return038F06:                   ;           |
    RTS                         ;$038F06    |


StatueFireDispX:                ;$038F07    | X offsets for each tile of the statue fireball, indexed by its direction.
    db $08,$00
    db $00,$08

StatueFireTiles:                ;$038F0B    | Tile numbers for each frame of the statue fireball's animation.
    db $32,$50
    db $33,$34
    db $32,$50
    db $33,$34

StatueFireGfxProp:              ;$038F11    | YXPPCCCT for each frame of the statue fireball's animation.
    db $09,$09
    db $09,$09
    db $89,$89
    db $89,$89

StatueFireballGfx:              ;-----------| Statue fireball GFX routine
    JSR GetDrawInfoBnk3         ;$038F1B    |
    LDA.w $157C,X               ;$038F1E    |\ 
    ASL                         ;$038F21    || $02 = horizontal direction, x2.
    STA $02                     ;$038F22    |/
    LDA $14                     ;$038F24    |\ 
    LSR                         ;$038F26    ||
    AND.b #$03                  ;$038F27    || $03 = animation frame, x4
    ASL                         ;$038F29    ||
    STA $03                     ;$038F2A    |/
    PHX                         ;$038F2C    |
    LDX.b #$01                  ;$038F2D    |
CODE_038F2F:                    ;```````````| Tile loop.
    LDA $01                     ;$038F2F    |\ Store Y position to OAM.
    STA.w $0301,Y               ;$038F31    |/
    PHX                         ;$038F34    |
    TXA                         ;$038F35    |\ 
    ORA $02                     ;$038F36    ||
    TAX                         ;$038F38    ||
    LDA $00                     ;$038F39    || Store X position to OAM.
    CLC                         ;$038F3B    ||
    ADC.w StatueFireDispX,X     ;$038F3C    ||
    STA.w $0300,Y               ;$038F3F    |/
    PLA                         ;$038F42    |\ 
    PHA                         ;$038F43    ||
    ORA $03                     ;$038F44    || Store tile number to OAM.
    TAX                         ;$038F46    ||
    LDA.w StatueFireTiles,X     ;$038F47    ||
    STA.w $0302,Y               ;$038F4A    |/
    LDA.w StatueFireGfxProp,X   ;$038F4D    |\ 
    LDX $02                     ;$038F50    ||
    BNE CODE_038F56             ;$038F52    ||
    EOR.b #$40                  ;$038F54    || Store YXPPCCCT to OAM.
CODE_038F56:                    ;           ||
    ORA $64                     ;$038F56    ||
    STA.w $0303,Y               ;$038F58    |/
    PLX                         ;$038F5B    |
    INY                         ;$038F5C    |\ 
    INY                         ;$038F5D    ||
    INY                         ;$038F5E    || Loop for all tiles.
    INY                         ;$038F5F    ||
    DEX                         ;$038F60    ||
    BPL CODE_038F2F             ;$038F61    |/
    PLX                         ;$038F63    |
    LDY.b #$00                  ;$038F64    |\ 
    LDA.b #$01                  ;$038F66    || Upload 2 8x8 tiles.
    JSL FinishOAMWrite          ;$038F68    |/
    RTS                         ;$038F6C    |





BooStreamFrntTiles:             ;$038F6D    | Tile numbers for the Boo Stream's animation.
    db $88,$8C,$8E,$A8,$AA,$AE,$88,$8C

    ; Reflecting Fireball / Boo Stream misc RAM:
    ; $157C - (Boo Stream only) Horizontal direction the sprite is facing.
    
ReflectingFireball:             ;-----------| Reflecting fireball MAIN
    JSR CODE_038FF2             ;$038F75    | Draw GFX.
    BRA CODE_038FA4             ;$038F78    | Continue to routine below.


BooStream:                      ;-----------| Boo Stream MAIN
    LDA.b #$00                  ;$038F7A    |\ 
    LDY $B6,X                   ;$038F7C    ||
    BPL CODE_038F81             ;$038F7E    || Set horizontal direction based on current X speed.
    INC A                       ;$038F80    ||
CODE_038F81:                    ;           ||
    STA.w $157C,X               ;$038F81    |/
    JSL GenericSprGfxRt2        ;$038F84    | Draw a 16x16 tile.
    LDY.w $15EA,X               ;$038F88    |\ 
    LDA $14                     ;$038F8B    ||
    LSR                         ;$038F8D    ||
    LSR                         ;$038F8E    ||
    LSR                         ;$038F8F    ||
    LSR                         ;$038F90    ||
    AND.b #$01                  ;$038F91    ||
    STA $00                     ;$038F93    || Change tile number in OAM, animating based on the current frame number.
    TXA                         ;$038F95    ||
    AND.b #$03                  ;$038F96    ||
    ASL                         ;$038F98    ||
    ORA $00                     ;$038F99    ||
    PHX                         ;$038F9B    ||
    TAX                         ;$038F9C    ||
    LDA.w BooStreamFrntTiles,X  ;$038F9D    ||
    STA.w $0302,Y               ;$038FA0    |/
    PLX                         ;$038FA3    |
CODE_038FA4:                    ;```````````| Reflecting Fireball joins in.
    LDA.w $14C8,X               ;$038FA4    |\ 
    CMP.b #$08                  ;$038FA7    ||
    BNE Return038FF1            ;$038FA9    || Return if sprite dead or game frozen.
    LDA $9D                     ;$038FAB    ||
    BNE Return038FF1            ;$038FAD    |/
    TXA                         ;$038FAF    |\ 
    EOR $14                     ;$038FB0    ||
    AND.b #$07                  ;$038FB2    ||
    ORA.w $186C,X               ;$038FB4    || Boo Stream only:
    BNE CODE_038FC2             ;$038FB7    ||  Every 8 frames while vertically onscreen, spawn a stream trail minor extended sprite.
    LDA $9E,X                   ;$038FB9    ||
    CMP.b #$B0                  ;$038FBB    ||
    BNE CODE_038FC2             ;$038FBD    ||
    JSR CODE_039020             ;$038FBF    |/
CODE_038FC2:                    ;           |
    JSL UpdateYPosNoGrvty       ;$038FC2    | Update Y position.
    JSL UpdateXPosNoGrvty       ;$038FC6    | Update X position.
    JSL CODE_019138             ;$038FCA    | Process interaction with blocks.
    LDA.w $1588,X               ;$038FCE    |\ 
    AND.b #$03                  ;$038FD1    ||
    BEQ CODE_038FDC             ;$038FD3    ||
    LDA $B6,X                   ;$038FD5    || If hitting a wall, invert X speed.
    EOR.b #$FF                  ;$038FD7    ||
    INC A                       ;$038FD9    ||
    STA $B6,X                   ;$038FDA    |/
CODE_038FDC:                    ;           |
    LDA.w $1588,X               ;$038FDC    |\ 
    AND.b #$0C                  ;$038FDF    ||
    BEQ CODE_038FEA             ;$038FE1    ||
    LDA $AA,X                   ;$038FE3    || If hitting a ceiling/floor, invert Y speed.
    EOR.b #$FF                  ;$038FE5    ||
    INC A                       ;$038FE7    ||
    STA $AA,X                   ;$038FE8    |/
CODE_038FEA:                    ;           |
    JSL MarioSprInteract        ;$038FEA    | Process interaction with Mario.
    JSR SubOffscreen0Bnk3       ;$038FEE    | Process offscreen from -$40 to +$30.
Return038FF1:                   ;           |
    RTS                         ;$038FF1    |



CODE_038FF2:                    ;```````````| Routine to handle graphics for the Reflecting Fireball.
    JSL GenericSprGfxRt2        ;$038FF2    | Draw a 16x16 sprite.
    LDA $14                     ;$038FF6    |\ 
    LSR                         ;$038FF8    ||
    LSR                         ;$038FF9    || Get palette for current frame.
    LDA.b #$04                  ;$038FFA    ||
    BCC CODE_038FFF             ;$038FFC    ||
    ASL                         ;$038FFE    |/
CODE_038FFF:                    ;           |
    LDY $B6,X                   ;$038FFF    |\ 
    BPL CODE_039005             ;$039001    ||
    EOR.b #$40                  ;$039003    ||
CODE_039005:                    ;           ||
    LDY $AA,X                   ;$039005    || Get X/Y flip based on the direction the sprite is moving.
    BMI CODE_03900B             ;$039007    ||
    EOR.b #$80                  ;$039009    ||
CODE_03900B:                    ;           ||
    STA $00                     ;$03900B    |/
    LDY.w $15EA,X               ;$03900D    |
    LDA.b #$AC                  ;$039010    |\\ Tile to use for the reflecting fireball.
    STA.w $0302,Y               ;$039012    |/
    LDA.w $0303,Y               ;$039015    |\ 
    AND.b #$31                  ;$039018    || Change YXPPCCCT stored in OAM.
    ORA $00                     ;$03901A    ||
    STA.w $0303,Y               ;$03901C    |/
    RTS                         ;$03901F    |



CODE_039020:                    ;```````````| Subroutine to spawn the stream trail minor extended sprites for the Boo Stream.
    LDY.b #$0B                  ;$039020    |\ 
CODE_039022:                    ;           ||
    LDA.w $17F0,Y               ;$039022    ||
    BEQ CODE_039037             ;$039025    ||
    DEY                         ;$039027    ||
    BPL CODE_039022             ;$039028    || Find an empty minor extended sprite slot, or replace one if none found.
    DEC.w $185D                 ;$03902A    ||
    BPL CODE_039034             ;$03902D    ||
    LDA.b #$0B                  ;$03902F    ||
    STA.w $185D                 ;$039031    ||
CODE_039034:                    ;           ||
    LDY.w $185D                 ;$039034    |/
CODE_039037:                    ;           |
    LDA.b #$0A                  ;$039037    |\ Store sprite number.
    STA.w $17F0,Y               ;$039039    |/
    LDA $E4,X                   ;$03903C    |\ 
    STA.w $1808,Y               ;$03903E    ||
    LDA.w $14E0,X               ;$039041    ||
    STA.w $18EA,Y               ;$039044    || Spawn at the Boo Stream's position.
    LDA $D8,X                   ;$039047    ||
    STA.w $17FC,Y               ;$039049    ||
    LDA.w $14D4,X               ;$03904C    ||
    STA.w $1814,Y               ;$03904F    |/
    LDA.b #$30                  ;$039052    |\ Set lifespan timer.
    STA.w $1850,Y               ;$039054    |/
    LDA $B6,X                   ;$039057    |\ Transfer X speed, so that it faces the same direction.
    STA.w $182C,Y               ;$039059    |/
    RTS                         ;$03905C    |





FishinBooAccelX:                ;$03905D    | X accelerations for the Fishin' Boo.
    db $01,$FF

FishinBooMaxSpeedX:             ;$03905F    | Max X speeds for the Fishin' Boo.
    db $20,$E0

FishinBooAccelY:                ;$039061    | Y accelerations for the Fishin' Boo.
    db $01,$FF

FishinBooMaxSpeedY:             ;$039063    | Max Y speeds for the Fishin' Boo.
    db $10,$F0

    ; Fishin' Boo misc RAM:
    ; $C2   - Direction of vertical acceleration. Even = down, odd = up.
    ; $157C - Horizontal direciton the sprite is facing.
    ; $15AC - Turn timer.
    ; $1602 - Animation frame.
    ;          0 =normal, 1 = turning

FishinBoo:                      ;-----------| Fishin' Boo MAIN
    JSR FishinBooGfx            ;$039065    | Draw GFX.
    LDA $9D                     ;$039068    |\ Return if game frozen.
    BNE Return0390EA            ;$03906A    |/
    JSL MarioSprInteract        ;$03906C    | Process interaction with Mario.
    JSR SubHorzPosBnk3          ;$039070    |\ 
    STZ.w $1602,X               ;$039073    ||
    LDA.w $15AC,X               ;$039076    || Handle turning the sprite towards Mario.
    BEQ CODE_039086             ;$039079    ||
    INC.w $1602,X               ;$03907B    ||
    CMP.b #$10                  ;$03907E    ||\ 
    BNE CODE_039086             ;$039080    ||| Actually flip the direction of the sprite when time to.
    TYA                         ;$039082    |||
    STA.w $157C,X               ;$039083    ||/
CODE_039086:                    ;           ||
    TXA                         ;$039086    ||
    ASL                         ;$039087    ||
    ASL                         ;$039088    ||
    ASL                         ;$039089    ||
    ASL                         ;$03908A    ||
    ADC $13                     ;$03908B    ||
    AND.b #$3F                  ;$03908D    ||
    ORA.w $15AC,X               ;$03908F    ||
    BNE CODE_039099             ;$039092    ||
    LDA.b #$20                  ;$039094    ||| How long the Fishin' Boo takes to turn around.
    STA.w $15AC,X               ;$039096    |/
CODE_039099:                    ;           |
    LDA.w $18BF                 ;$039099    |\ 
    BEQ CODE_0390A2             ;$03909C    ||
    TYA                         ;$03909E    || If sprite D2 is spawned, make the Fishin' Boo fly away from Mario.
    EOR.b #$01                  ;$03909F    ||
    TAY                         ;$0390A1    |/
CODE_0390A2:                    ;           |
    LDA $B6,X                   ;$0390A2    |\ 
    CMP.w FishinBooMaxSpeedX,Y  ;$0390A4    ||
    BEQ CODE_0390AF             ;$0390A7    || Horizontally accelerate the Boo towards Mario if not already at the max speed.
    CLC                         ;$0390A9    ||
    ADC.w FishinBooAccelX,Y     ;$0390AA    ||
    STA $B6,X                   ;$0390AD    |/
CODE_0390AF:                    ;           |
    LDA $13                     ;$0390AF    |\ 
    AND.b #$01                  ;$0390B1    ||
    BNE CODE_0390C9             ;$0390B3    ||
    LDA $C2,X                   ;$0390B5    ||
    AND.b #$01                  ;$0390B7    ||
    TAY                         ;$0390B9    || Handle vertical acceleration.
    LDA $AA,X                   ;$0390BA    ||  When at the maximum Y speed in a particular direction, invert the direction of acceleration (for the "wave" motion).
    CLC                         ;$0390BC    ||
    ADC.w FishinBooAccelY,Y     ;$0390BD    ||
    STA $AA,X                   ;$0390C0    ||
    CMP.w FishinBooMaxSpeedY,Y  ;$0390C2    ||
    BNE CODE_0390C9             ;$0390C5    ||
    INC $C2,X                   ;$0390C7    |/
CODE_0390C9:                    ;           |
    LDA $B6,X                   ;$0390C9    |\ 
    PHA                         ;$0390CB    ||
    LDY.w $18BF                 ;$0390CC    ||
    BNE CODE_0390DC             ;$0390CF    ||
    LDA.w $17BD                 ;$0390D1    ||
    ASL                         ;$0390D4    ||
    ASL                         ;$0390D5    ||
    ASL                         ;$0390D6    || Update the sprite's X position, and move it with the screen.
    CLC                         ;$0390D7    ||
    ADC $B6,X                   ;$0390D8    ||
    STA $B6,X                   ;$0390DA    ||
CODE_0390DC:                    ;           ||
    JSL UpdateXPosNoGrvty       ;$0390DC    ||
    PLA                         ;$0390E0    ||
    STA $B6,X                   ;$0390E1    |/
    JSL UpdateYPosNoGrvty       ;$0390E3    | Update Y position.
    JSR CODE_0390F3             ;$0390E7    | Process interaction between the flame and Mario.
Return0390EA:                   ;           |
    RTS                         ;$0390EA    |



DATA_0390EB:                    ;           |
    db $1A,$14,$EE,$F8

DATA_0390EF:                    ;           |
    db $00,$00,$FF,$FF

CODE_0390F3:                    ;-----------| Subroutine to handle interaction with the Fishin' Boo's flame.
    LDA.w $157C,X               ;$0390F3    |\ 
    ASL                         ;$0390F6    ||
    ADC.w $1602,X               ;$0390F7    ||
    TAY                         ;$0390FA    ||
    LDA $E4,X                   ;$0390FB    ||
    CLC                         ;$0390FD    || Get X position of the flame.
    ADC.w DATA_0390EB,Y         ;$0390FE    ||
    STA $04                     ;$039101    ||
    LDA.w $14E0,X               ;$039103    ||
    ADC.w DATA_0390EF,Y         ;$039106    ||
    STA $0A                     ;$039109    |/
    LDA.b #$04                  ;$03910B    |\\ Size of the Fishin' Boo flame's hitbox.
    STA $06                     ;$03910D    ||
    STA $07                     ;$03910F    |/
    LDA $D8,X                   ;$039111    |\ 
    CLC                         ;$039113    ||
    ADC.b #$47                  ;$039114    ||
    STA $05                     ;$039116    || Get Y position of the flame.
    LDA.w $14D4,X               ;$039118    ||
    ADC.b #$00                  ;$03911B    ||
    STA $0B                     ;$03911D    |/
    JSL GetMarioClipping        ;$03911F    |\ 
    JSL CheckForContact         ;$039123    || Return if not in contact with Mario.
    BCC Return03912D            ;$039127    |/
    JSL HurtMario               ;$039129    | Hurt Mario (even if he's on Yoshi!).
Return03912D:                   ;           |
    RTS                         ;$03912D    |



FishinBooDispX:                 ;$03912E    | X offsets for the Fishin' Boo's tiles.
    db $FB,$05,$00,$F2,$FD,$03,$EA,$EA,$EA,$EA  ; Left, normal
    db $FB,$05,$00,$FA,$FD,$03,$F2,$F2,$F2,$F2  ; Left, turning
    db $FB,$05,$00,$0E,$03,$FD,$16,$16,$16,$16  ; Right, normal
    db $FB,$05,$00,$06,$03,$FD,$0E,$0E,$0E,$0E  ; Right, turning

FishinBooDispY:                 ;$039A66    | Y offsets for the Fishin' Boo's tiles.
    db $0B,$0B,$00,$03,$0F,$0F,$13,$23,$33,$43

FishinBooTiles1:                ;$039A70    | Tile numbers for the Fishin' Boo.
    db $60,$60,$64,$8A,$60,$60,$AC,$AC,$AC,$CE

FishinBooGfxProp:               ;$03917A    | YXPPCCCT for the Fishin' Boo.
    db $04,$04,$0D,$09,$04,$04,$0D,$0D,$0D,$07

FishinBooTiles2:                ;$039174    | Tile numbers for the Fishin' Boo's flame's animation.
    db $CC,$CE,$CC,$CE

DATA_039178:                    ;$039178    | YXPPCCCT for the Fishin' Boo's flame's animation.
    db $00,$00,$40,$40

DATA_03917C:                    ;$03917C    | YXPPCCCT for animating the Fishin' Boo's cloud.
    db $00,$40,$C0,$80

FishinBooGfx:                   ;-----------| Fishin' Boo GFX routine.
    JSR GetDrawInfoBnk3         ;$039180    |
    LDA.w $1602,X               ;$039183    |\ $04 = animation frame
    STA $04                     ;$039186    |/
    LDA.w $157C,X               ;$039188    |\ $02 = horizontal direction
    STA $02                     ;$03918B    |/
    PHX                         ;$03918D    |
    PHY                         ;$03918E    |
    LDX.b #$09                  ;$03918F    |
CODE_039191:                    ;```````````| Main tile loop.
    LDA $01                     ;$039191    |\ 
    CLC                         ;$039193    || Store Y position to OAM.
    ADC.w FishinBooDispY,X      ;$039194    ||
    STA.w $0301,Y               ;$039197    |/
    STZ $03                     ;$03919A    |\ 
    LDA.w FishinBooTiles1,X     ;$03919C    ||
    CPX.b #$09                  ;$03919F    ||
    BNE CODE_0391B4             ;$0391A1    ||
    LDA $14                     ;$0391A3    ||
    LSR                         ;$0391A5    ||
    LSR                         ;$0391A6    ||
    PHX                         ;$0391A7    || Store tile number to OAM.
    AND.b #$03                  ;$0391A8    ||
    TAX                         ;$0391AA    ||
    LDA.w DATA_039178,X         ;$0391AB    ||
    STA $03                     ;$0391AE    ||
    LDA.w FishinBooTiles2,X     ;$0391B0    ||
    PLX                         ;$0391B3    ||
CODE_0391B4:                    ;           ||
    STA.w $0302,Y               ;$0391B4    |/
    LDA $02                     ;$0391B7    |\ 
    CMP.b #$01                  ;$0391B9    ||
    LDA.w FishinBooGfxProp,X    ;$0391BB    ||
    EOR $03                     ;$0391BE    ||
    ORA $64                     ;$0391C0    || Store YXPPCCCT to OAM.
    BCS CODE_0391C6             ;$0391C2    ||
    EOR.b #$40                  ;$0391C4    ||
CODE_0391C6:                    ;           ||
    STA.w $0303,Y               ;$0391C6    |/
    PHX                         ;$0391C9    |
    LDA $04                     ;$0391CA    |\ 
    BEQ CODE_0391D3             ;$0391CC    ||
    TXA                         ;$0391CE    ||
    CLC                         ;$0391CF    ||
    ADC.b #$0A                  ;$0391D0    ||
    TAX                         ;$0391D2    ||
CODE_0391D3:                    ;           ||
    LDA $02                     ;$0391D3    ||
    BNE CODE_0391DC             ;$0391D5    || Store X position to OAM.
    TXA                         ;$0391D7    ||
    CLC                         ;$0391D8    ||
    ADC.b #$14                  ;$0391D9    ||
    TAX                         ;$0391DB    ||
CODE_0391DC:                    ;           ||
    LDA $00                     ;$0391DC    ||
    CLC                         ;$0391DE    ||
    ADC.w FishinBooDispX,X      ;$0391DF    ||
    STA.w $0300,Y               ;$0391E2    |/
    PLX                         ;$0391E5    |
    INY                         ;$0391E6    |\ 
    INY                         ;$0391E7    ||
    INY                         ;$0391E8    || Loop for all tiles.
    INY                         ;$0391E9    ||
    DEX                         ;$0391EA    ||
    BPL CODE_039191             ;$0391EB    |/
    LDA $14                     ;$0391ED    |\ 
    LSR                         ;$0391EF    ||
    LSR                         ;$0391F0    ||
    LSR                         ;$0391F1    ||
    AND.b #$03                  ;$0391F2    ||
    TAX                         ;$0391F4    || Animate the Fishin' Boo's cloud by X/Y flipping it.
    PLY                         ;$0391F5    ||
    LDA.w DATA_03917C,X         ;$0391F6    ||
    EOR.w $0313,Y               ;$0391F9    ||
    STA.w $0313,Y               ;$0391FC    ||
    STA.w $0327,Y               ;$0391FF    ||
    EOR.b #$C0                  ;$039202    ||
    STA.w $0317,Y               ;$039204    |/
    STA.w $0323,Y               ;$039207    |
    PLX                         ;$03920A    |
    LDY.b #$02                  ;$03920B    |\ 
    LDA.b #$09                  ;$03920D    || Upload 10 16x16 tiles.
    JSL FinishOAMWrite          ;$03920F    |/
    RTS                         ;$039213    |





    ; Falling Spike misc RAM:
    ; $C2   - Phase pointer. 0 = waiting, 1 = shaking/falling.
    ; $1540 - Timer for shaking before falling.
    
FallingSpike:                   ;-----------| Falling Spike MAIN
    JSL GenericSprGfxRt2        ;$039214    | Draw a 16x16.
    LDY.w $15EA,X               ;$039218    |
    LDA.b #$E0                  ;$03921B    |\\ Tile to use for the falling spike.
    STA.w $0302,Y               ;$03921D    |/
    LDA.w $0301,Y               ;$039220    |\ 
    DEC A                       ;$039223    || Graphically shift the sprite up one pixel.
    STA.w $0301,Y               ;$039224    |/
    LDA.w $1540,X               ;$039227    |\ 
    BEQ CODE_039237             ;$03922A    ||
    LSR                         ;$03922C    ||
    LSR                         ;$03922D    || If about to fall, make the spike shake from side to side.
    AND.b #$01                  ;$03922E    ||
    CLC                         ;$039230    ||
    ADC.w $0300,Y               ;$039231    ||
    STA.w $0300,Y               ;$039234    |/
CODE_039237:                    ;           |
    LDA $9D                     ;$039237    |\ Clear Y speed and return if game frozen.
    BNE CODE_03926C             ;$039239    |/
    JSR SubOffscreen0Bnk3       ;$03923B    | Process offscreen from -$40 to +$30.
    JSL UpdateSpritePos         ;$03923E    | Update X/Y position, apply gravity, and process block interaction.
    LDA $C2,X                   ;$039242    |
    JSL ExecutePtr              ;$039244    |

FallingSpikePtrs:               ;$039248    | Falling Spike phase pointers.
    dw CODE_03924C              ; 0 - Waiting
    dw CODE_039262              ; 1 - Shaking/falling



CODE_03924C:                    ;-----------| Falling Spike phase 0 - Waiting
    STZ $AA,X                   ;$03924C    | Clear Y speed.
    JSR SubHorzPosBnk3          ;$03924E    |\ 
    LDA $0F                     ;$039251    ||
    CLC                         ;$039253    ||
    ADC.b #$40                  ;$039254    || If Mario is within 4 tiles horizontally of the sprite, get ready to fall.
    CMP.b #$80                  ;$039256    ||
    BCS Return039261            ;$039258    ||
    INC $C2,X                   ;$03925A    ||
    LDA.b #$40                  ;$03925C    ||| How long the spike shakes for before falling.
    STA.w $1540,X               ;$03925E    |/
Return039261:                   ;           |
    RTS                         ;$039261    |



CODE_039262:                    ;-----------| Falling Spike phase 1 - Shaking/falling
    LDA.w $1540,X               ;$039262    |\ Branch if not time to fall.
    BNE CODE_03926C             ;$039265    |/
    JSL MarioSprInteract        ;$039267    | Process interaction with Mario.
    RTS                         ;$03926B    |

CODE_03926C:                    ;```````````| Spike is shaking before falling.
    STZ $AA,X                   ;$03926C    | Clear Y speed.
    RTS                         ;$03926E    |





CrtEatBlkSpeedX:                ;$03926F    | X speeds for the Creating/Eating block in each direction. Last value is when stationary.
    db $10,$F0,$00,$00,$00

CrtEatBlkSpeedY:                ;$039274    | Y speeds for the Creating/Eating block in each direction. Last value is when stationary.
    db $00,$00,$10,$F0,$00

DATA_039279:                    ;$039279    | Indices to the above to use for the Eating block when it needs to make a choice between paths in two directions.
    db $00,$00,$01,$00          ; ----, ---r, --l-, --lr
    db $02,$00,$00,$00          ; -d--, -d-r, -dl-, -dlr
    db $03,$00,$00              ; u---, u--r, u-l-  (remaining values are missing, hence the glitches from other path choices)

    ; Creating/Eating block misc RAM:
    ; $C2   - Unused, but set to 1 when the block is hit from below for the first time.
    ; $151C - Which type of block this is. 00 = creating, 10 = eating.
    ; $1528 - Always 0. Would cause Mario to move horizontally while on the block if non-zero.
    ; $1534 - (creating) Current index to the path tables.
    ; $1558 - Unused timer set when the block is hit from below for the first time.
    ; $1564 - Unsued timer set when the block is hit from below.
    ; $1570 - (creating) Number of tiles remaining in the path's current direction of movement.
    ; $157C - (creating) Current direction of movement. 0 = right, 1 = left, 2 = down, 3 = up
    ; $1602 - (creating) Current movement value, in the form XY, where Y is the direction and X is the total number of tiles to move along. FF indicates the end.
    
CreateEatBlock:                 ;-----------| Creating/Eating block MAIN
    JSL GenericSprGfxRt2        ;$039284    | Draw a 16x16 sprite.
    LDY.w $15EA,X               ;$039288    |
    LDA.w $0301,Y               ;$03928B    |\ 
    DEC A                       ;$03928E    || Move the sprite up one pixel (so it lines up with tiles).
    STA.w $0301,Y               ;$03928F    |/
    LDA.b #$2E                  ;$039292    |\\ Tile to use for the Creating/Eating sprite.
    STA.w $0302,Y               ;$039294    |/
    LDA.w $0303,Y               ;$039297    |\ 
    AND.b #$3F                  ;$03929A    || Clear X/Y flip in OAM.
    STA.w $0303,Y               ;$03929C    |/
    LDY.b #$02                  ;$03929F    |\ 
    LDA.b #$00                  ;$0392A1    || Upload one 16x16 sprite (again?).
    JSL FinishOAMWrite          ;$0392A3    |/
    LDY.b #$04                  ;$0392A7    |\ 
    LDA.w $1909                 ;$0392A9    ||
    CMP.b #$FF                  ;$0392AC    ||
    BEQ CODE_0392C0             ;$0392AE    || Get current direction of movement (if moving at all).
    LDA $13                     ;$0392B0    ||  Also handle the sound effects if it is actually moving.
    AND.b #$03                  ;$0392B2    ||
    ORA $9D                     ;$0392B4    ||
    BNE CODE_0392BD             ;$0392B6    ||
    LDA.b #$04                  ;$0392B8    ||\ SFX for the creating/eating block.
    STA.w $1DFA                 ;$0392BA    ||/
CODE_0392BD:                    ;           ||
    LDY.w $157C,X               ;$0392BD    |/
CODE_0392C0:                    ;           |
    LDA $9D                     ;$0392C0    |\ Return if game frozen.
    BNE Return03932B            ;$0392C2    |/
    LDA.w CrtEatBlkSpeedX,Y     ;$0392C4    |\ 
    STA $B6,X                   ;$0392C7    || Store X/Y speed for the current direction.
    LDA.w CrtEatBlkSpeedY,Y     ;$0392C9    ||
    STA $AA,X                   ;$0392CC    |/
    JSL UpdateYPosNoGrvty       ;$0392CE    | Update Y position.
    JSL UpdateXPosNoGrvty       ;$0392D2    | Update X position.
    STZ.w $1528,X               ;$0392D6    |\ Make solid.
    JSL InvisBlkMainRt          ;$0392D9    |/
    LDA.w $1909                 ;$0392DD    |\ 
    CMP.b #$FF                  ;$0392E0    || Return if the platform hasn't started yet.
    BEQ Return03932B            ;$0392E2    |/
    LDA $D8,X                   ;$0392E4    |\ 
    ORA $E4,X                   ;$0392E6    || Return if not centered on a tile yet.
    AND.b #$0F                  ;$0392E8    ||
    BNE Return03932B            ;$0392EA    |/
    LDA.w $151C,X               ;$0392EC    |\ Branch for the eating block (not the creating block).
    BNE CODE_03932C             ;$0392EF    |/
    DEC.w $1570,X               ;$0392F1    |\ 
    BMI CODE_0392F8             ;$0392F4    || Branch if not at the end of the current movement.
    BNE CODE_03931F             ;$0392F6    |/
CODE_0392F8:                    ;           |
    LDY.w $0DB3                 ;$0392F8    |\ 
    LDA.w $1F11,Y               ;$0392FB    ||
    CMP.b #$01                  ;$0392FE    ||
    LDY.w $1534,X               ;$039300    ||
    INC.w $1534,X               ;$039303    || Get current movement value.
    LDA.w CrtEatBlkData1,Y      ;$039306    ||  Decides which of the two path data tables to use based on whether Mario is on the main map or submaps.
    BCS CODE_03930E             ;$039309    ||
    LDA.w CrtEatBlkData2,Y      ;$03930B    ||
CODE_03930E:                    ;           ||
    STA.w $1602,X               ;$03930E    |/
    PHA                         ;$039311    |
    LSR                         ;$039312    |\ 
    LSR                         ;$039313    ||
    LSR                         ;$039314    || Get length of the current movement.
    LSR                         ;$039315    ||
    STA.w $1570,X               ;$039316    |/
    PLA                         ;$039319    |\ 
    AND.b #$03                  ;$03931A    || Get direction of movement.
    STA.w $157C,X               ;$03931C    |/
CODE_03931F:                    ;```````````| Not at the end of the current movement.
    LDA.b #$0D                  ;$03931F    |\ Generate a used block at the current position.
    JSR GenTileFromSpr1         ;$039321    |/
    LDA.w $1602,X               ;$039324    |\ 
    CMP.b #$FF                  ;$039327    || Branch if at the end of the path.
    BEQ CODE_039387             ;$039329    |/
Return03932B:                   ;           |
    RTS                         ;$03932B    |

CODE_03932C:                    ;```````````| Eating block routine.
    LDA.b #$02                  ;$03932C    |\ Erase the tile at the current position.
    JSR GenTileFromSpr1         ;$03932E    |/
    LDA.b #$01                  ;$039331    |\ 
    STA $B6,X                   ;$039333    || Interact with blocks below/right of the sprite.
    STA $AA,X                   ;$039335    ||
    JSL CODE_019138             ;$039337    |/
    LDA.w $1588,X               ;$03933B    |
    PHA                         ;$03933E    |
    LDA.b #$FF                  ;$03933F    |\ 
    STA $B6,X                   ;$039341    ||
    STA $AA,X                   ;$039343    ||
    LDA $E4,X                   ;$039345    ||
    PHA                         ;$039347    ||
    SEC                         ;$039348    ||
    SBC.b #$01                  ;$039349    || Interact with blocks above/left of the sprite.
    STA $E4,X                   ;$03934B    ||
    LDA.w $14E0,X               ;$03934D    ||
    PHA                         ;$039350    ||
    SBC.b #$00                  ;$039351    ||
    STA.w $14E0,X               ;$039353    ||
    LDA $D8,X                   ;$039356    ||
    PHA                         ;$039358    ||
    SEC                         ;$039359    ||
    SBC.b #$01                  ;$03935A    ||
    STA $D8,X                   ;$03935C    ||
    LDA.w $14D4,X               ;$03935E    ||
    PHA                         ;$039361    ||
    SBC.b #$00                  ;$039362    ||
    STA.w $14D4,X               ;$039364    ||
    JSL CODE_019138             ;$039367    ||
    PLA                         ;$03936B    ||
    STA.w $14D4,X               ;$03936C    ||
    PLA                         ;$03936F    ||
    STA $D8,X                   ;$039370    ||
    PLA                         ;$039372    ||
    STA.w $14E0,X               ;$039373    ||
    PLA                         ;$039376    ||
    STA $E4,X                   ;$039377    |/
    PLA                         ;$039379    |\ 
    ORA.w $1588,X               ;$03937A    || Branch to erase the sprite if no blocks were found.
    BEQ CODE_039387             ;$03937D    |/
    TAY                         ;$03937F    |\ 
    LDA.w DATA_039279,Y         ;$039380    || Store next direction of movement.
    STA.w $157C,X               ;$039383    |/
    RTS                         ;$039386    |

CODE_039387:                    ;```````````| Erasing the eating block at the end of its path.
    STZ.w $14C8,X               ;$039387    |
    RTS                         ;$03938A    |



GenTileFromSpr1:                ;-----------| Subroutine to generate a Map16 tile at the position of the sprite currently being processed. Only used by the creating/eating sprite.
    STA $9C                     ;$03938B    |
    LDA $E4,X                   ;$03938D    |
    STA $9A                     ;$03938F    |
    LDA.w $14E0,X               ;$039391    |
    STA $9B                     ;$039394    |
    LDA $D8,X                   ;$039396    |
    STA $98                     ;$039398    |
    LDA.w $14D4,X               ;$03939A    |
    STA $99                     ;$03939D    |
    JSL GenerateTile            ;$03939F    |
    RTS                         ;$0393A3    |



CrtEatBlkData1:                 ;$0393A4    | Creating block path for submaps. (Larry's Castle)
    db $10,$13,$10,$13,$10,$13,$10,$13      ; Format is one byte per command: XY
    db $10,$13,$10,$13,$10,$13,$10,$13      ;  Y = direction (0 = right, 1 = left, 2 = down, 3 = up)
    db $F0,$F0,$20,$12,$10,$12,$10,$12      ;  X = number of tiles to travel
    db $10,$12,$10,$12,$10,$12,$10,$12
    db $D0,$C3,$F1,$21,$22,$F1,$F1,$51
    db $43,$10,$13,$10,$13,$10,$13,$F0
    db $F0,$F0,$60,$32,$60,$32,$71,$32
    db $60,$32,$61,$32,$70,$33,$10,$33
    db $10,$33,$10,$33,$10,$33,$F0,$10
    db $F2,$52,$FF

CrtEatBlkData2:                 ;$0393EF    | Creating block path for the main map. (Roy's Castle)
    db $80,$13,$10,$13,$10,$13,$10,$13      ; Same format as above.
    db $60,$23,$20,$23,$B0,$22,$A1,$22
    db $A0,$22,$A1,$22,$C0,$13,$10,$13
    db $10,$13,$10,$13,$10,$13,$10,$13
    db $10,$13,$F0,$F0,$F0,$52,$50,$33
    db $50,$32,$50,$33,$50,$22,$50,$33
    db $F0,$50,$82,$FF





    ; Wooden spike misc RAM:
    ; $C2   - Sprite phase pointer. Mod 4: 0 = retracting, 1 = waiting to extend, 2 = extending, 3 = waiting to retract
    ; $151C - Initial direction of movement. 00 = down, 10 = up
    ; $1540 - Phase timer.
    
WoodenSpike:                    ;-----------| Wooden Spike MAIN
    JSR WoodSpikeGfx            ;$039423    | Draw GFX.
    LDA $9D                     ;$039426    |\ Return if game frozen.
    BNE Return039440            ;$039428    |/
    JSR SubOffscreen0Bnk3       ;$03942A    | Process offscreen from -$40 to +$30.
    JSR CODE_039488             ;$03942D    | Process interaction with Mario.
    LDA $C2,X                   ;$039430    |
    AND.b #$03                  ;$039432    |
    JSL ExecutePtr              ;$039434    |

WoodenSpikePtrs:                ;$039438    | Wooden Spike phase pointers.
    dw CODE_039458              ; 0 - Retracting
    dw CODE_03944E              ; 1 - Waiting to extend
    dw CODE_039441              ; 2 - Extending
    dw CODE_03946B              ; 3 - Waiting to retract

Return039440:
    RTS                         ;$039440    |



CODE_039441:                    ;-----------| Wooden Spike phase 2 - Extending
    LDA.w $1540,X               ;$039441    |\ Branch if done extending.
    BEQ CODE_03944A             ;$039444    |/
    LDA.b #$20                  ;$039446    |\\ How quickly to extend the wooden spike.
    BRA CODE_039475             ;$039448    |/

CODE_03944A:                    ;```````````| Done extending.
    LDA.b #$30                  ;$03944A    |\\ How long to wait before retracting the spike.
    BRA SetTimerNextState       ;$03944C    |/



CODE_03944E:                    ;-----------| Wooden Spike phase 1 - Waiting to extend
    LDA.w $1540,X               ;$03944E    |\ Return if not time to extend yet.
    BNE Return039457            ;$039451    |/
    LDA.b #$18                  ;$039453    |\\ How long to spend extending.
    BRA SetTimerNextState       ;$039455    |/
Return039457:                   ;           |
    RTS                         ;$039457    |



CODE_039458:                    ;-----------| Wooden Spike phase 0 - Retracting
    LDA.w $1540,X               ;$039458    |\ Branch if done retracting.
    BEQ CODE_039463             ;$03945B    |/
    LDA.b #$F0                  ;$03945D    |\\ How quickly to retract the spike.
    JSR CODE_039475             ;$03945F    |/
    RTS                         ;$039462    |

CODE_039463:                    ;```````````| Done retracting.
    LDA.b #$30                  ;$039463    |\\ How long to wait before extending the spike.
SetTimerNextState:              ;           ||
    STA.w $1540,X               ;$039465    ||
    INC $C2,X                   ;$039468    |/
    RTS                         ;$03946A    |



CODE_03946B:                    ;-----------| Wooden Spike phase 3 - Waiting to retract
    LDA.w $1540,X               ;$03946B    |\ Return if not time to retract.
    BNE Return039474            ;$03946E    |/
    LDA.b #$2F                  ;$039470    |\\ How long to spend retracting the spike.
    BRA SetTimerNextState       ;$039472    |/
Return039474:                   ;           |
    RTS                         ;$039474    |



CODE_039475:                    ;```````````| Retracting/extending the sprite: set Y speed.
    LDY.w $151C,X               ;$039475    |\ 
    BEQ CODE_03947D             ;$039478    ||
    EOR.b #$FF                  ;$03947A    || Store Y speed.
    INC A                       ;$03947C    ||  If the spike is sprite AD in an odd X position, invert the given Y speed.
CODE_03947D:                    ;           ||
    STA $AA,X                   ;$03947D    |/ 
    JSL UpdateYPosNoGrvty       ;$03947F    | Update Y position.
    RTS                         ;$039483    |



DATA_039484:                    ;$039484    | Distances (lo) to push Mario out of the wooden spike when he's touching the side of it.
    db $01,$FF

DATA_039486:                    ;$039486    | Distances (hi) to push Mario out of the wooden spike when he's touching the side of it.
    db $00,$FF

CODE_039488:                    ;-----------| Routine for processing interaction between the wooden spike and Mario.
    JSL MarioSprInteract        ;$039488    |\ Return if not in contact with Mario.
    BCC Return0394B0            ;$03948C    |/
    JSR SubHorzPosBnk3          ;$03948E    |\ 
    LDA $0F                     ;$039491    ||
    CLC                         ;$039493    || Branch if not within 4 pixels of the sprite.
    ADC.b #$04                  ;$039494    ||
    CMP.b #$08                  ;$039496    ||
    BCS CODE_03949F             ;$039498    |/
    JSL HurtMario               ;$03949A    | Hurt Mario.
    RTS                         ;$03949E    |

CODE_03949F:                    ;```````````| Not within 4 pixels of the sprite; touching the sides.
    LDA $94                     ;$03949F    |\ 
    CLC                         ;$0394A1    ||
    ADC.w DATA_039484,Y         ;$0394A2    ||
    STA $94                     ;$0394A5    || Push Mario to the side of the sprite.
    LDA $95                     ;$0394A7    ||
    ADC.w DATA_039486,Y         ;$0394A9    ||
    STA $95                     ;$0394AC    |/
    STZ $7B                     ;$0394AE    | Clear Mario's X speed.
Return0394B0:                   ;           |
    RTS                         ;$0394B0    |



WoodSpikeDispY:                 ;$0394B1    | Y offsets for each tile of the wooden spike.
    db $00,$10,$20,$30,$40                  ; Downwards-pointing
    db $40,$30,$20,$10,$00                  ; Upwards-pointing

WoodSpikeTiles:                 ;$0394BB    | Tile numbers for each tile of the wooden spike.
    db $6A,$6A,$6A,$6A,$4A                  ; Downwards-pointing
    db $6A,$6A,$6A,$6A,$4A                  ; Upwards-pointing

WoodSpikeGfxProp:               ;$0394C5    | YXPPCCCT for each tile of the wooden spike.
    db $81,$81,$81,$81,$81                  ; Downwards-pointing
    db $01,$01,$01,$01,$01                  ; Upwards-pointing

WoodSpikeGfx:                   ;-----------| Wooden spike GFX routine
    JSR GetDrawInfoBnk3         ;$0394CF    |
    STZ $02                     ;$0394D2    |\ 
    LDA $9E,X                   ;$0394D4    ||
    CMP.b #$AD                  ;$0394D6    || Get base index to the above tables for the spike.
    BNE CODE_0394DE             ;$0394D8    ||
    LDA.b #$05                  ;$0394DA    ||
    STA $02                     ;$0394DC    |/
CODE_0394DE:                    ;           |
    PHX                         ;$0394DE    |
    LDX.b #$04                  ;$0394DF    |
WoodSpikeGfxLoopSt:             ;```````````| Tile loop.
    PHX                         ;$0394E1    |
    TXA                         ;$0394E2    |\ 
    CLC                         ;$0394E3    || Get index for the current tile.
    ADC $02                     ;$0394E4    ||
    TAX                         ;$0394E6    |/
    LDA $00                     ;$0394E7    |\ Store X position to OAM.
    STA.w $0300,Y               ;$0394E9    |/ 
    LDA $01                     ;$0394EC    |\ 
    CLC                         ;$0394EE    || Store Y position to OAM.
    ADC.w WoodSpikeDispY,X      ;$0394EF    ||
    STA.w $0301,Y               ;$0394F2    |/
    LDA.w WoodSpikeTiles,X      ;$0394F5    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$0394F8    |/
    LDA.w WoodSpikeGfxProp,X    ;$0394FB    |\ Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$0394FE    |/
    INY                         ;$039501    |\ 
    INY                         ;$039502    ||
    INY                         ;$039503    ||
    INY                         ;$039504    || Loop for all of the tiles.
    PLX                         ;$039505    ||
    DEX                         ;$039506    ||
    BPL WoodSpikeGfxLoopSt      ;$039507    |/ 
    PLX                         ;$039509    |
    LDY.b #$02                  ;$03950A    |\ 
    LDA.b #$04                  ;$03950C    || Upload 5 16x16 tiles.
    JSL FinishOAMWrite          ;$03950E    |/
    RTS                         ;$039512    |





RexSpeed:                       ;$039513    | Rex walking speeds. First two are normal, second two are squished.
    db $08,$F8,$10,$F0

    ; Rex misc RAM:
    ; $C2   - Counter for the number of times the Rex has been bounced on. Normal (0), half-squished (1), or fully squished (2).
    ; $1558 - Timer for showing the Rex's fully-squished frame.
    ; $1570 - Frame counter for animation.
    ; $157C - Horizontal direction the sprite is facing.
    ; $15D0 - Timer set when squished to prevent being hit by a capespin/quake sprite.
    ; $1602 - Animation frame.
    ;          0/1 = walking, 2 = half-squished transision, 3/4 = half-squished walking, 5 = fully squished
    ; $1FE2 - Timer set when the Rex is bounced on for the first time, for briefly pausing it before it starts running in its half-squished state.

RexMainRt:                      ;-----------| Rex MAIN
    JSR RexGfxRt                ;$039517    | Draw GFX
    LDA.w $14C8,X               ;$03951A    |\ 
    CMP.b #$08                  ;$03951D    ||
    BNE RexReturn               ;$03951F    || Return if sprites are frozen, or the Rex is dying.
    LDA $9D                     ;$039521    ||
    BNE RexReturn               ;$039523    |/
    LDA.w $1558,X               ;$039525    |\ Branch if the sprite hasn't been fully squished.
    BEQ RexAlive                ;$039528    |/
    STA.w $15D0,X               ;$03952A    |\ 
    DEC A                       ;$03952D    || Erase the sprite once its squish timer runs out.
    BNE RexReturn               ;$03952E    ||
    STZ.w $14C8,X               ;$039530    |/
RexReturn:                      ;           |
    RTS                         ;$039533    |

RexAlive:                       ;```````````| Rex isn't dead from squishing.
    JSR SubOffscreen0Bnk3       ;$039534    | Process offscreen from -$40 to +$30.
    INC.w $1570,X               ;$039537    |\ 
    LDA.w $1570,X               ;$03953A    ||
    LSR                         ;$03953D    ||
    LSR                         ;$03953E    ||
    LDY $C2,X                   ;$03953F    ||
    BEQ CODE_03954A             ;$039541    ||
    AND.b #$01                  ;$039543    || Handle animating the Rex's walk cycle.
    CLC                         ;$039545    ||  0/1 for normal, 3/4 for half-squished.
    ADC.b #$03                  ;$039546    ||
    BRA CODE_03954D             ;$039548    ||
CODE_03954A:                    ;           ||
    LSR                         ;$03954A    ||
    AND.b #$01                  ;$03954B    ||
CODE_03954D:                    ;           ||
    STA.w $1602,X               ;$03954D    |/
    LDA.w $1588,X               ;$039550    |\ 
    AND.b #$04                  ;$039553    ||
    BEQ RexInAir                ;$039555    ||
    LDA.b #$10                  ;$039557    ||
    STA $AA,X                   ;$039559    ||
    LDY.w $157C,X               ;$03955B    || If on the ground, store X speed.
    LDA $C2,X                   ;$03955E    ||
    BEQ RexNoAdjustSpeed        ;$039560    ||
    INY                         ;$039562    ||
    INY                         ;$039563    ||
RexNoAdjustSpeed:               ;           ||
    LDA.w RexSpeed,Y            ;$039564    ||
    STA $B6,X                   ;$039567    |/
RexInAir:                       ;           |
    LDA.w $1FE2,X               ;$039569    |\ 
    BNE RexHalfSmushed          ;$03956C    || If the Rex wasn't just bounced on, update X/Y position, apply gravity, and process block interaction.
    JSL UpdateSpritePos         ;$03956E    |/
RexHalfSmushed:                 ;           |
    LDA.w $1588,X               ;$039572    |\ 
    AND.b #$03                  ;$039575    ||
    BEQ CODE_039581             ;$039577    || If the Rex hits a wall, turn it around.
    LDA.w $157C,X               ;$039579    ||
    EOR.b #$01                  ;$03957C    ||
    STA.w $157C,X               ;$03957E    |/
CODE_039581:                    ;           |
    JSL SprSprInteract          ;$039581    | Process interaction with other sprites.
    JSL MarioSprInteract        ;$039585    |\ Branch if not in contact with Mario.
    BCC NoRexContact            ;$039589    |/
    LDA.w $1490                 ;$03958B    |\ Branch if Mario has star power.
    BNE RexStarKill             ;$03958E    |/
    LDA.w $154C,X               ;$039590    |\ Branch if the Rex already interacted with Mario once and needs to wait before interacting again.
    BNE NoRexContact            ;$039593    |/
    LDA.b #$08                  ;$039595    |\ Set timer to prevent multiple interactions.
    STA.w $154C,X               ;$039597    |/
    LDA $7D                     ;$03959A    |\ 
    CMP.b #$10                  ;$03959C    || Branch if Mario is moving upwards with a speed faster than #$10 (i.e. not able to bounce off).
    BMI RexWins                 ;$03959E    |/
MarioBeatsRex:                  ;```````````| Rex was bounced on.
    JSR RexPoints               ;$0395A0    | Give points.
    JSL BoostMarioSpeed         ;$0395A3    | Bounce Mario.
    JSL DispContactMario        ;$0395A7    | Display a contact sprite.
    LDA.w $140D                 ;$0395AB    |\ 
    ORA.w $187A                 ;$0395AE    || Branch if Mario was spinjumping or riding Yoshi.
    BNE RexSpinKill             ;$0395B1    |/
    INC $C2,X                   ;$0395B3    | Increment hit counter. 
    LDA $C2,X                   ;$0395B5    |\ 
    CMP.b #$02                  ;$0395B7    || Branch if the Rex hasn't been fully squished yet.
    BNE SmushRex                ;$0395B9    |/
    LDA.b #$20                  ;$0395BB    |\\ How long the Rex shows its fully-squished animation frame for.
    STA.w $1558,X               ;$0395BD    |/
    RTS                         ;$0395C0    |


SmushRex:                       ;```````````| Half-squishing the Rex.
    LDA.b #$0C                  ;$0395C1    |\\ How long the half-squished Rex pauses for.
    STA.w $1FE2,X               ;$0395C3    |/
    STZ.w $1662,X               ;$0395C6    | Change sprite clipping.
    RTS                         ;$0395C9    |


RexWins:                        ;```````````| Mario is being hurt by the Rex.
    LDA.w $1497                 ;$0395CA    |\ 
    ORA.w $187A                 ;$0395CD    || Return no contact if Mario has invulnerability frames or is riding Yoshi (who handles interaction in his own routine).
    BNE NoRexContact            ;$0395D0    |/
    JSR SubHorzPosBnk3          ;$0395D2    |\ 
    TYA                         ;$0395D5    || Make the Rex face towards Mario.
    STA.w $157C,X               ;$0395D6    |/
    JSL HurtMario               ;$0395D9    | Hurt Mario.
NoRexContact:                   ;           |
    RTS                         ;$0395DD    |


RexSpinKill:                    ;```````````| Rex was killed by a spinjump / Yoshi stomp.
    LDA.b #$04                  ;$0395DE    |\ Switch status to disappearing in a cloud of smoke.
    STA.w $14C8,X               ;$0395E0    |/
    LDA.b #$1F                  ;$0395E3    |\ Set timer for the smoke cloud.
    STA.w $1540,X               ;$0395E5    |/
    JSL CODE_07FC3B             ;$0395E8    | Draw the spinjump stars.
    LDA.b #$08                  ;$0395EC    |\ SFX for stomping the Rex.
    STA.w $1DF9                 ;$0395EE    |/
    RTS                         ;$0395F1    |


RexStarKill:                    ;```````````| Rex was killed by star power.
    LDA.b #$02                  ;$0395F2    |\ Kill the Rex.
    STA.w $14C8,X               ;$0395F4    |/
    LDA.b #$D0                  ;$0395F7    |\\ Y speed to give the Rex when killed by star power.
    STA $AA,X                   ;$0395F9    |/
    JSR SubHorzPosBnk3          ;$0395FB    |\ 
    LDA.w RexKilledSpeed,Y      ;$0395FE    || Make the Rex fly away from Mario.
    STA $B6,X                   ;$039601    |/
    INC.w $18D2                 ;$039603    |\ 
    LDA.w $18D2                 ;$039606    ||
    CMP.b #$08                  ;$039609    || Increment Mario's star power kill count.
    BCC CODE_039612             ;$03960B    ||
    LDA.b #$08                  ;$03960D    ||
    STA.w $18D2                 ;$03960F    |/
CODE_039612:                    ;           |
    JSL GivePoints              ;$039612    | Give respective number of points.
    LDY.w $18D2                 ;$039616    |\ 
    CPY.b #$08                  ;$039619    ||
    BCS Return039623            ;$03961B    || Store sound effect for the kill.
    LDA.w DATA_038000-1,Y       ;$03961D    ||
    STA.w $1DF9                 ;$039620    |/
Return039623:                   ;           |
    RTS                         ;$039623    |

    RTS                         ;$039624    |

RexKilledSpeed:                 ;$039625    | X speeds to give the Rex when killed with star power.
    db $F0,$10


    RTS                         ;$039627    |

RexPoints:                      ;-----------| Subroutine to give points for bounce off of a Rex.
    PHY                         ;$039628    |
    LDA.w $1697                 ;$039629    |\ 
    CLC                         ;$03962C    ||
    ADC.w $1626,X               ;$03962D    ||
    INC.w $1697                 ;$039630    ||
    TAY                         ;$039633    || Increase Mario's bounce counter and play an appropriate sound effect.
    INY                         ;$039634    ||
    CPY.b #$08                  ;$039635    ||
    BCS CODE_03963F             ;$039637    ||
    LDA.w DATA_038000-1,Y       ;$039639    ||
    STA.w $1DF9                 ;$03963C    |/
CODE_03963F:                    ;           |
    TYA                         ;$03963F    |\ 
    CMP.b #$08                  ;$039640    ||
    BCC CODE_039646             ;$039642    || Give Mario an appropriate number of points.
    LDA.b #$08                  ;$039644    ||
CODE_039646:                    ;           ||
    JSL GivePoints              ;$039646    |/
    PLY                         ;$03964A    |
    RTS                         ;$03964B    |



RexTileDispX:                   ;$03964C    | X offsets for each of the Rex's animation frames.
    db $FC,$00,$FC,$00                      ; Walking A/B, right
    db $FE,$00                              ; Half-smushed trasition, right
    db $00,$00,$00,$00                      ; Half-smushed walking A/B, right
    db $00,$08                              ; Fully-smushed, right
    db $04,$00,$04,$00                      ; Walking A/B, left
    db $02,$00                              ; Half-smushed trasition, left
    db $00,$00,$00,$00                      ; Half-smushed walking A/B, left
    db $08,$00                              ; Fully-smushed, left

RexTileDispY:                   ;$039664    | Y offsets for each of the Rex's animation frames.
    db $F1,$00,$F0,$00                      ; Walking A/B
    db $F8,$00                              ; Half-smushed trasition
    db $00,$00,$00,$00                      ; Half-smushed walking A/B
    db $08,$08                              ; Fully-smushed

RexTiles:                       ;$039670    | Tile numbers for each of the Rex's animation frames.
    db $8A,$AA,$8A,$AC                      ; Walking A/B
    db $8A,$AA                              ; Half-smushed trasition
    db $8C,$8C,$A8,$A8                      ; Half-smushed walking A/B
    db $A2,$B2                              ; Fully-smushed

RexGfxProp:                     ;$03967C    | YXPPCCCT for the Rex, indexed by his direction.
    db $47,$07

RexGfxRt:                       ;-----------| Rex GFX routine
    LDA.w $1558,X               ;$03967E    |\ 
    BEQ RexGfxAlive             ;$039681    || If the Rex was smushed, use animation frame 5.
    LDA.b #$05                  ;$039683    ||
    STA.w $1602,X               ;$039685    |/
RexGfxAlive:                    ;           |
    LDA.w $1FE2,X               ;$039688    |\ 
    BEQ RexNotHalfSmushed       ;$03968B    || If the Rex was just half-smushed, use animation frame 2.
    LDA.b #$02                  ;$03968D    ||
    STA.w $1602,X               ;$03968F    |/
RexNotHalfSmushed:              ;           |
    JSR GetDrawInfoBnk3         ;$039692    |
    LDA.w $1602,X               ;$039695    |\ 
    ASL                         ;$039698    || $03 = animation frame x2
    STA $03                     ;$039699    |/
    LDA.w $157C,X               ;$03969B    |\ $02 = horizontal direction
    STA $02                     ;$03969E    |/
    PHX                         ;$0396A0    |
    LDX.b #$01                  ;$0396A1    |
RexGfxLoopStart:                ;           |
    PHX                         ;$0396A3    |
    TXA                         ;$0396A4    |\ 
    ORA $03                     ;$0396A5    ||
    PHA                         ;$0396A7    ||
    LDX $02                     ;$0396A8    ||
    BNE RexFaceLeft             ;$0396AA    ||
    CLC                         ;$0396AC    ||
    ADC.b #$0C                  ;$0396AD    || Store X position to OAM.
RexFaceLeft:                    ;           ||
    TAX                         ;$0396AF    ||
    LDA $00                     ;$0396B0    ||
    CLC                         ;$0396B2    ||
    ADC.w RexTileDispX,X        ;$0396B3    ||
    STA.w $0300,Y               ;$0396B6    |/
    PLX                         ;$0396B9    |\ 
    LDA $01                     ;$0396BA    ||
    CLC                         ;$0396BC    || Store Y position to OAM.
    ADC.w RexTileDispY,X        ;$0396BD    ||
    STA.w $0301,Y               ;$0396C0    |/
    LDA.w RexTiles,X            ;$0396C3    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$0396C6    |/
    LDX $02                     ;$0396C9    |\ 
    LDA.w RexGfxProp,X          ;$0396CB    || Store YXPPCCCT to OAM.
    ORA $64                     ;$0396CE    ||
    STA.w $0303,Y               ;$0396D0    |/
    TYA                         ;$0396D3    |\ 
    LSR                         ;$0396D4    ||
    LSR                         ;$0396D5    ||
    LDX $03                     ;$0396D6    ||
    CPX.b #$0A                  ;$0396D8    ||
    TAX                         ;$0396DA    || Store tile size to OAM; normally 16x16, except when fully-squished.
    LDA.b #$00                  ;$0396DB    ||
    BCS Rex8x8Tile              ;$0396DD    ||
    LDA.b #$02                  ;$0396DF    ||
Rex8x8Tile:                     ;           ||
    STA.w $0460,X               ;$0396E1    |/
    PLX                         ;$0396E4    |
    INY                         ;$0396E5    |\ 
    INY                         ;$0396E6    ||
    INY                         ;$0396E7    || Loop for the second tile.
    INY                         ;$0396E8    ||
    DEX                         ;$0396E9    ||
    BPL RexGfxLoopStart         ;$0396EA    |/
    PLX                         ;$0396EC    |
    LDY.b #$FF                  ;$0396ED    |\ 
    LDA.b #$01                  ;$0396EF    || Upload 2 manually-sized tiles.
    JSL FinishOAMWrite          ;$0396F1    |/
    RTS                         ;$0396F5    |





    ; Fishbone misc RAM:
    ; $C2   - Phase pointer. 0 = boosting, 1 = decelerating.
    ; $1540 - Phase timer.
    ; $1558 - Timer for the Fishbone's blink animation. Randomly has a chance of being set every 128 frames.
    ; $1570 - Frame counter for animation.
    ; $157C - Horizontal direction the sprite is facing.
    ; $1602 - Animation frame. 0/1 = swimming
    
Fishbone:                       ;-----------| Fishbone MAIN
    JSR FishboneGfx             ;$0396F6    | Draw GFX.
    LDA $9D                     ;$0396F9    |\ Return if game frozen.
    BNE Return03972A            ;$0396FB    |/
    JSR SubOffscreen0Bnk3       ;$0396FD    | Process offscreen from -$40 to +$30.
    JSL MarioSprInteract        ;$039700    | Process interaction with Mario.
    JSL UpdateXPosNoGrvty       ;$039704    | Update X position.
    TXA                         ;$039708    |\ 
    ASL                         ;$039709    ||
    ASL                         ;$03970A    ||
    ASL                         ;$03970B    ||
    ASL                         ;$03970C    ||
    ADC $13                     ;$03970D    ||
    AND.b #$7F                  ;$03970F    || Every 128 frames, randomly decide whether to boost the fishbone or not.
    BNE CODE_039720             ;$039711    ||
    JSL GetRand                 ;$039713    ||
    AND.b #$01                  ;$039717    ||
    BNE CODE_039720             ;$039719    ||
    LDA.b #$0C                  ;$03971B    ||
    STA.w $1558,X               ;$03971D    |/
CODE_039720:                    ;           |
    LDA $C2,X                   ;$039720    |
    JSL ExecutePtr              ;$039722    |

FishbonePtrs:                   ;$039726    | Fishbone phase pointers.
    dw CODE_03972F              ; 0 - Boosting
    dw CODE_03975E              ; 1 - Decelerating

Return03972A:
    RTS                         ;$03972A    |



FishboneMaxSpeed:               ;$03972B    | Max X speeds for the Fishbone.
    db $10,$F0

FishboneAcceler:                ;$03972D    | X accelerations for the Fishbone.
    db $01,$FF

CODE_03972F:                    ;-----------| Fishbone phase 0 - Boosting
    INC.w $1570,X               ;$03972F    |\ 
    LDA.w $1570,X               ;$039732    ||
    NOP                         ;$039735    || Handle swimming animation.
    LSR                         ;$039736    ||
    AND.b #$01                  ;$039737    ||
    STA.w $1602,X               ;$039739    |/
    LDA.w $1540,X               ;$03973C    |\ Branch if done boosting.
    BEQ CODE_039756             ;$03973F    |/
    AND.b #$01                  ;$039741    |\ Return if not a frame to accelerate the Fishbone.
    BNE Return039755            ;$039743    |/
    LDY.w $157C,X               ;$039745    |\ 
    LDA $B6,X                   ;$039748    ||
    CMP.w FishboneMaxSpeed,Y    ;$03974A    ||
    BEQ Return039755            ;$03974D    || Horizontally accelerate the Fishbone, if not already at the max speed.
    CLC                         ;$03974F    ||
    ADC.w FishboneAcceler,Y     ;$039750    ||
    STA $B6,X                   ;$039753    |/
Return039755:                   ;           |
    RTS                         ;$039755    |

CODE_039756:                    ;```````````| Done boosting.
    INC $C2,X                   ;$039756    | Increment phase pointer.
    LDA.b #$30                  ;$039758    |\\ How long the Fishbone decelerates for before boosting again.
    STA.w $1540,X               ;$03975A    |/
    RTS                         ;$03975D    |



CODE_03975E:                    ;-----------| Fishbone phase 1 - Decelerating
    STZ.w $1602,X               ;$03975E    |
    LDA.w $1540,X               ;$039761    |\ Branch if time to boost again.
    BEQ CODE_039776             ;$039764    |/
    AND.b #$03                  ;$039766    |\ Branch if not a frame to decelerate.
    BNE Return039775            ;$039768    |/
    LDA $B6,X                   ;$03976A    |\ 
    BEQ Return039775            ;$03976C    ||
    BPL CODE_039773             ;$03976E    ||
    INC $B6,X                   ;$039770    || Slow the Fishbone down.
    RTS                         ;$039772    ||
CODE_039773:                    ;           ||
    DEC $B6,X                   ;$039773    |/
Return039775:                   ;           |
    RTS                         ;$039775    |

CODE_039776:                    ;```````````| Time to boost again.
    STZ $C2,X                   ;$039776    | Clear phase pointer.
    LDA.b #$30                  ;$039778    |\\ How long the Fishbone boosts for.
    STA.w $1540,X               ;$03977A    |/
    RTS                         ;$03977D    |



FishboneDispX:                  ;$03977E    | X offsets for the Fishbone's tail, indexed by its direction.
    db $F8,$F8                  ; Right
    db $10,$10                  ; Left

FishboneDispY:                  ;$039782    | Y offsets for the Fishbone's tail.
    db $00,$08

FishboneGfxProp:                ;$039784    | YXPPCCCT for the Fishbone's tail, indexed by its direction.
    db $4D,$CD                  ; Right
    db $0D,$8D                  ; Left

FishboneTailTiles:              ;$039788    | Tile numbers for the Fishbone's tail, indexed by its animation frame.
    db $A3,$A3
    db $B3,$B3

FishboneGfx:                    ;-----------| Fishbone GFX routine
    JSL GenericSprGfxRt2        ;$03978C    | Draw a 16x16 (for the fishbone's head).
    LDY.w $15EA,X               ;$039790    |
    LDA.w $1558,X               ;$039793    |\ 
    CMP.b #$01                  ;$039796    || Change tile number in OAM.
    LDA.b #$A6                  ;$039798    ||| Tile to use for the Fishbone's head normally.
    BCC CODE_03979E             ;$03979A    ||
    LDA.b #$A8                  ;$03979C    ||| Tile to use for the Fishbone's head when blinking.
CODE_03979E:                    ;           ||
    STA.w $0302,Y               ;$03979E    |/
    JSR GetDrawInfoBnk3         ;$0397A1    |
    LDA.w $157C,X               ;$0397A4    |\ 
    ASL                         ;$0397A7    || $02 = horizontal direction x2
    STA $02                     ;$0397A8    |/
    LDA.w $1602,X               ;$0397AA    |\ 
    ASL                         ;$0397AD    || $03 = animation frame x2
    STA $03                     ;$0397AE    |/
    LDA.w $15EA,X               ;$0397B0    |
    CLC                         ;$0397B3    |
    ADC.b #$04                  ;$0397B4    |
    STA.w $15EA,X               ;$0397B6    |
    TAY                         ;$0397B9    |
    PHX                         ;$0397BA    |
    LDX.b #$01                  ;$0397BB    |
CODE_0397BD:                    ;```````````| Tile loop for the Fishbone's tail tiles.
    LDA $01                     ;$0397BD    |\ 
    CLC                         ;$0397BF    || Store Y position to OAM.
    ADC.w FishboneDispY,X       ;$0397C0    ||
    STA.w $0301,Y               ;$0397C3    |/
    PHX                         ;$0397C6    |
    TXA                         ;$0397C7    |\ 
    ORA $02                     ;$0397C8    ||
    TAX                         ;$0397CA    ||
    LDA $00                     ;$0397CB    || Store X position to OAM.
    CLC                         ;$0397CD    ||
    ADC.w FishboneDispX,X       ;$0397CE    ||
    STA.w $0300,Y               ;$0397D1    |/
    LDA.w FishboneGfxProp,X     ;$0397D4    |\ 
    ORA $64                     ;$0397D7    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$0397D9    |/
    PLA                         ;$0397DC    |
    PHA                         ;$0397DD    |\ 
    ORA $03                     ;$0397DE    ||
    TAX                         ;$0397E0    || Store tile number to OAM.
    LDA.w FishboneTailTiles,X   ;$0397E1    ||
    STA.w $0302,Y               ;$0397E4    |/
    PLX                         ;$0397E7    |
    INY                         ;$0397E8    |\ 
    INY                         ;$0397E9    ||
    INY                         ;$0397EA    || Loop for both tiles.
    INY                         ;$0397EB    ||
    DEX                         ;$0397EC    ||
    BPL CODE_0397BD             ;$0397ED    |/
    PLX                         ;$0397EF    |
    LDY.b #$00                  ;$0397F0    |\ 
    LDA.b #$02                  ;$0397F2    || Draw 2 8x8 tiles.
    JSL FinishOAMWrite          ;$0397F4    |/
    RTS                         ;$0397F8    |





CODE_0397F9:                    ;-----------| Subroutine to decide where to shoot Reznor's fireballs.
    STA $01                     ;$0397F9    |  Input: A - Minimum speed in any direction, X = sprite number to aim from
    PHX                         ;$0397FB    |  Output: $00 = X speed, $01 = Y speed
    PHY                         ;$0397FC    |
    JSR SubVertPosBnk3          ;$0397FD    |\ 
    STY $02                     ;$039800    ||
    LDA $0E                     ;$039802    ||
    BPL CODE_03980B             ;$039804    || Set $0C to the absolute vertical distance from Mario.
    EOR.b #$FF                  ;$039806    || Appears to be have a coding error on Nintendo's part;
    CLC                         ;$039808    ||  SubVertPosBnk3 uses $0F, not $0E like the normal SubVertPos routine.
    ADC.b #$01                  ;$039809    ||
CODE_03980B:                    ;           ||
    STA $0C                     ;$03980B    |/
    JSR SubHorzPosBnk3          ;$03980D    |\ 
    STY $03                     ;$039810    ||
    LDA $0F                     ;$039812    ||
    BPL CODE_03981B             ;$039814    || Set $0D to the absolute horizontal distance from Mario.
    EOR.b #$FF                  ;$039816    ||
    CLC                         ;$039818    ||
    ADC.b #$01                  ;$039819    ||
CODE_03981B:                    ;           ||
    STA $0D                     ;$03981B    |/
    LDY.b #$00                  ;$03981D    |\\ 
    LDA $0D                     ;$03981F    |||
    CMP $0C                     ;$039821    |||
    BCS CODE_03982E             ;$039823    ||| If further away horizontally than vertically, swap $0C/$0D
    INY                         ;$039825    |||  (so that the shorter distance is in $0C).
    PHA                         ;$039826    |||
    LDA $0C                     ;$039827    |||
    STA $0D                     ;$039829    |||
    PLA                         ;$03982B    |||
    STA $0C                     ;$03982C    ||/
CODE_03982E:                    ;           ||
    LDA.b #$00                  ;$03982E    ||
    STA $0B                     ;$039830    ||
    STA $00                     ;$039832    ||
    LDX $01                     ;$039834    ||\ 
CODE_039836:                    ;           |||
    LDA $0B                     ;$039836    |||
    CLC                         ;$039838    |||
    ADC $0C                     ;$039839    ||| $00 = ($0C * $01) / $0D
    CMP $0D                     ;$03983B    ||| $0B = ($0C * $01) % $0D
    BCC CODE_039843             ;$03983D    |||
    SBC $0D                     ;$03983F    ||| Essentially, this does a ratio of the vertical and horizontal distances,
    INC $00                     ;$039841    |||  then scales the base speed using that ratio.
CODE_039843:                    ;           |||
    STA $0B                     ;$039843    |||
    DEX                         ;$039845    |||
    BNE CODE_039836             ;$039846    ||/
    TYA                         ;$039848    ||\ 
    BEQ CODE_039855             ;$039849    |||
    LDA $00                     ;$03984B    |||
    PHA                         ;$03984D    ||| If $0C/$0D were swapped before,
    LDA $01                     ;$03984E    |||  swap $00/$01.
    STA $00                     ;$039850    |||
    PLA                         ;$039852    |||
    STA $01                     ;$039853    |//
CODE_039855:                    ;           |
    LDA $00                     ;$039855    |\ 
    LDY $02                     ;$039857    ||
    BEQ CODE_039862             ;$039859    ||
    EOR.b #$FF                  ;$03985B    || Invert $00 if Mario is to the left.
    CLC                         ;$03985D    ||
    ADC.b #$01                  ;$03985E    ||
    STA $00                     ;$039860    |/
CODE_039862:                    ;           |
    LDA $01                     ;$039862    |\ 
    LDY $03                     ;$039864    ||
    BEQ CODE_03986F             ;$039866    ||
    EOR.b #$FF                  ;$039868    || Invert $01 if Mario is to the right.
    CLC                         ;$03986A    ||
    ADC.b #$01                  ;$03986B    ||
    STA $01                     ;$03986D    |/
CODE_03986F:                    ;           |
    PLY                         ;$03986F    |
    PLX                         ;$039870    |
    RTS                         ;$039871    |





ReznorInit:                     ;-----------| Reznor INIT
    CPX.b #$07                  ;$039872    |\ Branch if not the "base" Reznor sprite.
    BNE CODE_03987E             ;$039874    |/
    LDA.b #$04                  ;$039876    |\ Store Mode 7 index.
    STA $C2,X                   ;$039878    |/
    JSL CODE_03DD7D             ;$03987A    | Load palette/GFX files.
CODE_03987E:                    ;           |
    JSL GetRand                 ;$03987E    |\ Store a random value to Reznor's initial fireball timer.
    STA.w $1570,X               ;$039882    |/
    RTL                         ;$039885    |



ReznorStartPosLo:               ;$039886    | Initial angular positions for each Reznor, low
    db $00,$80,$00,$80

ReznorStartPosHi:               ;$03988A    | Initial angular positions for each Reznor, high
    db $00,$00,$01,$01

ReboundSpeedX:                  ;$03988E    | X speeds to give Mario when he runs into the side of Reznor's platform.
    db $20,$E0

    ; Reznor misc RAM:
    ; $C2   - Set to #$04 for the "base" Reznor in slot 7, to indicate which Mode 7 room needs to be loaded.
    ;          Also (unintentially) set to 1 for the other Reznors if their platform is hit after the Reznor has already been killed.
    ; $151C - Flag for whether this Reznor has been killed.
    ; $1528 - Number of pixels moved horizontally during the frame, for moving Mario with the Reznor's platform if he's on top of it.
    ; $1558 - Timer for Reznor's firing animation. Set to #$40 when shooting.
    ;          Also set after the Reznor is killed when hitting the platform for the first time, although this is unused.
    ; $1564 - Timer set whenever Reznor's platform is hit from below, for the platform's bounce animation.
    ; $1570 - Frame counter to determine when Reznor should shoot a fireball. Sets to a random initial number; a fireball is shot when it hits 0.
    ; $157C - Horizontal direction the sprite is facing. 00 = right, 01 = left
    ; $15AC - Timer for turning.
    ; $1602 - Animation frame.
    ;          0 = normal, 1 = shooting, 2 = turning
    ; $163E - Timer for waiting before ending the level after all Reznors are dead.
    
Reznor:                         ;-----------| Reznor MAIN
    INC.w $140F                 ;$039890    | Set flag to send smoke sprites to a different VRAM address.
    LDA $9D                     ;$039893    |\ 
    BEQ ReznorNotLocked         ;$039895    || If game frozen, skip Mario interaction and position updating.
    JMP CODE_039A7B             ;$039897    |/
ReznorNotLocked:                ;           |
    CPX.b #$07                  ;$03989A    |\ If not the base Reznor, skip down.
    BNE CODE_039910             ;$03989C    |/
    PHX                         ;$03989E    |
    JSL CODE_03D70C             ;$03989F    | Handle collapsing the bridge if time to.
    LDA.b #$80                  ;$0398A3    |\\ X position of the center of rotation for Reznor's wheel.
    STA $2A                     ;$0398A5    ||
    STZ $2B                     ;$0398A7    |/
    LDX.b #$00                  ;$0398A9    |
    LDA.b #$C0                  ;$0398AB    |\\ X position of Reznor's wheel. 
    STA $E4                     ;$0398AD    ||
    STZ.w $14E0                 ;$0398AF    |/
    LDA.b #$B2                  ;$0398B2    |\\ Y position of Reznor's wheel.
    STA $D8                     ;$0398B4    ||
    STZ.w $14D4                 ;$0398B6    |/
    LDA.b #$2C                  ;$0398B9    |\ 
    STA.w $1BA2                 ;$0398BB    || Attach the wheel to Reznor's position.
    JSL CODE_03DEDF             ;$0398BE    |/
    PLX                         ;$0398C2    |
    REP #$20                    ;$0398C3    |
    LDA $36                     ;$0398C5    |\ 
    CLC                         ;$0398C7    ||
    ADC.w #$0001                ;$0398C8    ||| Speed that Reznor's wheel rotates with.
    AND.w #$01FF                ;$0398CB    ||| How many frames until the wheel resets its rotation.
    STA $36                     ;$0398CE    |/
    SEP #$20                    ;$0398D0    |
    CPX.b #$07                  ;$0398D2    |\ Useless? Since this was already checked earlier.
    BNE CODE_039910             ;$0398D4    |/
    LDA.w $163E,X               ;$0398D6    |\ Branch if Reznor hasn't been defeated.
    BEQ ReznorNoLevelEnd        ;$0398D9    |/
    DEC A                       ;$0398DB    |\ Branch further if Reznor has been defeated, but not time to end the level yet.
    BNE CODE_039910             ;$0398DC    |/
    DEC.w $13C6                 ;$0398DE    |
    LDA.b #$FF                  ;$0398E1    |\ Set end level timer.
    STA.w $1493                 ;$0398E3    |/
    LDA.b #$0B                  ;$0398E6    |\ SFX/music played after defeating Reznor.
    STA.w $1DFB                 ;$0398E8    |/
    RTS                         ;$0398EB    |

ReznorNoLevelEnd:               ;```````````| Not ending the level yet.
    LDA.w $1523                 ;$0398EC    |\ 
    CLC                         ;$0398EF    ||
    ADC.w $1522                 ;$0398F0    ||
    ADC.w $1521                 ;$0398F3    || Branch if all four Reznors haven't been defeated yet.
    ADC.w $1520                 ;$0398F6    ||
    CMP.b #$04                  ;$0398F9    ||
    BNE CODE_039910             ;$0398FB    |/
    LDA.b #$90                  ;$0398FD    |\ Set timer to wait before actually ending the level.
    STA.w $163E,X               ;$0398FF    |/
    JSL KillMostSprites         ;$039902    | Make any other sprites disappear in a puff of smoke.
    LDY.b #$07                  ;$039906    |\ 
    LDA.b #$00                  ;$039908    ||
CODE_03990A:                    ;           || Erase all of Reznor's fireballs.
    STA.w $170B,Y               ;$03990A    ||
    DEY                         ;$03990D    ||
    BPL CODE_03990A             ;$03990E    |/
CODE_039910:                    ;```````````| Non-base Reznors join back in here.
    LDA.w $14C8,X               ;$039910    |\ 
    CMP.b #$08                  ;$039913    || If not alive, skip Mario interaction and position updating.
    BEQ CODE_03991A             ;$039915    ||
    JMP CODE_039A7B             ;$039917    |/

CODE_03991A:                    ;```````````| Calculate Reznor's position on the wheel.
    TXA                         ;$03991A    |
    AND.b #$03                  ;$03991B    |
    TAY                         ;$03991D    |
    LDA $36                     ;$03991E    |\ 
    CLC                         ;$039920    ||
    ADC.w ReznorStartPosLo,Y    ;$039921    ||
    STA $00                     ;$039924    || Get Reznor's base angular position.
    LDA $37                     ;$039926    ||
    ADC.w ReznorStartPosHi,Y    ;$039928    ||
    AND.b #$01                  ;$03992B    ||
    STA $01                     ;$03992D    |/
    REP #$30                    ;$03992F    |
    LDA $00                     ;$039931    |\ 
    EOR.w #$01FF                ;$039933    ||
    INC A                       ;$039936    ||
    STA $00                     ;$039937    || Rotate Reznor counter-clockwise.
    CLC                         ;$039939    ||
    ADC.w #$0080                ;$03993A    ||
    AND.w #$01FF                ;$03993D    ||
    STA $02                     ;$039940    |/
    LDA $00                     ;$039942    |\ 
    AND.w #$00FF                ;$039944    ||
    ASL                         ;$039947    || Get the sin value.
    TAX                         ;$039948    ||
    LDA.l CircleCoords,X        ;$039949    ||
    STA $04                     ;$03994D    |/
    LDA $02                     ;$03994F    |\ 
    AND.w #$00FF                ;$039951    ||
    ASL                         ;$039954    || Get the cos value.
    TAX                         ;$039955    ||
    LDA.l CircleCoords,X        ;$039956    ||
    STA $06                     ;$03995A    |/
    SEP #$30                    ;$03995C    |
    LDA $04                     ;$03995E    |\ 
    STA.w $4202                 ;$039960    ||
    LDA.b #$38                  ;$039963    ||| X-radius of Reznor's rotation.
    LDY $05                     ;$039965    ||
    BNE CODE_039978             ;$039967    ||
    STA.w $4203                 ;$039969    ||
    NOP                         ;$03996C    ||
    NOP                         ;$03996D    ||
    NOP                         ;$03996E    ||
    NOP                         ;$03996F    || Calculate Reznor's current X offset on the wheel.
    ASL.w $4216                 ;$039970    ||
    LDA.w $4217                 ;$039973    ||
    ADC.b #$00                  ;$039976    ||
CODE_039978:                    ;           ||
    LSR $01                     ;$039978    ||
    BCC CODE_03997F             ;$03997A    ||
    EOR.b #$FF                  ;$03997C    ||
    INC A                       ;$03997E    ||
CODE_03997F:                    ;           ||
    STA $04                     ;$03997F    |/
    LDA $06                     ;$039981    |\ 
    STA.w $4202                 ;$039983    ||
    LDA.b #$38                  ;$039986    ||| Y-radius of Reznor's rotation.
    LDY $07                     ;$039988    ||
    BNE CODE_03999B             ;$03998A    ||
    STA.w $4203                 ;$03998C    ||
    NOP                         ;$03998F    ||
    NOP                         ;$039990    ||
    NOP                         ;$039991    ||
    NOP                         ;$039992    || Calculate Reznor's current Y offset on the wheel.
    ASL.w $4216                 ;$039993    ||
    LDA.w $4217                 ;$039996    ||
    ADC.b #$00                  ;$039999    ||
CODE_03999B:                    ;           ||
    LSR $03                     ;$03999B    ||
    BCC CODE_0399A2             ;$03999D    ||
    EOR.b #$FF                  ;$03999F    ||
    INC A                       ;$0399A1    ||
CODE_0399A2:                    ;           ||
    STA $06                     ;$0399A2    |/
    LDX.w $15E9                 ;$0399A4    |
    LDA $E4,X                   ;$0399A7    |\ 
    PHA                         ;$0399A9    ||
    STZ $00                     ;$0399AA    ||
    LDA $04                     ;$0399AC    ||
    BPL CODE_0399B2             ;$0399AE    ||
    DEC $00                     ;$0399B0    ||
CODE_0399B2:                    ;           ||
    CLC                         ;$0399B2    ||
    ADC $2A                     ;$0399B3    || Update X position.
    PHP                         ;$0399B5    ||
    CLC                         ;$0399B6    ||
    ADC.b #$40                  ;$0399B7    ||
    STA $E4,X                   ;$0399B9    ||
    LDA $2B                     ;$0399BB    ||
    ADC.b #$00                  ;$0399BD    ||
    PLP                         ;$0399BF    ||
    ADC $00                     ;$0399C0    ||
    STA.w $14E0,X               ;$0399C2    |/
    PLA                         ;$0399C5    |\ 
    SEC                         ;$0399C6    ||
    SBC $E4,X                   ;$0399C7    || Track number of pixels the platform has moved horizontally.
    EOR.b #$FF                  ;$0399C9    ||
    INC A                       ;$0399CB    ||
    STA.w $1528,X               ;$0399CC    |/
    STZ $01                     ;$0399CF    |\ 
    LDA $06                     ;$0399D1    ||
    BPL CODE_0399D7             ;$0399D3    ||
    DEC $01                     ;$0399D5    ||
CODE_0399D7:                    ;           ||
    CLC                         ;$0399D7    ||
    ADC $2C                     ;$0399D8    ||
    PHP                         ;$0399DA    || Update Y position.
    ADC.b #$20                  ;$0399DB    ||
    STA $D8,X                   ;$0399DD    ||
    LDA $2D                     ;$0399DF    ||
    ADC.b #$00                  ;$0399E1    ||
    PLP                         ;$0399E3    ||
    ADC $01                     ;$0399E4    ||
    STA.w $14D4,X               ;$0399E6    |/
    LDA.w $151C,X               ;$0399E9    |\ Branch if this Reznor hasn't been killed.
    BEQ ReznorAlive             ;$0399EC    |/
    JSL InvisBlkMainRt          ;$0399EE    | Make the Reznor's platform solid after he dies.
    JMP CODE_039A7B             ;$0399F2    | Branch down to continue code.

ReznorAlive:                    ;```````````| Reznor is still alive; this handles the actual Reznor.
    LDA $13                     ;$0399F5    |\ 
    AND.b #$00                  ;$0399F7    || Don't shoot fire if Reznor is turning.
    ORA.w $15AC,X               ;$0399F9    ||  (with a useless AND)
    BNE NoSetRznrFireTime       ;$0399FC    |/
    INC.w $1570,X               ;$0399FE    |\ 
    LDA.w $1570,X               ;$039A01    || Only shoot fire every 256 frames.
    CMP.b #$00                  ;$039A04    ||
    BNE NoSetRznrFireTime       ;$039A06    |/
    STZ.w $1570,X               ;$039A08    | (useless)
    LDA.b #$40                  ;$039A0B    |\\ How long Reznor spends with his mouth open. Fireball shoots when this decrements to #$20.
    STA.w $1558,X               ;$039A0D    |/
NoSetRznrFireTime:              ;           |
    TXA                         ;$039A10    |\ 
    ASL                         ;$039A11    ||
    ASL                         ;$039A12    ||
    ASL                         ;$039A13    ||
    ASL                         ;$039A14    || Check whether to allow Reznor to turn and branch if not.
    ADC $14                     ;$039A15    ||  (conditions for not: not a frame to check, currently shooting a fireball, already turning)
    AND.b #$3F                  ;$039A17    ||
    ORA.w $1558,X               ;$039A19    ||
    ORA.w $15AC,X               ;$039A1C    ||
    BNE NoSetRenrTurnTime       ;$039A1F    |/
    LDA.w $157C,X               ;$039A21    |\ 
    PHA                         ;$039A24    ||
    JSR SubHorzPosBnk3          ;$039A25    ||
    TYA                         ;$039A28    || Check whether Reznor is facing Mario and, if he's not, change his direction.
    STA.w $157C,X               ;$039A29    ||
    PLA                         ;$039A2C    ||
    CMP.w $157C,X               ;$039A2D    ||
    BEQ NoSetRenrTurnTime       ;$039A30    ||
    LDA.b #$0A                  ;$039A32    ||| How long Reznor takes to turn around.
    STA.w $15AC,X               ;$039A34    |/
NoSetRenrTurnTime:              ;           |
    LDA.w $154C,X               ;$039A37    |\ 
    BNE CODE_039A7B             ;$039A3A    || Skip Mario interaction routine if dying or not touching Mario.
    JSL MarioSprInteract        ;$039A3C    ||
    BCC CODE_039A7B             ;$039A40    |/
    LDA.b #$08                  ;$039A42    |
    STA.w $154C,X               ;$039A44    |
    LDA $96                     ;$039A47    |\ 
    SEC                         ;$039A49    ||
    SBC $D8,X                   ;$039A4A    || Check where Mario has touched Reznor.
    CMP.b #$ED                  ;$039A4C    ||  If touching the actual Reznor, branch to hurt Mario.
    BMI HitReznor               ;$039A4E    ||  If touching the side of the platform, branch to stop Mario.
    CMP.b #$F2                  ;$039A50    ||  If touching the bottom of the platform, continue below to kill the Reznor.
    BMI HitPlatSide             ;$039A52    ||
    LDA $7D                     ;$039A54    ||
    BPL HitPlatSide             ;$039A56    |/
HitPlatBottom:                  ;```````````| Hit the bottom of the platform.
    LDA.b #$29                  ;$039A58    |\ Change interaction hitbox.
    STA.w $1662,X               ;$039A5A    |/
    LDA.b #$0F                  ;$039A5D    |\ Set timer for the platform's bounce animation (and for killing the Reznor).
    STA.w $1564,X               ;$039A5F    |/
    LDA.b #$10                  ;$039A62    |\ Set Y speed for Mario.
    STA $7D                     ;$039A64    |/
    LDA.b #$01                  ;$039A66    |\ SFX for kitting the bottom of Reznor's platform.
    STA.w $1DF9                 ;$039A68    |/
    BRA CODE_039A7B             ;$039A6B    | Branch down to continue code.

HitPlatSide:                    ;```````````| Hit the side of the platform.
    JSR SubHorzPosBnk3          ;$039A6D    |\ 
    LDA.w ReboundSpeedX,Y       ;$039A70    || Push Mario back.
    STA $7B                     ;$039A73    |/
    BRA CODE_039A7B             ;$039A75    | Branch down to continue code.

HitReznor:                      ;```````````| Hit the actual Reznor.
    JSL HurtMario               ;$039A77    | Hurt Mario.
CODE_039A7B:                    ;```````````| All Reznor routines rejoin here.
    STZ.w $1602,X               ;$039A7B    |\ 
    LDA.w $157C,X               ;$039A7E    ||
    PHA                         ;$039A81    ||
    LDY.w $15AC,X               ;$039A82    ||
    BEQ ReznorNoTurning         ;$039A85    ||
    CPY.b #$05                  ;$039A87    || Handle Reznor's turning animation.
    BCC ReznorTurning           ;$039A89    ||
    EOR.b #$01                  ;$039A8B    ||
    STA.w $157C,X               ;$039A8D    ||
ReznorTurning:                  ;           ||
    LDA.b #$02                  ;$039A90    ||
    STA.w $1602,X               ;$039A92    |/
ReznorNoTurning:                ;           |
    LDA.w $1558,X               ;$039A95    |\ 
    BEQ ReznorNoFiring          ;$039A98    ||
    CMP.b #$20                  ;$039A9A    ||
    BNE ReznorFiring            ;$039A9C    || If time to shoot a fireball, spawn one.
    JSR ReznorFireRt            ;$039A9E    ||  Then show an animation frame for firing for a brief period afterwards.
ReznorFiring:                   ;           ||
    LDA.b #$01                  ;$039AA1    ||
    STA.w $1602,X               ;$039AA3    |/
ReznorNoFiring:                 ;           |
    JSR ReznorGfxRt             ;$039AA6    | Draw GFX.
    PLA                         ;$039AA9    |
    STA.w $157C,X               ;$039AAA    |
    LDA $9D                     ;$039AAD    |\ 
    ORA.w $151C,X               ;$039AAF    || Return if:
    BNE Return039AF7            ;$039AB2    || - Game frozen
    LDA.w $1564,X               ;$039AB4    || - Reznor is already dead
    CMP.b #$0C                  ;$039AB7    || - Reznor's platform hasn't been hit
    BNE Return039AF7            ;$039AB9    |/
KillReznor:                     ;           |
    LDA.b #$03                  ;$039ABB    |\ SFX for a Reznor being killed.
    STA.w $1DF9                 ;$039ABD    |/
    STZ.w $1558,X               ;$039AC0    | Clear Reznor's fireball-shooting timer.
    INC.w $151C,X               ;$039AC3    | Set flag for the Reznor having been killed.
    JSL FindFreeSprSlot         ;$039AC6    |\ Return if there's no empty sprite slot to spawn the dead Reznor in.
    BMI Return039AF7            ;$039ACA    |/
    LDA.b #$02                  ;$039ACC    |\ 
    STA.w $14C8,Y               ;$039ACE    ||
    LDA.b #$A9                  ;$039AD1    ||| Sprite Reznor turns into after being hit (another Reznor).
    STA.w $009E,Y               ;$039AD3    |/
    LDA $E4,X                   ;$039AD6    |\ 
    STA.w $00E4,Y               ;$039AD8    ||
    LDA.w $14E0,X               ;$039ADB    ||
    STA.w $14E0,Y               ;$039ADE    || Spawn at the Reznor's current position.
    LDA $D8,X                   ;$039AE1    ||
    STA.w $00D8,Y               ;$039AE3    ||
    LDA.w $14D4,X               ;$039AE6    ||
    STA.w $14D4,Y               ;$039AE9    |/
    PHX                         ;$039AEC    |
    TYX                         ;$039AED    |
    JSL InitSpriteTables        ;$039AEE    |
    LDA.b #$C0                  ;$039AF2    |\\ Y speed the Reznor bounces with when knocked off his platform.
    STA $AA,X                   ;$039AF4    |/
    PLX                         ;$039AF6    |
Return039AF7:                   ;           |
    RTS                         ;$039AF7    |


ReznorFireRt:                   ;-----------| Subroutine to shoot Reznor's fireball.
    LDY.b #$07                  ;$039AF8    |\ 
CODE_039AFA:                    ;           ||
    LDA.w $170B,Y               ;$039AFA    ||
    BEQ FoundRznrFireSlot       ;$039AFD    || Find an empty extended sprite slot, and return if none found.
    DEY                         ;$039AFF    ||
    BPL CODE_039AFA             ;$039B00    ||
    RTS                         ;$039B02    |/
FoundRznrFireSlot:              ;           |
    LDA.b #$10                  ;$039B03    |\ SFX for Reznor's fireball being shot.
    STA.w $1DF9                 ;$039B05    |/
    LDA.b #$02                  ;$039B08    |\ Set the extended sprite number.
    STA.w $170B,Y               ;$039B0A    |/
    LDA $E4,X                   ;$039B0D    |\ 
    PHA                         ;$039B0F    ||
    SEC                         ;$039B10    ||
    SBC.b #$08                  ;$039B11    ||
    STA.w $171F,Y               ;$039B13    || Set X position.
    STA $E4,X                   ;$039B16    ||
    LDA.w $14E0,X               ;$039B18    ||
    SBC.b #$00                  ;$039B1B    ||
    STA.w $1733,Y               ;$039B1D    |/
    LDA $D8,X                   ;$039B20    |\ 
    PHA                         ;$039B22    ||
    SEC                         ;$039B23    ||
    SBC.b #$14                  ;$039B24    ||
    STA $D8,X                   ;$039B26    || Set Y position.
    STA.w $1715,Y               ;$039B28    ||
    LDA.w $14D4,X               ;$039B2B    ||
    PHA                         ;$039B2E    ||
    SBC.b #$00                  ;$039B2F    ||
    STA.w $1729,Y               ;$039B31    |/
    STA.w $14D4,X               ;$039B34    |\ 
    LDA.b #$10                  ;$039B37    ||
    JSR CODE_0397F9             ;$039B39    ||
    PLA                         ;$039B3C    ||
    STA.w $14D4,X               ;$039B3D    ||
    PLA                         ;$039B40    || Set X/Y speed.
    STA $D8,X                   ;$039B41    ||  Aim for Mario (or at least fail in trying).
    PLA                         ;$039B43    ||
    STA $E4,X                   ;$039B44    ||
    LDA $00                     ;$039B46    ||
    STA.w $173D,Y               ;$039B48    ||
    LDA $01                     ;$039B4B    ||
    STA.w $1747,Y               ;$039B4D    |/
    RTS                         ;$039B50    |



ReznorTileDispX:                ;$039B51    | X offsets for Reznor, indexed by his direction.
    db $00,$F0,$00,$F0                      ; Right
    db $F0,$00,$F0,$00                      ; Left

ReznorTileDispY:                ;$039B59    | Y offsets for Reznor.
    db $E0,$E0,$F0,$F0

ReznorTiles:                    ;$039B5D    | Tile numbers for Reznor.
    db $40,$42,$60,$62                      ; Normal
    db $44,$46,$64,$66                      ; Shooting
    db $28,$28,$48,$48                      ; Turning

ReznorPal:                      ;$039B69    | YXPPCCCT for Reznor.
    db $3F,$3F,$3F,$3F                      ; Normal
    db $3F,$3F,$3F,$3F                      ; Shooting
    db $7F,$3F,$7F,$3F                      ; Turning

ReznorGfxRt:                    ;-----------| Reznor GFX routine
    LDA.w $151C,X               ;$039B75    |\ Branch to just draw the platform if Reznor is dead.
    BNE DrawReznorPlats         ;$039B78    |/
    JSR GetDrawInfoBnk3         ;$039B7A    |
    LDA.w $1602,X               ;$039B7D    |\ 
    ASL                         ;$039B80    || $03 = animation frame, x4
    ASL                         ;$039B81    ||
    STA $03                     ;$039B82    |/
    LDA.w $157C,X               ;$039B84    |\ 
    ASL                         ;$039B87    || $02 = horizontal direction, x4
    ASL                         ;$039B88    ||
    STA $02                     ;$039B89    |/
    PHX                         ;$039B8B    |
    LDX.b #$03                  ;$039B8C    |
RznrGfxLoopStart:               ;```````````| Tile loop.
    PHX                         ;$039B8E    |
    LDA $03                     ;$039B8F    |\ 
    CMP.b #$08                  ;$039B91    ||
    BCS CODE_039B99             ;$039B93    ||
    TXA                         ;$039B95    ||
    ORA $02                     ;$039B96    ||
    TAX                         ;$039B98    || Store X position to OAM.
CODE_039B99:                    ;           ||
    LDA $00                     ;$039B99    ||
    CLC                         ;$039B9B    ||
    ADC.w ReznorTileDispX,X     ;$039B9C    ||
    STA.w $0300,Y               ;$039B9F    |/
    PLX                         ;$039BA2    |\ 
    LDA $01                     ;$039BA3    ||
    CLC                         ;$039BA5    || Store Y position to OAM.
    ADC.w ReznorTileDispY,X     ;$039BA6    ||
    STA.w $0301,Y               ;$039BA9    |/
    PHX                         ;$039BAC    |\ 
    TXA                         ;$039BAD    ||
    ORA $03                     ;$039BAE    || Store tile number to OAM.
    TAX                         ;$039BB0    ||
    LDA.w ReznorTiles,X         ;$039BB1    ||
    STA.w $0302,Y               ;$039BB4    |/
    LDA.w ReznorPal,X           ;$039BB7    |\ 
    CPX.b #$08                  ;$039BBA    ||
    BCS NoReznorGfxFlip         ;$039BBC    ||
    LDX $02                     ;$039BBE    || Store YXPPCCCT to OAM.
    BNE NoReznorGfxFlip         ;$039BC0    ||
    EOR.b #$40                  ;$039BC2    ||
NoReznorGfxFlip:                ;           ||
    STA.w $0303,Y               ;$039BC4    |/
    PLX                         ;$039BC7    |
    INY                         ;$039BC8    |\ 
    INY                         ;$039BC9    ||
    INY                         ;$039BCA    || Loop for all tiles.
    INY                         ;$039BCB    ||
    DEX                         ;$039BCC    ||
    BPL RznrGfxLoopStart        ;$039BCD    |/
    PLX                         ;$039BCF    |
    LDY.b #$02                  ;$039BD0    |\ 
    LDA.b #$03                  ;$039BD2    || Upload 4 16x16 tiles.
    JSL FinishOAMWrite          ;$039BD4    |/
    LDA.w $14C8,X               ;$039BD8    |\ 
    CMP.b #$02                  ;$039BDB    || Return if this is a dead Reznor (platform not included).
    BEQ Return039BE2            ;$039BDD    |/
DrawReznorPlats:                ;           |
    JSR ReznorPlatGfxRt         ;$039BDF    | Draw Reznor's platform.
Return039BE2:                   ;           |
    RTS                         ;$039BE2    |



ReznorPlatDispY:                ;$039BE3    | Y offsets for the bounce animation of Reznor's platform.
    db $00,$03,$04,$05,$05,$04,$03,$00

ReznorPlatGfxRt:                ;-----------| Reznor's platform GFX routine
    LDA.w $15EA,X               ;$039BEB    |
    CLC                         ;$039BEE    |
    ADC.b #$10                  ;$039BEF    |
    STA.w $15EA,X               ;$039BF1    |
    JSR GetDrawInfoBnk3         ;$039BF4    |
    LDA.w $1564,X               ;$039BF7    |\ 
    LSR                         ;$039BFA    ||
    PHY                         ;$039BFB    || $02 = Y offset for the platform's bounce animation when hit.
    TAY                         ;$039BFC    ||
    LDA.w ReznorPlatDispY,Y     ;$039BFD    ||
    STA $02                     ;$039C00    |/
    PLY                         ;$039C02    |
    LDA $00                     ;$039C03    |\ 
    STA.w $0304,Y               ;$039C05    ||
    SEC                         ;$039C08    || Store X positions to OAM.
    SBC.b #$10                  ;$039C09    ||
    STA.w $0300,Y               ;$039C0B    |/
    LDA $01                     ;$039C0E    |\ 
    SEC                         ;$039C10    ||
    SBC $02                     ;$039C11    || Store Y positions to OAM.
    STA.w $0301,Y               ;$039C13    ||
    STA.w $0305,Y               ;$039C16    |/
    LDA.b #$4E                  ;$039C19    |\\ Tile number to use for Reznor's platform.
    STA.w $0302,Y               ;$039C1B    ||
    STA.w $0306,Y               ;$039C1E    |/
    LDA.b #$33                  ;$039C21    |\\ YXPPCCCT for Reznor's platforms.
    STA.w $0303,Y               ;$039C23    ||
    ORA.b #$40                  ;$039C26    ||
    STA.w $0307,Y               ;$039C28    |/
    LDY.b #$02                  ;$039C2B    |\ 
    LDA.b #$01                  ;$039C2D    || Upload 2 16x16 tiles.
    JSL FinishOAMWrite          ;$039C2F    |/
    RTS                         ;$039C33    |





    ; Dino Rhino/Torch misc RAM:
    ; $C2   - Pointers to different routines. Fire is unused in the Rhino.
    ;          0 = walking, 1 = fire horz, 2 = fire vert, 3 = jumping
    ; $151C - Length of the Dino Torch's flame (0 = max, 4 = none). Also set for the Rhino at spawn, but otherwise unused.
    ; $1540 - Timer to wait before starting/stopping a flame. Rhino sets on spawn but doesn't use.
    ; $1570 - Frame counter for animation.
    ; $157C - Horizontal direction the sprite is facing.
    ; $1602 - Animation frame.
    ;          0/1 = walking, 2 = fire sideways, 3 = fire up

InvisBlkPDinosMain:             ;-----------| Invisible solid block MAIN / Dino Rhino MAIN / Dino Torch MAIN 
    LDA $9E,X                   ;$039C34    |\ 
    CMP.b #$6D                  ;$039C36    || Just make solid if sprite 6D (invisible block)
    BNE DinoMainRt              ;$039C38    ||  Honestly though, why is this here?
    JSL InvisBlkMainRt          ;$039C3A    |/
    RTL                         ;$039C3E    |

DinoMainRt:
    PHB                         ;$039C3F    |
    PHK                         ;$039C40    |
    PLB                         ;$039C41    |
    JSR DinoMainSubRt           ;$039C42    |
    PLB                         ;$039C45    |
    RTL                         ;$039C46    |

DinoMainSubRt:
    JSR DinoGfxRt               ;$039C47    | Draw graphics.
    LDA $9D                     ;$039C4A    |\ 
    BNE Return039CA3            ;$039C4C    ||
    LDA.w $14C8,X               ;$039C4E    || Return if game frozen or sprite dead.
    CMP.b #$08                  ;$039C51    ||
    BNE Return039CA3            ;$039C53    |/
    JSR SubOffscreen0Bnk3       ;$039C55    | Process offscreen from -$40 to +$30.
    JSL MarioSprInteract        ;$039C58    | Process interaction with Mario.
    JSL UpdateSpritePos         ;$039C5C    | Update X/Y position, apply gravity, and process block interaction.
    LDA $C2,X                   ;$039C60    |
    JSL ExecutePtr              ;$039C62    |

RhinoStatePtrs:                 ;$036C66    | Dino Rhino/Torch state pointers.
    dw CODE_039CA8                          ; 0 - Walking
    dw CODE_039D41                          ; 1 - Horizontal fire
    dw CODE_039D41                          ; 2 - Vertical fire
    dw CODE_039C74                          ; 3 - Jumping



DATA_039C6E:                    ;$039C6E    | Low X position shifts to push the Dino Rhino/Torch out of walls.
    db $00,$FE,$02

DATA_039C71:                    ;$039C71    | High X position shifts to push the Dino Rhino/Torch out of walls.
    db $00,$FF,$00

CODE_039C74:                    ;-----------| Dino Rhino/Torch rhino 3 - Jumping
    LDA $AA,X                   ;$039C74    |\ 
    BMI CODE_039C89             ;$039C76    ||
    STZ $C2,X                   ;$039C78    ||
    LDA.w $1588,X               ;$039C7A    || Return to state 0 if it starts falling,
    AND.b #$03                  ;$039C7D    ||  and invert direction if it's hitting a wall at that time.
    BEQ CODE_039C89             ;$039C7F    ||
    LDA.w $157C,X               ;$039C81    ||
    EOR.b #$01                  ;$039C84    ||
    STA.w $157C,X               ;$039C86    |/
CODE_039C89:                    ;           |
    STZ.w $1602,X               ;$039C89    |
    LDA.w $1588,X               ;$039C8C    |\ 
    AND.b #$03                  ;$039C8F    ||
    TAY                         ;$039C91    ||
    LDA $E4,X                   ;$039C92    ||
    CLC                         ;$039C94    || Push back from walls.
    ADC.w DATA_039C6E,Y         ;$039C95    ||
    STA $E4,X                   ;$039C98    ||
    LDA.w $14E0,X               ;$039C9A    ||
    ADC.w DATA_039C71,Y         ;$039C9D    ||
    STA.w $14E0,X               ;$039CA0    |/
Return039CA3:                   ;           |
    RTS                         ;$039CA3    |



DinoSpeed:                      ;$039CA3    | X speeds for the Dino Rhino and Dino Torch.
    db $08,$F8                              ; Rhino
    db $10,$F0                              ; Torch

CODE_039CA8:                    ;-----------| Dino Rhino/Torch phase 0 - Walking
    LDA.w $1588,X               ;$039CA8    |\ 
    AND.b #$04                  ;$039CAB    || If not on the ground, push the Rhino back from walls and return.
    BEQ CODE_039C89             ;$039CAD    |/
    LDA.w $1540,X               ;$039CAF    |\ 
    BNE CODE_039CC8             ;$039CB2    ||
    LDA $9E,X                   ;$039CB4    ||
    CMP.b #$6E                  ;$039CB6    ||
    BEQ CODE_039CC8             ;$039CB8    || If the Dino Torch's timer hits 0, spit fire in a random direction.
    LDA.b #$FF                  ;$039CBA    ||
    STA.w $1540,X               ;$039CBC    ||
    JSL GetRand                 ;$039CBF    ||
    AND.b #$01                  ;$039CC3    ||
    INC A                       ;$039CC5    ||
    STA $C2,X                   ;$039CC6    |/
CODE_039CC8:                    ;           |
    TXA                         ;$039CC8    |\ 
    ASL                         ;$039CC9    ||
    ASL                         ;$039CCA    ||
    ASL                         ;$039CCB    ||
    ASL                         ;$039CCC    ||
    ADC $14                     ;$039CCD    || Turn towards Mario every 64 frames. (when on the ground)
    AND.b #$3F                  ;$039CCF    ||
    BNE CODE_039CDA             ;$039CD1    ||
    JSR SubHorzPosBnk3          ;$039CD3    ||
    TYA                         ;$039CD6    ||
    STA.w $157C,X               ;$039CD7    |/
CODE_039CDA:                    ;           |
    LDA.b #$10                  ;$039CDA    |\ Set ground Y speed.
    STA $AA,X                   ;$039CDC    |/
    LDY.w $157C,X               ;$039CDE    |\ 
    LDA $9E,X                   ;$039CE1    ||
    CMP.b #$6E                  ;$039CE3    ||
    BEQ CODE_039CE9             ;$039CE5    ||
    INY                         ;$039CE7    || Set X speed.
    INY                         ;$039CE8    ||
CODE_039CE9:                    ;           ||
    LDA.w DinoSpeed,Y           ;$039CE9    ||
    STA $B6,X                   ;$039CEC    |/
    JSR DinoSetGfxFrame         ;$039CEE    | Animate the Dino Rhino/Torch's walking.
    LDA.w $1588,X               ;$039CF1    |\ 
    AND.b #$03                  ;$039CF4    || If it runs into a block, jump.
    BEQ Return039D00            ;$039CF6    ||
    LDA.b #$C0                  ;$039CF8    ||| Jump speed.
    STA $AA,X                   ;$039CFA    ||
    LDA.b #$03                  ;$039CFC    ||
    STA $C2,X                   ;$039CFE    |/
Return039D00:                   ;           |
    RTS                         ;$039D00    |



DinoFlameTable:                 ;$039D01    | Animation data for the Dino Torch's fire. In the format XY: Y = animation frame for the Dino, X = 4 - length of the flame
    db $41,$42,$42,$32,$22,$12,$02,$02      ; Horizontal
    db $02,$02,$02,$02,$02,$02,$02,$02
    db $02,$02,$02,$02,$02,$02,$02,$12
    db $22,$32,$42,$42,$42,$42,$41,$41
    db $41,$43,$43,$33,$23,$13,$03,$03      ; Vertical
    db $03,$03,$03,$03,$03,$03,$03,$03
    db $03,$03,$03,$03,$03,$03,$03,$13
    db $23,$33,$43,$43,$43,$43,$41,$41

CODE_039D41:                    ;-----------| Dino Rhino/Torch phase 1/2- Horizontal/Vertical fire
    STZ $B6,X                   ;$039D41    | Clear X speed.
    LDA.w $1540,X               ;$039D43    |\\ 
    BNE DinoFlameTimerSet       ;$039D46    ||| If done shooting fire, return to phase 0.
    STZ $C2,X                   ;$039D48    ||/
    LDA.b #$40                  ;$039D4A    ||
    STA.w $1540,X               ;$039D4C    ||
    LDA.b #$00                  ;$039D4F    ||
DinoFlameTimerSet:              ;           ||
    CMP.b #$C0                  ;$039D51    ||\ Branch if not time to play the fire sound.
    BNE CODE_039D5A             ;$039D53    ||/
    LDY.b #$17                  ;$039D55    ||\ SFX for the Dino Torch shooting fire.
    STY.w $1DFC                 ;$039D57    |//
CODE_039D5A:                    ;           |
    LSR                         ;$039D5A    |\ 
    LSR                         ;$039D5B    ||
    LSR                         ;$039D5C    ||
    LDY $C2,X                   ;$039D5D    ||
    CPY.b #$02                  ;$039D5F    ||
    BNE CODE_039D66             ;$039D61    ||
    CLC                         ;$039D63    || Get current frame of animation for the Dino Rhino.
    ADC.b #$20                  ;$039D64    ||
CODE_039D66:                    ;           ||
    TAY                         ;$039D66    ||
    LDA.w DinoFlameTable,Y      ;$039D67    ||
    PHA                         ;$039D6A    ||
    AND.b #$0F                  ;$039D6B    ||
    STA.w $1602,X               ;$039D6D    |/
    PLA                         ;$039D70    |\ 
    LSR                         ;$039D71    ||
    LSR                         ;$039D72    ||
    LSR                         ;$039D73    || Get height of the flame, and return if not at full length.
    LSR                         ;$039D74    ||
    STA.w $151C,X               ;$039D75    ||
    BNE Return039D9D            ;$039D78    |/
    LDA $9E,X                   ;$039D7A    |\ 
    CMP.b #$6E                  ;$039D7C    ||
    BEQ Return039D9D            ;$039D7E    ||
    TXA                         ;$039D80    ||
    EOR $13                     ;$039D81    || Return if:
    AND.b #$03                  ;$039D83    || - Sprite is not the Dino Torch.
    BNE Return039D9D            ;$039D85    || - Not a frame to process interaction with Mario.
    JSR DinoFlameClipping       ;$039D87    || - The flame is not in contact with Mario.
    JSL GetMarioClipping        ;$039D8A    || - Mario has invulnerability frames. 
    JSL CheckForContact         ;$039D8E    ||
    BCC Return039D9D            ;$039D92    ||
    LDA.w $1490                 ;$039D94    ||
    BNE Return039D9D            ;$039D97    |/
    JSL HurtMario               ;$039D99    | Hurt Mario.
Return039D9D:                   ;           |
    RTS                         ;$039D9D    |



DinoFlame1:                     ;$039D9E    |
    db $DC,$02,$10,$02

DinoFlame2:                     ;$039DA2    |
    db $FF,$00,$00,$00

DinoFlame3:                     ;$039DA6    |
    db $24,$0C,$24,$0C

DinoFlame4:                     ;$039DAA    |
    db $02,$DC,$02,$DC

DinoFlame5:                     ;$039DAE    |
    db $00,$FF,$00,$FF

DinoFlame6:                     ;$039DA2    |
    db $0C,$24,$0C,$24

DinoFlameClipping:              ;-----------| Subroutine to get clipping data for the Dino Torch's flame.
    LDA.w $1602,X               ;$039DB6    |\ 
    SEC                         ;$039DB9    ||
    SBC.b #$02                  ;$039DBA    ||
    TAY                         ;$039DBC    || Get index to the above tables for the flame.
    LDA.w $157C,X               ;$039DBD    ||
    BNE CODE_039DC4             ;$039DC0    ||
    INY                         ;$039DC2    ||
    INY                         ;$039DC3    |/
CODE_039DC4:                    ;           |
    LDA $E4,X                   ;$039DC4    |\ 
    CLC                         ;$039DC6    ||
    ADC.w DinoFlame1,Y          ;$039DC7    ||
    STA $04                     ;$039DCA    || Get clipping X position.
    LDA.w $14E0,X               ;$039DCC    ||
    ADC.w DinoFlame2,Y          ;$039DCF    ||
    STA $0A                     ;$039DD2    |/
    LDA.w DinoFlame3,Y          ;$039DD4    |\ Get clipping width.
    STA $06                     ;$039DD7    |/
    LDA $D8,X                   ;$039DD9    |\ 
    CLC                         ;$039DDB    ||
    ADC.w DinoFlame4,Y          ;$039DDC    ||
    STA $05                     ;$039DDF    || Get clipping Y position.
    LDA.w $14D4,X               ;$039DE1    ||
    ADC.w DinoFlame5,Y          ;$039DE4    ||
    STA $0B                     ;$039DE7    |/
    LDA.w DinoFlame6,Y          ;$039DE9    |\ Get clipping height.
    STA $07                     ;$039DEC    |/
    RTS                         ;$039DEE    |



DinoSetGfxFrame:                ;-----------| Subroutine to handle animating the Dino Rhino / Torch's walk cycle.
    INC.w $1570,X               ;$039DEF    |\ 
    LDA.w $1570,X               ;$039DF2    ||
    AND.b #$08                  ;$039DF5    ||
    LSR                         ;$039DF7    || Set animation frame (0/1).
    LSR                         ;$039DF8    ||
    LSR                         ;$039DF9    ||
    STA.w $1602,X               ;$039DFA    |/
    RTS                         ;$039DFD    |



DinoTorchTileDispX:             ;$039DFE    | X offsets for the Dino Torch and its flame. Fifth byte corresponds to the actual Dino.
    db $D8,$E0,$EC,$F8,$00                  ; Normal
    db $FF,$FF,$FF,$FF,$00                  ; Jumping

DinoTorchTileDispY:             ;$039E08    | Y offsets for the Dino Torch and its flame. Fifth byte corresponds to the actual Dino.
    db $00,$00,$00,$00,$00
    db $D8,$E0,$EC,$F8,$00

DinoFlameTiles:                 ;$039E12    | Tile numbers for the Dino Torch's flame. Fifth byte of each row unused.
    db $80,$82,$84,$86,$00
    db $88,$8A,$8C,$8E,$00

DinoTorchGfxProp:               ;$039E1C    | YXPPCCCT for the Dino Torch and its flame. Fifth byte corresponds to the actual Dino.
    db $09,$05,$05,$05,$0F

DinoTorchTiles:                 ;$039E21    | Tile numbers for the Dino Torch.
    db $EA,$AA,$C4,$C6

DinoRhinoTileDispX:             ;$039E25    | X offsets for the Dino Rhino.
    db $F8,$08,$F8,$08
    db $08,$F8,$08,$F8

DinoRhinoGfxProp:               ;$039E2D    | YXPPCCCT for the Dino Rhino.
    db $2F,$2F,$2F,$2F
    db $6F,$6F,$6F,$6F

DinoRhinoTileDispY:             ;$039E35    | Y offsets for the Dino Rhino.
    db $F0,$F0,$00,$00

DinoRhinoTiles:                 ;$039E39    | Tile numbers for the Dino Rhino.
    db $C0,$C2,$E4,$E6
    db $C0,$C2,$E0,$E2
    db $C8,$CA,$E8,$E2
    db $CC,$CE,$EC,$EE

DinoGfxRt:                      ;-----------| Dino Rhino/Torch GFX routine
    JSR GetDrawInfoBnk3         ;$039E49    |
    LDA.w $157C,X               ;$039E4C    |\ $02 = horizontal direction
    STA $02                     ;$039E4F    |/
    LDA.w $1602,X               ;$039E51    |\ $04 = animation frame
    STA $04                     ;$039E54    |/
    LDA $9E,X                   ;$039E56    |\ 
    CMP.b #$6F                  ;$039E58    || Branch for the Dino Torch.
    BEQ CODE_039EA9             ;$039E5A    |/
    PHX                         ;$039E5C    |
    LDX.b #$03                  ;$039E5D    |
CODE_039E5F:                    ;```````````| Dino Rhino tile loop.
    STX $0F                     ;$039E5F    |
    LDA $02                     ;$039E61    |\ 
    CMP.b #$01                  ;$039E63    ||
    BCS CODE_039E6C             ;$039E65    ||
    TXA                         ;$039E67    ||
    CLC                         ;$039E68    || Store YXPPCCCT to OAM.
    ADC.b #$04                  ;$039E69    ||
    TAX                         ;$039E6B    ||
CODE_039E6C:                    ;           ||
    LDA.w DinoRhinoGfxProp,X    ;$039E6C    ||
    STA.w $0303,Y               ;$039E6F    |/
    LDA.w DinoRhinoTileDispX,X  ;$039E72    |\ 
    CLC                         ;$039E75    || Store X position to OAM.
    ADC $00                     ;$039E76    ||
    STA.w $0300,Y               ;$039E78    |/
    LDA $04                     ;$039E7B    |\ 
    CMP.b #$01                  ;$039E7D    ||
    LDX $0F                     ;$039E7F    || Store Y position to OAM.
    LDA.w DinoRhinoTileDispY,X  ;$039E81    ||  Make the Dino Rhino shift up and down with the walk animation as well.
    ADC $01                     ;$039E84    ||
    STA.w $0301,Y               ;$039E86    |/
    LDA $04                     ;$039E89    |\ 
    ASL                         ;$039E8B    ||
    ASL                         ;$039E8C    ||
    ADC $0F                     ;$039E8D    || Store tile number to OAM.
    TAX                         ;$039E8F    ||
    LDA.w DinoRhinoTiles,X      ;$039E90    ||
    STA.w $0302,Y               ;$039E93    |/
    INY                         ;$039E96    |\ 
    INY                         ;$039E97    ||
    INY                         ;$039E98    ||
    INY                         ;$039E99    || Loop for all tiles.
    LDX $0F                     ;$039E9A    ||
    DEX                         ;$039E9C    ||
    BPL CODE_039E5F             ;$039E9D    |/
    PLX                         ;$039E9F    |
    LDA.b #$03                  ;$039EA0    |\ 
    LDY.b #$02                  ;$039EA2    || Upload 4 16x16 tiles.
    JSL FinishOAMWrite          ;$039EA4    |/
    RTS                         ;$039EA8    |


CODE_039EA9:                    ;```````````| Dino Torch GFX routine.
    LDA.w $151C,X               ;$039EA9    |\ $03 = length of the torch's flame (4 = none, 0 = max)
    STA $03                     ;$039EAC    |/
    LDA.w $1602,X               ;$039EAE    |\ $04 = animation frame (this was already set though, so useless).
    STA $04                     ;$039EB1    |/
    PHX                         ;$039EB3    |
    LDA $14                     ;$039EB4    |\ 
    AND.b #$02                  ;$039EB6    ||
    ASL                         ;$039EB8    ||
    ASL                         ;$039EB9    ||
    ASL                         ;$039EBA    ||
    ASL                         ;$039EBB    ||
    ASL                         ;$039EBC    || $05 = animation frame for the flame
    LDX $04                     ;$039EBD    ||
    CPX.b #$03                  ;$039EBF    ||
    BEQ CODE_039EC4             ;$039EC1    ||
    ASL                         ;$039EC3    ||
CODE_039EC4:                    ;           ||
    STA $05                     ;$039EC4    |/
    LDX.b #$04                  ;$039EC6    |
CODE_039EC8:                    ;```````````| Dino Torch tile loop
    STX $06                     ;$039EC8    |
    LDA $04                     ;$039ECA    |\ 
    CMP.b #$03                  ;$039ECC    ||
    BNE CODE_039ED5             ;$039ECE    ||
    TXA                         ;$039ED0    ||
    CLC                         ;$039ED1    ||
    ADC.b #$05                  ;$039ED2    ||
    TAX                         ;$039ED4    ||
CODE_039ED5:                    ;           ||
    PHX                         ;$039ED5    || Store X position to OAM.
    LDA.w DinoTorchTileDispX,X  ;$039ED6    ||  Invert offset if facing right.
    LDX $02                     ;$039ED9    ||
    BNE CODE_039EE0             ;$039EDB    ||
    EOR.b #$FF                  ;$039EDD    ||
    INC A                       ;$039EDF    ||
CODE_039EE0:                    ;           ||
    PLX                         ;$039EE0    ||
    CLC                         ;$039EE1    ||
    ADC $00                     ;$039EE2    ||
    STA.w $0300,Y               ;$039EE4    |/
    LDA.w DinoTorchTileDispY,X  ;$039EE7    |\ 
    CLC                         ;$039EEA    || Store Y position to OAM.
    ADC $01                     ;$039EEB    ||
    STA.w $0301,Y               ;$039EED    |/
    LDA $06                     ;$039EF0    |\ 
    CMP.b #$04                  ;$039EF2    ||
    BNE CODE_039EFD             ;$039EF4    ||
    LDX $04                     ;$039EF6    ||
    LDA.w DinoTorchTiles,X      ;$039EF8    || Store tile number to OAM.
    BRA CODE_039F00             ;$039EFB    ||
CODE_039EFD:                    ;           ||
    LDA.w DinoFlameTiles,X      ;$039EFD    ||
CODE_039F00:                    ;           ||
    STA.w $0302,Y               ;$039F00    |/
    LDA.b #$00                  ;$039F03    |\ 
    LDX $02                     ;$039F05    ||
    BNE CODE_039F0B             ;$039F07    ||
    ORA.b #$40                  ;$039F09    ||
CODE_039F0B:                    ;           ||
    LDX $06                     ;$039F0B    ||
    CPX.b #$04                  ;$039F0D    || Store YXPPCCCT to OAM.
    BEQ CODE_039F13             ;$039F0F    ||
    EOR $05                     ;$039F11    ||
CODE_039F13:                    ;           ||
    ORA.w DinoTorchGfxProp,X    ;$039F13    ||
    ORA $64                     ;$039F16    ||
    STA.w $0303,Y               ;$039F18    |/
    INY                         ;$039F1B    |\ 
    INY                         ;$039F1C    ||
    INY                         ;$039F1D    ||
    INY                         ;$039F1E    || Loop for all tiles.
    DEX                         ;$039F1F    ||
    CPX $03                     ;$039F20    ||
    BPL CODE_039EC8             ;$039F22    |/
    PLX                         ;$039F24    |
    LDY.w $151C,X               ;$039F25    |\ 
    LDA.w DinoTilesWritten,Y    ;$039F28    || Upload some number of 16x16 tiles.
    LDY.b #$02                  ;$039F2B    ||
    JSL FinishOAMWrite          ;$039F2D    |/
    RTS                         ;$039F31    |

DinoTilesWritten:               ;$039F32    | How many tiles (-1) to upload to OAM for the Dino Torch, indexed by the length its flame.
    db $04,$03,$02,$01,$00

    RTS                         ;$039F37    |





    ; Blargg misc RAM:
    ; $C2   - Sprite phase.
    ;          0 = Hiding under the lava, 1 = Eye rises out, 2 = Eye staring, 3 = Eye descending, 4 = Attacking
    ; $151C - Spawn X position (hi)
    ; $1528 - Spawn X position (lo)
    ; $1534 - Spawn Y position (hi)
    ; $1540 - Phase timer.
    ; $157C - Horizontal direction the sprite is facing.
    ; $1594 - Spawn Y position (lo)
    ; $1602 - Animation frame for the Blargg when fully emerged. 0 = mouth closed, 1 = mouth open

Blargg:                         ;-----------| Blargg MAIN
    JSR CODE_03A062             ;$039F38    | Draw GFX
    LDA $9D                     ;$039F3B    |\ Return if game frozen.
    BNE Return039F56            ;$039F3D    |/
    JSL MarioSprInteract        ;$039F3F    | Process interaction with Mario.
    JSR SubOffscreen0Bnk3       ;$039F43    | Process offscreen from -$40 to +$30.
    LDA $C2,X                   ;$039F46    |
    JSL ExecutePtr              ;$039F48    |

BlarggPtrs:                     ;$039F4C    | Blargg phase pointers.
    dw CODE_039F57              ; 0 - Hiding under the lava
    dw CODE_039F8B              ; 1 - Eye rises out
    dw CODE_039FA4              ; 2 - Eye staring
    dw CODE_039FC8              ; 3 - Eye descending
    dw CODE_039FEF              ; 4 - Attacking

Return039F56:
    RTS                         ;$039F56    |



CODE_039F57:                    ;-----------| Blargg phase 0 - Hiding under the lava.
    LDA.w $15A0,X               ;$039F57    |\ 
    ORA.w $1540,X               ;$039F5A    || Return if offscreen or not time to poke its eye out.
    BNE Return039F8A            ;$039F5D    |/
    JSR SubHorzPosBnk3          ;$039F5F    |\ 
    LDA $0F                     ;$039F62    ||
    CLC                         ;$039F64    || Return if Mario isn't within 7 tiles of the sprite.
    ADC.b #$70                  ;$039F65    ||
    CMP.b #$E0                  ;$039F67    ||
    BCS Return039F8A            ;$039F69    |/
    LDA.b #$E3                  ;$039F6B    |\\ Y speed to give the Blargg's eye when rising up.
    STA $AA,X                   ;$039F6D    |/
    LDA.w $14E0,X               ;$039F6F    |\ 
    STA.w $151C,X               ;$039F72    ||
    LDA $E4,X                   ;$039F75    ||
    STA.w $1528,X               ;$039F77    || Preserve the Blargg's spawn position.
    LDA.w $14D4,X               ;$039F7A    ||
    STA.w $1534,X               ;$039F7D    ||
    LDA $D8,X                   ;$039F80    ||
    STA.w $1594,X               ;$039F82    |/
    JSR CODE_039FC0             ;$039F85    | Turn to face Mario/
    INC $C2,X                   ;$039F88    | Increase phase pointer to phase 1.
Return039F8A:                   ;           |
    RTS                         ;$039F8A    |



CODE_039F8B:                    ;-----------| Blargg phase 1 - Eye rising up
    LDA $AA,X                   ;$039F8B    |\ 
    CMP.b #$10                  ;$039F8D    || Branch if not done rising up.
    BMI CODE_039F9B             ;$039F8F    |/
    LDA.b #$50                  ;$039F91    |\\ How long the Blargg stares out of the lava before ducking back down.
    STA.w $1540,X               ;$039F93    |/
    INC $C2,X                   ;$039F96    | Increase phase pointer to phase 2.
    STZ $AA,X                   ;$039F98    | Clear Y speed.
    RTS                         ;$039F9A    |

CODE_039F9B:                    ;```````````| Eye isn't done rising.
    JSL UpdateYPosNoGrvty       ;$039F9B    | Update Y position.
    INC $AA,X                   ;$039F9F    |\ Decrease Y speed.
    INC $AA,X                   ;$039FA1    |/
    RTS                         ;$039FA3    |



CODE_039FA4:                    ;-----------| Blargg phase 2 - Eye is staring
    LDA.w $1540,X               ;$039FA4    |\ Branch if not done staring.
    BNE CODE_039FB1             ;$039FA7    |/
    INC $C2,X                   ;$039FA9    | Increase phase pointer to phase 3.
    LDA.b #$0A                  ;$039FAB    |\\ How long the Blargg's eye spends lowering back into the lava.
    STA.w $1540,X               ;$039FAD    |/
    RTS                         ;$039FB0    |

CODE_039FB1:                    ;```````````| Not time to sink back down.
    CMP.b #$20                  ;$039FB1    |\ Once the timer starts going low enough, lock on to Mario. 
    BCC CODE_039FC0             ;$039FB3    |/
    AND.b #$1F                  ;$039FB5    |\ 
    BNE Return039FC7            ;$039FB7    ||
    LDA.w $157C,X               ;$039FB9    || Make the Blargg look from side to side.
    EOR.b #$01                  ;$039FBC    ||
    BRA CODE_039FC4             ;$039FBE    |/

CODE_039FC0:                    ;```````````| Turn the Blargg to face Mario.
    JSR SubHorzPosBnk3          ;$039FC0    |
    TYA                         ;$039FC3    |
CODE_039FC4:                    ;           |
    STA.w $157C,X               ;$039FC4    |
Return039FC7:                   ;           |
    RTS                         ;$039FC7    |



CODE_039FC8:                    ;-----------| Blargg phase 3 - Eye is descending back into the lava 
    LDA.w $1540,X               ;$039FC8    |\ Branch if time to attack.
    BEQ CODE_039FD6             ;$039FCB    |/
    LDA.b #$20                  ;$039FCD    |\\ Y speed the eye descends with.
    STA $AA,X                   ;$039FCF    |/
    JSL UpdateYPosNoGrvty       ;$039FD1    | Update Y position.
    RTS                         ;$039FD5    |

CODE_039FD6:                    ;```````````| Time to attack.
    LDA.b #$20                  ;$039FD6    |\\ How long the Blargg waits under the lava before actually attacking.
    STA.w $1540,X               ;$039FD8    |/
    LDY.w $157C,X               ;$039FDB    |\ 
    LDA.w DATA_039FED,Y         ;$039FDE    || Set attack X speed.
    STA $B6,X                   ;$039FE1    |/
    LDA.b #$E2                  ;$039FE3    |\\ Initial Y speed of the Blargg's attack.
    STA $AA,X                   ;$039FE5    |/
    JSR CODE_03A045             ;$039FE7    | Create a lava splash.
    INC $C2,X                   ;$039FEA    | Increment phase pointer to phase 4.
    RTS                         ;$039FEC    |



DATA_039FED:                    ;           |
    db $10,$F0

CODE_039FEF:                    ;-----------| Blargg phase 4 - Attacking
    STZ.w $1602,X               ;$039FEF    |
    LDA.w $1540,X               ;$039FF2    |\ Branch if already attacking.
    BEQ CODE_03A002             ;$039FF5    |/
    DEC A                       ;$039FF7    |\ Skip down and return if not time to attack yet (i.e. waiting under the lava)
    BNE CODE_03A038             ;$039FF8    |/
    LDA.b #$25                  ;$039FFA    |\ SFX for the Blargg attacking.
    STA.w $1DF9                 ;$039FFC    |/
    JSR CODE_03A045             ;$039FFF    | Create a lava splash.
CODE_03A002:                    ;           |
    JSL UpdateXPosNoGrvty       ;$03A002    | Update X position.
    JSL UpdateYPosNoGrvty       ;$03A006    | Update Y position.
    LDA $13                     ;$03A00A    |\ 
    AND.b #$00                  ;$03A00C    || Apply gravity.
    BNE CODE_03A012             ;$03A00E    ||
    INC $AA,X                   ;$03A010    |/
CODE_03A012:                    ;           |
    LDA $AA,X                   ;$03A012    |\ 
    CMP.b #$20                  ;$03A014    || Branch if not done attacking.
    BMI CODE_03A038             ;$03A016    |/
    JSR CODE_03A045             ;$03A018    | Creating yet another lava splash.
    STZ $C2,X                   ;$03A01B    | Return phase pointer to phase 0.
    LDA.w $151C,X               ;$03A01D    |\ 
    STA.w $14E0,X               ;$03A020    ||
    LDA.w $1528,X               ;$03A023    ||
    STA $E4,X                   ;$03A026    || Restore original spawn position.
    LDA.w $1534,X               ;$03A028    ||
    STA.w $14D4,X               ;$03A02B    ||
    LDA.w $1594,X               ;$03A02E    ||
    STA $D8,X                   ;$03A031    |/
    LDA.b #$40                  ;$03A033    |\\ How long the Blargg waits under the lava after attacking before poking its eye out again.
    STA.w $1540,X               ;$03A035    |/
CODE_03A038:                    ;           |
    LDA $AA,X                   ;$03A038    |\ 
    CLC                         ;$03A03A    ||
    ADC.b #$06                  ;$03A03B    || Handle the animation of the Blargg's mouth, based on how far into the jump it is.
    CMP.b #$0C                  ;$03A03D    ||
    BCS Return03A044            ;$03A03F    ||
    INC.w $1602,X               ;$03A041    |/
Return03A044:                   ;           |
    RTS                         ;$03A044    |



CODE_03A045:                    ;-----------| Subroutine to spawn a lava splash for the Blargg.
    LDA $D8,X                   ;$03A045    |\ 
    PHA                         ;$03A047    ||
    SEC                         ;$03A048    ||
    SBC.b #$0C                  ;$03A049    ||
    STA $D8,X                   ;$03A04B    || Offset Y position to display the splash at.
    LDA.w $14D4,X               ;$03A04D    ||
    PHA                         ;$03A050    ||
    SBC.b #$00                  ;$03A051    ||
    STA.w $14D4,X               ;$03A053    |/
    JSL CODE_028528             ;$03A056    | Create a lava splash.
    PLA                         ;$03A05A    |\ 
    STA.w $14D4,X               ;$03A05B    || Restore Y position.
    PLA                         ;$03A05E    ||
    STA $D8,X                   ;$03A05F    |/
    RTS                         ;$03A061    |



CODE_03A062:                    ;-----------| Blargg GFX routine
    JSR GetDrawInfoBnk3         ;$03A062    |
    LDA $C2,X                   ;$03A065    |\ Branch if the Blargg is currently hidden under the lava and shouldn't be drawn.
    BEQ CODE_03A038             ;$03A067    |/
    CMP.b #$04                  ;$03A069    |\ Branch ot the second GFX routine if the full body needs to be drawn. 
    BEQ CODE_03A09D             ;$03A06B    |/  Else, the code below draws just his eyes.
    JSL GenericSprGfxRt2        ;$03A06D    | Draw a 16x16 sprite.
    LDY.w $15EA,X               ;$03A071    |
    LDA.b #$A0                  ;$03A074    |\\ Tile to use for the Blargg's eye.
    STA.w $0302,Y               ;$03A076    |/
    LDA.w $0303,Y               ;$03A079    |\ 
    AND.b #$CF                  ;$03A07C    || Change YXPPCCCT in OAM.
    STA.w $0303,Y               ;$03A07E    |/
    RTS                         ;$03A081    |



DATA_03A082:                    ;$03A082    | X offsets for each tile of the Blargg, indexed by his direction.
    db $F8,$08,$F8,$08,$18                  ; Left
    db $08,$F8,$08,$F8,$E8                  ; Right

DATA_03A08C:                    ;$03A08C    | Y offsets for each tile of the Blargg.
    db $F8,$F8,$08,$08,$08

BlarggTilemap:                  ;$03A091    | Tile numbers for each tile of the Blargg.
    db $A2,$A4,$C2,$C4,$A6
    db $A2,$A4,$E6,$C8,$A6

DATA_03A09B:                    ;$03A09B    | YXPPCCCT for the Blargg, indexed by his direction.
    db $45,$05

CODE_03A09D:                    ;-----------| Blargg GFX routine 2 (when fully emerged)
    LDA.w $1602,X               ;$03A09D    |\ 
    ASL                         ;$03A0A0    ||
    ASL                         ;$03A0A1    || $03 = Animation frame, x5
    ADC.w $1602,X               ;$03A0A2    ||
    STA $03                     ;$03A0A5    |/
    LDA.w $157C,X               ;$03A0A7    |\ $02 = Horizontal direction
    STA $02                     ;$03A0AA    |/
    PHX                         ;$03A0AC    |
    LDX.b #$04                  ;$03A0AD    |
CODE_03A0AF:                    ;           |
    PHX                         ;$03A0AF    |
    PHX                         ;$03A0B0    |
    LDA $01                     ;$03A0B1    |\ 
    CLC                         ;$03A0B3    || Store Y position to OAM.
    ADC.w DATA_03A08C,X         ;$03A0B4    ||
    STA.w $0301,Y               ;$03A0B7    |/
    LDA $02                     ;$03A0BA    |\ 
    BNE CODE_03A0C3             ;$03A0BC    ||
    TXA                         ;$03A0BE    ||
    CLC                         ;$03A0BF    ||
    ADC.b #$05                  ;$03A0C0    ||
    TAX                         ;$03A0C2    || Store X position to OAM.
CODE_03A0C3:                    ;           ||
    LDA $00                     ;$03A0C3    ||
    CLC                         ;$03A0C5    ||
    ADC.w DATA_03A082,X         ;$03A0C6    ||
    STA.w $0300,Y               ;$03A0C9    |/
    PLA                         ;$03A0CC    |\ 
    CLC                         ;$03A0CD    ||
    ADC $03                     ;$03A0CE    || Store tile number to OAM.
    TAX                         ;$03A0D0    ||
    LDA.w BlarggTilemap,X       ;$03A0D1    ||
    STA.w $0302,Y               ;$03A0D4    |/
    LDX $02                     ;$03A0D7    |\ 
    LDA.w DATA_03A09B,X         ;$03A0D9    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03A0DC    |/
    PLX                         ;$03A0DF    |\ 
    INY                         ;$03A0E0    ||
    INY                         ;$03A0E1    ||
    INY                         ;$03A0E2    || Loop for all of the tiles.
    INY                         ;$03A0E3    ||
    DEX                         ;$03A0E4    ||
    BPL CODE_03A0AF             ;$03A0E5    |/
    PLX                         ;$03A0E7    |
    LDY.b #$02                  ;$03A0E8    |\ 
    LDA.b #$04                  ;$03A0EA    || Upload 5 16x16s.
    JSL FinishOAMWrite          ;$03A0EC    |/
    RTS                         ;$03A0F0    |





CODE_03A0F1:                    ;-----------| Bowser INIT
    JSL InitSpriteTables        ;$03A0F1    |
    STZ.w $15A0,X               ;$03A0F5    |
    LDA.b #$80                  ;$03A0F8    |\ 
    STA $D8,X                   ;$03A0FA    ||
    LDA.b #$FF                  ;$03A0FC    ||
    STA.w $14D4,X               ;$03A0FE    || Set initial position at 00D0,FF80.
    LDA.b #$D0                  ;$03A101    ||
    STA $E4,X                   ;$03A103    ||
    LDA.b #$00                  ;$03A105    ||
    STA.w $14E0,X               ;$03A107    |/
    LDA.b #$02                  ;$03A10A    |\\ Number of hits needed to defeat the first phase of Bowser.
    STA.w $187B,X               ;$03A10C    |/
    LDA.b #$03                  ;$03A10F    |\ Store Mode 7 index.
    STA $C2,X                   ;$03A111    |/
    JSL CODE_03DD7D             ;$03A113    | Load palette/GFX files.
    RTL                         ;$03A117    |





Bnk3CallSprMain:                ;-----------| Routine to find code for sprites which couldn't fit in bank 1/2.
    PHB                         ;$03A118    |
    PHK                         ;$03A119    |
    PLB                         ;$03A11A    |
    LDA $9E,X                   ;$03A11B    |\ 
    CMP.b #$C8                  ;$03A11D    || Light switch redirect
    BNE CODE_03A126             ;$03A11F    ||
    JSR LightSwitch             ;$03A121    |/
    PLB                         ;$03A124    |
    RTL                         ;$03A125    |

CODE_03A126:                    ;```````````| Invisible mushroom redirect
    CMP.b #$C7                  ;$03A126    |
    BNE CODE_03A12F             ;$03A128    |
    JSR InvisMushroom           ;$03A12A    |
    PLB                         ;$03A12D    |
    RTL                         ;$03A12E    |

CODE_03A12F:                    ;```````````| Ninji redirect
    CMP.b #$51                  ;$03A12F    |
    BNE CODE_03A138             ;$03A131    |
    JSR Ninji                   ;$03A133    |
    PLB                         ;$03A136    |
    RTL                         ;$03A137    |

CODE_03A138:                    ;```````````| Football redirect
    CMP.b #$1B                  ;$03A138    |
    BNE CODE_03A141             ;$03A13A    |
    JSR Football                ;$03A13C    |
    PLB                         ;$03A13F    |
    RTL                         ;$03A140    |

CODE_03A141:                    ;```````````| Spotlight redirect
    CMP.b #$C6                  ;$03A141    |
    BNE CODE_03A14A             ;$03A143    |
    JSR DarkRoomWithLight       ;$03A145    |
    PLB                         ;$03A148    |
    RTL                         ;$03A149    |

CODE_03A14A:                    ;```````````| Fireball redirect
    CMP.b #$7A                  ;$03A14A    |
    BNE CODE_03A153             ;$03A14C    |
    JSR FireworkMain            ;$03A14E    |
    PLB                         ;$03A151    |
    RTL                         ;$03A152    |

CODE_03A153:                    ;```````````| Peach redirect
    CMP.b #$7C                  ;$03A153    |
    BNE CODE_03A15C             ;$03A155    |
    JSR PrincessPeach           ;$03A157    |
    PLB                         ;$03A15A    |
    RTL                         ;$03A15B    |

CODE_03A15C:                    ;```````````| Big Boo Boss redirect
    CMP.b #$C5                  ;$03A15C    |
    BNE CODE_03A165             ;$03A15E    |
    JSR BigBooBoss              ;$03A160    |
    PLB                         ;$03A163    |
    RTL                         ;$03A164    |

CODE_03A165:                    ;```````````| Grey falling platform redirect
    CMP.b #$C4                  ;$03A165    |
    BNE CODE_03A16E             ;$03A167    |
    JSR GreyFallingPlat         ;$03A169    |
    PLB                         ;$03A16C    |
    RTL                         ;$03A16D    |

CODE_03A16E:                    ;```````````| Blurp redirect
    CMP.b #$C2                  ;$03A16E    |
    BNE CODE_03A177             ;$03A170    |
    JSR Blurp                   ;$03A172    |
    PLB                         ;$03A175    |
    RTL                         ;$03A176    |

CODE_03A177:                    ;```````````| Porcupuffer redirect
    CMP.b #$C3                  ;$03A177    |
    BNE CODE_03A180             ;$03A179    |
    JSR PorcuPuffer             ;$03A17B    |
    PLB                         ;$03A17E    |
    RTL                         ;$03A17F    |

CODE_03A180:                    ;```````````| Flying turnblocks redirect
    CMP.b #$C1                  ;$03A180    |
    BNE CODE_03A189             ;$03A182    |
    JSR FlyingTurnBlocks        ;$03A184    |
    PLB                         ;$03A187    |
    RTL                         ;$03A188    |

CODE_03A189:                    ;```````````| Grey lava platform redirect
    CMP.b #$C0                  ;$03A189    |
    BNE CODE_03A192             ;$03A18B    |
    JSR GrayLavaPlatform        ;$03A18D    |
    PLB                         ;$03A190    |
    RTL                         ;$03A191    |

CODE_03A192:                    ;```````````| Mega Mole redirect
    CMP.b #$BF                  ;$03A192    |
    BNE CODE_03A19B             ;$03A194    |
    JSR MegaMole                ;$03A196    |
    PLB                         ;$03A199    |
    RTL                         ;$03A19A    |

CODE_03A19B:                    ;```````````| Swooper redirect
    CMP.b #$BE                  ;$03A19B    |
    BNE CODE_03A1A4             ;$03A19D    |
    JSR Swooper                 ;$03A19F    |
    PLB                         ;$03A1A2    |
    RTL                         ;$03A1A3    |

CODE_03A1A4:                    ;```````````| Sliding Koopa redirect
    CMP.b #$BD                  ;$03A1A4    |
    BNE CODE_03A1AD             ;$03A1A6    |
    JSR SlidingKoopa            ;$03A1A8    |
    PLB                         ;$03A1AB    |
    RTL                         ;$03A1AC    |

CODE_03A1AD:                    ;```````````| Bowser Statue redirect
    CMP.b #$BC                  ;$03A1AD    |
    BNE CODE_03A1B6             ;$03A1AF    |
    JSR BowserStatue            ;$03A1B1    |
    PLB                         ;$03A1B4    |
    RTL                         ;$03A1B5    |

CODE_03A1B6:                    ;```````````| Carrot Top Lift redirect
    CMP.b #$B8                  ;$03A1B6    |
    BEQ CODE_03A1BE             ;$03A1B8    |
    CMP.b #$B7                  ;$03A1BA    |
    BNE CODE_03A1C3             ;$03A1BC    |
CODE_03A1BE:                    ;           |
    JSR CarrotTopLift           ;$03A1BE    |
    PLB                         ;$03A1C1    |
    RTL                         ;$03A1C2    |

CODE_03A1C3:                    ;```````````| Message Box redirect
    CMP.b #$B9                  ;$03A1C3    |
    BNE CODE_03A1CC             ;$03A1C5    |
    JSR InfoBox                 ;$03A1C7    |
    PLB                         ;$03A1CA    |
    RTL                         ;$03A1CB    |

CODE_03A1CC:                    ;```````````| Timed Lift redirect
    CMP.b #$BA                  ;$03A1CC    |
    BNE CODE_03A1D5             ;$03A1CE    |
    JSR TimedLift               ;$03A1D0    |
    PLB                         ;$03A1D3    |
    RTL                         ;$03A1D4    |

CODE_03A1D5:                    ;```````````| Grey Castle Block redirect
    CMP.b #$BB                  ;$03A1D5    |
    BNE CODE_03A1DE             ;$03A1D7    |
    JSR GreyCastleBlock         ;$03A1D9    |
    PLB                         ;$03A1DC    |
    RTL                         ;$03A1DD    |

CODE_03A1DE:                    ;```````````| Bowser Statue Fireball redirect
    CMP.b #$B3                  ;$03A1DE    |
    BNE CODE_03A1E7             ;$03A1E0    |
    JSR StatueFireball          ;$03A1E2    |
    PLB                         ;$03A1E5    |
    RTL                         ;$03A1E6    |

CODE_03A1E7:                    ;```````````| Falling Spike redirect
    LDA $9E,X                   ;$03A1E7    |
    CMP.b #$B2                  ;$03A1E9    |
    BNE CODE_03A1F2             ;$03A1EB    |
    JSR FallingSpike            ;$03A1ED    |
    PLB                         ;$03A1F0    |
    RTL                         ;$03A1F1    |

CODE_03A1F2:                    ;```````````| Fishin' Boo redirect
    CMP.b #$AE                  ;$03A1F2    |
    BNE CODE_03A1FB             ;$03A1F4    |
    JSR FishinBoo               ;$03A1F6    |
    PLB                         ;$03A1F9    |
    RTL                         ;$03A1FA    |

CODE_03A1FB:                    ;```````````| Reflecting Fireball redirect
    CMP.b #$B6                  ;$03A1FB    |
    BNE CODE_03A204             ;$03A1FD    |
    JSR ReflectingFireball      ;$03A1FF    |
    PLB                         ;$03A202    |
    RTL                         ;$03A203    |

CODE_03A204:                    ;```````````| Boo Stream redirect
    CMP.b #$B0                  ;$03A204    |
    BNE CODE_03A20D             ;$03A206    |
    JSR BooStream               ;$03A208    |
    PLB                         ;$03A20B    |
    RTL                         ;$03A20C    |

CODE_03A20D:                    ;```````````| Creating/Eating Block redirect
    CMP.b #$B1                  ;$03A20D    |
    BNE CODE_03A216             ;$03A20F    |
    JSR CreateEatBlock          ;$03A211    |
    PLB                         ;$03A214    |
    RTL                         ;$03A215    |

CODE_03A216:                    ;```````````| Wooden Spike redirect
    CMP.b #$AC                  ;$03A216    |
    BEQ CODE_03A21E             ;$03A218    |
    CMP.b #$AD                  ;$03A21A    |
    BNE CODE_03A223             ;$03A21C    |
CODE_03A21E:                    ;           |
    JSR WoodenSpike             ;$03A21E    |
    PLB                         ;$03A221    |
    RTL                         ;$03A222    |

CODE_03A223:                    ;```````````| Rex redirect
    CMP.b #$AB                  ;$03A223    |
    BNE CODE_03A22C             ;$03A225    |
    JSR RexMainRt               ;$03A227    |
    PLB                         ;$03A22A    |
    RTL                         ;$03A22B    |

CODE_03A22C:                    ;```````````| Fishbone redirect
    CMP.b #$AA                  ;$03A22C    |
    BNE CODE_03A235             ;$03A22E    |
    JSR Fishbone                ;$03A230    |
    PLB                         ;$03A233    |
    RTL                         ;$03A234    |

CODE_03A235:                    ;```````````| Reznor redirect
    CMP.b #$A9                  ;$03A235    |
    BNE CODE_03A23E             ;$03A237    |
    JSR Reznor                  ;$03A239    |
    PLB                         ;$03A23C    |
    RTL                         ;$03A23D    |

CODE_03A23E:                    ;```````````| Blargg redirect
    CMP.b #$A8                  ;$03A23E    |
    BNE CODE_03A247             ;$03A240    |
    JSR Blargg                  ;$03A242    |
    PLB                         ;$03A245    |
    RTL                         ;$03A246    |

CODE_03A247:                    ;```````````| Bowser's Bowling Ball redirect
    CMP.b #$A1                  ;$03A247    |
    BNE CODE_03A250             ;$03A249    |
    JSR BowserBowlingBall       ;$03A24B    |
    PLB                         ;$03A24E    |
    RTL                         ;$03A24F    |

CODE_03A250:                    ;```````````| MechaKoopa redirect
    CMP.b #$A2                  ;$03A250    |
    BNE BowserFight             ;$03A252    |
    JSR MechaKoopa              ;$03A254    |
    PLB                         ;$03A257    |
    RTL                         ;$03A258    |





    ; Bowser misc RAM:
    ; $C2   - Set to #$03 on spawn, to indicate which Mode 7 room needs to be loaded.
    ; $151C - Sprite phase.
    ;          0 = descending at start, 1 = swooping out, 2 = swooping in / peach, 3 = bowser flames
    ;          4 = rising up after death, 5 = death clouds / flipping upside down, 6 = dropping peach and flying away
    ;          7 = attack phase 1, 8 = attack phase 2, 3 = attack phase 3
    ; $1528 - Direction of horizontal acceleration in attack phase 1 (0 = left, 1 = right).
    ;          Also used when swooping out of the screen for the same purpose, with 0 = right, 1 = left, 2 = none.
    ; $1534 - Direction of vertical acceleration in attack phase 1 (0 = down, 1 = up).
    ;          Also used when swooping out of the screen for the same purpose, with 0 = up, 1 = down, 2 = none.
    ; $1540 - Timer for Bowser's ducking animations at the beginning/end of each phase.
    ;           Also used for waiting to turn upside-down after defeat, and for waiting to fly away after dropping Peach.
    ; $154C - Timer to disable contact with Mario.
    ;          Also used as a timer just before attack phase 1 for briefly pausing Bowser.
    ;          Furthermore used as a timer after Bowser rotates upside down after his defeat to wait before spawning Peach.
    ; $1558 - Timer for the clown car's blinking animation.
    ; $1564 - Timer for the cloud puffs after defeat.
    ; $1570 - Animation frame for Bowser.
    ;          0 = Normal, 2/4/6/8/A = ducking into car/blinking, C = hit, E = inside car, 10/12 = hurt
    ; $157C - Facing direction. 00 = left, 80 = right. Other values will mess up graphics.
    ; $1594 - Timer for Peach's "Help!" animation.
    ; $187B - HP for the current phase.

BowserFight:                    ;-----------| Bowser MAIN
    JSL CODE_03DFCC             ;$03A259    | Set up palette.
    JSR CODE_03A279             ;$03A25D    | Run primary code.
    JSR CODE_03B43C             ;$03A260    | Draw the room and item box.
    PLB                         ;$03A263    |
    RTL                         ;$03A264    |



DATA_03A265:                    ;$03A265    | Palette indices for Bowser's fade in/out animations.
    db $04,$03,$02,$01,$00,$01,$02,$03
    db $04,$05,$06,$07,$07,$07,$07,$07
    db $07,$07,$07,$07

CODE_03A279:                    ;-----------| Primary Bowser code.
    LDA $38                     ;$03A279    |\ 
    LSR                         ;$03A27B    ||
    LSR                         ;$03A27C    ||
    LSR                         ;$03A27D    || Set Bowser's current palette based on his "size".
    TAY                         ;$03A27E    ||
    LDA.w DATA_03A265,Y         ;$03A27F    ||
    STA.w $1429                 ;$03A282    |/
    LDA.w $1570,X               ;$03A285    |\ 
    CLC                         ;$03A288    ||
    ADC.b #$1E                  ;$03A289    || Set animation frame for Bowser. Bit 7 controls X flip.
    ORA.w $157C,X               ;$03A28B    ||
    STA.w $1BA2                 ;$03A28E    |/
    LDA $14                     ;$03A291    |\ 
    LSR                         ;$03A293    || Set animation frame for the propellor.
    AND.b #$03                  ;$03A294    ||
    STA.w $1428                 ;$03A296    |/
    LDA.b #$90                  ;$03A299    |\ 
    STA $2A                     ;$03A29B    || Set centers of rotation/scale for Mode 7.
    LDA.b #$C8                  ;$03A29D    ||
    STA $2C                     ;$03A29F    |/
    JSL CODE_03DEDF             ;$03A2A1    | Handle the Mode 7 tilemap.
    LDA.w $14B5                 ;$03A2A5    |\ 
    BEQ CODE_03A2AD             ;$03A2A8    || If Bowser has been hurt, draw the stars and teardrop above his head
    JSR CODE_03AF59             ;$03A2AA    |/
CODE_03A2AD:                    ;           |
    LDA.w $1564,X               ;$03A2AD    |\ 
    BEQ CODE_03A2B5             ;$03A2B0    || If Bowser has been defeated, handle the cloud puffs from his car and draw them.
    JSR CODE_03A3E2             ;$03A2B2    |/
CODE_03A2B5:                    ;           |
    LDA.w $1594,X               ;$03A2B5    |\ 
    BEQ CODE_03A2CE             ;$03A2B8    ||
    DEC A                       ;$03A2BA    || 
    LSR                         ;$03A2BB    ||
    LSR                         ;$03A2BC    ||
    PHA                         ;$03A2BD    ||
    LSR                         ;$03A2BE    || If Peach is being shown, handle her "Help!" animation and draw her.
    TAY                         ;$03A2BF    ||
    LDA.w DATA_03A8BE,Y         ;$03A2C0    ||
    STA $02                     ;$03A2C3    ||
    PLA                         ;$03A2C5    ||
    AND.b #$03                  ;$03A2C6    ||
    STA $03                     ;$03A2C8    ||
    JSR CODE_03AA6E             ;$03A2CA    |/
    NOP                         ;$03A2CD    |
CODE_03A2CE:                    ;           |
    LDA $9D                     ;$03A2CE    |\ Return if the game frozen.
    BNE Return03A340            ;$03A2D0    |/
    STZ.w $1594,X               ;$03A2D2    |
    LDA.b #$30                  ;$03A2D5    |\ 
    STA $64                     ;$03A2D7    ||
    LDA $38                     ;$03A2D9    || Set Bowser to be drawn behind Mario.
    CMP.b #$20                  ;$03A2DB    ||  If Bowser is moving "towards" the screen, send Mario behind him instead.
    BCS CODE_03A2E1             ;$03A2DD    ||
    STZ $64                     ;$03A2DF    |/
CODE_03A2E1:                    ;           |
    JSR CODE_03A661             ;$03A2E1    | Handle Bowser's hurt animation, and end the fight if it was the last hit.
    LDA.w $14B0                 ;$03A2E4    |\ 
    BEQ CODE_03A2F2             ;$03A2E7    ||
    LDA $13                     ;$03A2E9    || Handle the timer for Bowser's attacks.
    AND.b #$03                  ;$03A2EB    ||
    BNE CODE_03A2F2             ;$03A2ED    ||
    DEC.w $14B0                 ;$03A2EF    |/
CODE_03A2F2:                    ;           |
    LDA $13                     ;$03A2F2    |\ 
    AND.b #$7F                  ;$03A2F4    ||
    BNE CODE_03A305             ;$03A2F6    ||
    JSL GetRand                 ;$03A2F8    || Every 128 frames, randomly descide whether to make the clown car blink.
    AND.b #$01                  ;$03A2FC    ||
    BNE CODE_03A305             ;$03A2FE    ||
    LDA.b #$0C                  ;$03A300    ||\ How long the clown car's blinking animation lasts.
    STA.w $1558,X               ;$03A302    |//
CODE_03A305:                    ;           |
    JSR CODE_03B078             ;$03A305    | Process interaction with Mario and the MechaKoopas.
    LDA.w $151C,X               ;$03A308    |\ 
    CMP.b #$09                  ;$03A30B    ||
    BEQ CODE_03A31A             ;$03A30D    ||
    STZ.w $1427                 ;$03A30F    || If not in phase 9, animate the blinking animation for Bowser's clown car.
    LDA.w $1558,X               ;$03A312    ||
    BEQ CODE_03A31A             ;$03A315    ||
    INC.w $1427                 ;$03A317    |/
CODE_03A31A:                    ;           |
    JSR CODE_03A5AD             ;$03A31A    | Handle attacking.
    JSL UpdateXPosNoGrvty       ;$03A31D    | Update X position.
    JSL UpdateYPosNoGrvty       ;$03A321    | Update Y position.
    LDA.w $151C,X               ;$03A325    |
    JSL ExecutePtr              ;$03A328    |

BowserFightPtrs:                ;$03A32C    | Bowser phase pointers.
    dw CODE_03A441                          ; 0 - Descending at the start
    dw CODE_03A6F8                          ; 1 - Swooping out of the screen
    dw CODE_03A84B                          ; 2 - Swooping into the screen / Peach
    dw CODE_03A7AD                          ; 3 - Bowser flames dropping
    dw CODE_03AB9F                          ; 4 - Rising up after being killed
    dw CODE_03ABBE                          ; 5 - Death (cloud puffs, rotation)
    dw CODE_03AC03                          ; 6 - Dropping Peach and spinning away
    dw CODE_03A49C                          ; 7 - Phase 1
    dw CODE_03AB21                          ; 8 - Phase 2
    dw CODE_03AB64                          ; 9 - Phase 3

Return03A340:
    RTS                         ;$03A340    |



DATA_03A341:                    ;$03A341    | X offsets for each tile of the cloud puffs in Bowser's death animation. 8 tiles per frame.
    db $D5,$DD,$23,$2B,$D5,$DD,$23,$2B
    db $D5,$DD,$23,$2B,$D5,$DD,$23,$2B
    db $D6,$DE,$22,$2A,$D6,$DE,$22,$2A
    db $D7,$DF,$21,$29,$D7,$DF,$21,$29
    db $D8,$E0,$20,$28,$D8,$E0,$20,$28
    db $DA,$E2,$1E,$26,$DA,$E2,$1E,$26
    db $DC,$E4,$1C,$24,$DC,$E4,$1C,$24
    db $E0,$E8,$18,$20,$E0,$E8,$18,$20
    db $E8,$F0,$10,$18,$E8,$F0,$10,$18

DATA_03A389:                    ;$03A389    | Y offsets for each tile of the cloud puffs in Bowser's death animation. 8 tiles per frame.
    db $DD,$D5,$D5,$DD,$23,$2B,$2B,$23
    db $DD,$D5,$D5,$DD,$23,$2B,$2B,$23
    db $DE,$D6,$D6,$DE,$22,$2A,$2A,$22
    db $DF,$D7,$D7,$DF,$21,$29,$29,$21
    db $E0,$D8,$D8,$E0,$20,$28,$28,$20
    db $E2,$DA,$DA,$E2,$1E,$26,$26,$1E
    db $E4,$DC,$DC,$E4,$1C,$24,$24,$1C
    db $E8,$E0,$E0,$E8,$18,$20,$20,$18
    db $F0,$E8,$E8,$F0,$10,$18,$18,$10

DATA_03A3D1:                    ;$03A3D1    | YXPPCCCT for each of the cloud puffs spawned by Bowser when defeated.
    db $80,$40,$00,$C0,$00,$C0,$80,$40

DATA_03A3D9:                    ;$03A3D9    | Tile numbers for each frame of animation for the clouds from Bowser's Clown Car.
    db $E3,$ED,$ED,$EB,$EB,$E9,$E9,$E7,$E7

CODE_03A3E2:                    ;-----------| Subroutine to draw the cloud puffs when Bowser is defeated.
    JSR GetDrawInfoBnk3         ;$03A3E2    |
    LDA.w $1564,X               ;$03A3E5    |\ 
    DEC A                       ;$03A3E8    || $03 = animation frame of the puff
    LSR                         ;$03A3E9    ||
    STA $03                     ;$03A3EA    |/
    ASL                         ;$03A3EC    |\ 
    ASL                         ;$03A3ED    || $02 = animation frame, x8
    ASL                         ;$03A3EE    ||
    STA $02                     ;$03A3EF    |/
    LDA.b #$70                  ;$03A3F1    |\\ OAM index (from $0300) for Bowser's death clouds.
    STA.w $15EA,X               ;$03A3F3    |/
    TAY                         ;$03A3F6    |
    PHX                         ;$03A3F7    |
    LDX.b #$07                  ;$03A3F8    |
CODE_03A3FA:                    ;```````````| Cloud puffs tile loop.
    PHX                         ;$03A3FA    |
    TXA                         ;$03A3FB    |\ 
    ORA $02                     ;$03A3FC    ||
    TAX                         ;$03A3FE    ||
    LDA $00                     ;$03A3FF    ||
    CLC                         ;$03A401    || Store X position to OAM.
    ADC.w DATA_03A341,X         ;$03A402    ||
    CLC                         ;$03A405    ||
    ADC.b #$08                  ;$03A406    ||
    STA.w $0300,Y               ;$03A408    |/
    LDA $01                     ;$03A40B    |\ 
    CLC                         ;$03A40D    ||
    ADC.w DATA_03A389,X         ;$03A40E    || Store Y position to OAM.
    CLC                         ;$03A411    ||
    ADC.b #$30                  ;$03A412    ||
    STA.w $0301,Y               ;$03A414    |/
    LDX $03                     ;$03A417    |\ 
    LDA.w DATA_03A3D9,X         ;$03A419    || Store tile number to OAM.
    STA.w $0302,Y               ;$03A41C    |/
    PLX                         ;$03A41F    |\ 
    LDA.w DATA_03A3D1,X         ;$03A420    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03A423    |/
    INY                         ;$03A426    |\ 
    INY                         ;$03A427    ||
    INY                         ;$03A428    || Loop for all of the puffs.
    INY                         ;$03A429    ||
    DEX                         ;$03A42A    ||
    BPL CODE_03A3FA             ;$03A42B    |/
    PLX                         ;$03A42D    |
    LDY.b #$02                  ;$03A42E    |\ 
    LDA.b #$07                  ;$03A430    || Upload 8 manually-sized tiles.
    JSL FinishOAMWrite          ;$03A432    |/
    RTS                         ;$03A436    |



DATA_03A437:                    ;$03A437    | Animation frames for the animation of Bowser emerging from his clown car at the start of a phase.
    db $00,$00,$00,$00,$02,$04,$06,$08,$0A,$0E

CODE_03A441:                    ;-----------| Bowser phase 0 - Descending at the start
    LDA.w $154C,X               ;$03A441    |\ Branch if fully descended, Bowser has emerged, and waiting to start attack phase 1.
    BNE CODE_03A482             ;$03A444    |/
    LDA.w $1540,X               ;$03A446    |\ Branch if fully descended and waiting for Bowser to emerge.
    BNE CODE_03A465             ;$03A449    |/
    LDA.b #$0E                  ;$03A44B    |\\ Animation frame for Bowser when he's descending at the start of the battle.
    STA.w $1570,X               ;$03A44D    |/
    LDA.b #$04                  ;$03A450    |\\ Y speed of Bowser as he descends at the start of the battle.
    STA $AA,X                   ;$03A452    |/
    STZ $B6,X                   ;$03A454    | Clear X speed.
    LDA $D8,X                   ;$03A456    |\ 
    SEC                         ;$03A458    ||
    SBC $1C                     ;$03A459    || Return if not done descending.
    CMP.b #$10                  ;$03A45B    ||
    BNE Return03A464            ;$03A45D    |/
    LDA.b #$A4                  ;$03A45F    |\\ How long Bowser takes to emerge from his car at the start of the fight.
    STA.w $1540,X               ;$03A461    |/
Return03A464:                   ;           |
    RTS                         ;$03A464    |


CODE_03A465:                    ;```````````| Car has fully descended, waiting for Bowser to emerge.
    STZ $AA,X                   ;$03A465    |\ Clear X/Y speed.
    STZ $B6,X                   ;$03A467    |/
    CMP.b #$01                  ;$03A469    |\ Branch if Bowser is done emerging.
    BEQ CODE_03A47C             ;$03A46B    |/
    CMP.b #$40                  ;$03A46D    |\ 
    BCS Return03A47B            ;$03A46F    ||
    LSR                         ;$03A471    ||
    LSR                         ;$03A472    || Handle the animation for Bowser emerging from his car.
    LSR                         ;$03A473    ||
    TAY                         ;$03A474    ||
    LDA.w DATA_03A437,Y         ;$03A475    ||
    STA.w $1570,X               ;$03A478    |/
Return03A47B:                   ;           |
    RTS                         ;$03A47B    |

CODE_03A47C:                    ;```````````| Bowser just finished emergining.
    LDA.b #$24                  ;$03A47C    |\\ How long Bowser pauses for before attack phase 1 actually starts.
    STA.w $154C,X               ;$03A47E    |/
    RTS                         ;$03A481    |


CODE_03A482:                    ;```````````| Car has fully descended, Bowser has emerge, now just waiting to actually start phase 1.
    DEC A                       ;$03A482    |\ Return if not time to start.
    BNE Return03A48F            ;$03A483    |/
    LDA.b #$07                  ;$03A485    |\ Start Phase 1.
    STA.w $151C,X               ;$03A487    |/
    LDA.b #$78                  ;$03A48A    |\\ How long until Bowser throws his first set of MechaKoopas.
    STA.w $14B0                 ;$03A48C    |/
Return03A48F:                   ;           |
    RTS                         ;$03A48F    |



DATA_03A490                     ;$03A490    | X speed accelerations for Bowser in Phase 1.
    db $FF,$01

DATA_03A492:                    ;$03A492    | Maximum X speeds for Bowser in Phase 1.
    db $C8,$38

DATA_03A494:                    ;$03A494    | Y speed accelerations for Bowser in Phase 1.
    db $01,$FF

DATA_03A496:                    ;$03A496    | Maximum Y speeds for Bowser in Phase 1.
    db $1C,$E4

DATA_03A498:                    ;$03A498    | Animation pointers to use for Bowser's facial animation (squinting, closing mouth)
    db $00,$02,$04,$02

CODE_03A49C:                    ;-----------| Bowser phase 7 - Attack phase 1
    JSR CODE_03A4D2             ;$03A49C    | Animate Bowser's face.
    JSR CODE_03A4FD             ;$03A49F    | Prepare a MechaKoopa attack when time to.
    JSR CODE_03A4ED             ;$03A4A2    | Face Mario.
    LDA.w $1528,X               ;$03A4A5    |\ 
    AND.b #$01                  ;$03A4A8    ||
    TAY                         ;$03A4AA    ||
    LDA $B6,X                   ;$03A4AB    ||
    CLC                         ;$03A4AD    || Update Bowser's X speed and reverse acceleration if at the maximum.
    ADC.w DATA_03A490,Y         ;$03A4AE    ||
    STA $B6,X                   ;$03A4B1    ||
    CMP.w DATA_03A492,Y         ;$03A4B3    ||
    BNE CODE_03A4BB             ;$03A4B6    ||
    INC.w $1528,X               ;$03A4B8    |/
CODE_03A4BB:                    ;           |
    LDA.w $1534,X               ;$03A4BB    |\ 
    AND.b #$01                  ;$03A4BE    ||
    TAY                         ;$03A4C0    ||
    LDA $AA,X                   ;$03A4C1    ||
    CLC                         ;$03A4C3    || Update Bowser's Y speed and reverse acceleration if at the maximum.
    ADC.w DATA_03A494,Y         ;$03A4C4    ||
    STA $AA,X                   ;$03A4C7    ||
    CMP.w DATA_03A496,Y         ;$03A4C9    ||
    BNE Return03A4D1            ;$03A4CC    ||
    INC.w $1534,X               ;$03A4CE    |/
Return03A4D1:                   ;           |
    RTS                         ;$03A4D1    |



CODE_03A4D2:                    ;-----------| Subroutine to animate Bowser's facial animation.
    LDY.b #$00                  ;$03A4D2    || Default frame.
    LDA $13                     ;$03A4D4    |\ 
    AND.b #$E0                  ;$03A4D6    || Don't blink if not time to do so.
    BNE CODE_03A4E6             ;$03A4D8    |/
    LDA $13                     ;$03A4DA    |\ 
    AND.b #$18                  ;$03A4DC    ||
    LSR                         ;$03A4DE    ||
    LSR                         ;$03A4DF    || Get the animation frame for Bowser's blink animation.
    LSR                         ;$03A4E0    ||
    TAY                         ;$03A4E1    ||
    LDA.w DATA_03A498,Y         ;$03A4E2    ||
    TAY                         ;$03A4E5    |/
CODE_03A4E6:                    ;           |
    TYA                         ;$03A4E6    |
    STA.w $1570,X               ;$03A4E7    |
    RTS                         ;$03A4EA    |



DATA_03A4EB:                    ;$03A4EB    | 
    db $80,$00

CODE_03A4ED:                    ;-----------| Subroutine to turn Bowser toward Mario.
    LDA $13                     ;$03A4ED    |\ 
    AND.b #$1F                  ;$03A4EF    ||
    BNE Return03A4FC            ;$03A4F1    || Every 32 frames, turn Bowser to face Mario.
    JSR SubHorzPosBnk3          ;$03A4F3    ||
    LDA.w DATA_03A4EB,Y         ;$03A4F6    ||
    STA.w $157C,X               ;$03A4F9    |/
Return03A4FC:                   ;           |
    RTS                         ;$03A4FC    |



CODE_03A4FD:                    ;-----------| Handle Bowser's attacks (MechaKoopas, bowling balls)
    LDA.w $14B0                 ;$03A4FD    |\ Return if not time for an attack.
    BNE Return03A52C            ;$03A500    |/
    LDA.w $151C,X               ;$03A502    |\ Continue to next code if:
    CMP.b #$08                  ;$03A505    ||  - In phase 1/3
    BNE CODE_03A51A             ;$03A507    ||  - Already thrown two bowling balls
    INC.w $14B8                 ;$03A509    || Else, prepare a Bowling Ball attack and return.
    LDA.w $14B8                 ;$03A50C    ||
    CMP.b #$03                  ;$03A50F    ||| Number of bowling balls to drop (+1); use with $03A613.
    BEQ CODE_03A51A             ;$03A511    ||
    LDA.b #$FF                  ;$03A513    ||| How long to wait for dropping a bowling ball.
    STA.w $14B6                 ;$03A515    ||
    BRA Return03A52C            ;$03A518    |/

CODE_03A51A:                    ;```````````| Preparing MechaKoopa attack.
    STZ.w $14B8                 ;$03A51A    |
    LDA.w $14C8                 ;$03A51D    |\ 
    BEQ CODE_03A527             ;$03A520    ||
    LDA.w $14C9                 ;$03A522    || If slot 0 or 1 are empty, prepare a MechaKoopa attack.
    BNE Return03A52C            ;$03A525    || Else, return without doing so.
CODE_03A527:                    ;           ||
    LDA.b #$FF                  ;$03A527    ||
    STA.w $14B1                 ;$03A529    |/
Return03A52C:                   ;           |
    RTS                         ;$03A52C    |



DATA_03A52D:                    ;$03A52D    | Animation frames for Bowser ducking into his clown car
    db $00,$00,$00,$00,$00,$00,$00,$00      ;  during the MechaKoopa and bowling ball attacks.
    db $00,$02,$04,$06,$08,$0A,$0E,$0E
    db $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
    db $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
    db $0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E
    db $0E,$0E,$0A,$08,$06,$04,$02,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
DATA_03A56D:                    ;$03A56D    | Mode 7 rotation values for Bowser's bowling ball animation.
    db $00,$00,$00,$00,$00,$00,$00,$00      ; #$FF is handled as #$0100 instead. All other values remain 8-bit.
    db $00,$00,$10,$20,$30,$40,$50,$60
    db $80,$A0,$C0,$E0,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$C0,$80,$60
    db $40,$30,$20,$10,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00

CODE_03A5AD:                    ;-----------| Bowser's attack routine.
    LDA.w $14B1                 ;$03A5AD    |\ Branch if the MechaKoopa animation timer is not currently running.
    BEQ CODE_03A5D8             ;$03A5B0    |/
    DEC.w $14B1                 ;$03A5B2    |\ 
    BNE CODE_03A5BD             ;$03A5B5    || If the timer has just run out, reset it and return. Else, branch.
    LDA.b #$54                  ;$03A5B7    ||| Amount of time between Bowser throwing Mechakoopas in Phase 1.
    STA.w $14B0                 ;$03A5B9    |/
    RTS                         ;$03A5BC    |

CODE_03A5BD:                    ;```````````| MechaKoopa timer is running; handle animation and toss.
    LSR                         ;$03A5BD    |\ 
    LSR                         ;$03A5BE    ||
    TAY                         ;$03A5BF    || Animate Bowser's ducking movement.
    LDA.w DATA_03A52D,Y         ;$03A5C0    ||
    STA.w $1570,X               ;$03A5C3    |/
    LDA.w $14B1                 ;$03A5C6    |\ 
    CMP.b #$80                  ;$03A5C9    ||
    BNE CODE_03A5D5             ;$03A5CB    || Spawn the MechaKoopas when time to.
    JSR CODE_03B019             ;$03A5CD    ||
    LDA.b #$08                  ;$03A5D0    ||\ SFX for Bowser throwing MechaKoopas.
    STA.w $1DFC                 ;$03A5D2    |//
CODE_03A5D5:                    ;           |
    PLA                         ;$03A5D5    |
    PLA                         ;$03A5D6    |
    RTS                         ;$03A5D7    |

CODE_03A5D8:                    ;```````````| MechaKoopa timer is not running; handle bowling ball animation instead.
    LDA.w $14B6                 ;$03A5D8    |\ Return if the bowling ball animation timer is not running.
    BEQ Return03A60D            ;$03A5DB    |/
    DEC.w $14B6                 ;$03A5DD    |\ Branch if the timer just ran out.
    BEQ CODE_03A60E             ;$03A5E0    |/
    LSR                         ;$03A5E2    |\ 
    LSR                         ;$03A5E3    ||
    TAY                         ;$03A5E4    || Animate Bowser's ducking movement.
    LDA.w DATA_03A52D,Y         ;$03A5E5    ||
    STA.w $1570,X               ;$03A5E8    ||
    LDA.w DATA_03A56D,Y         ;$03A5EB    ||\ 
    STA $36                     ;$03A5EE    |||
    STZ $37                     ;$03A5F0    |||
    CMP.b #$FF                  ;$03A5F2    ||| Animate the car's rotation.
    BNE CODE_03A5FC             ;$03A5F4    |||
    STZ $36                     ;$03A5F6    |||
    INC $37                     ;$03A5F8    |||
    STZ $64                     ;$03A5FA    |//
CODE_03A5FC:                    ;           |
    LDA.w $14B6                 ;$03A5FC    |\ 
    CMP.b #$80                  ;$03A5FF    || Spawn the ball when time to.
    BNE CODE_03A60B             ;$03A601    ||
    LDA.b #$09                  ;$03A603    ||\ SFX for Bowser dropping a bowling ball.
    STA.w $1DFC                 ;$03A605    ||/
    JSR CODE_03A61D             ;$03A608    |/
CODE_03A60B:                    ;           |
    PLA                         ;$03A60B    |
    PLA                         ;$03A60C    |
Return03A60D:                   ;           |
    RTS                         ;$03A60D    |

CODE_03A60E:                    ;```````````| Bowling ball timer just ran out.
    LDA.b #$60                  ;$03A60E    || Amount of time before Bowser drops Mechakoopas after the bowling balls in Phase 2.
    LDY.w $14B8                 ;$03A610    |\ 
    CPY.b #$02                  ;$03A613    ||| Number of bowling balls to drop; use with $03A50F.
    BEQ CODE_03A619             ;$03A615    ||
    LDA.b #$20                  ;$03A617    ||| Amount of time between the bowling balls.
CODE_03A619:                    ;           ||
    STA.w $14B0                 ;$03A619    |/
    RTS                         ;$03A61C    |



CODE_03A61D:                    ;-----------| Subroutine to spawn one of Bowser's bowling balls.
    LDA.b #$08                  ;$03A61D    |\ 
    STA.w $14D0                 ;$03A61F    ||
    LDA.b #$A1                  ;$03A622    ||| Sprite to spawn (Bowling Ball).
    STA $A6                     ;$03A624    |/
    LDA $E4,X                   ;$03A626    |\ 
    CLC                         ;$03A628    ||
    ADC.b #$08                  ;$03A629    ||
    STA $EC                     ;$03A62B    ||
    LDA.w $14E0,X               ;$03A62D    ||
    ADC.b #$00                  ;$03A630    ||
    STA.w $14E8                 ;$03A632    || Spawn at Bowser's position.
    LDA $D8,X                   ;$03A635    ||
    CLC                         ;$03A637    ||
    ADC.b #$40                  ;$03A638    ||
    STA $E0                     ;$03A63A    ||
    LDA.w $14D4,X               ;$03A63C    ||
    ADC.b #$00                  ;$03A63F    ||
    STA.w $14DC                 ;$03A641    |/
    PHX                         ;$03A644    |
    LDX.b #$08                  ;$03A645    |
    JSL InitSpriteTables        ;$03A647    |
    PLX                         ;$03A64B    |
    RTS                         ;$03A64C    |



DATA_03A64D:                    ;$03A64D    | Angles for Bowser's hurt animation.
    db $00,$00,$00,$00,$FC,$F8,$F4,$F0      ; Positive values are 000-07F; negative are 180-1FF.
    db $F4,$F8,$FC,$00,$04,$08,$0C,$10
    db $0C,$08,$04,$00

CODE_03A661:                    ;-----------| Subroutine to handle animating Bowser when hurt.
    LDA.w $14B5                 ;$03A661    |\ Return if Bowser is not currently hurt.
    BEQ Return03A6BF            ;$03A664    |/
    STZ.w $14B1                 ;$03A666    |\ Clear Bowser's attack timers.
    STZ.w $14B6                 ;$03A669    |/
    DEC.w $14B5                 ;$03A66C    |\ Branch if not done with the hurt animation yet.
    BNE CODE_03A691             ;$03A66F    |/
    LDA.b #$50                  ;$03A671    |\\ How long before Bowser's next attack after taking damage.
    STA.w $14B0                 ;$03A673    |/
    DEC.w $187B,X               ;$03A676    |\\ Branch if not time to move onto the next phase.
    BNE CODE_03A691             ;$03A679    ||/
    LDA.w $151C,X               ;$03A67B    ||\ 
    CMP.b #$09                  ;$03A67E    ||| Branch if in phase 3 (to kill Bowser).
    BEQ CODE_03A6C0             ;$03A680    ||/
    LDA.b #$02                  ;$03A682    ||\\ How much HP to give Bowser in phase 2/3.
    STA.w $187B,X               ;$03A684    ||/
    LDA.b #$01                  ;$03A687    ||\ Set Bowser to swoop out of the screen. 
    STA.w $151C,X               ;$03A689    ||/
    LDA.b #$80                  ;$03A68C    ||\ Set timer for Bowser's ducking animation before swooping out.
    STA.w $1540,X               ;$03A68E    |//
CODE_03A691:                    ;           |
    PLY                         ;$03A691    |
    PLY                         ;$03A692    |
    PHA                         ;$03A693    |
    LDA.w $14B5                 ;$03A694    |\ 
    LSR                         ;$03A697    ||
    LSR                         ;$03A698    ||
    TAY                         ;$03A699    ||
    LDA.w DATA_03A64D,Y         ;$03A69A    || Animate the car's rotation.
    STA $36                     ;$03A69D    ||
    STZ $37                     ;$03A69F    ||
    BPL CODE_03A6A5             ;$03A6A1    ||
    INC $37                     ;$03A6A3    |/
CODE_03A6A5:                    ;           |
    PLA                         ;$03A6A5    |
    LDY.b #$0C                  ;$03A6A6    |\\ Frame for ducking slightly after being hit. 
    CMP.b #$40                  ;$03A6A8    ||
    BCS CODE_03A6B6             ;$03A6AA    ||
CODE_03A6AC:                    ;           ||
    LDA $13                     ;$03A6AC    || 
    LDY.b #$10                  ;$03A6AE    ||| Hurt pose frame 1.
    AND.b #$04                  ;$03A6B0    ||
    BEQ CODE_03A6B6             ;$03A6B2    ||
    LDY.b #$12                  ;$03A6B4    ||| Hurt pose frame 2.
CODE_03A6B6:                    ;           ||
    TYA                         ;$03A6B6    ||
    STA.w $1570,X               ;$03A6B7    |/
    LDA.b #$02                  ;$03A6BA    |\\ Frame to use for the clown car.
    STA.w $1427                 ;$03A6BC    |/
Return03A6BF:                   ;           |
    RTS                         ;$03A6BF    |

CODE_03A6C0:                    ;```````````| Phase 3 defeated.
    LDA.b #$04                  ;$03A6C0    |\ End the fight.
    STA.w $151C,X               ;$03A6C2    |/
    STZ $B6,X                   ;$03A6C5    | Clear Bowser's X speed.
    RTS                         ;$03A6C7    |





KillMostSprites:                ;-----------| Subroutine to kill most other sprites after a boss is defeated.
    LDY.b #$09                  ;$03A6C8    |\ 
CODE_03A6CA:                    ;           ||
    LDA.w $14C8,Y               ;$03A6CA    ||\ Find a living sprite. 
    BEQ CODE_03A6EC             ;$03A6CD    ||/
    LDA.w $009E,Y               ;$03A6CF    ||\ 
    CMP.b #$A9                  ;$03A6D2    |||
    BEQ CODE_03A6EC             ;$03A6D4    ||| If not sprite:
    CMP.b #$29                  ;$03A6D6    |||  A9 (Reznor)
    BEQ CODE_03A6EC             ;$03A6D8    |||  29 (Koopa Kid)
    CMP.b #$A0                  ;$03A6DA    |||  A0 (Bowser)
    BEQ CODE_03A6EC             ;$03A6DC    |||  C5 (Big Boo Boss)
    CMP.b #$C5                  ;$03A6DE    |||
    BEQ CODE_03A6EC             ;$03A6E0    ||/
    LDA.b #$04                  ;$03A6E2    ||\ 
    STA.w $14C8,Y               ;$03A6E4    ||| ...erase in a cloud of smoke.
    LDA.b #$1F                  ;$03A6E7    |||
    STA.w $1540,Y               ;$03A6E9    ||/
CODE_03A6EC:                    ;           ||
    DEY                         ;$03A6EC    ||
    BPL CODE_03A6CA             ;$03A6ED    |/
    RTL                         ;$03A6EF    |





DATA_03A6F0:                    ;$03A6F0    | Animation frames for Bowser ducking into the clown car before swooping out.
    db $0E,$0E,$0A,$08,$06,$04,$02,$00

CODE_03A6F8:                    ;-----------| Bowser phase 1 - Swooping out of the screen
    LDA.w $1540,X               ;$03A6F8    |\ Branch if Bowser is done ducking into his car and it's time to actually swoop.
    BEQ CODE_03A731             ;$03A6FB    |/
    CMP.b #$01                  ;$03A6FD    |\ 
    BNE CODE_03A706             ;$03A6FF    || Play SFX if time to actually swoop.
    LDY.b #$17                  ;$03A701    ||\ SFX/music for swooping out of the screen.
    STY.w $1DFB                 ;$03A703    |//
CODE_03A706:                    ;           |
    LSR                         ;$03A706    |\ 
    LSR                         ;$03A707    ||
    LSR                         ;$03A708    ||
    LSR                         ;$03A709    || Animate Bowser ducking into the car.
    TAY                         ;$03A70A    ||
    LDA.w DATA_03A6F0,Y         ;$03A70B    ||
    STA.w $1570,X               ;$03A70E    |/
    STZ $B6,X                   ;$03A711    |\ Clear X/Y speed.
    STZ $AA,X                   ;$03A713    |/
    STZ.w $1528,X               ;$03A715    |\ 
    STZ.w $1534,X               ;$03A718    || Clear movement related addresses.
    STZ.w $14B2                 ;$03A71B    |/
    RTS                         ;$03A71E    |


DATA_03A71F:                    ;$03A71F    | X accelerations to apply as Bowser swoops out of the screen.
    db $01,$FF

DATA_03A721:                    ;$03A721    | Max X speeds to accelerate to before increasing the X phase of Bowser's movement out of the screen.
    db $10,$80

DATA_03A723:                    ;$03A723    | How often to apply horizontal acceleration as Bowser swoops out of the screen.
    db $07,$03

DATA_03A725:                    ;$03A725    | Y accelerations to apply as Bowser swoops out of the screen.
    db $FF,$01

DATA_03A727:                    ;$03A727    | Max Y speeds to accelerate to before increasing the Y phase of Bowser's movement out of the screen.
    db $F0,$08

DATA_03A729:                    ;$03A729    | Speeds to scale Bowser with as he swoops out of the screen.
    db $01,$FF

DATA_03A72B:                    ;$03A72B    | How often to apply vertical acceleration as Bowser swoops out of the screen.
    db $03,$03

DATA_03A72D:                    ;$03A72D    | Maximum scaling to increase to before increasing the scale phase of Bowser's movement out of the screen.
    db $60,$02

DATA_03A72F:                    ;$03A72F    | How often to change the size of Bowser as he swoops out of the screen.
    db $01,$01

CODE_03A731:                    ;-----------| Routine to actually swoop Bowser out of the screen.
    LDY.w $1528,X               ;$03A731    |\ 
    CPY.b #$02                  ;$03A734    ||
    BCS CODE_03A74F             ;$03A736    ||
    LDA $13                     ;$03A738    ||
    AND.w DATA_03A723,Y         ;$03A73A    ||
    BNE CODE_03A74F             ;$03A73D    || Handle horizontal acceleration over the course of the movement.
    LDA $B6,X                   ;$03A73F    ||  If $1528 is #$02, no acceleration is applied (never reached, though).
    CLC                         ;$03A741    ||
    ADC.w DATA_03A71F,Y         ;$03A742    ||
    STA $B6,X                   ;$03A745    ||
    CMP.w DATA_03A721,Y         ;$03A747    ||
    BNE CODE_03A74F             ;$03A74A    ||
    INC.w $1528,X               ;$03A74C    |/
CODE_03A74F:                    ;           |
    LDY.w $1534,X               ;$03A74F    |\ 
    CPY.b #$02                  ;$03A752    ||
    BCS CODE_03A76D             ;$03A754    ||
    LDA $13                     ;$03A756    ||
    AND.w DATA_03A72B,Y         ;$03A758    ||
    BNE CODE_03A76D             ;$03A75B    || Handle vertical acceleration over the course of the movement.
    LDA $AA,X                   ;$03A75D    ||  If $1534 is #$02, no acceleration is applied.
    CLC                         ;$03A75F    ||
    ADC.w DATA_03A725,Y         ;$03A760    ||
    STA $AA,X                   ;$03A763    ||
    CMP.w DATA_03A727,Y         ;$03A765    ||
    BNE CODE_03A76D             ;$03A768    ||
    INC.w $1534,X               ;$03A76A    |/
CODE_03A76D:                    ;           |
    LDY.w $14B2                 ;$03A76D    |\ 
    CPY.b #$02                  ;$03A770    ||
    BEQ CODE_03A794             ;$03A772    ||
    LDA $13                     ;$03A774    ||
    AND.w DATA_03A72F,Y         ;$03A776    ||
    BNE CODE_03A78D             ;$03A779    ||
    LDA $38                     ;$03A77B    ||
    CLC                         ;$03A77D    || Handle size change over the course of the movement (think of it as the "Z acceleration").
    ADC.w DATA_03A729,Y         ;$03A77E    ||  If $14B2 is #$02, no change is applied.
    STA $38                     ;$03A781    ||
    STA $39                     ;$03A783    || Return if Bowser's sprite hasn't moved far enough left to mark Bowswer as "out of shot".
    CMP.w DATA_03A72D,Y         ;$03A785    ||  (i.e. not time to end the phase)
    BNE CODE_03A78D             ;$03A788    ||
    INC.w $14B2                 ;$03A78A    ||
CODE_03A78D:                    ;           ||
    LDA.w $14E0,X               ;$03A78D    ||
    CMP.b #$FE                  ;$03A790    ||
    BNE Return03A7AC            ;$03A792    |/
CODE_03A794:                    ;           |
    LDA.b #$03                  ;$03A794    |\ Switch to phase 3 (Bowser flames dropping).
    STA.w $151C,X               ;$03A796    |/
    LDA.b #$80                  ;$03A799    |\ Set timer for Bowser's flames phase.
    STA.w $14B0                 ;$03A79B    |/
    JSL GetRand                 ;$03A79E    |\ 
    AND.b #$F0                  ;$03A7A2    || Set random X position for the initial fireball.
    STA.w $14B7                 ;$03A7A4    |/
    LDA.b #$1D                  ;$03A7A7    |\ SFX/music for the Bowser flames phase.
    STA.w $1DFB                 ;$03A7A9    |/
Return03A7AC:                   ;           |
    RTS                         ;$03A7AC    |



CODE_03A7AD:                    ;-----------| Bowser phase 3 - Bowser flames dropping
    LDA.b #$60                  ;$03A7AD    |\ 
    STA $38                     ;$03A7AF    ||
    STA $39                     ;$03A7B1    ||
    LDA.b #$FF                  ;$03A7B3    || Keep Bowser out of shot.
    STA.w $14E0,X               ;$03A7B5    ||
    LDA.b #$60                  ;$03A7B8    ||
    STA $E4,X                   ;$03A7BA    |/
    LDA.w $14B0                 ;$03A7BC    |\ Branch if not time to end the phase.
    BNE CODE_03A7DF             ;$03A7BF    |/
    LDA.b #$18                  ;$03A7C1    |\ SFX/music for Bowser's flames phase.
    STA.w $1DFB                 ;$03A7C3    |/
    LDA.b #$02                  ;$03A7C6    |\ Switch to phase 3 (swooping in).
    STA.w $151C,X               ;$03A7C8    |/
    LDA.b #$18                  ;$03A7CB    |\ 
    STA $D8,X                   ;$03A7CD    || Set Y position for the start of the swoop at #$0018.
    LDA.b #$00                  ;$03A7CF    ||
    STA.w $14D4,X               ;$03A7D1    |/
    LDA.b #$08                  ;$03A7D4    |\ 
    STA $38                     ;$03A7D6    || Set initial scaling as Bowser swoops back in.
    STA $39                     ;$03A7D8    |/
    LDA.b #$64                  ;$03A7DA    |\ Set initial X speed as Bowser swoops back in.
    STA $B6,X                   ;$03A7DC    |/
    RTS                         ;$03A7DE    |

CODE_03A7DF:                    ;```````````| Bowser is still dropping flames.
    CMP.b #$60                  ;$03A7DF    |\ Return if not time to actually drop the flames.
    BCS Return03A840            ;$03A7E1    |/
    LDA $13                     ;$03A7E3    |\ 
    AND.b #$1F                  ;$03A7E5    ||| How often to spawn a Bowser flame.
    BNE Return03A840            ;$03A7E7    |/
    LDY.b #$07                  ;$03A7E9    |\ 
CODE_03A7EB:                    ;           ||
    LDA.w $14C8,Y               ;$03A7EB    ||
    BEQ CODE_03A7F6             ;$03A7EE    || Find an empty sprite slot and return if none found.
    DEY                         ;$03A7F0    ||
    CPY.b #$01                  ;$03A7F1    ||
    BNE CODE_03A7EB             ;$03A7F3    ||
    RTS                         ;$03A7F5    |/
CODE_03A7F6:                    ;           |
    LDA.b #$17                  ;$03A7F6    |\ SFX for a Bowser flame spawning.
    STA.w $1DFC                 ;$03A7F8    |/
    LDA.b #$08                  ;$03A7FB    |\\ Sprite status of Bowser's fireballs.
    STA.w $14C8,Y               ;$03A7FD    ||
    LDA.b #$33                  ;$03A800    ||| Sprite to use as Bowser's fire (Podoboo)
    STA.w $009E,Y               ;$03A802    |/
    LDA.w $14B7                 ;$03A805    |\ 
    PHA                         ;$03A808    ||
    STA.w $00E4,Y               ;$03A809    ||
    CLC                         ;$03A80C    || Set X position, 2 blocks right of the last fire.
    ADC.b #$20                  ;$03A80D    ||
    STA.w $14B7                 ;$03A80F    ||
    LDA.b #$00                  ;$03A812    ||
    STA.w $14E0,Y               ;$03A814    |/
    LDA.b #$00                  ;$03A817    |\ 
    STA.w $00D8,Y               ;$03A819    || Set Y position at the top of the screen.
    STA.w $14D4,Y               ;$03A81C    |/
    PHX                         ;$03A81F    |
    TYX                         ;$03A820    |
    JSL InitSpriteTables        ;$03A821    |
    INC $C2,X                   ;$03A825    | Spawn the sprite as the Bowser fire, not as a Podoboo.
    ASL.w $1686,X               ;$03A827    |\ Clear "don't interact with objects" flag.
    LSR.w $1686,X               ;$03A82A    |/
    LDA.b #$39                  ;$03A82D    |\ Change sprite clipping.
    STA.w $1662,X               ;$03A82F    |/
    PLX                         ;$03A832    |
    PLA                         ;$03A833    |
    LSR                         ;$03A834    |\ 
    LSR                         ;$03A835    ||
    LSR                         ;$03A836    ||
    LSR                         ;$03A837    || Get spawn sound effect based on where the flame is being spawned horizontally on the screen.
    LSR                         ;$03A838    ||
    TAY                         ;$03A839    ||
    LDA.w BowserSound,Y         ;$03A83A    ||
    STA.w $1DFC                 ;$03A83D    |/
Return03A840:                   ;           |
    RTS                         ;$03A840    |

BowserSound:                    ;$03A841    | SFX for Bowser's fires (Podoboo fades).
    db $2D,$2E,$2F,$30,$31,$32,$33,$34



BowserSoundMusic:               ;$03A849    | SFX/music for Bowser attack phases 2 and 3.
    db $19,$1A

CODE_03A84B:                    ;-----------| Bowser phase 2 - Swooping into the screen / Peach's item
    STZ $AA,X                   ;$03A84B    | CLear Y speed.
    LDA.w $1540,X               ;$03A84D    |\ Branch if showing Peach / Bowser is emerging.
    BNE CODE_03A86E             ;$03A850    |/
    LDA $B6,X                   ;$03A852    |\ 
    BEQ CODE_03A858             ;$03A854    || Declerate X speed.
    DEC $B6,X                   ;$03A856    |/
CODE_03A858:                    ;           |
    LDA $13                     ;$03A858    |\ 
    AND.b #$03                  ;$03A85A    || Return if not a frame to adjust scaling.
    BNE Return03A86D            ;$03A85C    |/
    INC $38                     ;$03A85E    |\ Scale Bowser away from the screen, to "swoop in".
    INC $39                     ;$03A860    |/
    LDA $38                     ;$03A862    |\ 
    CMP.b #$20                  ;$03A864    || Return if not fully scaled in.
    BNE Return03A86D            ;$03A866    |/
    LDA.b #$FF                  ;$03A868    |\ Set timer for the Peach animation and Bowser emerging.
    STA.w $1540,X               ;$03A86A    |/
Return03A86D:                   ;           |
    RTS                         ;$03A86D    |

CODE_03A86E:                    ;```````````| Showing Peach / emerging Bowser.
    CMP.b #$A0                  ;$03A86E    |\ 
    BNE CODE_03A877             ;$03A870    ||
    PHA                         ;$03A872    || Spawn a mushroom once time to do so.
    JSR CODE_03A8D6             ;$03A873    ||
    PLA                         ;$03A876    |/
CODE_03A877:                    ;           |
    STZ $B6,X                   ;$03A877    |\ Clear X/Y speed.
    STZ $AA,X                   ;$03A879    |/
    CMP.b #$01                  ;$03A87B    |\ Branch if done emerging Bowser.
    BEQ CODE_03A89D             ;$03A87D    |/
    CMP.b #$40                  ;$03A87F    |\ Branch if currently showing Peach.
    BCS CODE_03A8AE             ;$03A881    |/
    CMP.b #$3F                  ;$03A883    |\ 
    BNE CODE_03A892             ;$03A885    || Handle starting the next attack phase's music.
    PHA                         ;$03A887    ||
    LDY.w $14B4                 ;$03A888    ||\ 
    LDA.w BowserSoundMusic-7,Y  ;$03A88B    ||| Get music for Bowser's attack phase 2/3.
    STA.w $1DFB                 ;$03A88E    ||/
    PLA                         ;$03A891    |/
CODE_03A892:                    ;           |
    LSR                         ;$03A892    |\ 
    LSR                         ;$03A893    ||
    LSR                         ;$03A894    || Set animation frame for Bowser emerging.
    TAY                         ;$03A895    ||
    LDA.w DATA_03A437,Y         ;$03A896    ||
    STA.w $1570,X               ;$03A899    |/
    RTS                         ;$03A89C    |

CODE_03A89D:                    ;```````````| Done emerging Bowser, go to attack phase.
    LDA.w $14B4                 ;$03A89D    |
    INC A                       ;$03A8A0    |
    STA.w $151C,X               ;$03A8A1    |
    STZ $B6,X                   ;$03A8A4    |
    STZ $AA,X                   ;$03A8A6    |
    LDA.b #$80                  ;$03A8A8    |\\ How long Bowser waits before his next attack after swooping in.
    STA.w $14B0                 ;$03A8AA    |/
    RTS                         ;$03A8AD    |

CODE_03A8AE:                    ;```````````| Still showing Peach.
    CMP.b #$E8                  ;$03A8AE    |\ 
    BNE CODE_03A8B7             ;$03A8B0    || Play sound for Peach emerging when time to do so.
    LDY.b #$2A                  ;$03A8B2    ||\ SFX for Peach emerging from Bowser's car.
    STY.w $1DF9                 ;$03A8B4    |//
CODE_03A8B7:                    ;           |
    SEC                         ;$03A8B7    |\ 
    SBC.b #$3F                  ;$03A8B8    || Handle timer for Peach's "Help!" animation.
    STA.w $1594,X               ;$03A8BA    |/
    RTS                         ;$03A8BD    |



DATA_03A8BE:                    ;$03A8BE    | Additional Y offsets for Peach throughout her "Help!" animation.
    db $00,$00,$00,$08,$10,$14,$14,$16
    db $16,$18,$18,$17,$16,$16,$17,$18
    db $18,$17,$14,$10,$0C,$08,$04,$00



CODE_03A8D6:                    ;-----------| Subroutine to spawn Peach's mushroom.
    LDY.b #$07                  ;$03A8D6    |\ 
CODE_03A8D8:                    ;           ||
    LDA.w $14C8,Y               ;$03A8D8    ||
    BEQ CODE_03A8E3             ;$03A8DB    || Find an empty sprite slot and return if none found.
    DEY                         ;$03A8DD    ||
    CPY.b #$01                  ;$03A8DE    ||
    BNE CODE_03A8D8             ;$03A8E0    ||
    RTS                         ;$03A8E2    |/
CODE_03A8E3:                    ;           |
    LDA.b #$10                  ;$03A8E3    |\ Sound Peach makes when she throws a sprite.
    STA.w $1DF9                 ;$03A8E5    |/
    LDA.b #$08                  ;$03A8E8    |\\ Status of the sprite Peach throws.
    STA.w $14C8,Y               ;$03A8EA    ||
    LDA.b #$74                  ;$03A8ED    ||| Sprite Peach throws.
    STA.w $009E,Y               ;$03A8EF    |/
    LDA $E4,X                   ;$03A8F2    |\ 
    CLC                         ;$03A8F4    ||
    ADC.b #$04                  ;$03A8F5    ||
    STA.w $00E4,Y               ;$03A8F7    ||
    LDA.w $14E0,X               ;$03A8FA    ||
    ADC.b #$00                  ;$03A8FD    ||
    STA.w $14E0,Y               ;$03A8FF    || Spawn at Bowser/Peach's position.
    LDA $D8,X                   ;$03A902    ||
    CLC                         ;$03A904    ||
    ADC.b #$18                  ;$03A905    ||
    STA.w $00D8,Y               ;$03A907    ||
    LDA.w $14D4,X               ;$03A90A    ||
    ADC.b #$00                  ;$03A90D    ||
    STA.w $14D4,Y               ;$03A90F    |/
    PHX                         ;$03A912    |
    TYX                         ;$03A913    |
    JSL InitSpriteTables        ;$03A914    |
    LDA.b #$C0                  ;$03A918    |\\ Initial Y speed for the mushroom thrown by Peach.
    STA $AA,X                   ;$03A91A    |/
    STZ.w $157C,X               ;$03A91C    |\ 
    LDY.b #$0C                  ;$03A91F    || Set initial X speed and direction based on the direction Peach threw the sprite?
    LDA $E4,X                   ;$03A921    ||  (which will always be left...)
    BPL CODE_03A92A             ;$03A923    ||
    LDY.b #$F4                  ;$03A925    ||| X speed Peach throws the mushroom with.
    INC.w $157C,X               ;$03A927    ||
CODE_03A92A:                    ;           ||
    STY $B6,X                   ;$03A92A    |/
    PLX                         ;$03A92C    |
    RTS                         ;$03A92D    |



DATA_03A92E:                    ;$03A92E    | X offsets for Peach.
    db $00,$08,$00,$08          ; 00 - Help A (left)
    db $00,$08,$00,$08          ; 01 - Help B (left)
    db $00,$08,$00,$08          ; 02 - Help A (right)
    db $00,$08,$00,$08          ; 03 - Help B (right)
    db $00,$08,$00,$08          ; 04 - Walking A
    db $00,$08,$00,$08          ; 05 - Walking A, blinking
    db $00,$08,$00,$08          ; 06 - Floating down
    db $00,$08,$00,$08          ; 07 - Floating down, blinking
    db $00,$08,$00,$08          ; 08 - Walking B
    db $00,$08,$00,$08          ; 09 - Walking B, blinking
    db $00,$08,$00,$08          ; 09 - Kiss (unused duplicate?)
    db $00,$08,$00,$08          ; 0A - Kiss
    db $08,$00,$08,$00          ; 0B - Leftwards - Walking A
    db $08,$00,$08,$00          ; 0C - Leftwards - Walking A, blinking
    db $08,$00,$08,$00          ; 0D - Leftwards - Floating down
    db $08,$00,$08,$00          ; 0E - Leftwards - Floating down, blinking
    db $08,$00,$08,$00          ; 0F - Leftwards - Walking B
    db $08,$00,$08,$00          ; 10 - Leftwards - Walking B, blinking
    db $08,$00,$08,$00          ; 11 - Leftwards - Kiss (unused duplicate?)
    db $08,$00,$08,$00          ; 12 - Leftwards - Kiss

DATA_03A97E:                    ;$03A97E    | Y offsets for Peach.
    db $00,$00,$08,$08          ; 00 - Help A (left)
    db $00,$00,$08,$08          ; 01 - Help B (left)
    db $00,$00,$08,$08          ; 02 - Help A (right)
    db $00,$00,$08,$08          ; 03 - Help B (right)
    db $00,$00,$10,$10          ; 04 - Walking A
    db $00,$00,$10,$10          ; 05 - Walking A, blinking
    db $00,$00,$10,$10          ; 06 - Floating down
    db $00,$00,$10,$10          ; 07 - Floating down, blinking
    db $00,$00,$10,$10          ; 08 - Walking B
    db $00,$00,$10,$10          ; 09 - Walking B, blinking
    db $00,$00,$10,$10          ; 09 - Kiss (unused duplicate?)
    db $00,$00,$10,$10          ; 0A - Kiss
    db $00,$00,$10,$10          ; 0B - Leftwards - Walking A
    db $00,$00,$10,$10          ; 0C - Leftwards - Walking A, blinking
    db $00,$00,$10,$10          ; 0D - Leftwards - Floating down
    db $00,$00,$10,$10          ; 0E - Leftwards - Floating down, blinking
    db $00,$00,$10,$10          ; 0F - Leftwards - Walking B
    db $00,$00,$10,$10          ; 10 - Leftwards - Walking B, blinking
    db $00,$00,$10,$10          ; 11 - Leftwards - Kiss (unused duplicate?)
    db $00,$00,$10,$10          ; 12 - Leftwards - Kiss

DATA_03A9CE:                    ;$03A9CE    | Tile numbers for Peach.
    db $05,$06,$15,$16          ; 00 - Help A (left)
    db $9D,$9E,$4E,$AE          ; 01 - Help B (left)
    db $06,$05,$16,$15          ; 02 - Help A (right)
    db $9E,$9D,$AE,$4E          ; 03 - Help B (right)
    db $8A,$8B,$AA,$68          ; 04 - Walking A
    db $83,$84,$AA,$68          ; 05 - Walking A, blinking
    db $8A,$8B,$80,$81          ; 06 - Floating down
    db $83,$84,$80,$81          ; 07 - Floating down, blinking
    db $85,$86,$A5,$A6          ; 08 - Walking B
    db $83,$84,$A5,$A6          ; 09 - Walking B, blinking
    db $82,$83,$A2,$A3          ; 09 - Kiss (unused duplicate?)
    db $82,$83,$A2,$A3          ; 0A - Kiss
    db $8A,$8B,$AA,$68          ; 0B - Leftwards - Walking A
    db $83,$84,$AA,$68          ; 0C - Leftwards - Walking A, blinking
    db $8A,$8B,$80,$81          ; 0D - Leftwards - Floating down
    db $83,$84,$80,$81          ; 0E - Leftwards - Floating down, blinking
    db $85,$86,$A5,$A6          ; 0F - Leftwards - Walking B
    db $83,$84,$A5,$A6          ; 10 - Leftwards - Walking B, blinking
    db $82,$83,$A2,$A3          ; 11 - Leftwards - Kiss (unused duplicate?)
    db $82,$83,$A2,$A3          ; 12 - Leftwards - Kiss

DATA_03AA1E:                    ;$03AA1E    | YXPPCCCT for Peach.
    db $01,$01,$01,$01          ; 00 - Help A (left)
    db $01,$01,$01,$01          ; 01 - Help B (left)
    db $41,$41,$41,$41          ; 02 - Help A (right)
    db $41,$41,$41,$41          ; 03 - Help B (right)
    db $01,$01,$01,$01          ; 04 - Walking A
    db $01,$01,$01,$01          ; 05 - Walking A, blinking
    db $01,$01,$01,$01          ; 06 - Floating down
    db $01,$01,$01,$01          ; 07 - Floating down, blinking
    db $00,$00,$00,$00          ; 08 - Walking B
    db $01,$01,$00,$00          ; 09 - Walking B, blinking
    db $00,$00,$00,$00          ; 0A - Kiss (unused duplicate?)
    db $00,$00,$00,$00          ; 0B - Kiss
    db $41,$41,$41,$41          ; 0C - Rightwards - Walking A
    db $41,$41,$41,$41          ; 0D - Rightwards - Walking A, blinking
    db $41,$41,$41,$41          ; 0E - Rightwards - Floating down
    db $41,$41,$41,$41          ; 0F - Rightwards - Floating down, blinking
    db $40,$40,$40,$40          ; 10 - Rightwards - Walking B
    db $41,$41,$40,$40          ; 11 - Rightwards - Walking B, blinking
    db $40,$40,$40,$40          ; 12 - Rightwards - Kiss (unused duplicate?)
    db $40,$40,$40,$40          ; 13 - Rightwards - Kiss

    ;  Scratch RAM input:
    ;  $02 = Additional Y offset for Peach
    ;  $03 = Animation frame, for Peach (base timer / 4)
    ;  Y   = Animation frame, for Peach's speech bubble (base timer / 8)

CODE_03AA6E:                    ;-----------| Peach GFX routine, when in Bowser's clown car (includes "Help!" message).
    LDA $E4,X                   ;$03AA6E    |\ 
    CLC                         ;$03AA70    ||
    ADC.b #$04                  ;$03AA71    || $00 = onscreen X position
    SEC                         ;$03AA73    ||
    SBC $1A                     ;$03AA74    ||
    STA $00                     ;$03AA76    |/
    LDA $D8,X                   ;$03AA78    |\ 
    CLC                         ;$03AA7A    ||
    ADC.b #$20                  ;$03AA7B    ||
    SEC                         ;$03AA7D    || $01 = onscreen Y position
    SBC $02                     ;$03AA7E    ||
    SEC                         ;$03AA80    ||
    SBC $1C                     ;$03AA81    ||
    STA $01                     ;$03AA83    |/
    CPY.b #$08                  ;$03AA85    |\ 
    BCC CODE_03AAC6             ;$03AA87    || Branch if not showing Peach's "Help!" speech bubble.
    CPY.b #$10                  ;$03AA89    ||
    BCS CODE_03AAC6             ;$03AA8B    |/
    LDA $00                     ;$03AA8D    |\ 
    SEC                         ;$03AA8F    ||
    SBC.b #$04                  ;$03AA90    ||
    STA.w $02A0                 ;$03AA92    || Store X position to OAM for the speech bubble.
    CLC                         ;$03AA95    ||
    ADC.b #$10                  ;$03AA96    ||
    STA.w $02A4                 ;$03AA98    |/
    LDA $01                     ;$03AA9B    |\ 
    SEC                         ;$03AA9D    ||
    SBC.b #$18                  ;$03AA9E    || Store Y position to OAM for the speech bubble.
    STA.w $02A1                 ;$03AAA0    ||
    STA.w $02A5                 ;$03AAA3    |/
    LDA.b #$20                  ;$03AAA6    |\\ Tile A for Peach's speech bubble.
    STA.w $02A2                 ;$03AAA8    ||
    LDA.b #$22                  ;$03AAAB    ||| Tile B for Peach's speech bubble.
    STA.w $02A6                 ;$03AAAD    |/
    LDA $14                     ;$03AAB0    |\ 
    LSR                         ;$03AAB2    ||
    AND.b #$06                  ;$03AAB3    ||
    INC A                       ;$03AAB5    || Store YXPPCCCT to OAM for the speech bubble, making it flash through palettes A-D.
    INC A                       ;$03AAB6    ||
    INC A                       ;$03AAB7    ||
    STA.w $02A3                 ;$03AAB8    ||
    STA.w $02A7                 ;$03AABB    |/
    LDA.b #$02                  ;$03AABE    |\ 
    STA.w $0448                 ;$03AAC0    || Store size to OAM as 16x16.
    STA.w $0449                 ;$03AAC3    |/
CODE_03AAC6:                    ;           |
    LDY.b #$70                  ;$03AAC6    |] OAM index (from $0300) for Peach when in Bowser's clown car.
CODE_03AAC8:                    ;```````````| Peach GFX routine (even when out of Bowser's clown car). Note that Y, $00, $01, and $03 must be set up beforehand.
    LDA $03                     ;$03AAC8    |\ 
    ASL                         ;$03AACA    || $04 = animation frame, x4
    ASL                         ;$03AACB    ||
    STA $04                     ;$03AACC    |/
    PHX                         ;$03AACE    |
    LDX.b #$03                  ;$03AACF    |
CODE_03AAD1:                    ;```````````| Peach tile loop.
    PHX                         ;$03AAD1    |
    TXA                         ;$03AAD2    |\ 
    CLC                         ;$03AAD3    ||
    ADC $04                     ;$03AAD4    ||
    TAX                         ;$03AAD6    || Store X position to OAM.
    LDA $00                     ;$03AAD7    ||
    CLC                         ;$03AAD9    ||
    ADC.w DATA_03A92E,X         ;$03AADA    ||
    STA.w $0300,Y               ;$03AADD    |/
    LDA $01                     ;$03AAE0    |\ 
    CLC                         ;$03AAE2    || Store Y position to OAM.
    ADC.w DATA_03A97E,X         ;$03AAE3    ||
    STA.w $0301,Y               ;$03AAE6    |/
    LDA.w DATA_03A9CE,X         ;$03AAE9    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$03AAEC    |/
    LDA.w DATA_03AA1E,X         ;$03AAEF    |\ 
    PHX                         ;$03AAF2    ||
    LDX.w $15E9                 ;$03AAF3    ||
    CPX.b #$09                  ;$03AAF6    || Store YXPPCCCT to OAM. If not in Bowser's car, give high priority.
    BEQ CODE_03AAFC             ;$03AAF8    ||
    ORA.b #$30                  ;$03AAFA    ||
CODE_03AAFC:                    ;           ||
    STA.w $0303,Y               ;$03AAFC    |/
    PLX                         ;$03AAFF    |
    PHY                         ;$03AB00    |
    TYA                         ;$03AB01    |\ 
    LSR                         ;$03AB02    ||
    LSR                         ;$03AB03    || Store size to OAM as 16x16.
    TAY                         ;$03AB04    ||
    LDA.b #$02                  ;$03AB05    ||
    STA.w $0460,Y               ;$03AB07    |/
    PLY                         ;$03AB0A    |
    INY                         ;$03AB0B    |\ 
    INY                         ;$03AB0C    ||
    INY                         ;$03AB0D    ||
    INY                         ;$03AB0E    || Loop for all tiles.
    PLX                         ;$03AB0F    ||
    DEX                         ;$03AB10    ||
    BPL CODE_03AAD1             ;$03AB11    |/
    PLX                         ;$03AB13    |
    RTS                         ;$03AB14    |



DATA_03AB15:                    ;$03AB15    | X accelerations for Bowser in phase 2.
    db $01,$FF

DATA_03AB17:                    ;$03AB17    | Max X speeds for Bowser in phase 2.
    db $20,$E0

DATA_03AB19:                    ;$03AB19    | Y accelerations for Bowser in Phase 2.
    db $02,$FE

DATA_03AB1B:                    ;$03AB1B    | Max Y speeds for Bowser in phase 2.
    db $20,$E0

DATA_03AB1D:                    ;$03AB1D    | Unused acceleration and max speed values. Unknown what they would have been used by.
    db $01,$FF
    db $10,$F0

CODE_03AB21:                    ;-----------| Bowser phase 8 - Attack phase 2
    JSR CODE_03A4FD             ;$03AB21    | Prepare a MechaKoopa / Bowling Ball attack when time to.
    JSR CODE_03A4D2             ;$03AB24    | Animate Bowser's face.
    JSR CODE_03A4ED             ;$03AB27    | Face Mario.
    LDA $13                     ;$03AB2A    |\ 
    AND.b #$00                  ;$03AB2C    || Branch if not a frame to apply acceleration (although this is every frame).
    BNE CODE_03AB4B             ;$03AB2E    |/
    LDY.b #$00                  ;$03AB30    |\ 
    LDA $E4,X                   ;$03AB32    ||
    CMP $94                     ;$03AB34    ||
    LDA.w $14E0,X               ;$03AB36    ||
    SBC $95                     ;$03AB39    ||
    BMI CODE_03AB3E             ;$03AB3B    ||
    INY                         ;$03AB3D    || Accelerate horizontally towards Mario, if not already at the max X speed.
CODE_03AB3E:                    ;           ||
    LDA $B6,X                   ;$03AB3E    ||
    CMP.w DATA_03AB17,Y         ;$03AB40    ||
    BEQ CODE_03AB4B             ;$03AB43    ||
    CLC                         ;$03AB45    ||
    ADC.w DATA_03AB15,Y         ;$03AB46    ||
    STA $B6,X                   ;$03AB49    |/
CODE_03AB4B:                    ;           |
    LDY.b #$00                  ;$03AB4B    |\ 
    LDA $D8,X                   ;$03AB4D    ||
    CMP.b #$10                  ;$03AB4F    ||
    BMI CODE_03AB54             ;$03AB51    ||
    INY                         ;$03AB53    ||
CODE_03AB54:                    ;           || Accelerate vertically around Y=10, if not already at the max Y speed.
    LDA $AA,X                   ;$03AB54    ||  (this creates Bowser's "wave" motion")
    CMP.w DATA_03AB1B,Y         ;$03AB56    ||
    BEQ Return03AB61            ;$03AB59    ||
    CLC                         ;$03AB5B    ||
    ADC.w DATA_03AB19,Y         ;$03AB5C    ||
    STA $AA,X                   ;$03AB5F    |/
Return03AB61:                   ;           |
    RTS                         ;$03AB61    |



DATA_03AB62:                    ;$03AB62    | Bowser's X speeds for phase 3.
    db $10,$F0

CODE_03AB64:                    ;-----------| Bowser phase 9 - Attack phase 3
    LDA.b #$03                  ;$03AB64    |\ Set image to angry face.
    STA.w $1427                 ;$03AB66    |/
    JSR CODE_03A4FD             ;$03AB69    | Prepare a MechaKoopa attack when time to.
    JSR CODE_03A4D2             ;$03AB6C    | Animate Bowser's face.
    JSR CODE_03A4ED             ;$03AB6F    | Face Mario.
    LDA $AA,X                   ;$03AB72    |\ 
    CLC                         ;$03AB74    || Apply gravity.
    ADC.b #$03                  ;$03AB75    ||| Downwards vertical acceleration for Bowser in phase 3.
    STA $AA,X                   ;$03AB77    |/
    LDA $D8,X                   ;$03AB79    |\ 
    CMP.b #$64                  ;$03AB7B    ||
    BCC Return03AB9E            ;$03AB7D    ||
    LDA.w $14D4,X               ;$03AB7F    || Return if not hitting the ground (at Y = 0x0064).
    BMI Return03AB9E            ;$03AB82    ||
    LDA.b #$64                  ;$03AB84    ||
    STA $D8,X                   ;$03AB86    |/
    LDA.b #$A0                  ;$03AB88    |\\ Y speed to bounce Bowser up with. 
    STA $AA,X                   ;$03AB8A    |/
    LDA.b #$09                  ;$03AB8C    |\ SFX for slamming the ground.
    STA.w $1DFC                 ;$03AB8E    |/
    JSR SubHorzPosBnk3          ;$03AB91    |\ 
    LDA.w DATA_03AB62,Y         ;$03AB94    || Set X speed towards Mario.
    STA $B6,X                   ;$03AB97    |/
    LDA.b #$20                  ;$03AB99    |\\ How long to shake the ground for. 
    STA.w $1887                 ;$03AB9B    |/
Return03AB9E:                   ;           |
    RTS                         ;$03AB9E    |



CODE_03AB9F:                    ;-----------| Bowser phase 4 - Rising up after being killed
    JSR CODE_03A6AC             ;$03AB9F    | Show Bowser's hurt pose.
    LDA.w $14D4,X               ;$03ABA2    |\ 
    BMI CODE_03ABAF             ;$03ABA5    ||
    BNE CODE_03ABB9             ;$03ABA7    ||
    LDA $D8,X                   ;$03ABA9    || Continue to phase 5 if fully risen up (at Y = 0x0010)
    CMP.b #$10                  ;$03ABAB    ||
    BCS CODE_03ABB9             ;$03ABAD    ||
CODE_03ABAF:                    ;           ||
    LDA.b #$05                  ;$03ABAF    ||\ Switch to phase 5 (death puffs).
    STA.w $151C,X               ;$03ABB1    ||/
    LDA.b #$60                  ;$03ABB4    ||\\ How long Bowser shows the death puffs for.
    STA.w $1540,X               ;$03ABB6    |//
CODE_03ABB9:                    ;           |
    LDA.b #$F8                  ;$03ABB9    |\ Y speed to give Bowser as he rises upwards at the end of the fight.
    STA $AA,X                   ;$03ABBB    |/
    RTS                         ;$03ABBD    |



CODE_03ABBE:                    ;-----------| Bowser phase 5 - Defeated (cloud puffs, rotation)
    JSR CODE_03A6AC             ;$03ABBE    | Show Bowser's hurt pose.
    STZ $B6,X                   ;$03ABC1    |\ Clear X/Y speed.
    STZ $AA,X                   ;$03ABC3    |/
    LDA.w $1540,X               ;$03ABC5    |\ Branch if still showing the cloud puffs.
    BNE CODE_03ABEB             ;$03ABC8    |/
    LDA $36                     ;$03ABCA    |\ 
    CLC                         ;$03ABCC    ||
    ADC.b #$0A                  ;$03ABCD    ||
    STA $36                     ;$03ABCF    || Rotate Bowser, and return if not fully rotated upside-down.
    LDA $37                     ;$03ABD1    ||
    ADC.b #$00                  ;$03ABD3    ||
    STA $37                     ;$03ABD5    ||
    BEQ Return03ABEA            ;$03ABD7    |/
    STZ $36                     ;$03ABD9    |
    LDA.b #$20                  ;$03ABDB    |\ Set timer to wait before spawning Peach.
    STA.w $154C,X               ;$03ABDD    |/
    LDA.b #$60                  ;$03ABE0    |\ Set timer to wait before flying away.
    STA.w $1540,X               ;$03ABE2    |/
    LDA.b #$06                  ;$03ABE5    |\ Switch to phase 6 (dropping peach / flying away).
    STA.w $151C,X               ;$03ABE7    |/
Return03ABEA:                   ;           |
    RTS                         ;$03ABEA    |

CODE_03ABEB:                    ;```````````| Still showing the cloud puffs / waiting to rotate.
    CMP.b #$40                  ;$03ABEB    |\ Return if just waiting before rotating Bowser.
    BCC Return03AC02            ;$03ABED    |/
    CMP.b #$5E                  ;$03ABEF    |\ 
    BNE CODE_03ABF8             ;$03ABF1    || Change music when time to.
    LDY.b #$1B                  ;$03ABF3    ||\ Music for defeating Bowser.
    STY.w $1DFB                 ;$03ABF5    |//
CODE_03ABF8:                    ;           |
    LDA.w $1564,X               ;$03ABF8    |\ 
    BNE Return03AC02            ;$03ABFB    || Set timer for the cloud puffs.
    LDA.b #$12                  ;$03ABFD    ||
    STA.w $1564,X               ;$03ABFF    |/
Return03AC02:                   ;           |
    RTS                         ;$03AC02    |



CODE_03AC03:                    ;-----------| Bowser phase 6 - Dropping Peach and spinning away
    JSR CODE_03A6AC             ;$03AC03    | Show Bowser's hurt pose.
    LDA.w $154C,X               ;$03AC06    |\ 
    CMP.b #$01                  ;$03AC09    || Spawn Peach once time to do so.
    BNE CODE_03AC22             ;$03AC0B    ||
    LDA.b #$0B                  ;$03AC0D    ||\ Freeze Mario.
    STA $71                     ;$03AC0F    ||/
    INC.w $190D                 ;$03AC11    ||
    STZ.w $0701                 ;$03AC14    ||\ Clear lightning palette, just in case.
    STZ.w $0702                 ;$03AC17    ||/
    LDA.b #$03                  ;$03AC1A    ||\ Set flag to send Mario behind other sprites,
    STA.w $13F9                 ;$03AC1C    ||/  since most of Bowser's room will be moving the OAM range at $0300 in order to make room for the credits message.
    JSR CODE_03AC63             ;$03AC1F    |/
CODE_03AC22:                    ;           |
    LDA.w $1540,X               ;$03AC22    |\ Return if not time to fly away.
    BNE Return03AC4C            ;$03AC25    |/
    LDA.b #$FA                  ;$03AC27    |\\ X speed Bowser flies away with.
    STA $B6,X                   ;$03AC29    |/
    LDA.b #$FC                  ;$03AC2B    |\\ Y speed Bowser flies away with.
    STA $AA,X                   ;$03AC2D    |/
    LDA $36                     ;$03AC2F    |\ 
    CLC                         ;$03AC31    ||
    ADC.b #$05                  ;$03AC32    ||| Speed at which Bowser spins as he flies away.
    STA $36                     ;$03AC34    ||
    LDA $37                     ;$03AC36    ||
    ADC.b #$00                  ;$03AC38    ||
    STA $37                     ;$03AC3A    |/
    LDA $13                     ;$03AC3C    |\ 
    AND.b #$03                  ;$03AC3E    ||
    BNE Return03AC4C            ;$03AC40    ||
    LDA $38                     ;$03AC42    || Scale Bowser away.
    CMP.b #$80                  ;$03AC44    ||  Branch if he's flown far enough away.
    BCS CODE_03AC4D             ;$03AC46    ||
    INC $38                     ;$03AC48    ||
    INC $39                     ;$03AC4A    |/
Return03AC4C:                   ;           |
    RTS                         ;$03AC4C    |

CODE_03AC4D:                    ;```````````| Done with Bowser's defeat movement; play "adventure is over" music.
    LDA.w $164A,X               ;$03AC4D    |\ 
    BNE CODE_03AC5A             ;$03AC50    || Start the end music if it hasn't already.
    LDA.b #$1C                  ;$03AC52    ||\ SFX for the Peach kiss music.
    STA.w $1DFB                 ;$03AC54    ||/
    INC.w $164A,X               ;$03AC57    |/
CODE_03AC5A:                    ;           |
    LDA.b #$FE                  ;$03AC5A    |\ 
    STA.w $14E0,X               ;$03AC5C    || Hide Bowser out of shot.
    STA.w $14D4,X               ;$03AC5F    |/
    RTS                         ;$03AC62    |



CODE_03AC63:                    ;-----------| Routine to spawn Peach after defeating Bowser.
    LDA.b #$08                  ;$03AC63    |\ 
    STA.w $14D0                 ;$03AC65    ||
    LDA.b #$7C                  ;$03AC68    ||| Sprite ID (Peach) to spawn.
    STA $A6                     ;$03AC6A    |/
    LDA $E4,X                   ;$03AC6C    |\ 
    CLC                         ;$03AC6E    ||
    ADC.b #$08                  ;$03AC6F    ||
    STA $EC                     ;$03AC71    ||
    LDA.w $14E0,X               ;$03AC73    ||
    ADC.b #$00                  ;$03AC76    ||
    STA.w $14E8                 ;$03AC78    || Spawn at Bowser's position.
    LDA $D8,X                   ;$03AC7B    ||
    CLC                         ;$03AC7D    ||
    ADC.b #$47                  ;$03AC7E    ||
    STA $E0                     ;$03AC80    ||
    LDA.w $14D4,X               ;$03AC82    ||
    ADC.b #$00                  ;$03AC85    ||
    STA.w $14DC                 ;$03AC87    |/
    PHX                         ;$03AC8A    |
    LDX.b #$08                  ;$03AC8B    |
    JSL InitSpriteTables        ;$03AC8D    |
    PLX                         ;$03AC91    |
    RTS                         ;$03AC92    |



BlushTileDispY:                 ;$03AC93    | Y offsets for Mario's blush after Peach kisses him. Indexed by whether he's small or not.
    db $01,$11

BlushTiles:                     ;$03AC95    | Tile numbers for Mario's blush after Peach kisses him. Indexed by whether he's small or not.
    db $6E,$88

    ; Peach misc RAM:
    ; $C2   - Sprite phase.
    ;          0 = floating down, 1 = waiting after fall, 2 = walking towards Mario, 3 = standing next to Mario
    ;          4 = kissing Mario, 5 = displaying "Mario's adventure...", 6 = fading text, 7 = fireworks
    ; $151C - Flag to indicate Peach landed on top of Mario and should walk away from him.
    ; $1534 - Counter for the fireworks at the end.
    ; $1540 - Phase timer. In phase 5, it's also used for waiting between writing each letter.
    ; $154C - Timer for Peach's blink animation.
    ; $1558 - Timer for Mario's blush when Peach kisses him.
    ; $157C - Horizontal direction the sprite is facing.
    ; $1602 - Animation frame.
    ;          0/1/2/3 = "Help!" animation, 4 = walk A, 6 = floating down, 8 = walk B, A = kiss
    ; $1FE2 - (using slot #9's) Timer for spawning fireworks after the fight.
    
PrincessPeach:                  ;-----------| Princess Peach MAIN (also handles the "Mario's Adventure..." text)
    LDA $E4,X                   ;$03AC97    |\ 
    SEC                         ;$03AC99    || $00 = onscreen X position
    SBC $1A                     ;$03AC9A    ||
    STA $00                     ;$03AC9C    |/
    LDA $D8,X                   ;$03AC9E    |\ 
    SEC                         ;$03ACA0    || $01 = onscreen Y position
    SBC $1C                     ;$03ACA1    ||
    STA $01                     ;$03ACA3    |/
    LDA $13                     ;$03ACA5    |\ 
    AND.b #$7F                  ;$03ACA7    ||
    BNE CODE_03ACB8             ;$03ACA9    ||
    JSL GetRand                 ;$03ACAB    || Randomly make Peach blink.
    AND.b #$07                  ;$03ACAF    ||
    BNE CODE_03ACB8             ;$03ACB1    ||
    LDA.b #$0C                  ;$03ACB3    ||
    STA.w $154C,X               ;$03ACB5    |/
CODE_03ACB8:                    ;           |
    LDY.w $1602,X               ;$03ACB8    |\ 
    LDA.w $154C,X               ;$03ACBB    ||
    BEQ CODE_03ACC1             ;$03ACBE    ||
    INY                         ;$03ACC0    ||
CODE_03ACC1:                    ;           || Get animation frame.
    LDA.w $157C,X               ;$03ACC1    ||  If blinking, increment by 1.
    BNE CODE_03ACCB             ;$03ACC4    ||  If facing right, increment by 8.
    TYA                         ;$03ACC6    ||
    CLC                         ;$03ACC7    ||
    ADC.b #$08                  ;$03ACC8    ||
    TAY                         ;$03ACCA    |/
CODE_03ACCB:                    ;           |
    STY $03                     ;$03ACCB    |
    LDA.b #$D0                  ;$03ACCD    |\\ OAM index (from $0300) for Peach when out of Bowser's car.
    STA.w $15EA,X               ;$03ACCF    |/
    TAY                         ;$03ACD2    |
    JSR CODE_03AAC8             ;$03ACD3    |\ 
    LDY.b #$02                  ;$03ACD6    || Draw GFX (4 16x16 tiles).
    LDA.b #$03                  ;$03ACD8    ||
    JSL FinishOAMWrite          ;$03ACDA    |/
    LDA.w $1558,X               ;$03ACDE    |\ Branch if the tiles for Mario's blush aren't being drawn. 
    BEQ CODE_03AD18             ;$03ACE1    |/
    PHX                         ;$03ACE3    |
    LDX.b #$00                  ;$03ACE4    |\ 
    LDA $19                     ;$03ACE6    || Get index to Y offsets based on Mario's powerup.
    BNE CODE_03ACEB             ;$03ACE8    ||
    INX                         ;$03ACEA    |/
CODE_03ACEB:                    ;           |
    LDY.b #$4C                  ;$03ACEB    || OAM index (from $0300) of Mario's blush tile.
    LDA $7E                     ;$03ACED    |\ Store X position for the blush to OAM.
    STA.w $0300,Y               ;$03ACEF    |/
    LDA $80                     ;$03ACF2    |\ 
    CLC                         ;$03ACF4    || Store Y position for the blush to OAM.
    ADC.w BlushTileDispY,X      ;$03ACF5    ||
    STA.w $0301,Y               ;$03ACF8    |/
    LDA.w BlushTiles,X          ;$03ACFB    |\ Store tile number for the blush to OAM.
    STA.w $0302,Y               ;$03ACFE    |/
    PLX                         ;$03AD01    |
    LDA $76                     ;$03AD02    |\ 
    CMP.b #$01                  ;$03AD04    ||
    LDA.b #$31                  ;$03AD06    ||
    BCC CODE_03AD0C             ;$03AD08    || Store YXPPCCCT for the blush to OAM.
    ORA.b #$40                  ;$03AD0A    ||
CODE_03AD0C:                    ;           ||
    STA.w $0303,Y               ;$03AD0C    |/
    TYA                         ;$03AD0F    |\ 
    LSR                         ;$03AD10    ||
    LSR                         ;$03AD11    || Store size to OAM as 16x16.
    TAY                         ;$03AD12    ||
    LDA.b #$02                  ;$03AD13    ||
    STA.w $0460,Y               ;$03AD15    |/
CODE_03AD18:                    ;           |
    STZ $B6,X                   ;$03AD18    |\ Clear Mario and Peach's X speeds.
    STZ $7B                     ;$03AD1A    |/
    LDA.b #$04                  ;$03AD1C    |\ Set base animation frame.
    STA.w $1602,X               ;$03AD1E    |/
    LDA $C2,X                   ;$03AD21    |
    JSL ExecutePtr              ;$03AD23    |

PeachPtrs:                      ;$03AD27    | Peach phase pointers.
    dw CODE_03AD37              ; 0 - Floating down
    dw CODE_03ADB3              ; 1 - Waiting after fall
    dw CODE_03ADDD              ; 2 - Walking toward Mario
    dw CODE_03AE25              ; 3 - Standing next to Mario
    dw CODE_03AE32              ; 4 - Kissing Mario (and slightly after)
    dw CODE_03AEAF              ; 5 - Displaying the "Mario's adventure is over..." text
    dw CODE_03AEE8              ; 6 - Fade text
    dw CODE_03C796              ; 7 - Fireworks sequence



CODE_03AD37:                    ;-----------| Peach phase 0 - Floating down
    LDA.b #$06                  ;$03AD37    |\\ Animation frame for Peach floating down.
    STA.w $1602,X               ;$03AD39    |/
    JSL UpdateYPosNoGrvty       ;$03AD3C    | Update Y position.
    LDA $AA,X                   ;$03AD40    |\ 
    CMP.b #$08                  ;$03AD42    ||| Max X speed for Peach as she falls.
    BCS CODE_03AD4B             ;$03AD44    ||
    CLC                         ;$03AD46    ||
    ADC.b #$01                  ;$03AD47    ||| X acceleration for Peach as she falls.
    STA $AA,X                   ;$03AD49    |/
CODE_03AD4B:                    ;           |
    LDA.w $14D4,X               ;$03AD4B    |\ 
    BMI CODE_03AD63             ;$03AD4E    ||
    LDA $D8,X                   ;$03AD50    ||
    CMP.b #$A0                  ;$03AD52    ||
    BCC CODE_03AD63             ;$03AD54    || If on the ground (at Y = 0x00A0), increment to next phase.
    LDA.b #$A0                  ;$03AD56    ||
    STA $D8,X                   ;$03AD58    ||
    STZ $AA,X                   ;$03AD5A    ||
    LDA.b #$A0                  ;$03AD5C    ||| How long Peach waits on the ground before walking towards Mario.
    STA.w $1540,X               ;$03AD5E    ||
    INC $C2,X                   ;$03AD61    |/
CODE_03AD63:                    ;           |
    LDA $13                     ;$03AD63    |\ 
    AND.b #$07                  ;$03AD65    || Return if not a frame to spawn one of Peach's sparkles.
    BNE Return03AD73            ;$03AD67    |/
    LDY.b #$0B                  ;$03AD69    |\ 
CODE_03AD6B:                    ;           ||
    LDA.w $17F0,Y               ;$03AD6B    ||
    BEQ CODE_03AD74             ;$03AD6E    || Find an empty minor extended sprite slot and return if none found.
    DEY                         ;$03AD70    ||
    BPL CODE_03AD6B             ;$03AD71    ||
Return03AD73:                   ;           ||
    RTS                         ;$03AD73    |/ 
CODE_03AD74:                    ;           |
    LDA.b #$05                  ;$03AD74    |\\ Minor extended sprite to spawn (sparkle).
    STA.w $17F0,Y               ;$03AD76    |/
    JSL GetRand                 ;$03AD79    |\ 
    STZ $00                     ;$03AD7D    ||
    AND.b #$1F                  ;$03AD7F    ||
    CLC                         ;$03AD81    ||
    ADC.b #$F8                  ;$03AD82    ||
    BPL CODE_03AD88             ;$03AD84    ||
    DEC $00                     ;$03AD86    || Set at a random X position on Peach.
CODE_03AD88:                    ;           ||
    CLC                         ;$03AD88    ||
    ADC $E4,X                   ;$03AD89    ||
    STA.w $1808,Y               ;$03AD8B    ||
    LDA.w $14E0,X               ;$03AD8E    ||
    ADC $00                     ;$03AD91    ||
    STA.w $18EA,Y               ;$03AD93    |/
    LDA.w $148E                 ;$03AD96    |\ 
    AND.b #$1F                  ;$03AD99    ||
    ADC $D8,X                   ;$03AD9B    ||
    STA.w $17FC,Y               ;$03AD9D    || Set at a random Y position on Peach.
    LDA.w $14D4,X               ;$03ADA0    ||
    ADC.b #$00                  ;$03ADA3    ||
    STA.w $1814,Y               ;$03ADA5    |/
    LDA.b #$00                  ;$03ADA8    |\ Clear sprite Y speed (unused?).
    STA.w $1820,Y               ;$03ADAA    |/
    LDA.b #$17                  ;$03ADAD    |\ Set lifespan timer for the sparkle.
    STA.w $1850,Y               ;$03ADAF    |/
    RTS                         ;$03ADB2    |



CODE_03ADB3:                    ;-----------| Peach state 1 - Waiting after falling
    LDA.w $1540,X               ;$03ADB3    |\ 
    BNE CODE_03ADC2             ;$03ADB6    ||
    INC $C2,X                   ;$03ADB8    || If time to walk towards Mario, increment to next phase.
    JSR CODE_03ADCC             ;$03ADBA    ||  In doing so, if already on top of Mario, set flag to walk away from him.
    BCC CODE_03ADC2             ;$03ADBD    ||
    INC.w $151C,X               ;$03ADBF    |/
CODE_03ADC2:                    ;           |
    JSR SubHorzPosBnk3          ;$03ADC2    |\ 
    TYA                         ;$03ADC5    || Face Mario and Peach towards each other.
    STA.w $157C,X               ;$03ADC6    ||
    STA $76                     ;$03ADC9    |/
    RTS                         ;$03ADCB    |

CODE_03ADCC:
    JSL GetSpriteClippingA      ;$03ADCC    |
    JSL GetMarioClipping        ;$03ADD0    |
    JSL CheckForContact         ;$03ADD4    |
    RTS                         ;$03ADD8    |



DATA_03ADD9:                    ;$03ADD9    | X speeds for Mario and Peach when walking towards each other. Only the first two values seem to be used.
    db $08,$F8
    db $F8,$08

CODE_03ADDD:                    ;-----------| Peach phase 2 - Walking toward Mario
    LDA $14                     ;$03ADDD    |\ 
    AND.b #$08                  ;$03ADDF    ||
    BNE CODE_03ADE8             ;$03ADE1    || Animate Peach walking.
    LDA.b #$08                  ;$03ADE3    ||
    STA.w $1602,X               ;$03ADE5    |/
CODE_03ADE8:                    ;           |
    JSR CODE_03ADCC             ;$03ADE8    |\ 
    PHP                         ;$03ADEB    ||
    JSR SubHorzPosBnk3          ;$03ADEC    ||
    PLP                         ;$03ADEF    || Figure out how to move Peach and Mario.
    LDA.w $151C,X               ;$03ADF0    || If Peach wasn't in contact with him and still isn't, make them walk towards each other.
    BNE CODE_03ADF9             ;$03ADF3    || If Peach was in contact with him and still is, make them walk away from each other.
    BCS CODE_03AE14             ;$03ADF5    || If Peach wasn't in contact with him and now is (or was in contact and now isn't), branch to end the phase.
    BRA CODE_03ADFF             ;$03ADF7    ||
CODE_03ADF9:                    ;           ||
    BCC CODE_03AE14             ;$03ADF9    |/
    TYA                         ;$03ADFB    |\ 
    EOR.b #$01                  ;$03ADFC    ||
    TAY                         ;$03ADFE    ||
CODE_03ADFF:                    ;           ||
    LDA.w DATA_03ADD9,Y         ;$03ADFF    || Store X speed for Mario and Peach as decided.
    STA $B6,X                   ;$03AE02    ||
    EOR.b #$FF                  ;$03AE04    ||
    INC A                       ;$03AE06    ||
    STA $7B                     ;$03AE07    |/
    TYA                         ;$03AE09    |\ 
    STA.w $157C,X               ;$03AE0A    || Make Mario/Peach face the way they're walking.
    STA $76                     ;$03AE0D    |/
    JSL UpdateXPosNoGrvty       ;$03AE0F    | Update X position for Peach.
    RTS                         ;$03AE13    |

CODE_03AE14:                    ;```````````| Peach and Mario are right next to each other; end the phase.
    JSR SubHorzPosBnk3          ;$03AE14    |\ 
    TYA                         ;$03AE17    || Face Mario and Peach towards each other again.
    STA.w $157C,X               ;$03AE18    ||
    STA $76                     ;$03AE1B    |/
    INC $C2,X                   ;$03AE1D    | Increment to next phase.
    LDA.b #$60                  ;$03AE1F    |\\ How long Peach waits to kiss Mario.
    STA.w $1540,X               ;$03AE21    |/
    RTS                         ;$03AE24    |



CODE_03AE25:                    ;-----------| Peach phase 3 - Standing next to Mario
    LDA.w $1540,X               ;$03AE25    |\ Return if not time to kiss Mario.
    BNE Return03AE31            ;$03AE28    |/
    INC $C2,X                   ;$03AE2A    | Increment to next phase.
    LDA.b #$A0                  ;$03AE2C    |\ Set timer for the kiss animation.
    STA.w $1540,X               ;$03AE2E    |/
Return03AE31:                   ;           |
    RTS                         ;$03AE31    |



CODE_03AE32:                    ;-----------| Peach phase 4 - Kissing Mario
    LDA.w $1540,X               ;$03AE32    |\ 
    BNE CODE_03AE3F             ;$03AE35    || Increment to next phase if done kissing Mario.
    INC $C2,X                   ;$03AE37    ||
    STZ.w $188A                 ;$03AE39    ||\ Unused...?
    STZ.w $188B                 ;$03AE3C    |//
CODE_03AE3F:                    ;           |
    CMP.b #$50                  ;$03AE3F    |\ Return if done animating Peach's part of the kiss.
    BCC Return03AE5A            ;$03AE41    |/
    PHA                         ;$03AE43    |\ 
    BNE CODE_03AE4B             ;$03AE44    || Force timer for Peach's blink animation when the kiss ends (so Peach has her eyes closed).
    LDA.b #$14                  ;$03AE46    ||
    STA.w $154C,X               ;$03AE48    |/
CODE_03AE4B:                    ;           |
    LDA.b #$0A                  ;$03AE4B    |\\ Animation frame to use for Peach's kiss.
    STA.w $1602,X               ;$03AE4D    |/
    PLA                         ;$03AE50    |
    CMP.b #$68                  ;$03AE51    |\ 
    BNE Return03AE5A            ;$03AE53    || Set timer for Mario's blush animation when time to.
    LDA.b #$80                  ;$03AE55    ||
    STA.w $1558,X               ;$03AE57    |/
Return03AE5A:                   ;           |
    RTS                         ;$03AE5A    |



DATA_03AE5B:                    ;$03AE5B    | How long to wait between each letter.
    db $08,$08,$08,$08,$08,$08,$18,$08
    db $08,$08,$08,$08,$08,$08,$08,$08
    db $08,$08,$08,$08,$08,$08,$20,$08
    db $08,$08,$08,$08,$20,$08,$08,$10
    db $08,$08,$08,$08,$08,$08,$08,$08
    db $20,$08,$08,$08,$08,$08,$20,$08
    db $04,$20,$08,$08,$08,$08,$08,$08
    db $08,$08,$08,$08,$08,$08,$10,$08
    db $08,$08,$08,$08,$08,$08,$08,$08
    db $08,$08,$10,$08,$08,$08,$08,$08
    db $08,$08,$08,$40

CODE_03AEAF:                    ;-----------| Peach phase 5 - Displaying the "Mario's adventure..." text.
    JSR CODE_03D674             ;$03AEAF    | Write the message text so far.
    LDA.w $1540,X               ;$03AEB2    |\ Return if not time to write the next letter.
    BNE Return03AEC7            ;$03AEB5    |/
    LDY.w $1921                 ;$03AEB7    |\ 
    CPY.b #$54                  ;$03AEBA    || Branch if message is finished.
    BEQ CODE_03AEC8             ;$03AEBC    |/
    INC.w $1921                 ;$03AEBE    |\ 
    LDA.w DATA_03AE5B,Y         ;$03AEC1    || Add a new letter and set timer until the next one.
    STA.w $1540,X               ;$03AEC4    |/
Return03AEC7:                   ;           |
    RTS                         ;$03AEC7    |

CODE_03AEC8:                    ;```````````| Done with the message.
    INC $C2,X                   ;$03AEC8    | Increment to next phase.
    LDA.b #$40                  ;$03AECA    |\\ How long the game takes to fade the message away.
    STA.w $1540,X               ;$03AECC    |/
    RTS                         ;$03AECF    |



CODE_03AED0:                    ;```````````| Time to shoot fireworks.
    INC $C2,X                   ;$03AED0    | Increment to next phase (7).
    LDA.b #$80                  ;$03AED2    |\\ How long until the first firework is shot.
    STA.w $1FEB                 ;$03AED4    |/
    RTS                         ;$03AED7    |

DATA_03AED8:
    db $00,$00,$94,$18,$18,$9C,$9C,$FF
    db $00,$00,$52,$63,$63,$73,$73,$7F
 
CODE_03AEE8:                    ;-----------| Peach phase 6 - Fade text
    LDA.w $1540,X               ;$03AEE8    |\ Branch if done fading.
    BEQ CODE_03AED0             ;$03AEEB    |/
    LSR                         ;$03AEED    |\ 
    STA $00                     ;$03AEEE    ||
    STZ $01                     ;$03AEF0    || Fade the message text.
    REP #$20                    ;$03AEF2    ||
    LDA $00                     ;$03AEF4    ||\ 
    ASL                         ;$03AEF6    |||
    ASL                         ;$03AEF7    |||
    ASL                         ;$03AEF8    |||
    ASL                         ;$03AEF9    |||
    ASL                         ;$03AEFA    |||
    ORA $00                     ;$03AEFB    ||| Take current timer divided by 2 (rounded down), and multiply by 0x421.
    STA $00                     ;$03AEFD    |||
    ASL                         ;$03AEFF    ||| This gets the shade of white to use for the text currently,
    ASL                         ;$03AF00    |||  e.g. if timer is 3F (max) -> 1F -> 7FFF (full white) 
    ASL                         ;$03AF01    |||
    ASL                         ;$03AF02    |||
    ASL                         ;$03AF03    |||
    ORA $00                     ;$03AF04    |||
    STA $00                     ;$03AF06    ||/
    SEP #$20                    ;$03AF08    ||
    PHX                         ;$03AF0A    ||
    TAX                         ;$03AF0B    ||
    LDY.w $0681                 ;$03AF0C    ||
    LDA.b #$02                  ;$03AF0F    ||\ Transfer one color...
    STA.w $0682,Y               ;$03AF11    ||/
    LDA.b #$F1                  ;$03AF14    ||\ ...to color F1.
    STA.w $0683,Y               ;$03AF16    ||/
    LDA $00                     ;$03AF19    ||\ 
    STA.w $0684,Y               ;$03AF1B    ||| Write the value calculated before.
    LDA $01                     ;$03AF1E    |||
    STA.w $0685,Y               ;$03AF20    ||/
    LDA.b #$00                  ;$03AF23    ||\ Write end sentinel.
    STA.w $0686,Y               ;$03AF25    ||/
    TYA                         ;$03AF28    ||
    CLC                         ;$03AF29    ||
    ADC.b #$04                  ;$03AF2A    ||
    STA.w $0681                 ;$03AF2C    |/
    PLX                         ;$03AF2F    |
    JSR CODE_03D674             ;$03AF30    | Keep the message text written while it fades.
    RTS                         ;$03AF33    |



DATA_03AF34:                    ;$03AF34    | X offsets for the animation of the stars above Bowser's head when hurt.
    db $F4,$FF,$0C,$19,$24,$19,$0C,$FF

DATA_03AF3C:                    ;$03AF3C    | Y offsets for the animation of the stars above Bowser's head when hurt.
    db $FC,$F6,$F4,$F6,$FC,$02,$04,$02

DATA_03AF44:                    ;$03AF44    | YXPPCCCT for the animation of the stars above Bowser's head when hurt.
    db $05,$05,$05,$05,$45,$45,$45,$45

DATA_03AF4C:                    ;$03AF4C    | Y offsets for the teardrop on Bowser's head when hurt.
    db $34,$34,$34,$35,$35,$36,$36
    db $37,$38,$3A,$3E,$46,$54

CODE_03AF59:                    ;-----------| Subroutine to draw the spinning stars and teardrop above Bowser's head when hurt.
    JSR GetDrawInfoBnk3         ;$03AF59    |
    LDA.w $157C,X               ;$03AF5C    |\ $04 = horizontal direction
    STA $04                     ;$03AF5F    |/
    LDA $14                     ;$03AF61    |\ 
    LSR                         ;$03AF63    ||
    LSR                         ;$03AF64    || $02 = animation frame
    AND.b #$07                  ;$03AF65    ||
    STA $02                     ;$03AF67    |/
    LDA.b #$EC                  ;$03AF69    |\\ OAM index (from $0300) to use for the stars above Bowser's head.
    STA.w $15EA,X               ;$03AF6B    |/
    TAY                         ;$03AF6E    |
    PHX                         ;$03AF6F    |
    LDX.b #$03                  ;$03AF70    |
CODE_03AF72:                    ;```````````| Tile loop for the stars.
    PHX                         ;$03AF72    |
    TXA                         ;$03AF73    |\ 
    ASL                         ;$03AF74    ||
    ASL                         ;$03AF75    || Get index to the current tile.
    ADC $02                     ;$03AF76    ||
    AND.b #$07                  ;$03AF78    ||
    TAX                         ;$03AF7A    |/
    LDA $00                     ;$03AF7B    |\ 
    CLC                         ;$03AF7D    || Store X position to OAM.
    ADC.w DATA_03AF34,X         ;$03AF7E    ||
    STA.w $0300,Y               ;$03AF81    |/
    LDA $01                     ;$03AF84    |\ 
    CLC                         ;$03AF86    || Store Y position to OAM.
    ADC.w DATA_03AF3C,X         ;$03AF87    ||
    STA.w $0301,Y               ;$03AF8A    |/
    LDA.b #$59                  ;$03AF8D    |\\ Tile number to use for the stars above Bowser's head.
    STA.w $0302,Y               ;$03AF8F    |/
    LDA.w DATA_03AF44,X         ;$03AF92    |\ 
    ORA $64                     ;$03AF95    || Store YXPPCCCT.
    STA.w $0303,Y               ;$03AF97    |/
    PLX                         ;$03AF9A    |
    INY                         ;$03AF9B    |\ 
    INY                         ;$03AF9C    ||
    INY                         ;$03AF9D    || Loop for all four stars.
    INY                         ;$03AF9E    ||
    DEX                         ;$03AF9F    ||
    BPL CODE_03AF72             ;$03AFA0    |/
    LDA.w $14B3                 ;$03AFA2    |\ 
    INC.w $14B3                 ;$03AFA5    ||
    LSR                         ;$03AFA8    ||
    LSR                         ;$03AFA9    || Branch if not showing the teardrop on Bowser's head.
    LSR                         ;$03AFAA    ||
    CMP.b #$0D                  ;$03AFAB    ||
    BCS CODE_03AFD7             ;$03AFAD    |/
    TAX                         ;$03AFAF    |
    LDY.b #$FC                  ;$03AFB0    || OAM index (from $0300) to use for Bowser's teardrop.
    LDA $04                     ;$03AFB2    |\ 
    ASL                         ;$03AFB4    ||
    ROL                         ;$03AFB5    ||
    ASL                         ;$03AFB6    ||
    ASL                         ;$03AFB7    || Store X position to OAM.
    ASL                         ;$03AFB8    ||
    ADC $00                     ;$03AFB9    ||
    CLC                         ;$03AFBB    ||
    ADC.b #$15                  ;$03AFBC    ||
    STA.w $0300,Y               ;$03AFBE    |/
    LDA $01                     ;$03AFC1    |\ 
    CLC                         ;$03AFC3    || Store Y position to OAM.
    ADC.l DATA_03AF4C,X         ;$03AFC4    ||
    STA.w $0301,Y               ;$03AFC8    |/
    LDA.b #$49                  ;$03AFCB    |\\ Tile to use for the teardrop on Bowser's head.
    STA.w $0302,Y               ;$03AFCD    |/
    LDA.b #$07                  ;$03AFD0    |\ 
    ORA $64                     ;$03AFD2    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03AFD4    |/
CODE_03AFD7:                    ;```````````| Not drawing the teardrop.
    PLX                         ;$03AFD7    |
    LDY.b #$00                  ;$03AFD8    |\ 
    LDA.b #$04                  ;$03AFDA    || Upload 5 8x8 tiles (4 stars + teardrop).
    JSL FinishOAMWrite          ;$03AFDC    |/
    LDY.w $15EA,X               ;$03AFE0    |
    PHX                         ;$03AFE3    |
    LDX.b #$04                  ;$03AFE4    |\ 
CODE_03AFE6:                    ;           ||
    LDA.w $0300,Y               ;$03AFE6    ||
    STA.w $0200,Y               ;$03AFE9    ||
    LDA.w $0301,Y               ;$03AFEC    ||
    STA.w $0201,Y               ;$03AFEF    ||
    LDA.w $0302,Y               ;$03AFF2    ||
    STA.w $0202,Y               ;$03AFF5    ||
    LDA.w $0303,Y               ;$03AFF8    ||
    STA.w $0203,Y               ;$03AFFB    ||
    PHY                         ;$03AFFE    ||
    TYA                         ;$03AFFF    || Transfer all of the tiles just written from the $0300 range to the $0200 range.
    LSR                         ;$03B000    ||  (probably because Nintendo didn't bother to code a FinishOamWrite for that range....)
    LSR                         ;$03B001    ||
    TAY                         ;$03B002    ||
    LDA.w $0460,Y               ;$03B003    ||
    STA.w $0420,Y               ;$03B006    ||
    PLY                         ;$03B009    ||
    INY                         ;$03B00A    ||
    INY                         ;$03B00B    ||
    INY                         ;$03B00C    ||
    INY                         ;$03B00D    ||
    DEX                         ;$03B00E    ||
    BPL CODE_03AFE6             ;$03B00F    |/
    PLX                         ;$03B011    |
    RTS                         ;$03B012    |



DATA_03B013:                    ;$03B013    | X offsets (lo) for the MechaKoopas thrown by Bowser.
    db $00,$10

DATA_03B015:                    ;$03B015    | X offsets (hi) for the MechaKoopas thrown by Bowser.
    db $00,$00

DATA_03B017:                    ;$03B017    | X speeds for the MechaKoopas thrown by Bowser.
    db $F8,$08

CODE_03B019:                    ;-----------| Subroutine to spawn Bowser's MechaKoopas.
    STZ $02                     ;$03B019    |
    JSR CODE_03B020             ;$03B01B    |
    INC $02                     ;$03B01E    |
CODE_03B020:                    ;           |
    LDY.b #$01                  ;$02B020    |\ 
CODE_03B022:                    ;           ||
    LDA.w $14C8,Y               ;$03B022    ||
    BEQ CODE_03B02B             ;$03B025    || Find an empty sprite slot (in slots 0/1) and return if none found.
    DEY                         ;$03B027    ||
    BPL CODE_03B022             ;$03B028    ||
    RTS                         ;$03B02A    |/
CODE_03B02B:                    ;           |
    LDA.b #$08                  ;$03B02B    |\ 
    STA.w $14C8,Y               ;$03B02D    ||
    LDA.b #$A2                  ;$03B030    ||| Sprite to spawn (MechaKoopa).
    STA.w $009E,Y               ;$03B032    |/
    LDA $D8,X                   ;$03B035    |\ 
    CLC                         ;$03B037    ||
    ADC.b #$10                  ;$03B038    ||
    STA.w $00D8,Y               ;$03B03A    || Spawn at Bowser's Y position.
    LDA.w $14D4,X               ;$03B03D    ||
    ADC.b #$00                  ;$03B040    ||
    STA.w $14D4,Y               ;$03B042    |/
    LDA $E4,X                   ;$03B045    |\ 
    STA $00                     ;$03B047    ||
    LDA.w $14E0,X               ;$03B049    ||
    STA $01                     ;$03B04C    ||
    PHX                         ;$03B04E    ||
    LDX $02                     ;$03B04F    ||
    LDA $00                     ;$03B051    || Spawn at Bowser's X position, offset to either side.
    CLC                         ;$03B053    ||
    ADC.w DATA_03B013,X         ;$03B054    ||
    STA.w $00E4,Y               ;$03B057    ||
    LDA $01                     ;$03B05A    ||
    ADC.w DATA_03B015,X         ;$03B05C    ||
    STA.w $14E0,Y               ;$03B05F    |/
    TYX                         ;$03B062    |
    JSL InitSpriteTables        ;$03B063    |
    LDY $02                     ;$03B067    |\ 
    LDA.w DATA_03B017,Y         ;$03B069    || Store initial X speed.
    STA $B6,X                   ;$03B06C    |/
    LDA.b #$C0                  ;$03B06E    |\\ Y speed Bowser throws the MechaKoopas with.
    STA $AA,X                   ;$03B070    |/
    PLX                         ;$03B072    |
    RTS                         ;$03B073    |



DATA_03B074:                    ;$03B074    | X speeds to give Mario when he runs into Bowser's car normally.
    db $40,$C0

DATA_03B076:                    ;$03B076    | X speeds to give Mario when he runs into Bowser's car while it's attacking (MechaKoopa/Bowling Balls).
    db $10,$F0

CODE_03B078:                    ;-----------| Subroutine to process interaction for Bowser and his car with Mario.
    LDA $38                     ;$03B078    |\ 
    CMP.b #$20                  ;$03B07A    || Return if Bowser isn't exactly scaled to 0x20 (i.e. he's zooming in/out).
    BNE Return03B0DB            ;$03B07C    |/
    LDA.w $151C,X               ;$03B07E    |\ 
    CMP.b #$07                  ;$03B081    || Return if not in an attack phase.
    BCC Return03B0F2            ;$03B083    |/
    LDA $36                     ;$03B085    |\ 
    ORA $37                     ;$03B087    || Return if Bowser is rotated at all (e.g. hurt animation, dropping a Bowling Ball).
    BNE Return03B0F2            ;$03B089    |/
    JSR CODE_03B0DC             ;$03B08B    | Process interaction with MechaKoopas.
    LDA.w $154C,X               ;$03B08E    |\ Return if contact is disabled with Mario.
    BNE Return03B0DB            ;$03B091    |/
    LDA.b #$24                  ;$03B093    |\ Change sprite clipping (for interaction with the actual car).
    STA.w $1662,X               ;$03B095    |/
    JSL MarioSprInteract        ;$03B098    |\ Return if Mario isn't in contact with the car.
    BCC CODE_03B0BD             ;$03B09C    |/
    JSR CODE_03B0D6             ;$03B09E    | Disable additional contact with Mario.
    STZ $7D                     ;$03B0A1    | Clear Mario's Y speed.
    JSR SubHorzPosBnk3          ;$03B0A3    |\ 
    LDA.w $14B1                 ;$03B0A6    ||
    ORA.w $14B6                 ;$03B0A9    ||
    BEQ CODE_03B0B3             ;$03B0AC    ||
    LDA.w DATA_03B076,Y         ;$03B0AE    || Push Mario away from the car.
    BRA CODE_03B0B6             ;$03B0B1    ||  Speed Mario is pushed depends on whether the car is moving normally or attacking (with MechaKoopas or a bowling ball)
CODE_03B0B3:                    ;           ||
    LDA.w DATA_03B074,Y         ;$03B0B3    ||
CODE_03B0B6:                    ;           ||
    STA $7B                     ;$03B0B6    |/
    LDA.b #$01                  ;$03B0B8    |\ SFX for Mario hitting Bowser's car.
    STA.w $1DF9                 ;$03B0BA    |/
CODE_03B0BD:                    ;           |
    INC.w $1662,X               ;$03B0BD    |\ 
    JSL MarioSprInteract        ;$03B0C0    || If Mario is in contact with Bowser, hurt him, and disable additional contact with Mario.
    BCC CODE_03B0C9             ;$03B0C4    ||
    JSR CODE_03B0D2             ;$03B0C6    |/
CODE_03B0C9:                    ;           |
    INC.w $1662,X               ;$03B0C9    |\ 
    JSL MarioSprInteract        ;$03B0CC    ||
    BCC Return03B0DB            ;$03B0D0    ||
CODE_03B0D2:                    ;           || If Mario is in contact with Bowser's propeller, hurt him, and disable additional contact with Mario.
    JSL HurtMario               ;$03B0D2    ||
CODE_03B0D6:                    ;           ||
    LDA.b #$20                  ;$03B0D6    ||
    STA.w $154C,X               ;$03B0D8    |/
Return03B0DB:                   ;           |
    RTS                         ;$03B0DB    |


CODE_03B0DC:                    ;-----------| Subroutine to process interaction between Bowser and MechaKoopas.
    LDY.b #$01                  ;$03B0DC    |\ 
CODE_03B0DE:                    ;           ||
    PHY                         ;$03B0DE    ||
    LDA.w $14C8,Y               ;$03B0DF    ||
    CMP.b #$09                  ;$03B0E2    ||
    BNE CODE_03B0EE             ;$03B0E4    ||
    LDA.w $15A0,Y               ;$03B0E6    || Loop through the two MechaKoopa slots and run the below code for any that exist and aren't offscreen.
    BNE CODE_03B0EE             ;$03B0E9    ||
    JSR CODE_03B0F3             ;$03B0EB    ||
CODE_03B0EE:                    ;           ||
    PLY                         ;$03B0EE    ||
    DEY                         ;$03B0EF    ||
    BPL CODE_03B0DE             ;$03B0F0    ||
Return03B0F2:                   ;           ||
    RTS                         ;$03B0F2    |/

CODE_03B0F3:                    ;```````````| MechaKoopa found.
    PHX                         ;$03B0F3    |
    TYX                         ;$03B0F4    |
    JSL GetSpriteClippingB      ;$03B0F5    |\ 
    PLX                         ;$03B0F9    ||
    LDA.b #$24                  ;$03B0FA    ||
    STA.w $1662,X               ;$03B0FC    || Branch if in contact with the car (not the top!).
    JSL GetSpriteClippingA      ;$03B0FF    ||
    JSL CheckForContact         ;$03B103    ||
    BCS CODE_03B142             ;$03B107    |/
    INC.w $1662,X               ;$03B109    |\ 
    JSL GetSpriteClippingA      ;$03B10C    || Return if not in contact with Bowser either.
    JSL CheckForContact         ;$03B110    ||
    BCC Return03B160            ;$03B114    |/
    LDA.w $14B5                 ;$03B116    |\ Return if Bowser is already in his hurt state.
    BNE Return03B160            ;$03B119    |/
    LDA.b #$4C                  ;$03B11B    |\\ How long Bowser's hurt animation lasts.
    STA.w $14B5                 ;$03B11D    |/
    STZ.w $14B3                 ;$03B120    |
    LDA.w $151C,X               ;$03B123    |\ Track the phase that was just defeated (for changing music later).
    STA.w $14B4                 ;$03B126    |/
    LDA.b #$28                  ;$03B129    |\ SFX for hitting Bowser with a MechaKoopa.
    STA.w $1DFC                 ;$03B12B    |/
    LDA.w $151C,X               ;$03B12E    |\ 
    CMP.b #$09                  ;$03B131    ||
    BNE CODE_03B142             ;$03B133    ||
    LDA.w $187B,X               ;$03B135    ||
    CMP.b #$01                  ;$03B138    || If Bowser was hit in attack phase 3 on his last hit, kill all of the remaining MechaKoopas.
    BNE CODE_03B142             ;$03B13A    ||
    PHY                         ;$03B13C    ||
    JSL KillMostSprites         ;$03B13D    ||
    PLY                         ;$03B141    |/
CODE_03B142:                    ;```````````| MechaKoopa hit the car, not Bowser.
    LDA.b #$00                  ;$03B142    |\ Clear its X speed.
    STA.w $00B6,Y               ;$03B144    |/
    PHX                         ;$03B147    |\ 
    LDX.b #$10                  ;$03B148    ||| Y speed to give the MechaKoopa when it hits Bowser while moving up.
    LDA.w $00AA,Y               ;$03B14A    || 
    BMI CODE_03B151             ;$03B14D    ||
    LDX.b #$D0                  ;$03B14F    ||| Y speed to give the MechaKoopa when it hits Bowser while moving down.
CODE_03B151:                    ;           ||
    TXA                         ;$03B151    ||
    STA.w $00AA,Y               ;$03B152    |/
    LDA.b #$02                  ;$03B155    |\ Kill the MechaKoopa.
    STA.w $14C8,Y               ;$03B157    |/
    TYX                         ;$03B15A    |
    JSL DispContactSpr          ;$03B15B    | Display a contact sprite at the MechaKoopa's position.
    PLX                         ;$03B15F    |
Return03B160:                   ;           |
    RTS                         ;$03B160    |





BowserBallSpeed:                ;$03B161    | X speeds for Bowser's bowling ball.
    db $10,$F0

    ; Bowser's Bowling Ball misc RAM:
    ; $1570 - Frame counter for animating the ball's shine. Increments or decrements depending on the direction the ball is rolling.
    
BowserBowlingBall:              ;-----------| Bowser's Bowling Ball MAIN
    JSR BowserBallGfx           ;$03B163    | Draw GFX.
    LDA $9D                     ;$03B166    |\ Return if game frozen.
    BNE Return03B1D4            ;$03B168    |/
    JSR SubOffscreen0Bnk3       ;$03B16A    | Process offscreen from -$40 to +$30.
    JSL MarioSprInteract        ;$03B16D    | Process interaction with Mario.
    JSL UpdateXPosNoGrvty       ;$03B171    | Update X position.
    JSL UpdateYPosNoGrvty       ;$03B175    | Update Y position.
    LDA $AA,X                   ;$03B179    |\ 
    CMP.b #$40                  ;$03B17B    ||
    BPL CODE_03B186             ;$03B17D    || Handle Y speed.
    CLC                         ;$03B17F    ||
    ADC.b #$03                  ;$03B180    ||| Vertical acceleration for the Bowling ball.
    STA $AA,X                   ;$03B182    ||
    BRA CODE_03B18A             ;$03B184    ||
CODE_03B186:                    ;           ||
    LDA.b #$40                  ;$03B186    ||
    STA $AA,X                   ;$03B188    |/
CODE_03B18A:                    ;           |
    LDA $AA,X                   ;$03B18A    |\ 
    BMI CODE_03B1C5             ;$03B18C    ||
    LDA.w $14D4,X               ;$03B18E    ||
    BMI CODE_03B1C5             ;$03B191    || Branch if the ball isn't at the "ground" position, or it's already moving upwards.
    LDA $D8,X                   ;$03B193    ||
    CMP.b #$B0                  ;$03B195    ||
    BCC CODE_03B1C5             ;$03B197    |/
    LDA.b #$B0                  ;$03B199    |\ Lock the ball to the "ground" position. 
    STA $D8,X                   ;$03B19B    |/
    LDA $AA,X                   ;$03B19D    |\ 
    CMP.b #$3E                  ;$03B19F    || Branch if the ball isn't falling fast enough for the large bounce.
    BCC CODE_03B1AD             ;$03B1A1    ||
    LDY.b #$25                  ;$03B1A3    ||\ SFX for Bowser's ball's first bounce (the "slam").
    STY.w $1DFC                 ;$03B1A5    ||/
    LDY.b #$20                  ;$03B1A8    ||\ How long the screen shakes after the bowling ball slams the ground.
    STY.w $1887                 ;$03B1AA    |//
CODE_03B1AD:                    ;           |
    CMP.b #$08                  ;$03B1AD    |\ 
    BCC CODE_03B1B6             ;$03B1AF    || Branch if not falling fast enough for the smaller bounce.
    LDA.b #$01                  ;$03B1B1    ||\ SFX for Bowser's bowling ball's second bounce.
    STA.w $1DF9                 ;$03B1B3    |//
CODE_03B1B6:                    ;           |
    JSR CODE_03B7F8             ;$03B1B6    | Handle bouncing the ball.
    LDA $B6,X                   ;$03B1B9    |\ 
    BNE CODE_03B1C5             ;$03B1BB    ||
    JSR SubHorzPosBnk3          ;$03B1BD    || If the sprite doesn't already have an X speed set, make it move towards Mario.
    LDA.w BowserBallSpeed,Y     ;$03B1C0    ||
    STA $B6,X                   ;$03B1C3    |/
CODE_03B1C5:                    ;           |
    LDA $B6,X                   ;$03B1C5    |\ Return if the ball still has no X speed (i.e. it's still in the initial fall from Bowser's clown car).
    BEQ Return03B1D4            ;$03B1C7    |/
    BMI CODE_03B1D1             ;$03B1C9    |\ 
    DEC.w $1570,X               ;$03B1CB    ||
    DEC.w $1570,X               ;$03B1CE    || Handle timing the rolling animation.
CODE_03B1D1:                    ;           ||
    INC.w $1570,X               ;$03B1D1    |/
Return03B1D4:                   ;           |
    RTS                         ;$03B1D4    |



BowserBallDispX:                ;$03B1D5    | X offsets for each tile of Bowser's bowling ball.
    db $F0,$00,$10,$F0,$00,$10,$F0,$00
    db $10,$00,$00,$F8

BowserBallDispY:                ;$03B1E1    | Y offsets for each tile of Bowser's bowling ball.
    db $E2,$E2,$E2,$F2,$F2,$F2,$02,$02
    db $02,$02,$02,$EA

BowserBallTiles:                ;$03B1ED    | Tile numbers for each tile of Bowser's bowling ball.
    db $45,$47,$45,$65,$66,$65,$45,$47
    db $45,$39,$38,$63

BowserBallGfxProp:              ;$03B1F9    | YXPPCCCT for each tile of Bowser's bowling ball.
    db $0D,$0D,$4D,$0D,$0D,$4D,$8D,$8D
    db $CD,$0D,$0D,$0D

BowserBallTileSize:             ;$03B205    | Tile size for each tile of Bowser's bowling ball.
    db $02,$02,$02,$02,$02,$02,$02,$02
    db $02,$00,$00,$02

BowserBallDispX2:               ;$03B211    | X offsets for animation fo the "shine" on Bowser's bowling ball.
    db $04,$0D,$10,$0D,$04,$FB,$F8,$FB

BowserBallDispY2:               ;$03B21D    | Y offsets for animation fo the "shine" on Bowser's bowling ball.
    db $00,$FD,$F4,$EB,$E8,$EB,$F4,$FD

BowserBallGfx:                  ;-----------| Bowser's bowling ball GFX routine
    LDA.b #$70                  ;$03B221    |\\ OAM index (from $0300) for Bowser's bowling ball.
    STA.w $15EA,X               ;$03B223    |/
    JSR GetDrawInfoBnk3         ;$03B226    |
    PHX                         ;$03B229    |
    LDX.b #$0B                  ;$03B22A    |
CODE_03B22C:                    ;```````````| Tile loop.
    LDA $00                     ;$03B22C    |\ 
    CLC                         ;$03B22E    || Store X position to OAM.
    ADC.w BowserBallDispX,X     ;$03B22F    ||
    STA.w $0300,Y               ;$03B232    |/
    LDA $01                     ;$03B235    |\ 
    CLC                         ;$03B237    || Store Y position to OAM.
    ADC.w BowserBallDispY,X     ;$03B238    ||
    STA.w $0301,Y               ;$03B23B    |/
    LDA.w BowserBallTiles,X     ;$03B23E    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$03B241    |/
    LDA.w BowserBallGfxProp,X   ;$03B244    |\ 
    ORA $64                     ;$03B247    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03B249    |/
    PHY                         ;$03B24C    |
    TYA                         ;$03B24D    |\ 
    LSR                         ;$03B24E    ||
    LSR                         ;$03B24F    || Store tile size to OAM.
    TAY                         ;$03B250    ||
    LDA.w BowserBallTileSize,X  ;$03B251    ||
    STA.w $0460,Y               ;$03B254    |/
    PLY                         ;$03B257    |
    INY                         ;$03B258    |\ 
    INY                         ;$03B259    ||
    INY                         ;$03B25A    || Loop for all of the tiles.
    INY                         ;$03B25B    ||
    DEX                         ;$03B25C    ||
    BPL CODE_03B22C             ;$03B25D    |/
    PLX                         ;$03B25F    |
    PHX                         ;$03B260    |
    LDY.w $15EA,X               ;$03B261    |
    LDA.w $1570,X               ;$03B264    |\ 
    LSR                         ;$03B267    ||
    LSR                         ;$03B268    ||
    LSR                         ;$03B269    || Get index for the animation of the ball's "shine" tiles.
    AND.b #$07                  ;$03B26A    ||
    PHA                         ;$03B26C    ||
    TAX                         ;$03B26D    |/
    LDA.w $0304,Y               ;$03B26E    |\ 
    CLC                         ;$03B271    || Change X position of the second tile in OAM.
    ADC.w BowserBallDispX2,X    ;$03B272    ||
    STA.w $0304,Y               ;$03B275    |/
    LDA.w $0305,Y               ;$03B278    |\ 
    CLC                         ;$03B27B    || Change Y position of the second tile in OAM.
    ADC.w BowserBallDispY2,X    ;$03B27C    ||
    STA.w $0305,Y               ;$03B27F    |/
    PLA                         ;$03B282    |
    CLC                         ;$03B283    |
    ADC.b #$02                  ;$03B284    |
    AND.b #$07                  ;$03B286    |
    TAX                         ;$03B288    |
    LDA.w $0308,Y               ;$03B289    |\ 
    CLC                         ;$03B28C    || Change X position of the third tile in OAM.
    ADC.w BowserBallDispX2,X    ;$03B28D    ||
    STA.w $0308,Y               ;$03B290    |/
    LDA.w $0309,Y               ;$03B293    |\ 
    CLC                         ;$03B296    || Change Y position of the third tile in OAM.
    ADC.w BowserBallDispY2,X    ;$03B297    ||
    STA.w $0309,Y               ;$03B29A    |/
    PLX                         ;$03B29D    |
    LDA.b #$0B                  ;$03B29E    |\ 
    LDY.b #$FF                  ;$03B2A0    || Upload 12 manually-sized tiles.
    JSL FinishOAMWrite          ;$03B2A2    |/
    RTS                         ;$03B2A6    |





MechakoopaSpeed:                ;$03B2A7    | X speeds for the MechaKoopa.
    db $08,$F8

    ; MechaKoopa misc RAM:
    ; $C2   - Frame counter for deciding when to turn towards Mario.
    ; $1540 - Timer to wait before returning a stunned MechaKoopa to normal.
    ; $1570 - Frame counter for animation,
    ; $157C - Horizontal direction the sprite is facing.
    ; $1602 - Animation frame. 0/1/2/3 = walking, 4 = being stunned, 5 = stunned
    ; $1FE2 - Timer set after hitting a block in its stunned state.

MechaKoopa:                     ;-----------| MechaKoopa MAIN
    JSL CODE_03B307             ;$03B2A9    | Draw GFX.
    LDA.w $14C8,X               ;$03B2AD    |\ 
    CMP.b #$08                  ;$03B2B0    ||
    BNE Return03B306            ;$03B2B2    || Return if dying or game frozen.
    LDA $9D                     ;$03B2B4    ||
    BNE Return03B306            ;$03B2B6    |/
    JSR SubOffscreen0Bnk3       ;$03B2B8    | Process offscreen from -$40 to +$30.
    JSL SprSprPMarioSprRts      ;$03B2BB    | Process interaction with Mario and other sprites.
    JSL UpdateSpritePos         ;$03B2BF    | Update X/Y position, apply gravity, and process block interaction.
    LDA.w $1588,X               ;$03B2C3    |\ 
    AND.b #$04                  ;$03B2C6    || Branch if not on the ground.
    BEQ CODE_03B2E3             ;$03B2C8    ||
    STZ $AA,X                   ;$03B2CA    ||
    LDY.w $157C,X               ;$03B2CC    ||\ 
    LDA.w MechakoopaSpeed,Y     ;$03B2CF    ||| Set X speed.
    STA $B6,X                   ;$03B2D2    ||/
    LDA $C2,X                   ;$03B2D4    ||\ 
    INC $C2,X                   ;$03B2D6    |||
    AND.b #$3F                  ;$03B2D8    |||
    BNE CODE_03B2E3             ;$03B2DA    ||| Every 64 frames, turn towards Mario.
    JSR SubHorzPosBnk3          ;$03B2DC    |||
    TYA                         ;$03B2DF    |||
    STA.w $157C,X               ;$03B2E0    |//
CODE_03B2E3:                    ;           |
    LDA.w $1588,X               ;$03B2E3    |\ 
    AND.b #$03                  ;$03B2E6    ||
    BEQ CODE_03B2F9             ;$03B2E8    ||
    LDA $B6,X                   ;$03B2EA    ||
    EOR.b #$FF                  ;$03B2EC    || If hitting a wall, invert X speed and facing direction.
    INC A                       ;$03B2EE    ||
    STA $B6,X                   ;$03B2EF    ||
    LDA.w $157C,X               ;$03B2F1    ||
    EOR.b #$01                  ;$03B2F4    ||
    STA.w $157C,X               ;$03B2F6    |/
CODE_03B2F9:                    ;           |
    INC.w $1570,X               ;$03B2F9    |\ 
    LDA.w $1570,X               ;$03B2FC    ||
    AND.b #$0C                  ;$03B2FF    || Animate the MechaKoopa's walk animation.
    LSR                         ;$03B301    ||
    LSR                         ;$03B302    ||
    STA.w $1602,X               ;$03B303    |/
Return03B306:                   ;           |
    RTS                         ;$03B306    |


CODE_03B307:                    ;-----------| MechaKoopa GFX routine.
    PHB                         ;$03B307    |
    PHK                         ;$03B308    |
    PLB                         ;$03B309    |
    JSR MechaKoopaGfx           ;$03B30A    |
    PLB                         ;$03B30D    |
    RTL                         ;$03B30E    |

MechakoopaDispX:                ;$03B30F    | X offsets for the MechaKoopa, indexed by its direction.
    db $F8,$08,$F8,$00
    db $08,$00,$10,$00

MechakoopaDispY:                ;$03B317    | Y offsets for each frame of the MechaKoopa.
    db $F8,$F8,$08,$00
    db $F9,$F9,$09,$00
    db $F8,$F8,$08,$00
    db $F9,$F9,$09,$00
    db $FD,$00,$05,$00
    db $00,$00,$08,$00

MechakoopaTiles:                ;$03B32F    | Tile numbers for each frame of the MechaKoopa.
    db $40,$42,$60,$51
    db $40,$42,$60,$0A
    db $40,$42,$60,$0C
    db $40,$42,$60,$0E
    db $00,$02,$10,$01
    db $00,$02,$10,$01

MechakoopaGfxProp:              ;$03B347    | YXPPCCCT for the MechaKoopa, indexed by its direction.
    db $00,$00,$00,$00
    db $40,$40,$40,$40

MechakoopaTileSize:             ;$03B34F    | Tile sizes for each tile of the MechaKoopa.
    db $02,$00,$00,$02

MechakoopaPalette:              ;$03B353    | YXPPCCCT for the MechaKoopa to flash between when its stun timer runs low.
    db $0B,$05

MechaKoopaGfx:                  ;-----------| Actual MechaKoopa GFX routine.
    LDA.b #$0B                  ;$03B355    |\\ Normal YXPPCCCT for the MechaKoopa.
    STA.w $15F6,X               ;$03B357    |/
    LDA.w $1540,X               ;$03B35A    |\ Branch if not stunned.
    BEQ CODE_03B37F             ;$03B35D    |/
    LDY.b #$05                  ;$03B35F    |\ 
    CMP.b #$05                  ;$03B361    ||
    BCC CODE_03B369             ;$03B363    ||
    CMP.b #$FA                  ;$03B365    ||
    BCC CODE_03B36B             ;$03B367    || Animate the MechaKoopa's key.
CODE_03B369:                    ;           ||
    LDY.b #$04                  ;$03B369    ||
CODE_03B36B:                    ;           ||
    TYA                         ;$03B36B    ||
    STA.w $1602,X               ;$03B36C    |/
    LDA.w $1540,X               ;$03B36F    |\ 
    CMP.b #$30                  ;$03B372    ||
    BCS CODE_03B37F             ;$03B374    ||
    AND.b #$01                  ;$03B376    || Animate the MechaKoopa's palette as its stun tiemr runs low.
    TAY                         ;$03B378    ||
    LDA.w MechakoopaPalette,Y   ;$03B379    ||
    STA.w $15F6,X               ;$03B37C    |/
CODE_03B37F:                    ;```````````| Not stunned.
    JSR GetDrawInfoBnk3         ;$03B37F    |
    LDA.w $15F6,X               ;$03B382    |\ $04 = YXPPCCCT
    STA $04                     ;$03B385    |/
    TYA                         ;$03B387    |
    CLC                         ;$03B388    |
    ADC.b #$0C                  ;$03B389    |
    TAY                         ;$03B38B    |
    LDA.w $1602,X               ;$03B38C    |\ 
    ASL                         ;$03B38F    || $03 = animation frame
    ASL                         ;$03B390    ||
    STA $03                     ;$03B391    |/
    LDA.w $157C,X               ;$03B393    |\ 
    ASL                         ;$03B396    ||
    ASL                         ;$03B397    || $02 = horizontal direction
    EOR.b #$04                  ;$03B398    ||
    STA $02                     ;$03B39A    |/
    PHX                         ;$03B39C    |
    LDX.b #$03                  ;$03B39D    |
CODE_03B39F:                    ;```````````| Tile loop
    PHX                         ;$03B39F    |
    PHY                         ;$03B3A0    |
    TYA                         ;$03B3A1    |\ 
    LSR                         ;$03B3A2    ||
    LSR                         ;$03B3A3    || Store size to OAM.
    TAY                         ;$03B3A4    ||
    LDA.w MechakoopaTileSize,X  ;$03B3A5    ||
    STA.w $0460,Y               ;$03B3A8    |/
    PLY                         ;$03B3AB    |
    PLA                         ;$03B3AC    |\ 
    PHA                         ;$03B3AD    ||
    CLC                         ;$03B3AE    ||
    ADC $02                     ;$03B3AF    ||
    TAX                         ;$03B3B1    || Store X position to OAM.
    LDA $00                     ;$03B3B2    ||
    CLC                         ;$03B3B4    ||
    ADC.w MechakoopaDispX,X     ;$03B3B5    ||
    STA.w $0300,Y               ;$03B3B8    |/
    LDA.w MechakoopaGfxProp,X   ;$03B3BB    |\ 
    ORA $04                     ;$03B3BE    || Store YXPPCCCT to OAM.
    ORA $64                     ;$03B3C0    ||
    STA.w $0303,Y               ;$03B3C2    |/
    PLA                         ;$03B3C5    |\ 
    PHA                         ;$03B3C6    ||
    CLC                         ;$03B3C7    ||
    ADC $03                     ;$03B3C8    || Store tile number to OAM.
    TAX                         ;$03B3CA    ||
    LDA.w MechakoopaTiles,X     ;$03B3CB    ||
    STA.w $0302,Y               ;$03B3CE    |/
    LDA $01                     ;$03B3D1    |\ 
    CLC                         ;$03B3D3    || Store Y position to OAM.
    ADC.w MechakoopaDispY,X     ;$03B3D4    ||
    STA.w $0301,Y               ;$03B3D7    |/
    PLX                         ;$03B3DA    |
    DEY                         ;$03B3DB    |\ 
    DEY                         ;$03B3DC    ||
    DEY                         ;$03B3DD    || Loop for all four tiles.
    DEY                         ;$03B3DE    ||
    DEX                         ;$03B3DF    ||
    BPL CODE_03B39F             ;$03B3E0    |/
    PLX                         ;$03B3E2    |
    LDY.b #$FF                  ;$03B3E3    |\ 
    LDA.b #$03                  ;$03B3E5    || Uplaod 4 manually-sized tiles.
    JSL FinishOAMWrite          ;$03B3E7    |/
    JSR MechaKoopaKeyGfx        ;$03B3EB    | Draw the MechaKoopa's key.
    RTS                         ;$03B3EE    |


MechaKeyDispX:                  ;$03B3EF    | X offsets for the MechaKoopa's key, indexed by its direction.
    db $F9,$0F

MechaKeyGfxProp:                ;$03B3F1    | YXPPCCCT for the MechaKoopa's key, indexed by its direction.
    db $4D,$0D

MechaKeyTiles:                  ;$03B3F3    | Tile numbers for each frame animation for the MechaKoopa's key.
    db $70,$71,$72,$71

MechaKoopaKeyGfx:               ;-----------| GFX subroutine for the MechaKoopa's key.
    LDA.w $15EA,X               ;$03B3F7    |
    CLC                         ;$03B3FA    |
    ADC.b #$10                  ;$03B3FB    |
    STA.w $15EA,X               ;$03B3FD    |
    JSR GetDrawInfoBnk3         ;$03B400    |
    PHX                         ;$03B403    |
    LDA.w $1570,X               ;$03B404    |\ 
    LSR                         ;$03B407    ||
    LSR                         ;$03B408    || $02 = animation frame
    AND.b #$03                  ;$03B409    ||
    STA $02                     ;$03B40B    |/
    LDA.w $157C,X               ;$03B40D    |\ 
    TAX                         ;$03B410    ||
    LDA $00                     ;$03B411    || Store X position to OAM.
    CLC                         ;$03B413    ||
    ADC.w MechaKeyDispX,X       ;$03B414    ||
    STA.w $0300,Y               ;$03B417    |/
    LDA $01                     ;$03B41A    |\ 
    SEC                         ;$03B41C    || Store Y position to OAM.
    SBC.b #$00                  ;$03B41D    ||
    STA.w $0301,Y               ;$03B41F    |/
    LDA.w MechaKeyGfxProp,X     ;$03B422    |\ 
    ORA $64                     ;$03B425    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03B427    |/
    LDX $02                     ;$03B42A    |\ 
    LDA.w MechaKeyTiles,X       ;$03B42C    || Store tile number to OAM.
    STA.w $0302,Y               ;$03B42F    |/
    PLX                         ;$03B432    |
    LDY.b #$00                  ;$03B433    |\ 
    LDA.b #$00                  ;$03B435    || Uplaod 1 8x8 tile.
    JSL FinishOAMWrite          ;$03B437    |/
    RTS                         ;$03B43B    |





CODE_03B43C:                    ;-----------| Subroutine to draw the Bowser room graphics.
    JSR BowserItemBoxGfx        ;$03B43C    | Draw Mario's item box.
    JSR BowserSceneGfx          ;$03B43F    | Draw the room.
    RTS                         ;$03B442    |



BowserItemBoxPosX:              ;$03B443    | X offsets for each tile of Mario's item box in Bowser's room.
    db $70,$80,$70,$80

BowserItemBoxPosY:              ;$03B447    | Y offsets for each tile of Mario's item box in Bowser's room.
    db $07,$07,$17,$17

BowserItemBoxProp:              ;$03B44B    | Tile numbers for each tile of Mario's item box in Bowser's room.
    db $37,$77,$B7,$F7

BowserItemBoxGfx:               ;-----------| Subroutine to set up Mario's item box in Bowser's boss room.
    LDA.w $190D                 ;$03B44F    |\ 
    BEQ CODE_03B457             ;$03B452    ||
    STZ.w $0DC2                 ;$03B454    || Return if Mario has no item or Bowser has been defeated.
CODE_03B457:                    ;           ||
    LDA.w $0DC2                 ;$03B457    ||
    BEQ Return03B48B            ;$03B45A    |/
    PHX                         ;$03B45C    |
    LDX.b #$03                  ;$03B45D    |
    LDY.b #$04                  ;$03B45F    || OAM index (from $0200) to use for Mario's item box in Bowser's room.
CODE_03B461:                    ;           |
    LDA.w BowserItemBoxPosX,X   ;$03B461    |\ Store X position to OAM.
    STA.w $0200,Y               ;$03B464    |/
    LDA.w BowserItemBoxPosY,X   ;$03B467    |\ Store Y position to OAM.
    STA.w $0201,Y               ;$03B46A    |/
    LDA.b #$43                  ;$03B46D    |\\ Tile to use for the item box in Bowser's room.
    STA.w $0202,Y               ;$03B46F    |/
    LDA.w BowserItemBoxProp,X   ;$03B472    |\ Store YXPPCCCT to OAM.
    STA.w $0203,Y               ;$03B475    |/
    PHY                         ;$03B478    |
    TYA                         ;$03B479    |\ 
    LSR                         ;$03B47A    ||
    LSR                         ;$03B47B    || Set size as 16x16.
    TAY                         ;$03B47C    ||
    LDA.b #$02                  ;$03B47D    ||
    STA.w $0420,Y               ;$03B47F    |/
    PLY                         ;$03B482    |
    INY                         ;$03B483    |\ 
    INY                         ;$03B484    ||
    INY                         ;$03B485    || Loop for all four tiles.
    INY                         ;$03B486    ||
    DEX                         ;$03B487    ||
    BPL CODE_03B461             ;$03B488    |/
    PLX                         ;$03B48A    |
Return03B48B:                   ;           |
    RTS                         ;$03B48B    |



BowserRoofPosX:                 ;$03B48C    | X offsets for additional tiles for the floor of Bowser's room.
    db $00,$30,$60,$90,$C0,$F0              ; Merlons
    db $00,$30,$40,$50,$60                  ; Support columns
    db $90,$A0,$B0,$C0,$F0

BowserRoofPosY:                 ;$03B49C    | Y offsets for additional tiles for the floor of Bowser's room.
    db $B0,$B0,$B0,$B0,$B0,$B0              ; Merlons
    db $D0,$D0,$D0,$D0,$D0                  ; Support columns
    db $D0,$D0,$D0,$D0,$D0

BowserSceneGfx:                 ;-----------| Subroutine to set up Bowser's boss room.
    PHX                         ;$03B4AC    |
    LDY.b #$BC                  ;$03B4AD    |\\ OAM index (from $0300) for the floor of Bowser's room when Bowser is still alive.
    STZ $01                     ;$03B4AF    ||
    LDA.w $190D                 ;$03B4B1    ||
    STA $0F                     ;$03B4B4    || Get OAM index for the floor of Bowser's room.
    CMP.b #$01                  ;$03B4B6    ||  For some reason, it also has one less tile uploaded after Bowser is defeated (not sure why).
    LDX.b #$10                  ;$03B4B8    ||
    BCC CODE_03B4BF             ;$03B4BA    ||
    LDY.b #$90                  ;$03B4BC    ||| OAM index (from $0300) for the floor of Bowser's room after Bowser is defeated.
    DEX                         ;$03B4BE    |/
CODE_03B4BF:                    ;```````````| Tile loop for the floor of Bowser's room.
    LDA.b #$C0                  ;$03B4BF    |\ 
    SEC                         ;$03B4C1    || Store Y position to OAM.
    SBC $1C                     ;$03B4C2    ||
    STA.w $0301,Y               ;$03B4C4    |/
    LDA $01                     ;$03B4C7    |\ 
    SEC                         ;$03B4C9    ||
    SBC $1A                     ;$03B4CA    ||
    STA.w $0300,Y               ;$03B4CC    || Store X position to OAM.
    CLC                         ;$03B4CF    ||
    ADC.b #$10                  ;$03B4D0    ||
    STA $01                     ;$03B4D2    |/
    LDA.b #$08                  ;$03B4D4    |\\ Tile to use for the floor of Bowser's room.
    STA.w $0302,Y               ;$03B4D6    |/
    LDA.b #$0D                  ;$03B4D9    |\ 
    ORA $64                     ;$03B4DB    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03B4DD    |/
    PHY                         ;$03B4E0    |
    TYA                         ;$03B4E1    |\ 
    LSR                         ;$03B4E2    ||
    LSR                         ;$03B4E3    || Store size to OAM as 16x16.
    TAY                         ;$03B4E4    ||
    LDA.b #$02                  ;$03B4E5    ||
    STA.w $0460,Y               ;$03B4E7    |/
    PLY                         ;$03B4EA    |
    INY                         ;$03B4EB    |\ 
    INY                         ;$03B4EC    ||
    INY                         ;$03B4ED    || Loop for all of the tiles.
    INY                         ;$03B4EE    ||
    DEX                         ;$03B4EF    ||
    BPL CODE_03B4BF             ;$03B4F0    |/
    LDX.b #$0F                  ;$03B4F2    |
    LDA $0F                     ;$03B4F4    |\ Branch if Bowser has been defeated, to use the $0300 range of OAM.
    BNE CODE_03B532             ;$03B4F6    |/
    LDY.b #$14                  ;$03B4F8    || OAM index (from $0200) for the extra tiles in Bowser's room while Bowser is still alive.
CODE_03B4FA:                    ;```````````| Tile loop for additional tiles in Bowser's room.
    LDA.w BowserRoofPosX,X      ;$03B4FA    |\ 
    SEC                         ;$03B4FD    || Store X position to OAM.
    SBC $1A                     ;$03B4FE    ||
    STA.w $0200,Y               ;$03B500    |/
    LDA.w BowserRoofPosY,X      ;$03B503    |\ 
    SEC                         ;$03B506    || Store Y position to OAM.
    SBC $1C                     ;$03B507    ||
    STA.w $0201,Y               ;$03B509    |/
    LDA.b #$08                  ;$03B50C    |\\ Tile to use for the support columns of Bowser's floor.
    CPX.b #$06                  ;$03B50E    ||
    BCS CODE_03B514             ;$03B510    ||
    LDA.b #$03                  ;$03B512    ||| Tile to use for the merlons on Bowser's floor.
CODE_03B514:                    ;           ||
    STA.w $0202,Y               ;$03B514    |/
    LDA.b #$0D                  ;$03B517    |\ 
    ORA $64                     ;$03B519    || Store YXPPCCCT to OAM.
    STA.w $0203,Y               ;$03B51B    |/
    PHY                         ;$03B51E    |
    TYA                         ;$03B51F    |\ 
    LSR                         ;$03B520    ||
    LSR                         ;$03B521    || Store size to OAM as 16x16.
    TAY                         ;$03B522    ||
    LDA.b #$02                  ;$03B523    ||
    STA.w $0420,Y               ;$03B525    |/
    PLY                         ;$03B528    |
    INY                         ;$03B529    |\ 
    INY                         ;$03B52A    ||
    INY                         ;$03B52B    || Loop for all tiles.
    INY                         ;$03B52C    ||
    DEX                         ;$03B52D    ||
    BPL CODE_03B4FA             ;$03B52E    |/
    BRA CODE_03B56A             ;$03B530    |


CODE_03B532:                    ;```````````| Using the $0300 OAM range for Bowser's extra floor tiles.
    LDY.b #$50                  ;$03B532    || OAM index (from $0300) for the extra tiles in Bowser's room after Bowser has been defeated.
CODE_03B534:                    ;```````````| Alternate tile loop for additional tiles in Bowser's room.
    LDA.w BowserRoofPosX,X      ;$03B534    |\ 
    SEC                         ;$03B537    || Store X position to OAM.
    SBC $1A                     ;$03B538    ||
    STA.w $0300,Y               ;$03B53A    |/
    LDA.w BowserRoofPosY,X      ;$03B53D    |\ 
    SEC                         ;$03B540    || Store Y position to OAM.
    SBC $1C                     ;$03B541    ||
    STA.w $0301,Y               ;$03B543    |/
    LDA.b #$08                  ;$03B546    |\\ Tile to use for the support columns of Bowser's floor.
    CPX.b #$06                  ;$03B548    ||
    BCS CODE_03B54E             ;$03B54A    ||
    LDA.b #$03                  ;$03B54C    ||| Tile to use for the merlons on Bowser's floor.
CODE_03B54E:                    ;           ||
    STA.w $0302,Y               ;$03B54E    |/
    LDA.b #$0D                  ;$03B551    |\ 
    ORA $64                     ;$03B553    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03B555    |/
    PHY                         ;$03B558    |
    TYA                         ;$03B559    |\ 
    LSR                         ;$03B55A    ||
    LSR                         ;$03B55B    || Store size to OAM as 16x16.
    TAY                         ;$03B55C    ||
    LDA.b #$02                  ;$03B55D    ||
    STA.w $0460,Y               ;$03B55F    |/
    PLY                         ;$03B562    |
    INY                         ;$03B563    |\ 
    INY                         ;$03B564    ||
    INY                         ;$03B565    || Loop for all of the tiles.
    INY                         ;$03B566    ||
    DEX                         ;$03B567    ||
    BPL CODE_03B534             ;$03B568    |/
CODE_03B56A:                    ;           |
    PLX                         ;$03B56A    |
    RTS                         ;$03B56B    |





SprClippingDispX:               ;$03B56C    | X displacement of each sprite clipping.
    db $02,$02,$10,$14,$00,$00,$01,$08
    db $F8,$FE,$03,$06,$01,$00,$06,$02
    db $00,$E8,$FC,$FC,$04,$00,$FC,$02
    db $02,$02,$02,$02,$00,$02,$E0,$F0
    db $FC,$FC,$00,$F8,$F4,$F2,$00,$FC
    db $F2,$F0,$02,$00,$F8,$04,$02,$02
    db $08,$00,$00,$00,$FC,$03,$08,$00
    db $08,$04,$F8,$00

SprClippingWidth:               ;$03B5A8    | Width of each sprite clipping.
    db $0C,$0C,$10,$08,$30,$50,$0E,$28
    db $20,$14,$01,$03,$0D,$0F,$14,$24
    db $0F,$40,$08,$08,$18,$0F,$18,$0C
    db $0C,$0C,$0C,$0C,$0A,$1C,$30,$30
    db $08,$08,$10,$20,$38,$3C,$20,$18
    db $1C,$20,$0C,$10,$10,$08,$1C,$1C
    db $10,$30,$30,$40,$08,$12,$34,$0F
    db $20,$08,$20,$10

SprClippingDispY:               ;$03B5E4    | Y displacement of each sprite clipping.
    db $03,$03,$FE,$08,$FE,$FE,$02,$08
    db $FE,$08,$07,$06,$FE,$FC,$06,$FE
    db $FE,$E8,$10,$10,$02,$FE,$F4,$08
    db $13,$23,$33,$43,$0A,$FD,$F8,$FC
    db $E8,$10,$00,$E8,$20,$04,$58,$FC
    db $E8,$FC,$F8,$02,$F8,$04,$FE,$FE
    db $F2,$FE,$FE,$FE,$FC,$00,$08,$F8
    db $10,$03,$10,$00

SprClippingHeight:              ;$03B620    | Height of each sprite clipping.
    db $0A,$15,$12,$08,$0E,$0E,$18,$30
    db $10,$1E,$02,$03,$16,$10,$14,$12
    db $20,$40,$34,$74,$0C,$0E,$18,$45
    db $3A,$2A,$1A,$0A,$30,$1B,$20,$12
    db $18,$18,$10,$20,$38,$14,$08,$18
    db $28,$1B,$13,$4C,$10,$04,$22,$20
    db $1C,$12,$12,$12,$08,$20,$2E,$14
    db $28,$0A,$10,$0D

MairoClipDispY:                 ;$03B65C    | Mario Y displacement from his actual position, for sprite interaction.
    db $06,$14,$10,$18                      ; Order is big, small, big on Yoshi, small on Yoshi.

MarioClippingHeight:            ;$03B660    | Mario's height, for sprite interaction.
    db $1A,$0C,$20,$18                      ; Same order as above.

    ; Scratch RAM returns:
    ; $00 - Clipping X displacement lo
    ; $01 - Clipping Y displacement lo
    ; $02 - Clipping width
    ; $03 - Clipping height
    ; $08 - Clipping X displacement hi
    ; $09 - Clipping Y displacement hi

GetMarioClipping:               ;-----------| Get player clipping routine. Stores clipping data for Mario's hitbox (as sprite B).
    PHX                         ;$03B664    |
    LDA $94                     ;$03B665    |\ 
    CLC                         ;$03B667    ||
    ADC.b #$02                  ;$03B668    ||
    STA $00                     ;$03B66A    || Get clipping X position, offset 2 pixels right.
    LDA $95                     ;$03B66C    ||
    ADC.b #$00                  ;$03B66E    ||
    STA $08                     ;$03B670    |/
    LDA.b #$0C                  ;$03B672    |\\ Width of Mario's sprite interaction hitbox.
    STA $02                     ;$03B674    |/
    LDX.b #$00                  ;$03B676    |
    LDA $73                     ;$03B678    |
    BNE CODE_03B680             ;$03B67A    |
    LDA $19                     ;$03B67C    |\\ Use 16x16 hitbox if small, 16x32 otherwise. 
    BNE CODE_03B681             ;$03B67E    ||| [change BNE to LDA to always have 16x16, or to BRA to always have 16x32. Use with $00EB79 and $01B4C0]
CODE_03B680:                    ;           |||
    INX                         ;$03B680    ||/
CODE_03B681:                    ;           ||
    LDA.w $187A                 ;$03B681    ||\ 
    BEQ CODE_03B688             ;$03B684    ||| Increase hitbox size if riding Yoshi.
    INX                         ;$03B686    |||
    INX                         ;$03B687    ||/
CODE_03B688:                    ;           ||
    LDA.l MarioClippingHeight,X ;$03B688    ||
    STA $03                     ;$03B68C    |/
    LDA $96                     ;$03B68E    |\ 
    CLC                         ;$03B690    ||
    ADC.l MairoClipDispY,X      ;$03B691    ||
    STA $01                     ;$03B695    || Set clipping Y position.
    LDA $97                     ;$03B697    ||
    ADC.b #$00                  ;$03B699    ||
    STA $09                     ;$03B69B    |/
    PLX                         ;$03B69D    |
    RTL                         ;$03B69E    |



    ; Scratch RAM returns:
    ; $04 - Clipping X displacement, low
    ; $05 - Clipping Y displacement, low
    ; $06 - Clipping width
    ; $07 - Clipping height
    ; $0A - Clipping X displacement, high
    ; $0B - Clipping Y displacement, high

GetSpriteClippingA:             ;-----------| Get sprite clipping A routine. Stores clipping data for the hitbox of the sprite slot in X.
    PHY                         ;$03B69F    |
    PHX                         ;$03B6A0    |
    TXY                         ;$03B6A1    |
    LDA.w $1662,X               ;$03B6A2    |
    AND.b #$3F                  ;$03B6A5    |
    TAX                         ;$03B6A7    |
    STZ $0F                     ;$03B6A8    |
    LDA.l SprClippingDispX,X    ;$03B6AA    |
    BPL CODE_03B6B2             ;$03B6AE    |
    DEC $0F                     ;$03B6B0    |
CODE_03B6B2:                    ;           |
    CLC                         ;$03B6B2    |
    ADC.w $00E4,Y               ;$03B6B3    |
    STA $04                     ;$03B6B6    |
    LDA.w $14E0,Y               ;$03B6B8    |
    ADC $0F                     ;$03B6BB    |
    STA $0A                     ;$03B6BD    |
    LDA.l SprClippingWidth,X    ;$03B6BF    |
    STA $06                     ;$03B6C3    |
    STZ $0F                     ;$03B6C5    |
    LDA.l SprClippingDispY,X    ;$03B6C7    |
    BPL CODE_03B6CF             ;$03B6CB    |
    DEC $0F                     ;$03B6CD    |
CODE_03B6CF:                    ;           |
    CLC                         ;$03B6CF    |
    ADC.w $00D8,Y               ;$03B6D0    |
    STA $05                     ;$03B6D3    |
    LDA.w $14D4,Y               ;$03B6D5    |
    ADC $0F                     ;$03B6D8    |
    STA $0B                     ;$03B6DA    |
    LDA.l SprClippingHeight,X   ;$03B6DC    |
    STA $07                     ;$03B6E0    |
    PLX                         ;$03B6E2    |
    PLY                         ;$03B6E3    |
    RTL                         ;$03B6E4    |



    ; Scratch RAM returns:
    ; $00 - Clipping X displacement, low
    ; $01 - Clipping Y displacement, low
    ; $02 - Clipping width
    ; $03 - Clipping height
    ; $08 - Clipping X displacement, high
    ; $09 - Clipping Y displacement, high

GetSpriteClippingB:             ;-----------| Get sprite clipping B routine. Stores clipping data for the hitbox of a second sprite slot in X.
    PHY                         ;$03B6E5    |
    PHX                         ;$03B6E6    |
    TXY                         ;$03B6E7    |
    LDA.w $1662,X               ;$03B6E8    |
    AND.b #$3F                  ;$03B6EB    |
    TAX                         ;$03B6ED    |
    STZ $0F                     ;$03B6EE    |
    LDA.l SprClippingDispX,X    ;$03B6F0    |
    BPL CODE_03B6F8             ;$03B6F4    |
    DEC $0F                     ;$03B6F6    |
CODE_03B6F8:                    ;           |
    CLC                         ;$03B6F8    |
    ADC.w $00E4,Y               ;$03B6F9    |
    STA $00                     ;$03B6FC    |
    LDA.w $14E0,Y               ;$03B6FE    |
    ADC $0F                     ;$03B701    |
    STA $08                     ;$03B703    |
    LDA.l SprClippingWidth,X    ;$03B705    |
    STA $02                     ;$03B709    |
    STZ $0F                     ;$03B70B    |
    LDA.l SprClippingDispY,X    ;$03B70D    |
    BPL CODE_03B715             ;$03B711    |
    DEC $0F                     ;$03B713    |
CODE_03B715:                    ;           |
    CLC                         ;$03B715    |
    ADC.w $00D8,Y               ;$03B716    |
    STA $01                     ;$03B719    |
    LDA.w $14D4,Y               ;$03B71B    |
    ADC $0F                     ;$03B71E    |
    STA $09                     ;$03B720    |
    LDA.l SprClippingHeight,X   ;$03B722    |
    STA $03                     ;$03B726    |
    PLX                         ;$03B728    |
    PLY                         ;$03B729    |
    RTL                         ;$03B72A    |



CheckForContact:                ;-----------| Check for contact routine. Returns carry set if so, clear if not.
    PHX                         ;$03B72B    |  Run two of the three above routines first,
    LDX.b #$01                  ;$03B72C    |  or one of the codes at $02A519 / $02A547. 
CODE_03B72E:                    ;           |
    LDA $00,X                   ;$03B72E    |\ 
    SEC                         ;$03B730    ||
    SBC $04,X                   ;$03B731    ||
    PHA                         ;$03B733    ||
    LDA $08,X                   ;$03B734    ||
    SBC $0A,X                   ;$03B736    || Return no contact if not on the same screen.
    STA $0C                     ;$03B738    ||
    PLA                         ;$03B73A    ||
    CLC                         ;$03B73B    ||
    ADC.b #$80                  ;$03B73C    ||
    LDA $0C                     ;$03B73E    ||
    ADC.b #$00                  ;$03B740    ||
    BNE CODE_03B75A             ;$03B742    |/
    LDA $04,X                   ;$03B744    |\ 
    SEC                         ;$03B746    ||
    SBC $00,X                   ;$03B747    ||
    CLC                         ;$03B749    ||
    ADC $06,X                   ;$03B74A    ||
    STA $0F                     ;$03B74C    || Return no contact if too far apart.
    LDA $02,X                   ;$03B74E    ||
    CLC                         ;$03B750    ||
    ADC $06,X                   ;$03B751    ||
    CMP $0F                     ;$03B753    ||
    BCC CODE_03B75A             ;$03B755    |/
    DEX                         ;$03B757    |\ Loop for horizontal.
    BPL CODE_03B72E             ;$03B758    |/
CODE_03B75A:                    ;           |
    PLX                         ;$03B75A    |
    RTL                         ;$03B75B    |





DATA_03B75C:                    ;$03B75C    | Y position offsets to the bottom of a sprite, for checking if offscreen.
    db $0C,$1C

DATA_03B75E:                    ;$03B75E    | Bits to set in $186C, for each tile of a two-tile sprite.
    db $01,$02

    ; Misc RAM returns:
    ; Y   = OAM index (from $0300)
    ; $00 = Sprite X position relative to the screen border
    ; $01 = Sprite Y position relative to the screen border
    ; Also sets $15A0, $15C4, and $186C.

GetDrawInfoBnk3:                ;-----------| GetDrawInfo routine. Sets various graphical flags, including offscreen flags. 
    STZ.w $186C,X               ;$03B760    |\ Initialize offscreen flags.
    STZ.w $15A0,X               ;$03B763    |/
    LDA $E4,X                   ;$03B766    |\ 
    CMP $1A                     ;$03B768    ||
    LDA.w $14E0,X               ;$03B76A    || Check if offscreen horizontally, and set the flag if so.
    SBC $1B                     ;$03B76D    ||
    BEQ CODE_03B774             ;$03B76F    ||
    INC.w $15A0,X               ;$03B771    |/
CODE_03B774:                    ;           |
    LDA.w $14E0,X               ;$03B774    |\ 
    XBA                         ;$03B777    ||
    LDA $E4,X                   ;$03B778    ||
    REP #$20                    ;$03B77A    ||
    SEC                         ;$03B77C    ||
    SBC $1A                     ;$03B77D    ||
    CLC                         ;$03B77F    || Handle horizontal offscreen flag for 4 tiles offscreen. (-40 to +40)
    ADC.w #$0040                ;$03B780    ||  If so, return the sprite's graphical routine.
    CMP.w #$0180                ;$03B783    ||
    SEP #$20                    ;$03B786    ||
    ROL                         ;$03B788    ||
    AND.b #$01                  ;$03B789    ||
    STA.w $15C4,X               ;$03B78B    ||
    BNE CODE_03B7CF             ;$03B78E    |/
    LDY.b #$00                  ;$03B790    |\ 
    LDA.w $1662,X               ;$03B792    ||
    AND.b #$20                  ;$03B795    ||
    BEQ CODE_03B79A             ;$03B797    ||
    INY                         ;$03B799    ||
CODE_03B79A:                    ;           ||
    LDA $D8,X                   ;$03B79A    ||
    CLC                         ;$03B79C    ||
    ADC.w DATA_03B75C,Y         ;$03B79D    || Check if vertically offscreen, and set the flag if so.
    PHP                         ;$03B7A0    ||  Due to a typo (?), if a sprite uses sprite clipping 20+, $186C's bits will be set for two different tiles.
    CMP $1C                     ;$03B7A1    ||   First ("top") tile = bit 0
    ROL $00                     ;$03B7A3    ||   Second ("bottom") tile = bit 1
    PLP                         ;$03B7A5    ||
    LDA.w $14D4,X               ;$03B7A6    ||  Likely was supposed to be $190F instead of $1662, as in Bank 1's GFX routine.
    ADC.b #$00                  ;$03B7A9    ||   Fortunately for Nintendo, there don't seem to be any negative consequences of this.
    LSR $00                     ;$03B7AB    ||
    SBC $1D                     ;$03B7AD    ||
    BEQ CODE_03B7BA             ;$03B7AF    ||
    LDA.w $186C,X               ;$03B7B1    ||
    ORA.w DATA_03B75E,Y         ;$03B7B4    ||
    STA.w $186C,X               ;$03B7B7    ||
CODE_03B7BA:                    ;           ||
    DEY                         ;$03B7BA    ||
    BPL CODE_03B79A             ;$03B7BB    |/
    LDY.w $15EA,X               ;$03B7BD    |\ 
    LDA $E4,X                   ;$03B7C0    ||
    SEC                         ;$03B7C2    ||
    SBC $1A                     ;$03B7C3    ||
    STA $00                     ;$03B7C5    || Return onscreen position in $00 and $01, and OAM index in Y.
    LDA $D8,X                   ;$03B7C7    ||
    SEC                         ;$03B7C9    ||
    SBC $1C                     ;$03B7CA    ||
    STA $01                     ;$03B7CC    |/
    RTS                         ;$03B7CE    |

CODE_03B7CF:                    ;```````````| Sprite more than 4 tiles offscreen.
    PLA                         ;$03B7CF    |\ Return the sprite's routine (i.e. don't draw).
    PLA                         ;$03B7D0    |/
    RTS                         ;$03B7D1    |





DATA_03B7D2:                    ;$03B7D2    | Y speeds to bounce Bowser's bowling ball with, indexed by its Y speed on hitting the ground.
    db $00,$00,$00,$F8,$F8,$F8,$F8,$F8      ; 00 - Unused
    db $F8,$F7,$F6,$F5,$F4,$F3,$F2,$E8
    db $E8,$E8,$E8
    db $00,$00,$00,$00,$FE,$FC,$F8,$EC      ; 13 - Bowser's bowling ball
    db $EC,$EC,$E8,$E4,$E0,$DC,$D8,$D4
    db $D0,$CC,$C8

CODE_03B7F8:                    ;-----------| Subroutine to handle bouncing Bowser's bowling ball.
    LDA $AA,X                   ;$03B7F8    |\ 
    PHA                         ;$03B7FA    ||
    STZ $AA,X                   ;$03B7FB    ||
    PLA                         ;$03B7FD    || Get index to the above table for the height to bounce with.
    LSR                         ;$03B7FE    ||
    LSR                         ;$03B7FF    ||
    TAY                         ;$03B800    ||
    LDA $9E,X                   ;$03B801    ||\ 
    CMP.b #$A1                  ;$03B803    |||
    BNE CODE_03B80C             ;$03B805    ||| Increase index by 0x13 for Bowser's bowling ball...?
    TYA                         ;$03B807    |||  Apparently some other sprite used this routine at some point, too (Goomba maybe?).
    CLC                         ;$03B808    |||
    ADC.b #$13                  ;$03B809    |||
    TAY                         ;$03B80B    |//
CODE_03B80C:                    ;           |
    LDA.w DATA_03B7D2,Y         ;$03B80C    |\ 
    LDY.w $1588,X               ;$03B80F    || Store speed when if the ball has hit the ground.
    BMI Return03B816            ;$03B812    ||
    STA $AA,X                   ;$03B814    |/
Return03B816:                   ;           |
    RTS                         ;$03B816    |





    ; Equivalent routine in bank 1 at $01AD30, bank 2 at $02848D.
SubHorzPosBnk3:                 ;-----------| Subroutine to check horizontal proximity of Mario to a sprite.
    LDY.b #$00                  ;$03B817    |  Returns the side in Y (0 = right) and distance in $0F.
    LDA $94                     ;$03B819    |
    SEC                         ;$03B81B    |
    SBC $E4,X                   ;$03B81C    |
    STA $0F                     ;$03B81E    |
    LDA $95                     ;$03B820    |
    SBC.w $14E0,X               ;$03B822    |
    BPL Return03B828            ;$03B825    |
    INY                         ;$03B827    |
Return03B828:                   ;           |
    RTS                         ;$03B828    |





    ; Equivalent routine in bank 1 at $01AD42, and bank 2 at $02D50C.
SubVertPosBnk3:                 ;-----------| Subroutine to check vertical proximity of Mario to a sprite.
    LDY.b #$00                  ;$03B829    |  Returns the side in Y (0 = below) and distance in $0F.
    LDA $96                     ;$03B82B    |
    SEC                         ;$03B82D    | Note that that this returns in $0F, not $0E like the other SubVertPos routines.
    SBC $D8,X                   ;$03B82E    |  This was probably not intentional, since all the routines that use this
    STA $0F                     ;$03B830    |   actually still expect the result to be in $0E (and either just get lucky or don't actually work).
    LDA $97                     ;$03B832    |  As such, you can safely patch a fix to make it $0E without issue.
    SBC.w $14D4,X               ;$03B834    |
    BPL Return03B83A            ;$03B837    |
    INY                         ;$03B839    |
Return03B83A:                   ;           |
    RTS                         ;$03B83A    |





DATA_03B83B:                    ;           |
    db $40,$B0

DATA_03B83D:                    ;           |
    db $01,$FF

DATA_03B83F:                    ;$03B83F    | Low bytes for offscreen processing distances in bank 03.
    db $30,$C0,$A0,$80,$A0,$40,$60,$B0
DATA_03B847:                    ;$03B847    | High bytes for offscreen processing distances in bank 03.
    db $01,$FF,$01,$FF,$01,$00,$01,$FF

SubOffscreen3Bnk3:              ;-----------| SubOffscreenX7 routine. Processes sprites offscreen from -$50 to +$60 ($FFB0,$0160).
    LDA.b #$06                  ;$03B84F    |
    BRA CODE_03B859             ;$03B851    |

SubOffscreen2Bnk3:              ;-----------| SubOffscreenX6 routine. Processes sprites offscreen from $40 to +$A0 ($0040,$01A0).
    LDA.b #$04                  ;$03B853    | Unused in SMW. And yes, this stops processing in the middle of the visible screen.
    BRA CODE_03B859             ;$03B855    |

SubOffscreen1Bnk3:              ;-----------| SubOffscreenX5 routine. Processes sprites offscreen from -$80 to +$A0 ($01A0,$FF80).
    LDA.b #$02                  ;$03B857    | Unused in SMW.
CODE_03B859:                    ;           |
    STA $03                     ;$03B859    |
    BRA CODE_03B85F             ;$03B85B    |

SubOffscreen0Bnk3:              ;-----------| SubOffscreenX0 routine. Processes sprites offscreen from -$40 to +$30 ($0130,$FFC0).
    STZ $03                     ;$03B85D    |
CODE_03B85F:                    ;           |
    JSR IsSprOffScreenBnk3      ;$03B85F    |
    BEQ Return03B8C2            ;$03B862    |
    LDA $5B                     ;$03B864    |
    AND.b #$01                  ;$03B866    |
    BNE OffscreenVertBnk3       ;$03B868    |
    LDA $D8,X                   ;$03B86A    |
    CLC                         ;$03B86C    |
    ADC.b #$50                  ;$03B86D    |
    LDA.w $14D4,X               ;$03B86F    |
    ADC.b #$00                  ;$03B872    |
    CMP.b #$02                  ;$03B874    |
    BPL OffScrEraseSprBnk3      ;$03B876    |
    LDA.w $167A,X               ;$03B878    |
    AND.b #$04                  ;$03B87B    |
    BNE Return03B8C2            ;$03B87D    |
    LDA $13                     ;$03B87F    |
    AND.b #$01                  ;$03B881    |
    ORA $03                     ;$03B883    |
    STA $01                     ;$03B885    |
    TAY                         ;$03B887    |
    LDA $1A                     ;$03B888    |
    CLC                         ;$03B88A    |
    ADC.w DATA_03B83F,Y         ;$03B88B    |
    ROL $00                     ;$03B88E    |
    CMP $E4,X                   ;$03B890    |
    PHP                         ;$03B892    |
    LDA $1B                     ;$03B893    |
    LSR $00                     ;$03B895    |
    ADC.w DATA_03B847,Y         ;$03B897    |
    PLP                         ;$03B89A    |
    SBC.w $14E0,X               ;$03B89B    |
    STA $00                     ;$03B89E    |
    LSR $01                     ;$03B8A0    |
    BCC CODE_03B8A8             ;$03B8A2    |
    EOR.b #$80                  ;$03B8A4    |
    STA $00                     ;$03B8A6    |
CODE_03B8A8:                    ;           |
    LDA $00                     ;$03B8A8    |
    BPL Return03B8C2            ;$03B8AA    |
OffScrEraseSprBnk3:             ;           |
    LDA.w $14C8,X               ;$03B8AC    |
    CMP.b #$08                  ;$03B8AF    |
    BCC OffScrKillSprBnk3       ;$03B8B1    |
    LDY.w $161A,X               ;$03B8B3    |
    CPY.b #$FF                  ;$03B8B6    |
    BEQ OffScrKillSprBnk3       ;$03B8B8    |
    LDA.b #$00                  ;$03B8BA    |
    STA.w $1938,Y               ;$03B8BC    |
OffScrKillSprBnk3:              ;           |
    STZ.w $14C8,X               ;$03B8BF    |
Return03B8C2:                   ;           |
    RTS                         ;$03B8C2    |

OffscreenVertBnk3:
    LDA.w $167A,X               ;$03B8C3    |
    AND.b #$04                  ;$03B8C6    |
    BNE Return03B8C2            ;$03B8C8    |
    LDA $13                     ;$03B8CA    |
    LSR                         ;$03B8CC    |
    BCS Return03B8C2            ;$03B8CD    |
    AND.b #$01                  ;$03B8CF    |
    STA $01                     ;$03B8D1    |
    TAY                         ;$03B8D3    |
    LDA $1C                     ;$03B8D4    |
    CLC                         ;$03B8D6    |
    ADC.w DATA_03B83B,Y         ;$03B8D7    |
    ROL $00                     ;$03B8DA    |
    CMP $D8,X                   ;$03B8DC    |
    PHP                         ;$03B8DE    |
    LDA.w $1D                   ;$03B8DF    |
    LSR $00                     ;$03B8E2    |
    ADC.w DATA_03B83D,Y         ;$03B8E4    |
    PLP                         ;$03B8E7    |
    SBC.w $14D4,X               ;$03B8E8    |
    STA $00                     ;$03B8EB    |
    LDY $01                     ;$03B8ED    |
    BEQ CODE_03B8F5             ;$03B8EF    |
    EOR.b #$80                  ;$03B8F1    |
    STA $00                     ;$03B8F3    |
CODE_03B8F5:                    ;           |
    LDA $00                     ;$03B8F5    |
    BPL Return03B8C2            ;$03B8F7    |
    BMI OffScrEraseSprBnk3      ;$03B8F9    |
IsSprOffScreenBnk3:             ;           |
    LDA.w $15A0,X               ;$03B8FB    |
    ORA.w $186C,X               ;$03B8FE    |
    RTS                         ;$03B901    |





MagiKoopaPals:                  ;$03B902    | Magikoopa palettes. Affects palette F, colors 0-7.
    dw $7FFF,$294A,$0000,$1400              ; 8 palettes of 8 colors each, including the transparent color.
    dw $2000,$7E92,$000A,$002A
    dw $7FFF,$35AD,$0000,$2400
    dw $2C00,$722F,$000D,$00AD
    dw $7FFF,$4210,$0000,$3000
    dw $3800,$65CC,$0050,$0110
    dw $7FFF,$4E73,$0000,$3C00
    dw $4441,$5969,$00B3,$0173
    dw $7FFF,$5AD6,$0000,$4800
    dw $50A4,$4D06,$0116,$01D6
    dw $7FFF,$6739,$0000,$5442
    dw $5D07,$40A3,$0179,$0239
    dw $7FFF,$739C,$0000,$60A5
    dw $696A,$3440,$01DC,$029C
    dw $7FFF,$7FFF,$0000,$6D08
    dw $75CD,$2800,$023F,$02FF



BooBossPals:                    ;$03B982    | Big Boo Boss palette animation. Also used for the reappearing ghosts.
    dw $7FFF,$0C63,$0000,$0C00              ; 8 palettes of 8 colors each, including the transparent color.
    dw $0C00,$0C00,$0C00,$0003
    dw $7FFF,$1CE7,$0000,$1C00
    dw $1C00,$1C20,$1C81,$0007
    dw $7FFF,$2D6B,$0000,$2C00
    dw $2C40,$2CA2,$2D05,$000B
    dw $7FFF,$3DEF,$0000,$3C60
    dw $3CC3,$3D26,$3D89,$000F
    dw $7FFF,$4E73,$0000,$4CE4
    dw $4D47,$4DAA,$4E0D,$1013
    dw $7FFF,$5EF7,$0000,$5D68
    dw $5DCB,$5E2E,$5E91,$2017
    dw $7FFF,$6F7B,$0000,$6DEC
    dw $6E4F,$6EB2,$6F15,$301B
    dw $7FFF,$7FFF,$0000,$7E70
    dw $7ED3,$7F36,$7F99,$401F





Empty03BA02:                    ;$03BA02    | Empty. LM sticks various hijacks in this block.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $03BA50 - Used by LM as a hijack to $049199 for determining whether an overworld level is enterable.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF

    db $FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $03BB20 - Used by LM for its level name hijack.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $03BB90 - Used by LM for its message box text hijack.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $03BC7F - Used by LM as a table of message box stripe headers (first 2 bytes) for each line.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ;  With Lunar Magic's overworld level expansion, this table is shifted a bit earlier, to $03BC79.

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $03BC8F - Unused?
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $03BCC0 - Used by LM for a 16-byte table related to ExAnimation.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $03BCD0 - Unused?
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $03BE80 - Used by LM as 16-bit pointers to each message box's text.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ;  Indexed by ((level * 2) + message number) * 2.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; Note: if LM's overworld level expansion is applied, this table is moved to read3($03BBD9).
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ;  Instead, this table used for the initial level flags (moved from $05DDA0).
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ;  The remainder of the table ($03BF80 onwards) is then left unused for now.
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF





GenTileFromSpr2:                ;-----------| Routine to generate a tile at a sprite's position, +8 pixels left and down.
    STA $9C                     ;$03C000    |
    LDA $E4,X                   ;$03C002    |
    SEC                         ;$03C004    |
    SBC.b #$08                  ;$03C005    |
    STA $9A                     ;$03C007    |
    LDA.w $14E0,X               ;$03C009    |
    SBC.b #$00                  ;$03C00C    |
    STA $9B                     ;$03C00E    |
    LDA $D8,X                   ;$03C010    |
    CLC                         ;$03C012    |
    ADC.b #$08                  ;$03C013    |
    STA $98                     ;$03C015    |
    LDA.w $14D4,X               ;$03C017    |
    ADC.b #$00                  ;$03C01A    |
    STA $99                     ;$03C01C    |
    JSL GenerateTile            ;$03C01E    |
    RTL                         ;$03C022    |





CODE_03C023:                    ;-----------| Routine to feed Baby Yoshi, which gets used when the 'double-eat' glitch occurs.
    PHB                         ;$03C023    |  Otherwise, it's just a duplicate of $01A288.
    PHK                         ;$03C024    |
    PLB                         ;$03C025    |
    JSR CODE_03C02F             ;$03C026    |
    PLB                         ;$03C029    |
    RTL                         ;$03C02A    |

DATA_03C02B:                    ;$03C02B    | Sprite numbers that each value of the roulette sprite corresponds to.
    db $74,$75,$77,$76

CODE_03C02F:
    LDY.w $160E,X               ;$03C02F    |\ 
    LDA.b #$00                  ;$03C032    || Erase the sprite being eaten.
    STA.w $14C8,Y               ;$03C034    |/
    LDA.b #$06                  ;$03C037    |\ SFX for baby Yoshi swallowing.
    STA.w $1DF9                 ;$03C039    |/
    LDA.w $160E,Y               ;$03C03C    |\ If the sprite has $160E set (i.e. it's a berry, not a mushroom), don't grow instantly.
    BNE CODE_03C09B             ;$03C03F    |/
    LDA.w $009E,Y               ;$03C041    |\ 
    CMP.b #$81                  ;$03C044    ||
    BNE CODE_03C054             ;$03C046    ||
    LDA $14                     ;$03C048    ||
    LSR                         ;$03C04A    || If eating sprite 81 (roulette item), get the actual powerup being eaten.
    LSR                         ;$03C04B    ||
    LSR                         ;$03C04C    ||
    LSR                         ;$03C04D    ||
    AND.b #$03                  ;$03C04E    ||
    TAY                         ;$03C050    ||
    LDA.w DATA_03C02B,Y         ;$03C051    |/
CODE_03C054:                    ;           |
    CMP.b #$74                  ;$03C054    |\ 
    BCC CODE_03C09B             ;$03C056    || If baby Yoshi eats a powerup, instantly grow. Else, branch.
    CMP.b #$78                  ;$03C058    ||
    BCS CODE_03C09B             ;$03C05A    |/
CODE_03C05C:                    ;           |
    STZ.w $18AC                 ;$03C05C    |
    STZ.w $141E                 ;$03C05F    |
    LDA.b #$35                  ;$03C062    |\ 
    STA.w $9E,X                 ;$03C064    || Make a grown Yoshi.
    LDA.b #$08                  ;$03C067    ||
    STA.w $14C8,X               ;$03C069    |/
    LDA.b #$1F                  ;$03C06C    |\ SFX for Yoshi growing up.
    STA.w $1DFC                 ;$03C06E    |/
    LDA $D8,X                   ;$03C071    |\ 
    SBC.b #$10                  ;$03C073    ||
    STA $D8,X                   ;$03C075    || Spawn the adult Yoshi a tile higher than the baby Yoshi.
    LDA.w $14D4,X               ;$03C077    ||
    SBC.b #$00                  ;$03C07A    ||
    STA.w $14D4,X               ;$03C07C    |/
    LDA.w $15F6,X               ;$03C07F    |
    PHA                         ;$03C082    |
    JSL InitSpriteTables        ;$03C083    |
    PLA                         ;$03C087    |
    AND.b #$FE                  ;$03C088    |
    STA.w $15F6,X               ;$03C08A    |
    LDA.b #$0C                  ;$03C08D    |\ Set initial animation frame for the growing animation.
    STA.w $1602,X               ;$03C08F    |/
    DEC.w $160E,X               ;$03C092    |
    LDA.b #$40                  ;$03C095    |\\ How long Yoshi's growing animation lasts.
    STA.w $18E8                 ;$03C097    |/
    RTS                         ;$03C09A    |

CODE_03C09B:
    INC.w $1570,X               ;$03C09B    |\ 
    LDA.w $1570,X               ;$03C09E    ||
    CMP.b #$05                  ;$03C0A1    ||| Number of sprites baby Yoshi has to eat to grow (when double-eating). Change with $01A2FB.
    BNE CODE_03C0A7             ;$03C0A3    |/
    BRA CODE_03C05C             ;$03C0A5    |

CODE_03C0A7:                    ;```````````| Yoshi has eaten a sprite.
    JSL CODE_05B34A             ;$03C0A7    | Give a coin.
    LDA.b #$01                  ;$03C0AB    |\ Give 200 points.
    JSL GivePoints              ;$03C0AD    |/
    RTS                         ;$03C0B1    |





DATA_03C0B2:                    ;$03C0B2    | Tile numbers to use for the lava in Iggy/Larry's rooms.
    db $68,$6A,$6C,$6E

DATA_03C0B6:                    ;$03C0B6    | Indices to the above table for each actual lava tile in the room.
    db $00,$03,$01,$02,$04,$02,$00,$01
    db $00,$04,$00,$02,$00,$03,$04,$01

CODE_03C0C6:                    ;-----------| Subroutine to draw the top of the lava in Iggy/Larry's rooms.
    LDA $9D                     ;$03C0C6    |\ 
    BNE CODE_03C0CD             ;$03C0C8    || If the game isn't frozen, rotate Iggy/Larry's platform.
    JSR CODE_03C11E             ;$03C0CA    |/
CODE_03C0CD:                    ;           |
    STZ $00                     ;$03C0CD    |
    LDX.b #$13                  ;$03C0CF    |
    LDY.b #$B0                  ;$03C0D1    |
CODE_03C0D3:                    ;           |
    STX $02                     ;$03C0D3    |
    LDA $00                     ;$03C0D5    |\ 
    STA.w $0300,Y               ;$03C0D7    ||
    CLC                         ;$03C0DA    || Store X position to OAM.
    ADC.b #$10                  ;$03C0DB    ||
    STA $00                     ;$03C0DD    |/
    LDA.b #$C4                  ;$03C0DF    |\ Store Y position to OAM.
    STA.w $0301,Y               ;$03C0E1    |/
    LDA $64                     ;$03C0E4    |\ 
    ORA.b #$09                  ;$03C0E6    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03C0E8    |/
    PHX                         ;$03C0EB    |
    LDA $14                     ;$03C0EC    |\ 
    LSR                         ;$03C0EE    ||
    LSR                         ;$03C0EF    ||
    LSR                         ;$03C0F0    ||
    CLC                         ;$03C0F1    || Store tile number to OAM.
    ADC.l DATA_03C0B6,X         ;$03C0F2    ||
    AND.b #$03                  ;$03C0F6    ||
    TAX                         ;$03C0F8    ||
    LDA.l DATA_03C0B2,X         ;$03C0F9    ||
    STA.w $0302,Y               ;$03C0FD    |/
    TYA                         ;$03C100    |
    LSR                         ;$03C101    |
    LSR                         ;$03C102    |
    TAX                         ;$03C103    |
    LDA.b #$02                  ;$03C104    |\ Store size to OAM as 16x16.
    STA.w $0460,X               ;$03C106    |/
    PLX                         ;$03C109    |
    INY                         ;$03C10A    |\ 
    INY                         ;$03C10B    ||
    INY                         ;$03C10C    || Loop for all of the tiles.
    INY                         ;$03C10D    ||
    DEX                         ;$03C10E    ||
    BPL CODE_03C0D3             ;$03C10F    |/
    RTL                         ;$03C111    |



IggyPlatSpeed:                  ;$03C112    | Speeds (lo) to rotate Iggy/Larry's platform by.
    db $FF,$01
    db $FF,$01

DATA_03C116:                    ;$03C116    | Speeds (hi) to rotate Iggy/Larry's platform by.
    db $FF,$00
    db $FF,$00

IggyPlatBounds:                 ;$03C11A    | Max angles to rotate Iggy/Larry's platforms to.
    db $E7,$18
    db $D7,$28

CODE_03C11E:                    ;-----------| Subroutine to handle rotating Iggy/Larry's platform.
    LDA $9D                     ;$03C11E    |\ 
    ORA.w $1493                 ;$03C120    || Return if game frozen or level has ended.
    BNE Return03C175            ;$03C123    |/
    LDA.w $1906                 ;$03C125    |\ 
    BEQ CODE_03C12D             ;$03C128    || Handle the "paused" timer for Iggy/Larry's platform.
    DEC.w $1906                 ;$03C12A    |/
CODE_03C12D:                    ;           |
    LDA $13                     ;$03C12D    |\ 
    AND.b #$01                  ;$03C12F    || If the paused timer is set or it's not a frame to rotate the platform, return.
    ORA.w $1906                 ;$03C131    ||
    BNE Return03C175            ;$03C134    |/
    LDA.w $1905                 ;$03C136    |\ 
    AND.b #$01                  ;$03C139    ||
    TAX                         ;$03C13B    ||
    LDA.w $1907                 ;$03C13C    || Get index for the max tilt angle.
    CMP.b #$04                  ;$03C13F    ||  If on the third "phase" of the tilt, tilt the platform more than usual.
    BCC CODE_03C145             ;$03C141    ||
    INX                         ;$03C143    ||
    INX                         ;$03C144    |/
CODE_03C145:                    ;           |
    LDA $36                     ;$03C145    |\ 
    CLC                         ;$03C147    ||
    ADC.l IggyPlatSpeed,X       ;$03C148    ||
    STA $36                     ;$03C14C    ||
    PHA                         ;$03C14E    || Rotate the platform.
    LDA $37                     ;$03C14F    ||
    ADC.l DATA_03C116,X         ;$03C151    ||
    AND.b #$01                  ;$03C155    ||
    STA $37                     ;$03C157    |/
    PLA                         ;$03C159    |\ 
    CMP.l IggyPlatBounds,X      ;$03C15A    || Return if not at the max rotation.
    BNE Return03C175            ;$03C15E    |/
    INC.w $1905                 ;$03C160    | Increment tilt counter.
    LDA.b #$40                  ;$03C163    |\ Set pause timer to wait before the next rotation.
    STA.w $1906                 ;$03C165    |/
    INC.w $1907                 ;$03C168    |\ 
    LDA.w $1907                 ;$03C16B    ||
    CMP.b #$06                  ;$03C16E    || Increment the phase pointer.
    BNE Return03C175            ;$03C170    ||
    STZ.w $1907                 ;$03C172    |/
Return03C175:                   ;           |
    RTS                         ;$03C175    |





DATA_03C176:                    ;$03C176    | X offsets for the swallowing tile from Yoshi.
    db $0C,$0C,$0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D  ; Right
    db $FC,$FC,$FC,$FC,$FC,$FC,$FB,$FB,$FB,$FB  ; Left
    db $0C,$0C,$0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D  ; Right, ducking
    db $FC,$FC,$FC,$FC,$FC,$FC,$FB,$FB,$FB,$FB  ; Left, ducking

DATA_03C19E:                    ;$03C19E    | Y offsets for the swallowing tile from Yoshi.
    db $0E,$0E,$0E,$0D,$0D,$0D,$0C,$0C,$0B,$0B  ; Right
    db $0E,$0E,$0E,$0D,$0D,$0D,$0C,$0C,$0B,$0B  ; Left
    db $12,$12,$12,$11,$11,$11,$10,$10,$0F,$0F  ; Right, ducking
    db $12,$12,$12,$11,$11,$11,$10,$10,$0F,$0F  ; Left, ducking





DATA_03C1C6:                    ;$03C1C6    | "Speeds" that sprites get pushed down very steep slopes (low).
    db $02,$FE

DATA_03C1C8:                    ;$03C1C8    | "Speeds" that sprites get pushed down very steep slopes (high).
    db $00,$FF

CODE_03C1CA:                    ;-----------| Routine used to push a sprite down a very steep slope.
    PHB                         ;$03C1CA    |
    PHK                         ;$03C1CB    |
    PLB                         ;$03C1CC    |
    LDY.b #$00                  ;$03C1CD    |\ 
    LDA.w $15B8,X               ;$03C1CF    || Get direction to push.
    BPL CODE_03C1D5             ;$03C1D2    ||
    INY                         ;$03C1D4    |/
CODE_03C1D5:                    ;           |
    LDA $E4,X                   ;$03C1D5    |\ 
    CLC                         ;$03C1D7    ||
    ADC.w DATA_03C1C6,Y         ;$03C1D8    ||
    STA $E4,X                   ;$03C1DB    || Shift the sprite to the side.
    LDA.w $14E0,X               ;$03C1DD    ||
    ADC.w DATA_03C1C8,Y         ;$03C1E0    ||
    STA.w $14E0,X               ;$03C1E3    |/
    LDA.b #$18                  ;$03C1E6    |\ Set Y speed.
    STA $AA,X                   ;$03C1E8    |/
    PLB                         ;$03C1EA    |
    RTL                         ;$03C1EB    |





DATA_03C1EC:                    ;$03C1EC    | Y offsets for the light switch's bounce animation.
    db $00,$04,$07,$08,$08,$07,$04,$00,$00

    ; Light switch misc RAM:
    ; $C2   - Flag for the switch being hit.
    ; $1558 - Timer for the switch's bounce animation.
    ; $1564 - Unused timer set whenever hit from below. Not used for anything, though.
    
LightSwitch:                    ;-----------| Light switch MAIN
    LDA $9D                     ;$03C1F5    |\ Branch to just draw graphics if game frozen.
    BNE CODE_03C22B             ;$03C1F7    |/
    JSL InvisBlkMainRt          ;$03C1F9    | Make solid.
    JSR SubOffscreen0Bnk3       ;$03C1FD    | Process offscreen from -$40 to +$30.
    LDA.w $1558,X               ;$03C200    |\ 
    CMP.b #$05                  ;$03C203    || Branch to just draw graphics if the switch hasn't been hit.
    BNE CODE_03C22B             ;$03C205    |/
    STZ $C2,X                   ;$03C207    | Clear flag for the block being hit.
    LDY.b #$0B                  ;$03C209    |\ SFX for hitting the light switch block.
    STY.w $1DF9                 ;$03C20B    |/
    PHA                         ;$03C20E    |
    LDY.b #$09                  ;$03C20F    |\ 
CODE_03C211:                    ;           ||
    LDA.w $14C8,Y               ;$03C211    ||
    CMP.b #$08                  ;$03C214    ||
    BNE CODE_03C227             ;$03C216    ||
    LDA.w $009E,Y               ;$03C218    ||
    CMP.b #$C6                  ;$03C21B    || Loop through all the sprites to find any spotlight sprites.
    BNE CODE_03C227             ;$03C21D    ||  If one is found, invert the "active" flag for it.
    LDA.w $C2,Y                 ;$03C21F    ||
    EOR.b #$01                  ;$03C222    ||
    STA.w $C2,Y                 ;$03C224    ||
CODE_03C227:                    ;           ||
    DEY                         ;$03C227    ||
    BPL CODE_03C211             ;$03C228    |/
    PLA                         ;$03C22A    |
CODE_03C22B:                    ;```````````| Light switch GFX routine.
    LDA.w $1558,X               ;$03C22B    |\ 
    LSR                         ;$03C22E    ||
    TAY                         ;$03C22F    ||
    LDA $1C                     ;$03C230    ||
    PHA                         ;$03C232    ||
    CLC                         ;$03C233    || Offset Y position, for the bounce animation.
    ADC.w DATA_03C1EC,Y         ;$03C234    ||
    STA $1C                     ;$03C237    ||
    LDA $1D                     ;$03C239    ||
    PHA                         ;$03C23B    ||
    ADC.b #$00                  ;$03C23C    ||
    STA $1D                     ;$03C23E    |/
    JSL GenericSprGfxRt2        ;$03C240    | Draw a 16x16 tile.
    LDY.w $15EA,X               ;$03C244    |
    LDA.b #$2A                  ;$03C247    |\\ Tile to use for the light switch block.
    STA.w $0302,Y               ;$03C249    |/
    LDA.w $0303,Y               ;$03C24C    |\ 
    AND.b #$BF                  ;$03C24F    || Clear X flip from YXPPCCCT (but not Y, for some reason).
    STA.w $0303,Y               ;$03C251    |/
    PLA                         ;$03C254    |\ 
    STA $1D                     ;$03C255    || Restore Y position.
    PLA                         ;$03C257    ||
    STA $1C                     ;$03C258    |/
    RTS                         ;$03C25A    |





ChainsawMotorTiles:             ;$03C25B    | Tile numbers for the chainsaw's mechanism (not the actual saw, which is constant).
    db $E0,$C2,$C0,$C2

DATA_03C25F:                    ;$03C25F    | Y offsets between each tile of the chainsaw, indexed by whether it's upright or upside-down.
    db $F2,$0E

DATA_03C261:                    ;$03C261    | YXPPCCCT for the chainsaw, indexed by whether it's upright or upside-down.
    db $33,$B3

CODE_03C263:                    ;-----------| Chainsaw GFX routine.
    PHB                         ;$03C263    |
    PHK                         ;$03C264    |
    PLB                         ;$03C265    |
    JSR ChainsawGfx             ;$03C266    |
    PLB                         ;$03C269    |
    RTL                         ;$03C26A    |

ChainsawGfx:
    JSR GetDrawInfoBnk3         ;$03C26B    |
    PHX                         ;$03C26E    |
    LDA $9E,X                   ;$03C26F    |\ 
    SEC                         ;$03C271    ||
    SBC.b #$65                  ;$03C272    || Get data based on whether this is the upright chainsaw (65) or upside-down chainsaw (66).
    TAX                         ;$03C274    ||
    LDA.w DATA_03C25F,X         ;$03C275    ||\ $03 = Y offset between each tile.
    STA $03                     ;$03C278    ||/
    LDA.w DATA_03C261,X         ;$03C27A    ||\ $04 = YXPPCCCT for each tile
    STA $04                     ;$03C27D    |//
    PLX                         ;$03C27F    |
    LDA $14                     ;$03C280    |\ 
    AND.b #$02                  ;$03C282    || $02 = additional Y offset for animating the saw
    STA $02                     ;$03C284    |/
    LDA $00                     ;$03C286    |\ 
    SEC                         ;$03C288    ||
    SBC.b #$08                  ;$03C289    || Store X positions to OAM.
    STA.w $0300,Y               ;$03C28B    ||
    STA.w $0304,Y               ;$03C28E    ||
    STA.w $0308,Y               ;$03C291    |/
    LDA $01                     ;$03C294    |\ 
    SEC                         ;$03C296    ||
    SBC.b #$08                  ;$03C297    ||
    STA.w $0301,Y               ;$03C299    ||
    CLC                         ;$03C29C    ||
    ADC $03                     ;$03C29D    || Store Y positions to OAM.
    CLC                         ;$03C29F    ||
    ADC $02                     ;$03C2A0    ||
    STA.w $0305,Y               ;$03C2A2    ||
    CLC                         ;$03C2A5    ||
    ADC $03                     ;$03C2A6    ||
    STA.w $0309,Y               ;$03C2A8    |/
    LDA $14                     ;$03C2AB    |\\ 
    LSR                         ;$03C2AD    |||
    LSR                         ;$03C2AE    |||
    AND.b #$03                  ;$03C2AF    ||| Animate the chainsaw's motor.
    PHX                         ;$03C2B1    |||
    TAX                         ;$03C2B2    |||
    LDA.w ChainsawMotorTiles,X  ;$03C2B3    |||
    STA.w $0302,Y               ;$03C2B6    ||/
    PLX                         ;$03C2B9    ||
    LDA.b #$AE                  ;$03C2BA    ||\\ Tile A for the chainsaw's saw.
    STA.w $0306,Y               ;$03C2BC    ||/
    LDA.b #$8E                  ;$03C2BF    ||\\ Tile B for the chainsaw's saw.
    STA.w $030A,Y               ;$03C2C1    |//
    LDA.b #$37                  ;$03C2C4    |\ 
    STA.w $0303,Y               ;$03C2C6    ||
    LDA $04                     ;$03C2C9    || Store YXPPCCCT to OAM.
    STA.w $0307,Y               ;$03C2CB    ||
    STA.w $030B,Y               ;$03C2CE    |/
    LDY.b #$02                  ;$03C2D1    |\ 
    TYA                         ;$03C2D3    || Upload 3 16x16 tiles to OAM.
    JSL FinishOAMWrite          ;$03C2D4    |/
    RTS                         ;$03C2D8    |





TriggerInivis1Up:               ;-----------| Subroutine to spawn a 1up once all 4 invisible checkpoints have been touched.
    PHX                         ;$03C2D9    |
    LDX.b #$0B                  ;$03C2DA    |\ 
CODE_03C2DC:                    ;           ||
    LDA.w $14C8,X               ;$03C2DC    ||
    BEQ Generate1Up             ;$03C2DF    || Find an empty sprite slot and return if none found.
    DEX                         ;$03C2E1    ||
    BPL CODE_03C2DC             ;$03C2E2    ||
    PLX                         ;$03C2E4    ||
    RTL                         ;$03C2E5    |/
Generate1Up:                    ;           |
    LDA.b #$08                  ;$03C2E6    |\ 
    STA.w $14C8,X               ;$03C2E8    ||
    LDA.b #$78                  ;$03C2EB    ||| Sprite to spawn (1up).
    STA $9E,X                   ;$03C2ED    |/
    LDA $94                     ;$03C2EF    |\ 
    STA $E4,X                   ;$03C2F1    ||
    LDA $95                     ;$03C2F3    ||
    STA.w $14E0,X               ;$03C2F5    || Spawn at Mario's position.
    LDA $96                     ;$03C2F8    ||
    STA $D8,X                   ;$03C2FA    ||
    LDA $97                     ;$03C2FC    ||
    STA.w $14D4,X               ;$03C2FE    |/
    JSL InitSpriteTables        ;$03C301    |
    LDA.b #$10                  ;$03C305    |\ Disable contact with Mario briefly.
    STA.w $154C,X               ;$03C307    |/
    JSR PopupMushroom           ;$03C30A    |
    PLX                         ;$03C30D    |
    RTL                         ;$03C30E    |





InvisMushroom:                  ;-----------| Invisible mushroom MAIN.
    JSR GetDrawInfoBnk3         ;$03C30F    |
    JSL MarioSprInteract        ;$03C312    |\ Return if not in contact with Mario.
    BCC Return03C347            ;$03C316    |/
    LDA.b #$74                  ;$03C318    |\\ Sprite invisible mushroom spawns (mushroom).
    STA $9E,X                   ;$03C31A    |/
    JSL InitSpriteTables        ;$03C31C    |
    LDA.b #$20                  ;$03C320    |\ Disable contact for the mushroom with Mario briefly.
    STA.w $154C,X               ;$03C322    |/
    LDA $D8,X                   ;$03C325    |\ 
    SEC                         ;$03C327    ||
    SBC.b #$0F                  ;$03C328    ||
    STA $D8,X                   ;$03C32A    || Spawn above the invisible mushroom.
    LDA.w $14D4,X               ;$03C32C    ||
    SBC.b #$00                  ;$03C32F    ||
    STA.w $14D4,X               ;$03C331    |/
PopupMushroom:                  ;           |
    LDA.b #$00                  ;$03C334    |\ 
    LDY $7B                     ;$03C336    ||
    BPL CODE_03C33B             ;$03C338    || Spawn moving away from Mario.
    INC A                       ;$03C33A    ||
CODE_03C33B:                    ;           ||
    STA.w $157C,X               ;$03C33B    |/
    LDA.b #$C0                  ;$03C33E    |\\ Initial Y speed for the mushroom.
    STA $AA,X                   ;$03C340    |/
    LDA.b #$02                  ;$03C342    |\ SFX for spawning a mushroom from the invisible mushroom sprite.
    STA.w $1DFC                 ;$03C344    |/
Return03C347:                   ;           |
    RTS                         ;$03C347    |





NinjiSpeedY:                    ;$03C348    | Y speeds the Ninji can jump with.
    db $D0,$C0,$B0,$D0

    ; Ninji misc RAM:
    ; $C2   - Counter for the number of times the Ninji has jumped.
    ; $1540 - Timer for waiting between jumps.
    ; $157C - Horizontal direction the sprite is facing.
    ; $1602 - Animation frame. 0 = normal, 1 = jumping
    
Ninji:                          ;-----------| Ninji MAIN
    JSL GenericSprGfxRt2        ;$03C34B    | Draw a 16x16 sprite.
    LDA $9D                     ;$03C350    |\ Return if game frozen.
    BNE Return03C38F            ;$03C352    |/
    JSR SubHorzPosBnk3          ;$03C354    |\ 
    TYA                         ;$03C357    || Face Mario.
    STA.w $157C,X               ;$03C358    |/
    JSR SubOffscreen0Bnk3       ;$03C35B    | Process offscreen from -$40 to +$30.
    JSL SprSprPMarioSprRts      ;$03C35E    | Process interaction with Mario and other sprites.
    JSL UpdateSpritePos         ;$03C362    | Update X/Y position, apply gravity, and process block interaction.
    LDA.w $1588,X               ;$03C366    |\ 
    AND.b #$04                  ;$03C369    || Branch if not on the ground.
    BEQ CODE_03C385             ;$03C36B    |/
    STZ $AA,X                   ;$03C36D    | Clear Y speed.
    LDA.w $1540,X               ;$03C36F    |\ Branch if not time to jump.
    BNE CODE_03C385             ;$03C372    |/
    LDA.b #$60                  ;$03C374    |\\ How long the Ninji waits between jumps.
    STA.w $1540,X               ;$03C376    |/
    INC $C2,X                   ;$03C379    |\ 
    LDA $C2,X                   ;$03C37B    ||
    AND.b #$03                  ;$03C37D    || Set Y speed for the jump.
    TAY                         ;$03C37F    ||
    LDA.w NinjiSpeedY,Y         ;$03C380    ||
    STA $AA,X                   ;$03C383    |/
CODE_03C385:                    ;           |
    LDA.b #$00                  ;$03C385    |\ 
    LDY $AA,X                   ;$03C387    ||
    BMI CODE_03C38C             ;$03C389    || Set animation frame.
    INC A                       ;$03C38B    ||
CODE_03C38C:                    ;           ||
    STA.w $1602,X               ;$03C38C    |/
Return03C38F:                   ;           |
    RTS                         ;$03C38F    |





CODE_03C390:                    ;-----------| Dry Bones / Bony Beetle GFX routine container.
    PHB                         ;$03C390    |
    PHK                         ;$03C391    |
    PLB                         ;$03C392    |
    LDA.w $157C,X               ;$03C393    |\ 
    PHA                         ;$03C396    ||
    LDY.w $15AC,X               ;$03C397    ||
    BEQ CODE_03C3A5             ;$03C39A    || Handle turning the sprite around if its turn timer is set.
    CPY.b #$05                  ;$03C39C    ||
    BCC CODE_03C3A5             ;$03C39E    ||
    EOR.b #$01                  ;$03C3A0    ||
    STA.w $157C,X               ;$03C3A2    |/
CODE_03C3A5:                    ;           |
    JSR CODE_03C3DA             ;$03C3A5    | Draw GFX.
    PLA                         ;$03C3A8    |
    STA.w $157C,X               ;$03C3A9    |
    PLB                         ;$03C3AC    |
    RTL                         ;$03C3AD    |

CODE_03C3AE:                    ;```````````| Bony Beetle's GFX routine.
    JSL GenericSprGfxRt2        ;$03C3AE    | Draw a 16x16 sprite.
    RTS                         ;$03C3B2    |


DryBonesTileDispX:              ;$03C3B3    | Dry Bones tile X displacements. Bone, head, body for each frame.
    db $00,$08,$00                          ; Left
    db $00,$F8,$00                          ; Right
    db $00,$04,$00                          ; Left (turning)
    db $00,$FC,$00                          ; Right (turning)

DryBonesGfxProp:                ;$03C3BF    | Dry Bones YXPPCCCT. Bone, head, body.
    db $43,$43,$43                          ; Left
    db $03,$03,$03                          ; Right

DryBonesTileDispY:              ;$03C3C5    | Dry Bones tile Y displacements; bone, head, body for each frame. Bone byte is unused for walking.
    db $F4,$F0,$00                          ; Walk A
    db $F4,$F1,$00                          ; Walk B
    db $F4,$F0,$00                          ; Throwing bone

DryBonesTiles:                  ;$03C3CE    | Dry Bones tiles; bone, head, body for each frame. Bone byte is unused for walking.
    db $00,$64,$66                          ; Walk A
    db $00,$64,$68                          ; Walk B
    db $82,$64,$E6                          ; Throwing bone

DATA_03C3D7:                    ;$03C3D7    | Number of tiles for each frame, subtracted from 2. (i.e. 00 = 2 tiles, FF = 3)
    db $00                                  ; Walk A
    db $00                                  ; Walk B
    db $FF                                  ; THrowing bone

CODE_03C3DA:                    ;-----------| Dry Bones / Buzzy Beetle GFX routine.
    LDA $9E,X                   ;$03C3DA    |\ 
    CMP.b #$31                  ;$03C3DC    || Branch if running the Buzzy Beetle, to just draw a 16x16.
    BEQ CODE_03C3AE             ;$03C3DE    |/
    JSR GetDrawInfoBnk3         ;$03C3E0    |
    LDA.w $15AC,X               ;$03C3E3    |\ 
    STA $05                     ;$03C3E6    ||
    LDA.w $157C,X               ;$03C3E8    ||
    ASL                         ;$03C3EB    || Set up some additional scratch RAM.
    ADC.w $157C,X               ;$03C3EC    ||
    STA $02                     ;$03C3EF    || $02 = Direction (times 3)
    PHX                         ;$03C3F1    || $03 = Animation frame (times 3)
    LDA.w $1602,X               ;$03C3F2    || $04 = Number of tiles
    PHA                         ;$03C3F5    || $05 = Turn timer
    ASL                         ;$03C3F6    ||
    ADC.w $1602,X               ;$03C3F7    ||
    STA $03                     ;$03C3FA    ||
    PLX                         ;$03C3FC    ||
    LDA.w DATA_03C3D7,X         ;$03C3FD    ||
    STA $04                     ;$03C400    |/
    LDX.b #$02                  ;$03C402    |\ 
CODE_03C404:                    ;           ||
    PHX                         ;$03C404    ||
    TXA                         ;$03C405    ||\ 
    CLC                         ;$03C406    |||
    ADC $02                     ;$03C407    |||
    TAX                         ;$03C409    |||
    PHX                         ;$03C40A    |||
    LDA $05                     ;$03C40B    ||| Get X displacement index.
    BEQ CODE_03C414             ;$03C40D    |||
    TXA                         ;$03C40F    |||
    CLC                         ;$03C410    |||
    ADC.b #$06                  ;$03C411    |||
    TAX                         ;$03C413    ||/
CODE_03C414:                    ;           ||
    LDA $00                     ;$03C414    ||\ 
    CLC                         ;$03C416    ||| Set X displacement.
    ADC.w DryBonesTileDispX,X   ;$03C417    |||
    STA.w $0300,Y               ;$03C41A    ||/
    PLX                         ;$03C41D    ||
    LDA.w DryBonesGfxProp,X     ;$03C41E    ||\ 
    ORA $64                     ;$03C421    ||| Set YXPPCCCT.
    STA.w $0303,Y               ;$03C423    ||/
    PLA                         ;$03C426    ||
    PHA                         ;$03C427    ||
    CLC                         ;$03C428    ||\ 
    ADC $03                     ;$03C429    |||
    TAX                         ;$03C42B    |||
    LDA $01                     ;$03C42C    ||| Set Y displacement.
    CLC                         ;$03C42E    |||
    ADC.w DryBonesTileDispY,X   ;$03C42F    |||
    STA.w $0301,Y               ;$03C432    ||/
    LDA.w DryBonesTiles,X       ;$03C435    ||\ Set tile number.
    STA.w $0302,Y               ;$03C438    ||/
    PLX                         ;$03C43B    ||
    INY                         ;$03C43C    ||
    INY                         ;$03C43D    ||
    INY                         ;$03C43E    ||
    INY                         ;$03C43F    ||
    DEX                         ;$03C440    ||\ 
    CPX $04                     ;$03C441    ||| Loop for the correct number of tiles (2 or 3).
    BNE CODE_03C404             ;$03C443    |//
    PLX                         ;$03C445    |
    LDY.b #$02                  ;$03C446    |\ 
    TYA                         ;$03C448    || Draw 2 or 3 16x16s.
    JSL FinishOAMWrite          ;$03C449    |/
    RTS                         ;$03C44D    |





CODE_03C44E:                    ;-----------| Routine for the Dry Bones to spawn a bone.
    LDA.w $15A0,X               ;$03C44E    |\ 
    ORA.w $186C,X               ;$03C451    || Return if offscreen.
    BNE Return03C460            ;$03C454    |/
    LDY.b #$07                  ;$03C456    |\ 
CODE_03C458:                    ;           ||
    LDA.w $170B,Y               ;$03C458    ||
    BEQ CODE_03C461             ;$03C45B    || Find an empty extended sprite slot, and return if none found.
    DEY                         ;$03C45D    ||
    BPL CODE_03C458             ;$03C45E    ||
Return03C460:                   ;           ||
    RTL                         ;$03C460    |/

CODE_03C461:
    LDA.b #$06                  ;$03C461    |\ Set extended sprite number.
    STA.w $170B,Y               ;$03C463    |/
    LDA $D8,X                   ;$03C466    |\ 
    SEC                         ;$03C468    || Set Y position.
    SBC.b #$10                  ;$03C469    ||| Y displacement of the Dry Bones' bone.
    STA.w $1715,Y               ;$03C46B    ||
    LDA.w $14D4,X               ;$03C46E    ||
    SBC.b #$00                  ;$03C471    ||
    STA.w $1729,Y               ;$03C473    |/
    LDA $E4,X                   ;$03C476    |\ 
    STA.w $171F,Y               ;$03C478    || Set X position.
    LDA.w $14E0,X               ;$03C47B    ||
    STA.w $1733,Y               ;$03C47E    |/
    LDA.w $157C,X               ;$03C481    |\ 
    LSR                         ;$03C484    ||
    LDA.b #$18                  ;$03C485    ||| X speed of the bone when going right.
    BCC CODE_03C48B             ;$03C487    ||
    LDA.b #$E8                  ;$03C489    ||| X speed of the bone when going left.
CODE_03C48B:                    ;           ||
    STA.w $1747,Y               ;$03C48B    |/
    RTL                         ;$03C48E    |





DATA_03C48F:                    ;$03C48F    | Speeds the spotlight's window moves with.
    db $01,$FF

DATA_03C491:                    ;$03C491    | Max positions for the spotlight's window to move to.
    db $FF,$90

DiscoBallTiles:                 ;$03C493    | Tile numbers for the dark room spotlight First 8 used when active, 9th used when inactive.
    db $80,$82,$84,$86,$88,$8C,$C0,$C2
    db $C2

DATA_03C49C:                    ;$03C49C    | YXPPCCCT for the dark room spotlight. First 8 used when active, 9th used when inactive.
    db $31,$33,$35,$37,$31,$33,$35,$37
    db $39

CODE_03C4A5:                    ;-----------| Spotlight GFX routine.
    LDY.w $15EA,X               ;$03C4A5    |
    LDA.b #$78                  ;$03C4A8    |\ 
    STA.w $0300,Y               ;$03C4AA    || Set position at the top-middle of the screen.
    LDA.b #$28                  ;$03C4AD    ||
    STA.w $0301,Y               ;$03C4AF    |/
    PHX                         ;$03C4B2    |
    LDA $C2,X                   ;$03C4B3    |\ 
    LDX.b #$08                  ;$03C4B5    ||
    AND.b #$01                  ;$03C4B7    ||
    BEQ CODE_03C4C1             ;$03C4B9    || Get animation frame.
    LDA $13                     ;$03C4BB    ||
    LSR                         ;$03C4BD    ||
    AND.b #$07                  ;$03C4BE    ||
    TAX                         ;$03C4C0    |/
CODE_03C4C1:                    ;           |
    LDA.w DiscoBallTiles,X      ;$03C4C1    |\ Set current tile number for the animation.
    STA.w $0302,Y               ;$03C4C4    |/
    LDA.w DATA_03C49C,X         ;$03C4C7    |\ Set current YXPPCCCT for the animation.
    STA.w $0303,Y               ;$03C4CA    |/
    TYA                         ;$03C4CD    |\ 
    LSR                         ;$03C4CE    ||
    LSR                         ;$03C4CF    || Set size as 16x16.
    TAY                         ;$03C4D0    ||
    LDA.b #$02                  ;$03C4D1    ||
    STA.w $0460,Y               ;$03C4D3    |/
    PLX                         ;$03C4D6    |
    RTS                         ;$03C4D7    |



DATA_03C4D8:                    ;$03C4D8    | Back area colors (low byte) for usage by the spotlight.
    db $10,$8C                              ; First color is when inactive, second is active.

DATA_03C4DA:                    ;$03C4DA    | Back area colors (high byte) for usage by the spotlight.
    db $42,$31

    ; Spotlight misc RAM:
    ; $C2   - Flag to indicate whether the spotlight is active (1) or not (0).
    ; $1534 - Flag to indicate this spotlight is the "true" one (i.e. not a second one spawned later).
    
DarkRoomWithLight:              ;-----------| Dark Room Spotlight MAIN (disco ball)
    LDA.w $1534,X               ;$03C4DC    |\ 
    BNE CODE_03C500             ;$03C4DF    ||
    LDY.b #$09                  ;$03C4E1    ||
CODE_03C4E3:                    ;           ||
    CPY.w $15E9                 ;$03C4E3    ||
    BEQ CODE_03C4FA             ;$03C4E6    ||
    LDA.w $14C8,Y               ;$03C4E8    ||
    CMP.b #$08                  ;$03C4EB    ||
    BNE CODE_03C4FA             ;$03C4ED    || If another spotlight has already been spawned, delete this one.
    LDA.w $009E,Y               ;$03C4EF    ||
    CMP.b #$C6                  ;$03C4F2    ||
    BNE CODE_03C4FA             ;$03C4F4    ||
    STZ.w $14C8,X               ;$03C4F6    ||
Return03C4F9:                   ;           ||
    RTS                         ;$03C4F9    ||
CODE_03C4FA:                    ;           ||
    DEY                         ;$03C4FA    ||
    BPL CODE_03C4E3             ;$03C4FB    ||
    INC.w $1534,X               ;$03C4FD    |/
CODE_03C500:                    ;           |
    JSR CODE_03C4A5             ;$03C500    | Draw GFX.
    LDA.b #$FF                  ;$03C503    |\ Set CGADSUB (enable half-color subtract on every layer).
    STA $40                     ;$03C505    |/
    LDA.b #$20                  ;$03C507    |\ Set CGWSEL (enable color math inside window only).
    STA $44                     ;$03C509    |/
    LDA.b #$20                  ;$03C50B    |\ Set WOBJSEL (enable window on BG2/BG4/color only).
    STA $43                     ;$03C50D    |/
    LDA.b #$80                  ;$03C50F    |\ Enable HDMA on channel 7.
    STA.w $0D9F                 ;$03C511    |/
    LDA $C2,X                   ;$03C514    |\ 
    AND.b #$01                  ;$03C516    ||
    TAY                         ;$03C518    ||
    LDA.w DATA_03C4D8,Y         ;$03C519    || Set color for addition based on whether the spotlight is active or not.
    STA.w $0701                 ;$03C51C    ||
    LDA.w DATA_03C4DA,Y         ;$03C51F    ||
    STA.w $0702                 ;$03C522    |/
    LDA $9D                     ;$03C525    |\ Return if game frozen.
    BNE Return03C4F9            ;$03C527    |/
    LDA.w $1482                 ;$03C529    |\ 
    BNE CODE_03C54D             ;$03C52C    || Initialize the spotlight window if it hasn't already been.
    LDA.b #$00                  ;$03C52E    ||\ Left position of the base.
    STA.w $1476                 ;$03C530    ||/
    LDA.b #$90                  ;$03C533    ||\ Right position of the base.
    STA.w $1478                 ;$03C535    ||/
    LDA.b #$78                  ;$03C538    ||\ Left position of the top.
    STA.w $1472                 ;$03C53A    ||/
    LDA.b #$87                  ;$03C53D    ||\ Right position of the top.
    STA.w $1474                 ;$03C53F    ||/
    LDA.b #$01                  ;$03C542    ||\ (unused)
    STA.w $1486                 ;$03C544    ||/
    STZ.w $1483                 ;$03C547    || Set spotlight to move right initially.
    INC.w $1482                 ;$03C54A    |/
CODE_03C54D:                    ;```````````| Spotlight window has been initialized.
    LDY.w $1483                 ;$03C54D    |
    LDA.w $1476                 ;$03C550    |\ 
    CLC                         ;$03C553    || Update left position of the base.
    ADC.w DATA_03C48F,Y         ;$03C554    ||
    STA.w $1476                 ;$03C557    |/
    LDA.w $1478                 ;$03C55A    |\ 
    CLC                         ;$03C55D    || Update right position of the base.
    ADC.w DATA_03C48F,Y         ;$03C55E    ||
    STA.w $1478                 ;$03C561    |/
    CMP.w DATA_03C491,Y         ;$03C564    |\ 
    BNE CODE_03C572             ;$03C567    ||
    LDA.w $1483                 ;$03C569    || If at the maximum position in the current direction,
    INC A                       ;$03C56C    ||  invert direction of the spotlight's movement.
    AND.b #$01                  ;$03C56D    ||
    STA.w $1483                 ;$03C56F    |/
CODE_03C572:                    ;           |
    LDA $13                     ;$03C572    |\ 
    AND.b #$03                  ;$03C574    || Return if not a frame to update the window.
    BNE Return03C4F9            ;$03C576    |/
    LDY.b #$00                  ;$03C578    |\ 
    LDA.w $1472                 ;$03C57A    ||
    STA.w $147A                 ;$03C57D    ||
    SEC                         ;$03C580    ||
    SBC.w $1476                 ;$03C581    ||
    BCS CODE_03C58A             ;$03C584    || Get width between the top-left and bottom-left windows,
    INY                         ;$03C586    ||  and set some related addresses for calculating the window.
    EOR.b #$FF                  ;$03C587    ||
    INC A                       ;$03C589    ||
CODE_03C58A:                    ;           ||
    STA.w $1480                 ;$03C58A    ||
    STY.w $1484                 ;$03C58D    ||
    STZ.w $147E                 ;$03C590    |/
    LDY.b #$00                  ;$03C593    |\ 
    LDA.w $1474                 ;$03C595    ||
    STA.w $147C                 ;$03C598    ||
    SEC                         ;$03C59B    ||
    SBC.w $1478                 ;$03C59C    ||
    BCS CODE_03C5A5             ;$03C59F    || Get width between the top-right and bottom-right windows,
    INY                         ;$03C5A1    ||  and set some related addresses for calculating the window.
    EOR.b #$FF                  ;$03C5A2    ||
    INC A                       ;$03C5A4    ||
CODE_03C5A5:                    ;           ||
    STA.w $1481                 ;$03C5A5    ||
    STY.w $1485                 ;$03C5A8    ||
    STZ.w $147F                 ;$03C5AB    |/
    LDA $C2,X                   ;$03C5AE    |\ $0F = flag for whether the spotlight is active.
    STA $0F                     ;$03C5B0    |/
    PHX                         ;$03C5B2    |
    REP #$10                    ;$03C5B3    |
    LDX.w #$0000                ;$03C5B5    |
CODE_03C5B8:                    ;```````````| Loop for updating the window HDMA table.
    CPX.w #$005F                ;$03C5B8    |\ If above the spotlight, set the window fully across the scanline.
    BCC CODE_03C607             ;$03C5BB    |/
    LDA.w $147E                 ;$03C5BD    |\ 
    CLC                         ;$03C5C0    ||
    ADC.w $1480                 ;$03C5C1    ||
    STA.w $147E                 ;$03C5C4    ||
    BCS CODE_03C5CD             ;$03C5C7    ||
    CMP.b #$CF                  ;$03C5C9    ||
    BCC CODE_03C5E0             ;$03C5CB    || Get left window position for the current scanline.
CODE_03C5CD:                    ;           ||
    SBC.b #$CF                  ;$03C5CD    ||
    STA.w $147E                 ;$03C5CF    ||
    INC.w $147A                 ;$03C5D2    ||
    LDA.w $1484                 ;$03C5D5    ||
    BNE CODE_03C5E0             ;$03C5D8    ||
    DEC.w $147A                 ;$03C5DA    ||
    DEC.w $147A                 ;$03C5DD    |/
CODE_03C5E0:                    ;           |
    LDA.w $147F                 ;$03C5E0    |\ 
    CLC                         ;$03C5E3    ||
    ADC.w $1481                 ;$03C5E4    ||
    STA.w $147F                 ;$03C5E7    ||
    BCS CODE_03C5F0             ;$03C5EA    ||
    CMP.b #$CF                  ;$03C5EC    ||
    BCC CODE_03C603             ;$03C5EE    ||
CODE_03C5F0:                    ;           || Get right window position for the current scanline.
    SBC.b #$CF                  ;$03C5F0    ||
    STA.w $147F                 ;$03C5F2    ||
    INC.w $147C                 ;$03C5F5    ||
    LDA.w $1485                 ;$03C5F8    ||
    BNE CODE_03C603             ;$03C5FB    ||
    DEC.w $147C                 ;$03C5FD    ||
    DEC.w $147C                 ;$03C600    |/
CODE_03C603:                    ;           |
    LDA $0F                     ;$03C603    |\ Branch if the spotlight actually is active.
    BNE CODE_03C60F             ;$03C605    |/
CODE_03C607:                    ;```````````| Full window on the current scanline.
    LDA.b #$01                  ;$03C607    |\ 
    STA.w $04A0,X               ;$03C609    || Set width as 0x0100.
    DEC A                       ;$03C60C    ||
    BRA CODE_03C618             ;$03C60D    |/

CODE_03C60F:                    ;```````````| Spotlight is active and there is an opening in the window.
    LDA.w $147A                 ;$03C60F    |\ 
    STA.w $04A0,X               ;$03C612    ||
    LDA.w $147C                 ;$03C615    || Set width as calculated.
CODE_03C618:                    ;           ||
    STA.w $04A1,X               ;$03C618    |/
    INX                         ;$03C61B    |\ 
    INX                         ;$03C61C    || Loop for all the scanlines.
    CPX.w #$01C0                ;$03C61D    ||
    BNE CODE_03C5B8             ;$03C620    |/
    SEP #$10                    ;$03C622    |
    PLX                         ;$03C624    |
    RTS                         ;$03C625    |





DATA_03C626:                    ;$03C626    | Max X offset of each firework particle from the center of a normal explosion.
    db $14,$28,$38,$20,$30,$4C,$40,$34      ; Subtract #$40 from this value for the offset.
    db $2C,$1C,$08,$0C,$04,$0C,$1C,$24
    db $2C,$38,$40,$48,$50,$5C,$5C,$6C
    db $4C,$58,$24,$78,$64,$70,$78,$7C
    db $70,$68,$58,$4C,$40,$34,$24,$04
    db $18,$2C,$0C,$0C,$14,$18,$1C,$24
    db $2C,$28,$24,$30,$30,$34,$38,$3C
    db $44,$54,$48,$5C,$68,$40,$4C,$40
    db $3C,$40,$50,$54,$60,$54,$4C,$5C
    db $5C,$68,$74,$6C,$7C,$78,$68,$80
    db $18,$48,$2C,$1C

DATA_03C67A:                    ;$03C67A    | Max Y offset of each firework particle from the center of a normal explosion.
    db $1C,$0C,$08,$1C,$14,$08,$14,$24      ; Subtract #$50 from this value for the offset.
    db $28,$2C,$30,$3C,$44,$4C,$44,$34
    db $40,$34,$24,$1C,$10,$0C,$18,$18
    db $2C,$28,$68,$28,$34,$34,$38,$40
    db $44,$44,$38,$3C,$44,$48,$4C,$5C
    db $5C,$54,$64,$74,$74,$88,$80,$94
    db $8C,$78,$6C,$64,$70,$7C,$8C,$98
    db $90,$98,$84,$84,$88,$78,$78,$6C
    db $5C,$50,$50,$48,$50,$5C,$64,$64
    db $74,$78,$74,$64,$60,$58,$54,$50
    db $50,$58,$30,$34

DATA_03C6CE:                    ;$03C6CE    | Max X offset of each firework particle from the center of the heart explosion.
    db $20,$30,$39,$47,$50,$60,$70,$7C      ; Subtract #$40 from this value for the offset.
    db $7B,$80,$7D,$78,$6E,$60,$4F,$47
    db $41,$38,$30,$2A,$20,$10,$04,$00
    db $00,$08,$10,$20,$1A,$10,$0A,$06
    db $0F,$17,$16,$1C,$1F,$21,$10,$18
    db $20,$2C,$2E,$3B,$30,$30,$2D,$2A
    db $34,$36,$3A,$3F,$45,$4D,$5F,$54
    db $4E,$67,$70,$67,$70,$5C,$4E,$40
    db $48,$56,$57,$5F,$68,$72,$77,$6F
    db $66,$60,$67,$5C,$57,$4B,$4D,$54
    db $48,$43,$3D,$3C

DATA_03C722:                    ;$03C722    | Max Y offset of each firework particle from the center of the heart explosion.
    db $18,$1E,$25,$22,$1A,$17,$20,$30      ; Subtract #$50 from this value for the offset.
    db $41,$4F,$61,$70,$7F,$8C,$94,$92
    db $A0,$86,$93,$88,$88,$78,$66,$50
    db $40,$30,$22,$20,$2C,$30,$40,$4F
    db $59,$51,$3F,$39,$4C,$5F,$6A,$6F
    db $77,$7E,$6C,$60,$58,$48,$3D,$2F
    db $28,$38,$44,$30,$36,$27,$21,$2F
    db $39,$2A,$2F,$39,$40,$3F,$49,$50
    db $60,$59,$4C,$51,$48,$4F,$56,$67
    db $5B,$68,$75,$7D,$87,$8A,$7A,$6B
    db $70,$82,$73,$92

DATA_03C776:                    ;$03C776    | X position of each firework.
    db $60,$B0,$40,$80

FireworkSfx1:                   ;$03C77A    | SFX (1DF9) to use when first shooting each firework.
    db $26,$00,$26,$28

FireworkSfx2:                   ;$03C77E    | SFX (1DFC) to use when first shooting each firework.
    db $00,$2B,$00,$00

FireworkSfx3:                   ;$03C782    | SFX (1DF9) to use when exploding each firework.
    db $27,$00,$27,$29

FireworkSfx4:                   ;$03C786    | SFX (1DFC) to use when exploding each firework.
    db $00,$2C,$00,$00

DATA_03C78A:                    ;$03C78A    | Low byte of colors to use for the background color when a firework explodes.
    db $00,$AA,$FF,$AA
DATA_03C78E:                    ;$03C78E    | High byte of colors to use for the background color when a firework explodes.
    db $00,$7E,$27,$7E

DATA_03C792:                    ;$03C792    | Frames between each firework.
    db $C0,$C0,$FF,$C0

CODE_03C796:                    ;-----------| Peach phase 7 - Spawning fireworks
    LDA.w $1564,X               ;$03C796    |\ Branch if the fireworks aren't done yet.
    BEQ CODE_03C7A7             ;$03C799    |/
    DEC A                       ;$03C79B    |\ Return if not time to fade to the credits.
    BNE Return03C7A6            ;$03C79C    |/
    INC.w $13C6                 ;$03C79E    |\ 
    LDA.b #$FF                  ;$03C7A1    || Start fade to credits.
    STA.w $1493                 ;$03C7A3    |/
Return03C7A6:                   ;           |
    RTS                         ;$03C7A6    |

CODE_03C7A7:                    ;```````````| Not done shooting fireworks.
    LDA.w $156D                 ;$03C7A7    |\ 
    AND.b #$03                  ;$03C7AA    ||
    TAY                         ;$03C7AC    ||
    LDA.w DATA_03C78A,Y         ;$03C7AD    || Animate the flashing from the fireworks exploding.
    STA.w $0701                 ;$03C7B0    ||
    LDA.w DATA_03C78E,Y         ;$03C7B3    ||
    STA.w $0702                 ;$03C7B6    |/
    LDA.w $1FEB                 ;$03C7B9    |\ Return if not time to spawn a new firework.
    BNE Return03C80F            ;$03C7BC    |/
    LDA.w $1534,X               ;$03C7BE    |\ 
    CMP.b #$04                  ;$03C7C1    || Branch if the last firework has been fired.
    BEQ CODE_03C810             ;$03C7C3    |/
    LDY.b #$01                  ;$03C7C5    |\ 
CODE_03C7C7:                    ;           ||
    LDA.w $14C8,Y               ;$03C7C7    ||
    BEQ CODE_03C7D0             ;$03C7CA    || Find an empty sprite slot (in slots 0/1) to spawn the firework in, and return if none found.
    DEY                         ;$03C7CC    ||
    BPL CODE_03C7C7             ;$03C7CD    ||
    RTS                         ;$03C7CF    |/
CODE_03C7D0:                    ;           |
    LDA.b #$08                  ;$03C7D0    |\ 
    STA.w $14C8,Y               ;$03C7D2    ||
    LDA.b #$7A                  ;$03C7D5    ||| Sprite to spawn (firework).
    STA.w $009E,Y               ;$03C7D7    |/
    LDA.b #$00                  ;$03C7DA    |
    STA.w $14E0,Y               ;$03C7DC    |
    LDA.b #$A8                  ;$03C7DF    |\ 
    CLC                         ;$03C7E1    ||
    ADC $1C                     ;$03C7E2    ||
    STA.w $00D8,Y               ;$03C7E4    || Spawn at the bottom of the screen.
    LDA $1D                     ;$03C7E7    ||
    ADC.b #$00                  ;$03C7E9    ||
    STA.w $14D4,Y               ;$03C7EB    |/
    PHX                         ;$03C7EE    |
    TYX                         ;$03C7EF    |
    JSL InitSpriteTables        ;$03C7F0    |
    PLX                         ;$03C7F4    |
    PHX                         ;$03C7F5    |
    LDA.w $1534,X               ;$03C7F6    |\ 
    AND.b #$03                  ;$03C7F9    || Track which firework this was.
    STA.w $1534,Y               ;$03C7FB    |/
    TAX                         ;$03C7FE    |
    LDA.w DATA_03C792,X         ;$03C7FF    |\ Set time until next firework.
    STA.w $1FEB                 ;$03C802    |/
    LDA.w DATA_03C776,X         ;$03C805    |\ Set X position for this firework.
    STA.w $00E4,Y               ;$03C808    |/
    PLX                         ;$03C80B    |
    INC.w $1534,X               ;$03C80C    | Increment counter for number of fireworks.
Return03C80F:                   ;           |
    RTS                         ;$03C80F    |


CODE_03C810:                    ;```````````| Last firework has been shot, wait to fade to credits.
    LDA.b #$70                  ;$03C810    |\\ How long until the game fades to credits after the fireworks.
    STA.w $1564,X               ;$03C812    |/
    RTS                         ;$03C815    |





    ; Firework misc RAM:
    ; $B6   - Used as a timer for decelerating the Y speed while shooting up.
    ; $C2   - Sprite phase.
    ;          0 = initial fire, 1 = shooting up, 2 = exploding, 3 = fading away
    ; $151C - Speed at which the explosion is expanding.
    ; $1534 - Which firework this is. 0 = big, 1 = small, 2 = medium, 3 = heart
    ; $1564 - Timer for waiting to play the second part of the firing sound effect.
    ;          Slot #9's is also used for timing the explosion color flash effect.
    ; $1570 - Current "radius" of the explosion.
    ; $15AC - Timer for waiting to play the explosion sound effect.
    ; $1602 - Animation set for the particles. Valid values are 0-9.
    
FireworkMain:                   ;-----------| Firework MAIN
    LDA $C2,X                   ;$03C816    |
    JSL ExecutePtr              ;$03C818    |

FireworkPtrs:                   ;$03C81C    | Fireworks phase pointers.
    dw CODE_03C828              ; 0 - Initial fire
    dw CODE_03C845              ; 1 - Shooting up
    dw CODE_03C88D              ; 2 - Exploding
    dw CODE_03C941              ; 3 - Fading away



FireworkSpeedY:                 ;$03C824    | Y speeds to shoot each firework with.
    db $E4,$E6,$E4,$E2

CODE_03C828:                    ;-----------| Fireworks phase 0 - Initial fire
    LDY.w $1534,X               ;$03C828    |\ 
    LDA.w FireworkSpeedY,Y      ;$03C82B    || Set Y speed.
    STA $AA,X                   ;$03C82E    |/
    LDA.b #$25                  ;$03C830    |\ SFX for shooting a firework.
    STA.w $1DFC                 ;$03C832    |/
    LDA.b #$10                  ;$03C835    |\ Set timer to wait a bit before playing the second part of the shoot sound effect.
    STA.w $1564,X               ;$03C837    |/
    INC $C2,X                   ;$03C83A    | Increment to phase 1.
    RTS                         ;$03C83C    |



DATA_03C83D:                    ;$03C83D    | Initial speeds for each firework's particles.
    db $14,$0C,$10,$15

DATA_03C841:                    ;$03C841    | Delay before the explosion sound for each firework.
    db $08,$10,$0C,$05

CODE_03C845:                    ;-----------| Fireworks phase 1 - Shooting up
    LDA.w $1564,X               ;$03C845    |\ 
    CMP.b #$01                  ;$03C848    ||
    BNE CODE_03C85B             ;$03C84A    ||
    LDY.w $1534,X               ;$03C84C    || Once time to, play the second/third part of the firework shooting sound effect.
    LDA.w FireworkSfx1,Y        ;$03C84F    ||
    STA.w $1DF9                 ;$03C852    ||
    LDA.w FireworkSfx2,Y        ;$03C855    ||
    STA.w $1DFC                 ;$03C858    |/
CODE_03C85B:                    ;           |
    JSL UpdateYPosNoGrvty       ;$03C85B    | Update Y position.
    INC $B6,X                   ;$03C85F    |\ 
    LDA $B6,X                   ;$03C861    ||
    AND.b #$03                  ;$03C863    || Handle Y deceleration.
    BNE CODE_03C869             ;$03C865    ||
    INC $AA,X                   ;$03C867    |/
CODE_03C869:                    ;           |
    LDA $AA,X                   ;$03C869    |\ 
    CMP.b #$FC                  ;$03C86B    || Branch if it hasn't slowed down enough to explode.
    BNE CODE_03C885             ;$03C86D    |/
    INC $C2,X                   ;$03C86F    | Increment phase pointer to 2.
    LDY.w $1534,X               ;$03C871    |\ 
    LDA.w DATA_03C83D,Y         ;$03C874    || Set initial speed for the explosion's particles.
    STA.w $151C,X               ;$03C877    |/
    LDA.w DATA_03C841,Y         ;$03C87A    |\ Set timer for waiting before the exposion sound.
    STA.w $15AC,X               ;$03C87D    |/
    LDA.b #$08                  ;$03C880    |\ Set timer for the background color flash.
    STA.w $156D                 ;$03C882    |/
CODE_03C885:                    ;           |
    JSR CODE_03C96D             ;$03C885    | Draw the firework.
    RTS                         ;$03C888    |



DATA_03C889:                    ;$03C889    | Maximum sizes for each explosion.
    db $FF,$80,$C0,$FF

CODE_03C88D:                    ;-----------| Fireworks phase 2 - Exploding
    LDA.w $15AC,X               ;$03C88D    |\ 
    DEC A                       ;$03C890    ||
    BNE CODE_03C8A2             ;$03C891    ||
    LDY.w $1534,X               ;$03C893    || Once time to, play the explosion part of the firework sound effect.
    LDA.w FireworkSfx3,Y        ;$03C896    ||
    STA.w $1DF9                 ;$03C899    ||
    LDA.w FireworkSfx4,Y        ;$03C89C    ||
    STA.w $1DFC                 ;$03C89F    |/
CODE_03C8A2:                    ;           |
    JSR CODE_03C8B1             ;$03C8A2    |\ 
    LDA $C2,X                   ;$03C8A5    ||
    CMP.b #$02                  ;$03C8A7    || Expand the explosion. Run twice per frame, for some reason.
    BNE CODE_03C8AE             ;$03C8A9    ||
    JSR CODE_03C8B1             ;$03C8AB    |/
CODE_03C8AE:                    ;           |
    JMP CODE_03C9E9             ;$03C8AE    | Draw the particles.

CODE_03C8B1:                    ;```````````| Subroutine to expand the firework's explosion.
    LDY.w $1534,X               ;$03C8B1    |\ 
    LDA.w $1570,X               ;$03C8B4    ||
    CLC                         ;$03C8B7    || Expand the explosion.
    ADC.w $151C,X               ;$03C8B8    ||  Branch if it's overflows, to cap at #$FF.
    STA.w $1570,X               ;$03C8BB    ||
    BCS CODE_03C8DB             ;$03C8BE    |/
    CMP.w DATA_03C889,Y         ;$03C8C0    |\ Branch if at the maximum size for this explosion.
    BCS CODE_03C8E0             ;$03C8C3    |/
    LDA.w $151C,X               ;$03C8C5    |\ 
    CMP.b #$02                  ;$03C8C8    ||
    BCC CODE_03C8D4             ;$03C8CA    ||
    SEC                         ;$03C8CC    ||
    SBC.b #$01                  ;$03C8CD    || Decelerate the speed of the explosion, then branch down.
    STA.w $151C,X               ;$03C8CF    ||
    BCS CODE_03C8E4             ;$03C8D2    ||
CODE_03C8D4:                    ;           ||
    LDA.b #$01                  ;$03C8D4    ||
    STA.w $151C,X               ;$03C8D6    |/
    BRA CODE_03C8E4             ;$03C8D9    |

CODE_03C8DB:                    ;```````````| Overflowed explosion size.
    LDA.b #$FF                  ;$03C8DB    |\ Cap at #$FF.
    STA.w $1570,X               ;$03C8DD    |/
CODE_03C8E0:                    ;```````````| At maximum explosion size.
    INC $C2,X                   ;$03C8E0    | Increment phase pointer to 3.
    STZ $AA,X                   ;$03C8E2    |
CODE_03C8E4:                    ;```````````| Not at max size.
    LDA.w $151C,X               ;$03C8E4    |\ 
    AND.b #$FF                  ;$03C8E7    ||
    TAY                         ;$03C8E9    || Get animation frame for the particles.
    LDA.w DATA_03C8F1,Y         ;$03C8EA    ||
    STA.w $1602,X               ;$03C8ED    |/
    RTS                         ;$03C8F0    |

DATA_03C8F1:                    ;$03C8F1    | Animation frames for the firework's particles as they're exploding outwards.
    db $06,$05,$04,$03,$03,$03,$03,$02
    db $02,$02,$02,$02,$02,$02,$01,$01
    db $01,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $03,$03,$03,$03,$03,$03,$03,$03
    db $03,$03,$02,$02,$02,$02,$02,$02
    db $02,$02,$02,$02,$02,$02,$02,$02
    db $02,$02,$02,$02,$02,$02,$02,$02



CODE_03C941:                    ;-----------| Fireworks phase 3 - Fading away
    LDA $13                     ;$03C941    |\ 
    AND.b #$07                  ;$03C943    || Handle downwards acceleration.
    BNE CODE_03C949             ;$03C945    ||
    INC $AA,X                   ;$03C947    |/
CODE_03C949:                    ;           |
    JSL UpdateYPosNoGrvty       ;$03C949    | Update Y position.
    LDA.b #$07                  ;$03C94D    |\ 
    LDY $AA,X                   ;$03C94F    ||\ 
    CPY.b #$08                  ;$03C951    ||| Erase the particles once they start falling fast enough.
    BNE CODE_03C958             ;$03C953    |||
    STZ.w $14C8,X               ;$03C955    ||/
CODE_03C958:                    ;           ||
    CPY.b #$03                  ;$03C958    ||
    BCC CODE_03C962             ;$03C95A    || Get "animation frame" for the particles, based on how fast they're falling.
    INC A                       ;$03C95C    ||
    CPY.b #$05                  ;$03C95D    ||
    BCC CODE_03C962             ;$03C95F    ||
    INC A                       ;$03C961    ||
CODE_03C962:                    ;           ||
    STA.w $1602,X               ;$03C962    |/
    JSR CODE_03C9E9             ;$03C965    | Draw the particles.
    RTS                         ;$03C968    |



DATA_03C969:                    ;$03C969    | Tile numbers for the fireworks.
    db $EC,$8E,$EC,$EC

CODE_03C96D:                    ;-----------| GFX routine for the firework as it's shooting upwards.
    TXA                         ;$03C96D    |\ 
    EOR $13                     ;$03C96E    || Only draw once every 4 frames (to make it flash).
    AND.b #$03                  ;$03C970    ||
    BNE Return03C9B8            ;$03C972    |/
    JSR GetDrawInfoBnk3         ;$03C974    |
    LDY.b #$00                  ;$03C977    |] OAM index (from $0300) to use for the firework.
    LDA $00                     ;$03C979    |\ Store X position to OAM.
    STA.w $0300,Y               ;$03C97B    |/
    STA.w $0304,Y               ;$03C97E    | (mistake?...)
    LDA $01                     ;$03C981    |\ Store Y position to OAM.
    STA.w $0301,Y               ;$03C983    |/
    PHX                         ;$03C986    |
    LDA.w $1534,X               ;$03C987    |\ 
    TAX                         ;$03C98A    ||
    LDA $13                     ;$03C98B    ||
    LSR                         ;$03C98D    ||
    LSR                         ;$03C98E    || Store tile number to OAM.
    AND.b #$02                  ;$03C98F    ||
    LSR                         ;$03C991    ||
    ADC.w DATA_03C969,X         ;$03C992    ||
    STA.w $0302,Y               ;$03C995    |/
    PLX                         ;$03C998    |
    LDA $13                     ;$03C999    |\ 
    ASL                         ;$03C99B    ||
    AND.b #$0E                  ;$03C99C    ||
    STA $02                     ;$03C99E    ||
    LDA $13                     ;$03C9A0    ||
    ASL                         ;$03C9A2    ||
    ASL                         ;$03C9A3    || Store YXPPCCCT to OAM.
    ASL                         ;$03C9A4    ||
    ASL                         ;$03C9A5    ||
    AND.b #$40                  ;$03C9A6    ||
    ORA $02                     ;$03C9A8    ||
    ORA.b #$31                  ;$03C9AA    ||
    STA.w $0303,Y               ;$03C9AC    |/
    TYA                         ;$03C9AF    |\ 
    LSR                         ;$03C9B0    ||
    LSR                         ;$03C9B1    || Store size to OAM as 8x8.
    TAY                         ;$03C9B2    ||
    LDA.b #$00                  ;$03C9B3    ||
    STA.w $0460,Y               ;$03C9B5    |/
Return03C9B8:                   ;           |
    RTS                         ;$03C9B8    |



DATA_03C9B9:                    ;$03C9B9    | Tile numbers for the particles as they fade away. 03 corresponds to invisible.
    db $36,$35,$C7,$34,$34,$34,$34,$24,$03,$03  ; To get a value:
    db $36,$35,$C7,$34,$34,$24,$24,$24,$24,$03  ;  take frame number mod 4 for row number, 
    db $36,$35,$C7,$34,$34,$34,$24,$24,$03,$24  ;  then value from $1602 for column number.
    db $36,$35,$C7,$34,$24,$24,$24,$24,$24,$03

DATA_03C9E1:                    ;$03C9E1    | X offsets for animating the particle's "shake" as it falls.
    db $00,$01,$01,$00,$00,$FF,$FF,$00

CODE_03C9E9:                    ;-----------| GFX routine for the exploded firework's particles.
    TXA                         ;$03C9E9    |\ 
    EOR $13                     ;$03C9EA    || $05 = base index for X offsetting the particles as they fall (making them "shake" slightly)
    STA $05                     ;$03C9EC    |/
    LDA.w $1570,X               ;$03C9EE    |\ $06 = size of the explosion
    STA $06                     ;$03C9F1    |/
    LDA.w $1602,X               ;$03C9F3    |\ $07 = animation frame for the particles
    STA $07                     ;$03C9F6    |/
    LDA $E4,X                   ;$03C9F8    |\ $08 = center X position 
    STA $08                     ;$03C9FA    |/
    LDA $D8,X                   ;$03C9FC    |\ 
    SEC                         ;$03C9FE    || $09 = center Y position
    SBC $1C                     ;$03C9FF    ||
    STA $09                     ;$03CA01    |/
    LDA.w $1534,X               ;$03CA03    |\ $0A = which firework this is
    STA $0A                     ;$03CA06    |/
    PHX                         ;$03CA08    |
    LDX.b #$3F                  ;$03CA09    |
    LDY.b #$00                  ;$03CA0B    |
CODE_03CA0D:                    ;```````````| Tile loop for the first set of particles; these ones go into $0200.
    STX $04                     ;$03CA0D    |
    LDA $0A                     ;$03CA0F    |\ 
    CMP.b #$03                  ;$03CA11    ||
    LDA.w DATA_03C626,X         ;$03CA13    ||
    BCC CODE_03CA1B             ;$03CA16    ||
    LDA.w DATA_03C6CE,X         ;$03CA18    || $00 = Max X offset of the current particle from the center
CODE_03CA1B:                    ;           ||
    SEC                         ;$03CA1B    ||
    SBC.b #$40                  ;$03CA1C    ||
    STA $00                     ;$03CA1E    |/
    PHY                         ;$03CA20    |
    LDA $0A                     ;$03CA21    |\ 
    CMP.b #$03                  ;$03CA23    ||
    LDA.w DATA_03C67A,X         ;$03CA25    ||
    BCC CODE_03CA2D             ;$03CA28    ||
    LDA.w DATA_03C722,X         ;$03CA2A    || $01 = Max Y offset of the current particle from the center
CODE_03CA2D:                    ;           ||
    SEC                         ;$03CA2D    ||
    SBC.b #$50                  ;$03CA2E    ||
    STA $01                     ;$03CA30    |/
    LDA $00                     ;$03CA32    |\ 
    BPL CODE_03CA39             ;$03CA34    ||
    EOR.b #$FF                  ;$03CA36    ||
    INC A                       ;$03CA38    ||
CODE_03CA39:                    ;           ||
    STA.w $4202                 ;$03CA39    ||
    LDA $06                     ;$03CA3C    ||
    STA.w $4203                 ;$03CA3E    ||
    NOP                         ;$03CA41    || $02 = X offset * firework size
    NOP                         ;$03CA42    ||
    NOP                         ;$03CA43    ||
    NOP                         ;$03CA44    ||
    LDA.w $4217                 ;$03CA45    ||
    LDY $00                     ;$03CA48    ||
    BPL CODE_03CA4F             ;$03CA4A    ||
    EOR.b #$FF                  ;$03CA4C    ||
    INC A                       ;$03CA4E    ||
CODE_03CA4F:                    ;           ||
    STA $02                     ;$03CA4F    |/
    LDA $01                     ;$03CA51    |\ 
    BPL CODE_03CA58             ;$03CA53    ||
    EOR.b #$FF                  ;$03CA55    ||
    INC A                       ;$03CA57    ||
CODE_03CA58:                    ;           ||
    STA.w $4202                 ;$03CA58    ||
    LDA $06                     ;$03CA5B    ||
    STA.w $4203                 ;$03CA5D    ||
    NOP                         ;$03CA60    ||
    NOP                         ;$03CA61    || $03 = X offset * firework size
    NOP                         ;$03CA62    ||
    NOP                         ;$03CA63    ||
    LDA.w $4217                 ;$03CA64    ||
    LDY $01                     ;$03CA67    ||
    BPL CODE_03CA6E             ;$03CA69    ||
    EOR.b #$FF                  ;$03CA6B    ||
    INC A                       ;$03CA6D    ||
CODE_03CA6E:                    ;           ||
    STA $03                     ;$03CA6E    |/
    LDY.b #$00                  ;$03CA70    |\ 
    LDA $07                     ;$03CA72    ||\ 
    CMP.b #$06                  ;$03CA74    |||
    BCC CODE_03CA82             ;$03CA76    |||
    LDA $05                     ;$03CA78    |||
    CLC                         ;$03CA7A    ||| If the particle is close to fading away, make it "shake" slightly from side to side.
    ADC $04                     ;$03CA7B    |||
    LSR                         ;$03CA7D    |||
    LSR                         ;$03CA7E    |||
    AND.b #$07                  ;$03CA7F    |||
    TAY                         ;$03CA81    ||/
CODE_03CA82:                    ;           ||
    LDA.w DATA_03C9E1,Y         ;$03CA82    ||
    PLY                         ;$03CA85    ||
    CLC                         ;$03CA86    || Store X position to OAM.
    ADC $02                     ;$03CA87    ||
    CLC                         ;$03CA89    ||
    ADC $08                     ;$03CA8A    ||
    STA.w $0200,Y               ;$03CA8C    |/
    LDA $03                     ;$03CA8F    |\ 
    CLC                         ;$03CA91    || Store Y position to OAM.
    ADC $09                     ;$03CA92    ||
    STA.w $0201,Y               ;$03CA94    |/
    PHX                         ;$03CA97    |
    LDA $05                     ;$03CA98    |\ 
    AND.b #$03                  ;$03CA9A    ||
    STA $0F                     ;$03CA9C    ||
    ASL                         ;$03CA9E    ||
    ASL                         ;$03CA9F    ||
    ASL                         ;$03CAA0    || Store tile number to OAM.
    ADC $0F                     ;$03CAA1    ||
    ADC $0F                     ;$03CAA3    ||
    ADC $07                     ;$03CAA5    ||
    TAX                         ;$03CAA7    ||
    LDA.w DATA_03C9B9,X         ;$03CAA8    ||
    STA.w $0202,Y               ;$03CAAB    |/
    PLX                         ;$03CAAE    |
    LDA $05                     ;$03CAAF    |\ 
    LSR                         ;$03CAB1    ||
    NOP                         ;$03CAB2    ||
    NOP                         ;$03CAB3    ||
    PHX                         ;$03CAB4    ||
    LDX $0A                     ;$03CAB5    ||
    CPX.b #$03                  ;$03CAB7    || Store YXPPCCCT to OAM.
    BEQ CODE_03CABD             ;$03CAB9    ||
    EOR $04                     ;$03CABB    ||
CODE_03CABD:                    ;           ||
    AND.b #$0E                  ;$03CABD    ||
    ORA.b #$31                  ;$03CABF    ||
    STA.w $0203,Y               ;$03CAC1    |/
    PLX                         ;$03CAC4    |
    PHY                         ;$03CAC5    |
    TYA                         ;$03CAC6    |\ 
    LSR                         ;$03CAC7    ||
    LSR                         ;$03CAC8    || Set size in OAM as 8x8.
    TAY                         ;$03CAC9    ||
    LDA.b #$00                  ;$03CACA    ||
    STA.w $0420,Y               ;$03CACC    |/
    PLY                         ;$03CACF    |
    INY                         ;$03CAD0    |\ 
    INY                         ;$03CAD1    ||
    INY                         ;$03CAD2    ||
    INY                         ;$03CAD3    || Loop for all of the particles.
    DEX                         ;$03CAD4    ||
    BMI CODE_03CADA             ;$03CAD5    ||
    JMP CODE_03CA0D             ;$03CAD7    |/

CODE_03CADA:                    ;```````````| Done with the first set of particles, now for the second.
    LDX.b #$53                  ;$03CADA    |
CODE_03CADC:                    ;```````````| Tile loop for the second set of particles; these ones go into $0300.
    STX $04                     ;$03CADC    |
    LDA $0A                     ;$03CADE    |\ 
    CMP.b #$03                  ;$03CAE0    ||
    LDA.w DATA_03C626,X         ;$03CAE2    ||
    BCC CODE_03CAEA             ;$03CAE5    ||
    LDA.w DATA_03C6CE,X         ;$03CAE7    || $00 = Max X offset of the current particle from the center
CODE_03CAEA:                    ;           ||
    SEC                         ;$03CAEA    ||
    SBC.b #$40                  ;$03CAEB    ||
    STA $00                     ;$03CAED    |/
    LDA $0A                     ;$03CAEF    |
    CMP.b #$03                  ;$03CAF1    |\ 
    LDA.w DATA_03C67A,X         ;$03CAF3    ||
    BCC CODE_03CAFB             ;$03CAF6    ||
    LDA.w DATA_03C722,X         ;$03CAF8    ||
CODE_03CAFB:                    ;           || $01 = Max Y offset of the current particle from the center
    SEC                         ;$03CAFB    ||
    SBC.b #$50                  ;$03CAFC    ||
    STA $01                     ;$03CAFE    ||
    PHY                         ;$03CB00    |/
    LDA $00                     ;$03CB01    |\ 
    BPL CODE_03CB08             ;$03CB03    ||
    EOR.b #$FF                  ;$03CB05    ||
    INC A                       ;$03CB07    ||
CODE_03CB08:                    ;           ||
    STA.w $4202                 ;$03CB08    ||
    LDA $06                     ;$03CB0B    ||
    STA.w $4203                 ;$03CB0D    ||
    NOP                         ;$03CB10    || $02 = X offset * firework size
    NOP                         ;$03CB11    ||
    NOP                         ;$03CB12    ||
    NOP                         ;$03CB13    ||
    LDA.w $4217                 ;$03CB14    ||
    LDY $00                     ;$03CB17    ||
    BPL CODE_03CB1E             ;$03CB19    ||
    EOR.b #$FF                  ;$03CB1B    ||
    INC A                       ;$03CB1D    ||
CODE_03CB1E:                    ;           ||
    STA $02                     ;$03CB1E    |/
    LDA $01                     ;$03CB20    |\ 
    BPL CODE_03CB27             ;$03CB22    ||
    EOR.b #$FF                  ;$03CB24    ||
    INC A                       ;$03CB26    ||
CODE_03CB27:                    ;           ||
    STA.w $4202                 ;$03CB27    ||
    LDA $06                     ;$03CB2A    ||
    STA.w $4203                 ;$03CB2C    ||
    NOP                         ;$03CB2F    ||
    NOP                         ;$03CB30    || $03 = X offset * firework size
    NOP                         ;$03CB31    ||
    NOP                         ;$03CB32    ||
    LDA.w $4217                 ;$03CB33    ||
    LDY $01                     ;$03CB36    ||
    BPL CODE_03CB3D             ;$03CB38    ||
    EOR.b #$FF                  ;$03CB3A    ||
    INC A                       ;$03CB3C    ||
CODE_03CB3D:                    ;           ||
    STA $03                     ;$03CB3D    |/
    LDY.b #$00                  ;$03CB3F    |\ 
    LDA $07                     ;$03CB41    ||\ 
    CMP.b #$06                  ;$03CB43    |||
    BCC CODE_03CB51             ;$03CB45    |||
    LDA $05                     ;$03CB47    |||
    CLC                         ;$03CB49    ||| If the particle is close to fading away, make it "shake" slightly from side to side.
    ADC $04                     ;$03CB4A    |||
    LSR                         ;$03CB4C    |||
    LSR                         ;$03CB4D    |||
    AND.b #$07                  ;$03CB4E    |||
    TAY                         ;$03CB50    ||/
CODE_03CB51:                    ;           ||
    LDA.w DATA_03C9E1,Y         ;$03CB51    ||
    PLY                         ;$03CB54    ||
    CLC                         ;$03CB55    || Store X position to OAM.
    ADC $02                     ;$03CB56    ||
    CLC                         ;$03CB58    ||
    ADC $08                     ;$03CB59    ||
    STA.w $0300,Y               ;$03CB5B    |/
    LDA $03                     ;$03CB5E    |\ 
    CLC                         ;$03CB60    || Store Y position to OAM.
    ADC $09                     ;$03CB61    ||
    STA.w $0301,Y               ;$03CB63    |/
    PHX                         ;$03CB66    |
    LDA $05                     ;$03CB67    |\ 
    AND.b #$03                  ;$03CB69    ||
    STA $0F                     ;$03CB6B    ||
    ASL                         ;$03CB6D    ||
    ASL                         ;$03CB6E    ||
    ASL                         ;$03CB6F    || Store tile number to OAM.
    ADC $0F                     ;$03CB70    ||
    ADC $0F                     ;$03CB72    ||
    ADC $07                     ;$03CB74    ||
    TAX                         ;$03CB76    ||
    LDA.w DATA_03C9B9,X         ;$03CB77    ||
    STA.w $0302,Y               ;$03CB7A    |/
    PLX                         ;$03CB7D    |
    LDA $05                     ;$03CB7E    |\ 
    LSR                         ;$03CB80    ||
    NOP                         ;$03CB81    ||
    NOP                         ;$03CB82    ||
    PHX                         ;$03CB83    ||
    LDX $0A                     ;$03CB84    ||
    CPX.b #$03                  ;$03CB86    || Store YXPPCCCT to OAM.
    BEQ CODE_03CB8C             ;$03CB88    ||
    EOR $04                     ;$03CB8A    ||
CODE_03CB8C:                    ;           ||
    AND.b #$0E                  ;$03CB8C    ||
    ORA.b #$31                  ;$03CB8E    ||
    STA.w $0303,Y               ;$03CB90    |/
    PLX                         ;$03CB93    |
    PHY                         ;$03CB94    |
    TYA                         ;$03CB95    |\ 
    LSR                         ;$03CB96    ||
    LSR                         ;$03CB97    || Set size in OAM as 8x8.
    TAY                         ;$03CB98    ||
    LDA.b #$00                  ;$03CB99    ||
    STA.w $0460,Y               ;$03CB9B    |/
    PLY                         ;$03CB9E    |
    INY                         ;$03CB9F    |\ 
    INY                         ;$03CBA0    ||
    INY                         ;$03CBA1    ||
    INY                         ;$03CBA2    || Loop for all of the particles.
    DEX                         ;$03CBA3    ||
    CPX.b #$3F                  ;$03CBA4    ||
    BEQ CODE_03CBAB             ;$03CBA6    ||
    JMP CODE_03CADC             ;$03CBA8    |/
CODE_03CBAB:                    ;           |
    PLX                         ;$03CBAB    |
    RTS                         ;$03CBAC    |





ChuckSprGenDispXLo:             ;$03CBAD    |
    db $14,$EC

ChuckSprGenDispXHi:             ;$03CBAF    |
    db $00,$FF

ChuckSprGenSpeed:               ;$03CBB1    |
    db $18,$E8

CODE_03CBB3:                    ;-----------| Routine to spawn a football for the Puntin' Chuck.
    JSL FindFreeSprSlot         ;$03CBB3    |\ Return if there are no empty sprite slots.
    BMI Return03CC08            ;$03CBB7    |/
    LDA.b #$1B                  ;$03CBB9    |\\ Sprite to spawn (football).
    STA.w $009E,Y               ;$03CBBB    ||
    PHX                         ;$03CBBE    ||
    TYX                         ;$03CBBF    ||
    JSL InitSpriteTables        ;$03CBC0    ||
    PLX                         ;$03CBC4    ||
    LDA.b #$08                  ;$03CBC5    ||
    STA.w $14C8,Y               ;$03CBC7    |/
    LDA $D8,X                   ;$03CBCA    |\ 
    STA.w $00D8,Y               ;$03CBCC    ||
    LDA.w $14D4,X               ;$03CBCF    ||
    STA.w $14D4,Y               ;$03CBD2    ||
    LDA $E4,X                   ;$03CBD5    ||
    STA $01                     ;$03CBD7    ||
    LDA.w $14E0,X               ;$03CBD9    ||
    STA $00                     ;$03CBDC    ||
    PHX                         ;$03CBDE    || Spawn at the Chuck's position, offset slightly in front of it.
    LDA.w $157C,X               ;$03CBDF    ||
    TAX                         ;$03CBE2    ||
    LDA $01                     ;$03CBE3    ||
    CLC                         ;$03CBE5    ||
    ADC.l ChuckSprGenDispXLo,X  ;$03CBE6    ||
    STA.w $00E4,Y               ;$03CBEA    ||
    LDA $00                     ;$03CBED    ||
    ADC.l ChuckSprGenDispXHi,X  ;$03CBEF    ||
    STA.w $14E0,Y               ;$03CBF3    |/
    LDA.l ChuckSprGenSpeed,X    ;$03CBF6    |\ Set the X speed for the football.
    STA.w $00B6,Y               ;$03CBFA    |/
    LDA.b #$E0                  ;$03CBFD    |\\ Y speed to spawn the Chuck's football with.
    STA.w $00AA,Y               ;$03CBFF    |/
    LDA.b #$10                  ;$03CC02    |\ Set the timer to pause it until it actually gets kicked.
    STA.w $1540,Y               ;$03CC04    |/
    PLX                         ;$03CC07    |
Return03CC08:                   ;           |
    RTL                         ;$03CC08    |





    ; Wendy/Lemmy misc RAM:
    ; $C2   - (from Koopa Kid) Which boss the sprite is running.
    ;          5 = Lemmy, 6 = Wendy
    ; $151C - Phase pointer.
    ;          0 = in pipe, 1 = rising, 2 = out of pipe, 3 = lowering, 4 = hit, 5 = falling, 6 = lava.
    ; $1528 - Emerged animation pointer.
    ;          0 = looking at camera, 1 = waving hands A, 2 = opening mouth, 3 = looking side to side,
    ;          4 = weird face A, 5 = legs, 6 = weird face B, 7 = waving hands B, 8 = dummy
    ; $1540 - Phase timer.
    ; $1570 - Flag for being a dummy, used to index some tables. 00 = wendy/lemmy, 10 = dummy 1, 20 = dummy 2.
    ; $1602 - Animation frame.
    ;          0/1 = hurt, 2/3 = looking at camera, 4/5 = waving hands A, 6/7 = opening mouth, 
    ;          8/9 = look side to side, A/B = weird face A, C/D = legs, E/F = weird face B,
    ;          10/11/12 = waving hands B, 13 = dummy, 14/15/16 = dummy hurt
    ; $160E - Spawn position index, for deciding which pipes to emerge each sprite from.

CODE_03CC09:                    ;-----------| Wendy/Lemmy MAIN
    PHB                         ;$03CC09    |
    PHK                         ;$03CC0A    |
    PLB                         ;$03CC0B    |
    STZ.w $1662,X               ;$03CC0C    |
    JSR CODE_03CC14             ;$03CC0F    |
    PLB                         ;$03CC12    |
    RTL                         ;$03CC13    |

CODE_03CC14:
    JSR CODE_03D484             ;$03CC14    | Draw the boss.
    LDA.w $14C8,X               ;$03CC17    |\ 
    CMP.b #$08                  ;$03CC1A    ||
    BNE Return03CC37            ;$03CC1C    || Return if dead or game frozen.
    LDA $9D                     ;$03CC1E    ||
    BNE Return03CC37            ;$03CC20    |/
    LDA.w $151C,X               ;$03CC22    |
    JSL ExecutePtr              ;$03CC25    |

PipeKoopaPtrs:                  ;$03CC29    | Pointers to the different routines for Wendy/Lemmy.
    dw CODE_03CC8A                          ; 0 - Waiting in pipe
    dw CODE_03CD21                          ; 1 - Rising from pipe
    dw CODE_03CDC7                          ; 2 - Waiting out of pipe
    dw CODE_03CDEF                          ; 3 - Lowering into pipe
    dw CODE_03CE0E                          ; 4 - Hurt
    dw CODE_03CE5A                          ; 5 - Falling
    dw CODE_03CE89                          ; 6 - Sinking in lava

Return03CC37:
    RTS                         ;$03CC37    |



DATA_03CC38:                    ;$03CC38    | Possible X spawn positions for Wendy/Lemmy and the dummies.
    db $18,$38,$58,$78,$98,$B8,$D8          ; Last byte is unused.
    db $78
    
DATA_03CC40:                    ;$03CC40    | Corresponding Y spawn positions for Lemmy and his dummies.
    db $40,$50,$50,$40,$30,$40,$50          ; Last byte is unused.
    db $40

DATA_03CC48:                    ;$03CC48    | Length of time to wait while emerging from the pipe with each animation.
    db $50,$4A,$50,$4A,$4A,$40,$4A,$48      ; Last byte used for the dummies.
    db $4A

DATA_03CC51:                    ;$03CC51    | Animations to randomly choose from for when fully emerged.
    db $02,$04,$06,$08,$0B,$0C,$0E,$10      ; Last byte used for the dummies.
    db $13

DATA_03CC5A:                    ;$03CC5A    | Indexes to the above X/Y position tables for each RNG number.
    db $00,$01,$02,$03,$04,$05,$06,$00,$01,$02,$03,$04,$05,$06,$00,$01  ; Wendy/Lemmy.
    db $02,$03,$04,$05,$06,$00,$01,$02,$03,$04,$05,$06,$00,$01,$02,$03  ; Dummy 1
    db $04,$05,$06,$00,$01,$02,$03,$04,$05,$06,$00,$01,$02,$03,$04,$05  ; Dummy 2

CODE_03CC8A:                    ;-----------| Wendy/Lemmy phase 0 - Waiting in pipe.
    LDA.w $1540,X               ;$03CC8A    |\ Return if not time to start rising.
    BNE Return03CCDF            ;$03CC8D    |/
    LDA.w $1570,X               ;$03CC8F    |\ 
    BNE CODE_03CC9D             ;$03CC92    ||
    JSL GetRand                 ;$03CC94    || Get a random number 0-F for fetching a position.
    AND.b #$0F                  ;$03CC98    ||
    STA.w $160E,X               ;$03CC9A    |/
CODE_03CC9D:                    ;           |
    LDA.w $160E,X               ;$03CC9D    |\ 
    ORA.w $1570,X               ;$03CCA0    ||
    TAY                         ;$03CCA3    ||
    LDA.w DATA_03CC5A,Y         ;$03CCA4    || Get X spawn position.
    TAY                         ;$03CCA7    ||
    LDA.w DATA_03CC38,Y         ;$03CCA8    ||
    STA $E4,X                   ;$03CCAB    |/
    LDA $C2,X                   ;$03CCAD    |\ 
    CMP.b #$06                  ;$03CCAF    ||
    LDA.w DATA_03CC40,Y         ;$03CCB1    || Get Y spawn position.
    BCC CODE_03CCB8             ;$03CCB4    ||
    LDA.b #$50                  ;$03CCB6    ||| Y position for Wendy's spawn location.
CODE_03CCB8:                    ;           ||
    STA $D8,X                   ;$03CCB8    |/
    LDA.b #$08                  ;$03CCBA    |\ 
    LDY.w $1570,X               ;$03CCBC    ||
    BNE CODE_03CCCC             ;$03CCBF    ||
    JSR CODE_03CCE2             ;$03CCC1    ||
    JSL GetRand                 ;$03CCC4    ||
    LSR                         ;$03CCC8    ||
    LSR                         ;$03CCC9    ||
    AND.b #$07                  ;$03CCCA    || Set up positions, and set animation/timer for emerging.
CODE_03CCCC:                    ;           ||  Also accounts for a dummy instead of Wendy.
    STA.w $1528,X               ;$03CCCC    ||
    TAY                         ;$03CCCF    ||
    LDA.w DATA_03CC48,Y         ;$03CCD0    ||
    STA.w $1540,X               ;$03CCD3    ||
    INC.w $151C,X               ;$03CCD6    ||
    LDA.w DATA_03CC51,Y         ;$03CCD9    ||
    STA.w $1602,X               ;$03CCDC    |/
Return03CCDF:                   ;           |
    RTS                         ;$03CCDF    |



DATA_03CCE0:                    ;$03CCE0    | Flags for the two dummies.
    db $10,$20

CODE_03CCE2:                    ;-----------| Set positions for the Wendy/Lemmy dummies.
    LDY.b #$01                  ;$03CCE2    || Base sprite slot to spawn dummies in.
    JSR CODE_03CCE8             ;$03CCE4    |
    DEY                         ;$03CCE7    |
CODE_03CCE8:                    ;           |
    LDA.b #$08                  ;$03CCE8    |\ 
    STA.w $14C8,Y               ;$03CCEA    ||
    LDA.b #$29                  ;$03CCED    ||
    STA.w $009E,Y               ;$03CCEF    || Initialize a new dummy.
    PHX                         ;$03CCF2    ||
    TYX                         ;$03CCF3    ||
    JSL InitSpriteTables        ;$03CCF4    ||
    PLX                         ;$03CCF8    |/
    LDA.w DATA_03CCE0,Y         ;$03CCF9    |\ Mark as a dummy.
    STA.w $1570,Y               ;$03CCFC    |/
    LDA $C2,X                   ;$03CCFF    |\ 
    STA.w $C2,Y                 ;$03CD01    || Set it as the same sprite as the currently processed one.
    LDA.w $160E,X               ;$03CD04    ||
    STA.w $160E,Y               ;$03CD07    |/
    LDA $E4,X                   ;$03CD0A    |\ 
    STA.w $00E4,Y               ;$03CD0C    ||
    LDA.w $14E0,X               ;$03CD0F    ||
    STA.w $14E0,Y               ;$03CD12    || Set at the same position as Wendy/Lemmy currently is.
    LDA $D8,X                   ;$03CD15    ||
    STA.w $00D8,Y               ;$03CD17    ||
    LDA.w $14D4,X               ;$03CD1A    ||
    STA.w $14D4,Y               ;$03CD1D    |/
    RTS                         ;$03CD20    |



CODE_03CD21:                    ;-----------| Wendy/Lemmy phase 1 - Rising from pipe
    LDA.w $1540,X               ;$03CD21    |\ 
    BNE CODE_03CD2E             ;$03CD24    ||
    LDA.b #$40                  ;$03CD26    || When fully extended, reset timer and switch to next phase.
    STA.w $1540,X               ;$03CD28    ||
    INC.w $151C,X               ;$03CD2B    |/
CODE_03CD2E:                    ;           |
    LDA.b #$F8                  ;$03CD2E    |\\ Y speed when rising from the pipe.
    STA $AA,X                   ;$03CD30    ||
    JSL UpdateYPosNoGrvty       ;$03CD32    |/
    RTS                         ;$03CD36    |



DATA_03CD37:                    ;$03CD37    | Animations for Wendy/Lemmy when out of the pipe.
    db $02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$02,$02,$02,$02  ; Looking at camera
    db $04,$04,$04,$04,$05,$05,$04,$05,$05,$04,$05,$05,$04,$04,$04,$04  ; Waving hands
    db $06,$06,$06,$06,$07,$07,$07,$07,$07,$07,$07,$07,$06,$06,$06,$06  ; Opening mouth
    db $08,$08,$08,$08,$08,$09,$09,$08,$08,$09,$09,$08,$08,$08,$08,$08  ; Looking side to side
    db $0B,$0B,$0B,$0B,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0A,$0B,$0B,$0B,$0B  ; Weird face A
    db $0C,$0C,$0C,$0C,$0D,$0C,$0D,$0C,$0D,$0C,$0D,$0C,$0D,$0D,$0D,$0D  ; Legs
    db $0E,$0E,$0E,$0E,$0E,$0F,$0E,$0F,$0E,$0F,$0E,$0F,$0E,$0E,$0E,$0E  ; Weird face B
    db $10,$10,$10,$10,$11,$12,$11,$10,$11,$12,$11,$10,$11,$11,$11,$11  ; Waving hands
    db $13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13,$13  ; Dummy

CODE_03CDC7:                    ;-----------| Wendy/Lemmy phase 2 - Waiting out of pipe.
    JSR CODE_03CEA7             ;$03CDC7    | Process interaction with Mario.
    LDA.w $1540,X               ;$03CDCA    |\ Branch if not time to descend back into the pipe.
    BNE CODE_03CDDA             ;$03CDCD    |/
CODE_03CDCF:                    ;           |
    LDA.b #$24                  ;$03CDCF    |\ How long Wendy/Lemmy takes to descend into their pipe.
    STA.w $1540,X               ;$03CDD1    |/
    LDA.b #$03                  ;$03CDD4    |\ Switch to phase 3 (descending into pipe).
    STA.w $151C,X               ;$03CDD6    |/
    RTS                         ;$03CDD9    |

CODE_03CDDA:                    ;```````````| Not time to descend into the pipe.
    LSR                         ;$03CDDA    |\ 
    LSR                         ;$03CDDB    ||
    STA $00                     ;$03CDDC    ||
    LDA.w $1528,X               ;$03CDDE    ||
    ASL                         ;$03CDE1    ||
    ASL                         ;$03CDE2    || Animate the boss.
    ASL                         ;$03CDE3    ||
    ASL                         ;$03CDE4    ||
    ORA $00                     ;$03CDE5    ||
    TAY                         ;$03CDE7    ||
    LDA.w DATA_03CD37,Y         ;$03CDE8    ||
    STA.w $1602,X               ;$03CDEB    |/
    RTS                         ;$03CDEE    |



CODE_03CDEF:                    ;-----------| Wendy/Lemmy phase 3 - Descending into pipe
    LDA.w $1540,X               ;$03CDEF    |\ Branch if not done descending.
    BNE CODE_03CE05             ;$03CDF2    |/
    LDA.w $1570,X               ;$03CDF4    |\ Branch if not a dummy.
    BEQ CODE_03CDFD             ;$03CDF7    |/
    STZ.w $14C8,X               ;$03CDF9    | Erase the dummy.
    RTS                         ;$03CDFC    |

CODE_03CDFD:                    ;```````````| Wendy/Lemmy fully descended.
    STZ.w $151C,X               ;$03CDFD    | Return to phase 0 (waiting in pipe).
    LDA.b #$30                  ;$03CE00    |\\ How long until Wendy/Lemmy/dummies emerge from the pipes.
    STA.w $1540,X               ;$03CE02    |/
CODE_03CE05:                    ;```````````| Not done descending.
    LDA.b #$10                  ;$03CE05    |\\ Speed at which Wendy/Lemmy descend into the pipes.
    STA $AA,X                   ;$03CE07    ||
    JSL UpdateYPosNoGrvty       ;$03CE09    |/
    RTS                         ;$03CE0D    |



CODE_03CE0E:                    ;-----------| Wendy/Lemmy phase 4 - Hurt
    LDA.w $1540,X               ;$03CE0E    |\ Branch if not done with the hurt animation.
    BNE CODE_03CE2A             ;$03CE11    |/
    INC.w $1534,X               ;$03CE13    |\ 
    LDA.w $1534,X               ;$03CE16    || Branch if Wendy/Lemmy isn't dead.
    CMP.b #$03                  ;$03CE19    ||| How much HP Wend/Lemmy have.
    BNE CODE_03CDCF             ;$03CE1B    |/
    LDA.b #$05                  ;$03CE1D    |\ Switch to phase 5 (falling).
    STA.w $151C,X               ;$03CE1F    |/
    STZ $AA,X                   ;$03CE22    |
    LDA.b #$23                  ;$03CE24    |\ SFX for Wendy/Lemmy falling.
    STA.w $1DF9                 ;$03CE26    |/
    RTS                         ;$03CE29    |

CODE_03CE2A:                    ;```````````| Not done with the hurt animation.
    LDY.w $1570,X               ;$03CE2A    |
    BNE CODE_03CE42             ;$03CE2D    |
CODE_03CE2F:                    ;```````````| Wendy/Lemmy isn't dead yet.
    CMP.b #$24                  ;$03CE2F    |\ 
    BNE CODE_03CE38             ;$03CE31    ||
    LDY.b #$29                  ;$03CE33    ||\ SFX for hitting Wendy/Lemmy (correct).
    STY.w $1DFC                 ;$03CE35    |//
CODE_03CE38:                    ;           |
    LDA $14                     ;$03CE38    |\ 
    LSR                         ;$03CE3A    ||
    LSR                         ;$03CE3B    || Get Wendy/Lemmy's animation frame (0/1).
    AND.b #$01                  ;$03CE3C    ||
    STA.w $1602,X               ;$03CE3E    |/
    RTS                         ;$03CE41    |

CODE_03CE42:                    ;```````````| Dummy was hurt.
    CMP.b #$10                  ;$03CE42    |\ 
    BNE CODE_03CE4B             ;$03CE44    ||
    LDY.b #$2A                  ;$03CE46    ||\ SFX for hitting one of the dummies (incorrect).
    STY.w $1DFC                 ;$03CE48    |//
CODE_03CE4B:                    ;           |
    LSR                         ;$03CE4B    |\ 
    LSR                         ;$03CE4C    ||
    LSR                         ;$03CE4D    || Get the dummy's animation frame.
    TAY                         ;$03CE4E    ||
    LDA.w DATA_03CE56,Y         ;$03CE4F    ||
    STA.w $1602,X               ;$03CE52    |/
    RTS                         ;$03CE55    |

DATA_03CE56:                    ;$03CE56    | Animation frames for the dummy's hurt animation.
    db $16,$16,$15,$14



CODE_03CE5A:                    ;-----------| Wendy/Lemmy phase 5 - Falling
    JSL UpdateYPosNoGrvty       ;$03CE5A    | Update Y posiiton.
    LDA $AA,X                   ;$03CE5E    |\ 
    CMP.b #$40                  ;$03CE60    ||
    BPL CODE_03CE69             ;$03CE62    || Apply gravity.
    CLC                         ;$03CE64    ||
    ADC.b #$03                  ;$03CE65    ||| How quickly Wendy/Lemmy accelerate while falling.
    STA $AA,X                   ;$03CE67    |/
CODE_03CE69:                    ;           |
    LDA.w $14D4,X               ;$03CE69    |\ 
    BEQ CODE_03CE87             ;$03CE6C    ||
    LDA $D8,X                   ;$03CE6E    || Branch if not in the lava yet.
    CMP.b #$85                  ;$03CE70    ||
    BCC CODE_03CE87             ;$03CE72    |/
    LDA.b #$06                  ;$03CE74    |\ Switch to phase 6 (sinking in lava).
    STA.w $151C,X               ;$03CE76    |/
    LDA.b #$80                  ;$03CE79    |\\ How long Wendy/Lemmy sink in the lava for.
    STA.w $1540,X               ;$03CE7B    |/
    LDA.b #$20                  ;$03CE7E    |\ SFX for Wendy/Lemmy falling in the lava.
    STA.w $1DFC                 ;$03CE80    |/
    JSL CODE_028528             ;$03CE83    | Create a lava splash. 
CODE_03CE87:                    ;```````````| Not in the lava yet.
    BRA CODE_03CE2F             ;$03CE87    | Animate the boss as they fall.



CODE_03CE89:                    ;-----------| Wendy/Lemmy phase 6 - Sinking in lava
    LDA.w $1540,X               ;$03CE89    |\ Branch if not time to erase the boss.
    BNE CODE_03CE9E             ;$03CE8C    |/
    STZ.w $14C8,X               ;$03CE8E    | Erase the boss.
    INC.w $13C6                 ;$03CE91    |\ 
    LDA.b #$FF                  ;$03CE94    ||| How long the fadeout is before the castle destruction scene appears.
    STA.w $1493                 ;$03CE96    |/
    LDA.b #$0B                  ;$03CE99    |\ SFX for the song after Wendy/Lemmy is defeated.
    STA.w $1DFB                 ;$03CE9B    |/
CODE_03CE9E:                    ;```````````| Not done sinking.
    LDA.b #$04                  ;$03CE9E    |\\ How fast Wendy/Lemmy sinks.
    STA $AA,X                   ;$03CEA0    |/
    JSL UpdateYPosNoGrvty       ;$03CEA2    | Update Y positino.
    RTS                         ;$03CEA6    |



CODE_03CEA7:                    ;-----------| Mario interaction routine for Wendy/Lemmy.
    JSL MarioSprInteract        ;$03CEA7    |\ Return if not in contact.
    BCC Return03CEF1            ;$03CEAB    |/
    LDA $7D                     ;$03CEAD    |\ 
    CMP.b #$10                  ;$03CEAF    || Branch if Mario isn't falling fast enough (to hurt him).
    BMI CODE_03CEED             ;$03CEB1    |/
    JSL DispContactMario        ;$03CEB3    | Display a contact sprite.
    LDA.b #$02                  ;$03CEB7    |\\ Points given for hitting Wendy/Lemmy/dummies.
    JSL GivePoints              ;$03CEB9    |/
    JSL BoostMarioSpeed         ;$03CEBD    | Bounce Mario.
    LDA.b #$02                  ;$03CEC1    |\ SFX for hitting Wendy/Lemmy/dummies.
    STA.w $1DF9                 ;$03CEC3    |/
    LDA.w $1570,X               ;$03CEC6    |\ 
    BNE CODE_03CEDB             ;$03CEC9    ||
    LDA.b #$28                  ;$03CECB    ||\ SFX for hitting specifically Wendy/Lemmy (not a dummy). Doubled on top of the other one.
    STA.w $1DFC                 ;$03CECD    ||/
    LDA.w $1534,X               ;$03CED0    ||\ 
    CMP.b #$02                  ;$03CED3    |||| Number of times (minus 1) that Wendy/Lemmy has to be hit before other sprites in the room are erased.
    BNE CODE_03CEDB             ;$03CED5    |||
    JSL KillMostSprites         ;$03CED7    |//
CODE_03CEDB:                    ;           |
    LDA.b #$04                  ;$03CEDB    |\ Switch to phase 4 (hurt).
    STA.w $151C,X               ;$03CEDD    |/
    LDA.b #$50                  ;$03CEE0    |\\ How long Wendy/Lemmy stalls after being hit.
    LDY.w $1570,X               ;$03CEE2    ||
    BEQ CODE_03CEE9             ;$03CEE5    ||
    LDA.b #$1F                  ;$03CEE7    ||| How long Wendy/Lemmy stalls after a dummy is hit.
CODE_03CEE9:                    ;           ||
    STA.w $1540,X               ;$03CEE9    |/
    RTS                         ;$03CEEC    |

CODE_03CEED:                    ;```````````| Wendy/Lemmy hit while not falling fast enough.
    JSL HurtMario               ;$03CEED    | Hurt Mario.
Return03CEF1:                   ;           |
    RTS                         ;$03CEF1    |



DATA_03CEF2:                    ;$03CEF2    | X offsets for Lemmy's tiles.
    db $F8,$08,$F8,$08,$00,$00
    db $F8,$08,$F8,$08,$00,$00
    db $F8,$00,$00,$00,$00,$00
    db $FB,$00,$FB,$03,$00,$00
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$00,$00,$00,$00,$00
    db $F8,$00,$08,$00,$00,$00
    db $F8,$08,$00,$06,$00,$00
    db $F8,$08,$00,$02,$00,$00
    db $F8,$08,$00,$04,$00,$08
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00

DATA_03CF7C:                    ;$03CF7C    | X offsets for Wendy's tiles.
    db $F8,$08,$F8,$08,$00,$00              ; [change $CFAF and $CFB5 to 08 to fix Wendy's bow, in conjunction with $03D1A4]
    db $F8,$08,$F8,$08,$00,$00
    db $F8,$00,$08,$00,$00,$00
    db $FB,$00,$FB,$03,$00,$00
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$00,$08,$00,$00,$00
    db $F8,$00,$08,$00,$00,$00
    db $F8,$08,$00,$06,$00,$08
    db $F8,$08,$00,$02,$00,$08
    db $F8,$08,$00,$04,$00,$08
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$08,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00
    db $F8,$08,$00,$00,$00,$00

DATA_03D006:                    ;$03D006    | Y offsets for Lemmy's tiles.
    db $04,$04,$14,$14,$00,$00
    db $04,$04,$14,$14,$00,$00
    db $00,$08,$F8,$00,$00,$00
    db $00,$08,$F8,$F8,$00,$00
    db $05,$05,$00,$F8,$F8,$00
    db $05,$05,$00,$00,$00,$00
    db $00,$08,$F8,$00,$00,$00
    db $00,$08,$00,$00,$00,$00
    db $05,$05,$00,$F8,$00,$00
    db $05,$05,$00,$F8,$00,$00
    db $05,$05,$00,$0F,$F8,$F8
    db $05,$05,$00,$F8,$F8,$00
    db $00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00
    db $05,$05,$00,$F8,$F8,$00
    db $05,$05,$00,$F8,$F8,$00
    db $04,$04,$02,$00,$00,$00
    db $04,$04,$01,$00,$00,$00
    db $04,$04,$00,$00,$00,$00
    db $05,$05,$00,$F8,$F8,$00
    db $05,$05,$00,$00,$00,$00
    db $05,$05,$03,$00,$00,$00
    db $05,$05,$04,$00,$00,$00

DATA_03D090:                    ;$03D090    | Y offsets for Wendy's tiles.
    db $04,$04,$14,$14,$00,$00
    db $04,$04,$14,$14,$00,$00
    db $00,$08,$00,$00,$00,$00
    db $00,$08,$F8,$F8,$00,$00
    db $05,$05,$00,$F8,$F8,$00
    db $05,$05,$00,$00,$00,$00
    db $00,$08,$00,$00,$00,$00
    db $00,$08,$08,$00,$00,$00
    db $05,$05,$00,$F8,$F8,$00
    db $05,$05,$00,$F8,$F8,$00
    db $05,$05,$00,$0F,$F8,$F8
    db $05,$05,$00,$F8,$F8,$00
    db $00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00
    db $05,$05,$00,$F8,$F8,$00
    db $05,$05,$00,$F8,$F8,$00
    db $04,$04,$02,$00,$00,$00
    db $04,$04,$01,$00,$00,$00
    db $04,$04,$00,$00,$00,$00
    db $05,$05,$00,$F8,$F8,$00
    db $05,$05,$00,$00,$00,$00
    db $05,$05,$03,$00,$00,$00
    db $05,$05,$04,$00,$00,$00

DATA_03D11A:                    ;$03D11A    | Lemmy (and dummies) tilemap.
    db $20,$20,$26,$26,$08,$00
    db $2E,$2E,$24,$24,$08,$00
    db $00,$28,$02,$00,$00,$00
    db $04,$28,$12,$12,$00,$00
    db $22,$22,$04,$12,$12,$00
    db $20,$20,$08,$00,$00,$00
    db $00,$28,$02,$00,$00,$00
    db $0A,$28,$13,$00,$00,$00
    db $20,$20,$0C,$02,$00,$00
    db $20,$20,$0C,$02,$00,$00
    db $22,$22,$06,$03,$12,$12
    db $20,$20,$06,$12,$12,$00
    db $2A,$2A,$00,$00,$00,$00
    db $2C,$2C,$00,$00,$00,$00
    db $20,$20,$06,$12,$12,$00
    db $20,$20,$06,$12,$12,$00
    db $22,$22,$08,$00,$00,$00
    db $20,$20,$08,$00,$00,$00
    db $2E,$2E,$08,$00,$00,$00
    db $4E,$4E,$60,$43,$43,$00
    db $4E,$4E,$64,$00,$00,$00
    db $62,$62,$64,$00,$00,$00
    db $62,$62,$64,$00,$00,$00

DATA_03D1A4:                    ;$03D1A4    | Wendy (and dummies) tilemap.
    db $20,$20,$26,$26,$48,$00      ; [change $D1D7 to 1F 1E and $D1DD to 1E 1F to fix Wendy's bow, in conjunction with $03CF7C]
    db $2E,$2E,$24,$24,$48,$00
    db $40,$28,$42,$00,$00,$00
    db $44,$28,$52,$52,$00,$00
    db $22,$22,$44,$52,$52,$00
    db $20,$20,$48,$00,$00,$00
    db $40,$28,$42,$00,$00,$00
    db $4A,$28,$53,$00,$00,$00
    db $20,$20,$4C,$1E,$1F,$00
    db $20,$20,$4C,$1F,$1E,$00
    db $22,$22,$44,$03,$52,$52
    db $20,$20,$44,$52,$52,$00
    db $2A,$2A,$00,$00,$00,$00
    db $2C,$2C,$00,$00,$00,$00
    db $20,$20,$46,$52,$52,$00
    db $20,$20,$46,$52,$52,$00
    db $22,$22,$48,$00,$00,$00
    db $20,$20,$48,$00,$00,$00
    db $2E,$2E,$48,$00,$00,$00
    db $4E,$4E,$66,$68,$68,$00
    db $4E,$4E,$6A,$00,$00,$00
    db $62,$62,$6A,$00,$00,$00
    db $62,$62,$6A,$00,$00,$00

LemmyGfxProp:                   ;$03D22E    | Lemmy's YXPPCCCT properties.
    db $05,$45,$05,$45,$05,$00
    db $05,$45,$05,$45,$05,$00
    db $05,$05,$05,$00,$00,$00
    db $05,$05,$05,$45,$00,$00
    db $05,$45,$05,$05,$45,$00
    db $05,$45,$05,$00,$00,$00
    db $05,$05,$05,$00,$00,$00
    db $05,$05,$05,$00,$00,$00
    db $05,$45,$05,$05,$00,$00
    db $05,$45,$45,$45,$00,$00
    db $05,$45,$05,$05,$05,$45
    db $05,$45,$45,$05,$45,$00
    db $05,$45,$00,$00,$00,$00
    db $05,$45,$00,$00,$00,$00
    db $05,$45,$45,$05,$45,$00
    db $05,$45,$05,$05,$45,$00
    db $05,$45,$05,$00,$00,$00
    db $05,$45,$05,$00,$00,$00
    db $05,$45,$05,$00,$00,$00
    db $07,$47,$07,$07,$47,$00
    db $07,$47,$07,$00,$00,$00
    db $07,$47,$07,$00,$00,$00
    db $07,$47,$07,$00,$00,$00

WendyGfxProp:                   ;$03D2B8    | Wendy's YXPPCCCT properties.
    db $09,$49,$09,$49,$09,$00
    db $09,$49,$09,$49,$09,$00
    db $09,$09,$09,$00,$00,$00
    db $09,$09,$09,$49,$00,$00
    db $09,$49,$09,$09,$49,$00
    db $09,$49,$09,$00,$00,$00
    db $09,$09,$09,$00,$00,$00
    db $09,$09,$09,$00,$00,$00
    db $09,$49,$09,$09,$09,$00
    db $09,$49,$49,$49,$49,$00
    db $09,$49,$09,$09,$09,$49
    db $09,$49,$49,$09,$49,$00
    db $09,$49,$00,$00,$00,$00
    db $09,$49,$00,$00,$00,$00
    db $09,$49,$49,$09,$49,$00
    db $09,$49,$09,$09,$49,$00
    db $09,$49,$09,$00,$00,$00
    db $09,$49,$09,$00,$00,$00
    db $09,$49,$09,$00,$00,$00
    db $05,$45,$05,$05,$45,$00
    db $05,$45,$05,$00,$00,$00
    db $05,$45,$05,$00,$00,$00
    db $05,$45,$05,$00,$00,$00

DATA_03D342:                    ;$03D342    | Tile sizes for Lemmy.
    db $02,$02,$02,$02,$02,$04
    db $02,$02,$02,$02,$02,$04
    db $02,$02,$00,$04,$04,$04
    db $02,$02,$00,$00,$04,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$00,$04,$04,$04
    db $02,$02,$00,$04,$04,$04
    db $02,$02,$02,$00,$04,$04
    db $02,$02,$02,$00,$04,$04
    db $02,$02,$02,$00,$00,$00
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$04,$04,$04,$04
    db $02,$02,$04,$04,$04,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$04,$04,$04

DATA_03D3CC:                    ;$03D3CC    | Tile sizes for Wendy.
    db $02,$02,$02,$02,$02,$04
    db $02,$02,$02,$02,$02,$04
    db $02,$02,$00,$04,$04,$04
    db $02,$02,$00,$00,$04,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$00,$04,$04,$04
    db $02,$02,$00,$04,$04,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$00,$00,$00
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$04,$04,$04,$04
    db $02,$02,$04,$04,$04,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$00,$00,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$04,$04,$04
    db $02,$02,$02,$04,$04,$04

DATA_03D456:                    ;$03D456    | Number of tiles in each animation frame for Lemmy (-1).
    db $04,$04,$02,$03,$04,$02,$02,$02
    db $03,$03,$05,$04,$01,$01,$04,$04
    db $02,$02,$02,$04,$02,$02,$02

DATA_03D46D:                    ;$03D46D    | Number of tiles in each animation frame for Wendy (-1).
    db $04,$04,$02,$03,$04,$02,$02,$02
    db $04,$04,$05,$04,$01,$01,$04,$04
    db $02,$02,$02,$04,$02,$02,$02

CODE_03D484:                    ;-----------| Wendy/Lemmy GFX routine.
    JSR GetDrawInfoBnk3         ;$03D484    |
    LDA.w $1602,X               ;$03D487    |\ 
    ASL                         ;$03D48A    ||
    ASL                         ;$03D48B    || Multiply animation frame by 6,
    ADC.w $1602,X               ;$03D48C    ||  to get index to the tilemap tables.
    ADC.w $1602,X               ;$03D48F    ||
    STA $02                     ;$03D492    |/
    LDA $C2,X                   ;$03D494    |\ 
    CMP.b #$06                  ;$03D496    || Branch for Wendy.
    BEQ CODE_03D4DF             ;$03D498    |/
CODE_03D49A:                    ;```````````| Lemmy GFX routine.
    PHX                         ;$03D49A    |
    LDA.w $1602,X               ;$03D49B    |\ 
    TAX                         ;$03D49E    || Get the number of tiles in this animation frame.
    LDA.w DATA_03D456,X         ;$03D49F    ||
    TAX                         ;$03D4A2    |/
CODE_03D4A3:                    ;           |
    PHX                         ;$03D4A3    |
    TXA                         ;$03D4A4    |\ 
    CLC                         ;$03D4A5    || Get the index to the current tile.
    ADC $02                     ;$03D4A6    ||
    TAX                         ;$03D4A8    |/
    LDA $00                     ;$03D4A9    |\ 
    CLC                         ;$03D4AB    || Store X position to OAM.
    ADC.w DATA_03CEF2,X         ;$03D4AC    ||
    STA.w $0300,Y               ;$03D4AF    |/
    LDA $01                     ;$03D4B2    |\ 
    CLC                         ;$03D4B4    || Store Y position to OAM.
    ADC.w DATA_03D006,X         ;$03D4B5    ||
    STA.w $0301,Y               ;$03D4B8    |/
    LDA.w DATA_03D11A,X         ;$03D4BB    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$03D4BE    |/
    LDA.w LemmyGfxProp,X        ;$03D4C1    |\ 
    ORA.b #$10                  ;$03D4C4    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03D4C6    |/
    PHY                         ;$03D4C9    |
    TYA                         ;$03D4CA    |\ 
    LSR                         ;$03D4CB    ||
    LSR                         ;$03D4CC    || Store tile size to OAM.
    TAY                         ;$03D4CD    ||
    LDA.w DATA_03D342,X         ;$03D4CE    ||
    STA.w $0460,Y               ;$03D4D1    |/
    PLY                         ;$03D4D4    |
    INY                         ;$03D4D5    |\ 
    INY                         ;$03D4D6    ||
    INY                         ;$03D4D7    ||
    INY                         ;$03D4D8    || Loop for all of the tiles.
    PLX                         ;$03D4D9    ||
    DEX                         ;$03D4DA    ||
    BPL CODE_03D4A3             ;$03D4DB    |/
CODE_03D4DD:                    ;           |
    PLX                         ;$03D4DD    |
    RTS                         ;$03D4DE    |

CODE_03D4DF:                    ;```````````| Wendy GFX routine.
    PHX                         ;$03D4DF    |
    LDA.w $1602,X               ;$03D4E0    |\ 
    TAX                         ;$03D4E3    || Get the number of tiles in this animation frame.
    LDA.w DATA_03D46D,X         ;$03D4E4    ||
    TAX                         ;$03D4E7    |/
CODE_03D4E8:                    ;           |
    PHX                         ;$03D4E8    |
    TXA                         ;$03D4E9    |\ 
    CLC                         ;$03D4EA    || Get the index to the current tile.
    ADC $02                     ;$03D4EB    ||
    TAX                         ;$03D4ED    |/
    LDA $00                     ;$03D4EE    |\ 
    CLC                         ;$03D4F0    || Store X position to OAM.
    ADC.w DATA_03CF7C,X         ;$03D4F1    ||
    STA.w $0300,Y               ;$03D4F4    |/
    LDA $01                     ;$03D4F7    |\ 
    CLC                         ;$03D4F9    || Store Y position to OAM.
    ADC.w DATA_03D090,X         ;$03D4FA    ||
    STA.w $0301,Y               ;$03D4FD    |/
    LDA.w DATA_03D1A4,X         ;$03D500    |\ Store tile number to OAM.
    STA.w $0302,Y               ;$03D503    |/
    LDA.w WendyGfxProp,X        ;$03D506    |\ 
    ORA.b #$10                  ;$03D509    || Store YXPPCCCT to OAM.
    STA.w $0303,Y               ;$03D50B    |/
    PHY                         ;$03D50E    |
    TYA                         ;$03D50F    |\ 
    LSR                         ;$03D510    ||
    LSR                         ;$03D511    || Store tile size to OAM.
    TAY                         ;$03D512    ||
    LDA.w DATA_03D3CC,X         ;$03D513    ||
    STA.w $0460,Y               ;$03D516    |/
    PLY                         ;$03D519    |
    INY                         ;$03D51A    |\ 
    INY                         ;$03D51B    ||
    INY                         ;$03D51C    ||
    INY                         ;$03D51D    || Loop for all of the tiles.
    PLX                         ;$03D51E    ||
    DEX                         ;$03D51F    ||
    BPL CODE_03D4E8             ;$03D520    |/
    BRA CODE_03D4DD             ;$03D522    |





DATA_03D524:                    ;$03D524    | OAM data for the "Mario's adventure is over..." message. In raw OAM format.
    db $18,$20,$A1,$0E,$20,$20,$88,$0E      ; Ma        Mario's adventure is over.
    db $28,$20,$AB,$0E,$30,$20,$99,$0E      ; ri        Mario,the Princess,Yoshi,
    db $38,$20,$A8,$0E,$40,$20,$BF,$0E      ; o'        and his friends are going
    db $48,$20,$AC,$0E,$58,$20,$88,$0E      ; sa        to take a vacation.
    db $60,$20,$8B,$0E,$68,$20,$AF,$0E      ; dv
    db $70,$20,$8C,$0E,$78,$20,$9E,$0E      ; en
    db $80,$20,$AD,$0E,$88,$20,$AE,$0E      ; tu
    db $90,$20,$AB,$0E,$98,$20,$8C,$0E      ; re
    db $A8,$20,$99,$0E,$B0,$20,$AC,$0E      ; is
    db $C0,$20,$A8,$0E,$C8,$20,$AF,$0E      ; ov
    db $D0,$20,$8C,$0E,$D8,$20,$AB,$0E      ; er
    db $E0,$20,$BD,$0E,$18,$30,$A1,$0E      ; .M
    db $20,$30,$88,$0E,$28,$30,$AB,$0E      ; ar
    db $30,$30,$99,$0E,$38,$30,$A8,$0E      ; io
    db $40,$30,$BE,$0E,$48,$30,$AD,$0E      ; ,t
    db $50,$30,$98,$0E,$58,$30,$8C,$0E      ; he
    db $68,$30,$A0,$0E,$70,$30,$AB,$0E      ; Pr
    db $78,$30,$99,$0E,$80,$30,$9E,$0E      ; in
    db $88,$30,$8A,$0E,$90,$30,$8C,$0E      ; ce
    db $98,$30,$AC,$0E,$A0,$30,$AC,$0E      ; ss
    db $A8,$30,$BE,$0E,$B0,$30,$B0,$0E      ; ,Y
    db $B8,$30,$A8,$0E,$C0,$30,$AC,$0E      ; os
    db $C8,$30,$98,$0E,$D0,$30,$99,$0E      ; hi
    db $D8,$30,$BE,$0E,$18,$40,$88,$0E      ; ,a
    db $20,$40,$9E,$0E,$28,$40,$8B,$0E      ; nd
    db $38,$40,$98,$0E,$40,$40,$99,$0E      ; hi
    db $48,$40,$AC,$0E,$58,$40,$8D,$0E      ; sf
    db $60,$40,$AB,$0E,$68,$40,$99,$0E      ; ri
    db $70,$40,$8C,$0E,$78,$40,$9E,$0E      ; en
    db $80,$40,$8B,$0E,$88,$40,$AC,$0E      ; ds
    db $98,$40,$88,$0E,$A0,$40,$AB,$0E      ; ar
    db $A8,$40,$8C,$0E,$B8,$40,$8E,$0E      ; eg
    db $C0,$40,$A8,$0E,$C8,$40,$99,$0E      ; oi
    db $D0,$40,$9E,$0E,$D8,$40,$8E,$0E      ; ng
    db $18,$50,$AD,$0E,$20,$50,$A8,$0E      ; to
    db $30,$50,$AD,$0E,$38,$50,$88,$0E      ; ta
    db $40,$50,$9B,$0E,$48,$50,$8C,$0E      ; ke
    db $58,$50,$88,$0E,$68,$50,$AF,$0E      ; av
    db $70,$50,$88,$0E,$78,$50,$8A,$0E      ; ac
    db $80,$50,$88,$0E,$88,$50,$AD,$0E      ; at
    db $90,$50,$99,$0E,$98,$50,$A8,$0E      ; io
    db $A0,$50,$9E,$0E,$A8,$50,$BD,$0E      ; n.

CODE_03D674:                    ;-----------| Routine to write the "Mario's adventure is over..." message.
    PHX                         ;$03D674    |
    REP #$30                    ;$03D675    |
    LDX.w $1921                 ;$03D677    |\ Return if the message isn't being written yet.
    BEQ CODE_03D6A8             ;$03D67A    |/
    DEX                         ;$03D67C    |
    LDY.w #$0000                ;$03D67D    |
CODE_03D680:                    ;```````````| Tile loop for all of the currently written letters. Loops twice per letter.
    PHX                         ;$03D680    |
    TXA                         ;$03D681    |
    ASL                         ;$03D682    |
    ASL                         ;$03D683    |
    TAX                         ;$03D684    |
    LDA.w DATA_03D524,X         ;$03D685    |\ Store X/Y position to OAM.
    STA.w $0200,Y               ;$03D688    |/
    LDA.w DATA_03D524+2,X       ;$03D68B    |\ Store tile number / YXPPCCCT to OAM.
    STA.w $0202,Y               ;$03D68E    |/
    PHY                         ;$03D691    |
    TYA                         ;$03D692    |\ 
    LSR                         ;$03D693    ||
    LSR                         ;$03D694    ||
    TAY                         ;$03D695    || Store size to OAM as 8x8.
    SEP #$20                    ;$03D696    ||
    LDA.b #$00                  ;$03D698    ||
    STA.w $0420,Y               ;$03D69A    ||
    REP #$20                    ;$03D69D    |/
    PLY                         ;$03D69F    |
    PLX                         ;$03D6A0    |
    INY                         ;$03D6A1    |\ 
    INY                         ;$03D6A2    ||
    INY                         ;$03D6A3    || Loop for all of the tiles.
    INY                         ;$03D6A4    ||
    DEX                         ;$03D6A5    ||
    BPL CODE_03D680             ;$03D6A6    |/
CODE_03D6A8:                    ;           |
    SEP #$30                    ;$03D6A8    |
    PLX                         ;$03D6AA    |
    RTS                         ;$03D6AB    |



Empty03D6AC:                    ;$03D6AC    |
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF





DATA_03D700:                    ; X positions to to erase breaking Reznor's bridge, offset from the center of the room.
    db $B0,$A0,$90,$80,$70,$60,$50,$40
    db $30,$20,$10,$00

CODE_03D70C:                    ;-----------| Routine to break Reznor's bridge.
    PHX                         ;$03D70C    |
    LDA.w $1520                 ;$03D70D    |\ 
    CLC                         ;$03D710    ||
    ADC.w $1521                 ;$03D711    || Return if enough Reznors (at least 2) haven't died yet.
    ADC.w $1522                 ;$03D714    ||
    ADC.w $1523                 ;$03D717    ||
    CMP.b #$02                  ;$03D71A    ||| How many Reznors need to be killed for the bridge to begin breaking.
    BCC CODE_03D757             ;$03D71C    |/
BreakBridge:                    ;           |
    LDX.w $1B9F                 ;$03D71E    |\ Return if the bridge is done breaking.
    CPX.b #$0C                  ;$03D721    ||| How many pairs of tiles there are in Reznor's bridge.
    BCS CODE_03D757             ;$03D723    |/
    LDA.l DATA_03D700,X         ;$03D725    |\ 
    STA $9A                     ;$03D729    || Get X position of the tile to break.
    STZ $9B                     ;$03D72B    |/
    LDA.b #$B0                  ;$03D72D    |\\ Y position of Reznor's bridge, for breaking it.
    STA $98                     ;$03D72F    ||
    STZ $99                     ;$03D731    |/
    LDA.w $14A7                 ;$03D733    |\ Branch if time to reset the timer until the next block breaks.
    BEQ CODE_03D74A             ;$03D736    |/
    CMP.b #$3C                  ;$03D738    |\ Return if not time to break the bridge part.
    BNE CODE_03D757             ;$03D73A    |/
    JSR CODE_03D77F             ;$03D73C    | Erase the tile on the left.
    JSR CODE_03D759             ;$03D73F    |\ Erase the tile on the right.
    JSR CODE_03D77F             ;$03D742    |/
    INC.w $1B9F                 ;$03D745    |\ Increment counter for next block and return.
    BRA CODE_03D757             ;$03D748    |/

CODE_03D74A:                    ;```````````| Reset the timer for breaking Reznor's bridge.
    JSR CODE_03D766             ;$03D74A    |
    LDA.b #$40                  ;$03D74D    |\\ How many frames to wait before breaking each bridge tile.
    STA.w $14A7                 ;$03D74F    |/
    LDA.b #$07                  ;$03D752    |\ SFX for destroying a tile in Reznor's bridge.
    STA.w $1DFC                 ;$03D754    |/
CODE_03D757:                    ;           |
    PLX                         ;$03D757    |
    RTL                         ;$03D758    |


CODE_03D759:                    ;```````````| Subroutine to get the position of the second block to break.
    REP #$20                    ;$03D759    |
    LDA.w #$0170                ;$03D75B    |\ 
    SEC                         ;$03D75E    || Get X position of the block on other side of the room.
    SBC $9A                     ;$03D75F    ||
    STA $9A                     ;$03D761    |/
    SEP #$20                    ;$03D763    |
    RTS                         ;$03D765    |


CODE_03D766:                    ;```````````| Subroutine to generate smoke at the destroyed bridge positions.
    JSR CODE_03D76C             ;$03D766    | Generate smoke for the left bridge tile.
    JSR CODE_03D759             ;$03D769    | Get position of the right bridge tile (to generate smoke at it, too).
CODE_03D76C:                    ;           |
    REP #$20                    ;$03D76C    |
    LDA $9A                     ;$03D76E    |\ 
    SEC                         ;$03D770    ||
    SBC $1A                     ;$03D771    || Return if horizontally offscreen.
    CMP.w #$0100                ;$03D773    ||
    SEP #$20                    ;$03D776    ||
    BCS Return03D77E            ;$03D778    |/
    JSL CODE_028A44             ;$03D77A    | Generate smoke.
Return03D77E:                   ;           |
    RTS                         ;$03D77E    |


CODE_03D77F:                    ;```````````| Subroutine to erase a bridge tile in Reznor's fight.
    LDA $9A                     ;$03D77F    |\ 
    LSR                         ;$03D781    ||
    LSR                         ;$03D782    ||
    LSR                         ;$03D783    ||
    STA $01                     ;$03D784    ||
    LSR                         ;$03D786    ||
    ORA $98                     ;$03D787    ||
    REP #$20                    ;$03D789    ||
    AND.w #$00FF                ;$03D78B    || Get Map16 index to the tile to ovewrite.
    LDX $9B                     ;$03D78E    ||  $00 = 16-bit value to append to the VRAM data write for the X position of the tile.
    BEQ CODE_03D798             ;$03D790    ||
    CLC                         ;$03D792    ||
    ADC.w #$01B0                ;$03D793    ||
    LDX.b #$04                  ;$03D796    ||
CODE_03D798:                    ;           ||
    STX $00                     ;$03D798    ||
    REP #$10                    ;$03D79A    ||
    TAX                         ;$03D79C    |/
    SEP #$20                    ;$03D79D    |
    LDA.b #$25                  ;$03D79F    |\ 
    STA.l $7EC800,X             ;$03D7A1    || Write a blank tile to Map16.
    LDA.b #$00                  ;$03D7A5    ||
    STA.l $7FC800,X             ;$03D7A7    |/
    REP #$20                    ;$03D7AB    |
    LDA.l $7F837B               ;$03D7AD    |\ 
    TAX                         ;$03D7B1    ||
    LDA.w #$C05A                ;$03D7B2    ||
    CLC                         ;$03D7B5    ||
    ADC $00                     ;$03D7B6    ||
    STA.l $7F837D,X             ;$03D7B8    || Write to the VRAM upload table:
    ORA.w #$2000                ;$03D7BC    ||  5A C0 40 02 - FC 38
    STA.l $7F8383,X             ;$03D7BF    ||  5A E0 40 02 - FC 38
    LDA.w #$0240                ;$03D7C3    ||  FF
    STA.l $7F837F,X             ;$03D7C6    || With X position factored into the first 2 bytes of each row.
    STA.l $7F8385,X             ;$03D7CA    ||
    LDA.w #$38FC                ;$03D7CE    ||
    STA.l $7F8381,X             ;$03D7D1    ||
    STA.l $7F8387,X             ;$03D7D5    ||
    LDA.w #$00FF                ;$03D7D9    ||
    STA.l $7F8389,X             ;$03D7DC    |/
    TXA                         ;$03D7E0    |\ 
    CLC                         ;$03D7E1    || Increment stripe image index.
    ADC.w #$000C                ;$03D7E2    ||
    STA.l $7F837B               ;$03D7E5    |/
    SEP #$30                    ;$03D7E9    |
    RTS                         ;$03D7EB    |





IggyPlatform:                   ;$03D7EC    | Iggy/Larry platform tilemap. Values here are also used to handle interaction.
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$15,$16,$17,$18,$17,$18,$17,$18,$17,$18,$19,$1A,$00,$00
    db $00,$00,$01,$02,$03,$04,$03,$04,$03,$04,$03,$04,$05,$12,$00,$00
    db $00,$00,$00,$07,$04,$03,$04,$03,$04,$03,$04,$03,$08,$00,$00,$00
    db $00,$00,$00,$09,$0A,$04,$03,$04,$03,$04,$03,$0B,$0C,$00,$00,$00
    db $00,$00,$00,$00,$0D,$0E,$04,$03,$04,$03,$0F,$10,$00,$00,$00,$00
    db $00,$00,$00,$00,$11,$02,$03,$04,$03,$04,$05,$12,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$07,$04,$03,$04,$03,$08,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$09,$0A,$04,$03,$0B,$0C,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$13,$03,$04,$14,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$13,$14,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

DATA_03D8EC:                    ;$03D8EC    | Map16 data for each of the tiles listed above. Refer to this image for tiles:  http://i.imgur.com/uEvZD71.png
    db $FF,$FF,$FF,$FF          ; 00
    db $FF,$FF,$24,$34          ; 01
    db $25,$0B,$26,$36          ; 02
    db $0E,$1B,$0C,$1C          ; 03
    db $0D,$1D,$0E,$1E          ; 04
    db $29,$39,$2A,$3A          ; 05
    db $2B,$3B,$26,$38          ; 06
    db $20,$30,$21,$31          ; 07
    db $27,$37,$28,$38          ; 08
    db $FF,$FF,$22,$32          ; 09
    db $0E,$33,$0C,$1C          ; 0A
    db $0D,$1D,$0E,$3C          ; 0B
    db $2D,$3D,$FF,$FF          ; 0C
    db $07,$17,$0E,$23          ; 0D
    db $0E,$04,$0C,$1C          ; 0E
    db $0D,$1D,$0E,$09          ; 0F
    db $0E,$2C,$0A,$1A          ; 10
    db $FF,$FF,$24,$34          ; 11
    db $2B,$3B,$FF,$FF          ; 12
    db $07,$17,$0E,$18          ; 13
    db $0E,$19,$0A,$1A          ; 14
    db $02,$12,$03,$13          ; 15
    db $03,$08,$03,$05          ; 16
    db $03,$05,$03,$14          ; 17
    db $03,$15,$03,$05          ; 18
    db $03,$05,$03,$08          ; 19
    db $03,$06,$0F,$1F          ; 1A

CODE_03D958:                    ;-----------| Routine to clear out the Mode 7 tilemap. Also uploads Iggy/Larry's platform tilemap in their room.
    REP #$10                    ;$03D958    |
    STZ.w $2115                 ;$03D95A    |\ 
    STZ.w $2116                 ;$03D95D    ||
    STZ.w $2117                 ;$03D960    ||
    LDX.w #$4000                ;$03D963    ||
    LDA.b #$FF                  ;$03D966    || Clear out FG/BG GFX files and Layer 1/2 tilemaps.
CODE_03D968:                    ;           ||
    STA.w $2118                 ;$03D968    ||
    DEX                         ;$03D96B    ||
    BNE CODE_03D968             ;$03D96C    |/
    SEP #$10                    ;$03D96E    |
    BIT.w $0D9B                 ;$03D970    |\ Return if not in Iggy/Larry's rooms.
    BVS Return03D990            ;$03D973    |/
    PHB                         ;$03D975    |
    PHK                         ;$03D976    |
    PLB                         ;$03D977    |
    LDA.b #$EC                  ;$03D978    |\ 
    STA $05                     ;$03D97A    ||
    LDA.b #$D7                  ;$03D97C    || $05 = pointer to $03D7EC.
    STA $06                     ;$03D97E    ||
    LDA.b #$03                  ;$03D980    ||
    STA $07                     ;$03D982    |/
    LDA.b #$10                  ;$03D984    |\ 
    STA $00                     ;$03D986    || $00 = Base VRAM address to write to (0810).
    LDA.b #$08                  ;$03D988    ||
    STA $01                     ;$03D98A    |/
    JSR CODE_03D991             ;$03D98C    | Upload the tilemap.
    PLB                         ;$03D98F    |
Return03D990:                   ;           |
    RTL                         ;$03D990    |


CODE_03D991:                    ;```````````| Subroutine to upload the tilemap for Iggy/Larry's platform.
    STZ.w $2115                 ;$03D991    |
    LDY.b #$00                  ;$03D994    |
CODE_03D996:                    ;```````````| Outer loop; this loop uploads each row of the tilemap.
    STY $02                     ;$03D996    |  $02 = row number
    LDA.b #$00                  ;$03D998    |
CODE_03D99A:                    ;```````````| Inner loop (2); this loop uploads the full tilemap data for each tile in a row.
    STA $03                     ;$03D99A    |   $03 = counter for which half of the tilemap to write.
    LDA $00                     ;$03D99C    |\ 
    STA.w $2116                 ;$03D99E    || Store VRAM address to write to.
    LDA $01                     ;$03D9A1    ||
    STA.w $2117                 ;$03D9A3    |/
    LDY $02                     ;$03D9A6    |
    LDA.b #$10                  ;$03D9A8    |\ $04 = col number
    STA $04                     ;$03D9AA    |/
CODE_03D9AC:                    ;```````````| Inner loop; this loop uploads one half of the tilemap data for each tile in a row.
    LDA [$05],Y                 ;$03D9AC    |\ Load tile number to $0AF6.
    STA.w $0AF6,Y               ;$03D9AE    |/
    ASL                         ;$03D9B1    |\ 
    ASL                         ;$03D9B2    ||
    ORA $03                     ;$03D9B3    ||
    TAX                         ;$03D9B5    || Upload half of the 8x8 tilemap to VRAM.
    LDA.l DATA_03D8EC,X         ;$03D9B6    ||
    STA.w $2118                 ;$03D9BA    ||
    LDA.l DATA_03D8EC+2,X       ;$03D9BD    ||
    STA.w $2118                 ;$03D9C1    |/
    INY                         ;$03D9C4    |\ 
    DEC $04                     ;$03D9C5    || Loop for all tiles in the row.
    BNE CODE_03D9AC             ;$03D9C7    |/
    LDA $00                     ;$03D9C9    |\ 
    CLC                         ;$03D9CB    ||
    ADC.b #$80                  ;$03D9CC    || Increment VRAM pointer to next row.
    STA $00                     ;$03D9CE    ||
    BCC CODE_03D9D4             ;$03D9D0    ||
    INC $01                     ;$03D9D2    |/
CODE_03D9D4:                    ;           |
    LDA $03                     ;$03D9D4    |\ 
    EOR.b #$01                  ;$03D9D6    || Loop for the second half of the tilemap.
    BNE CODE_03D99A             ;$03D9D8    |/
    TYA                         ;$03D9DA    |\ Loop for all rows of the tilemap.
    BNE CODE_03D996             ;$03D9DB    |/
    RTS                         ;$03D9DD    |





DATA_03D9DE:                    ;$03D9DE    | Morton, Roy, and Ludwig Mode 7 tilemap.
    db $FF,$00,$FF,$FF,$02,$04,$06,$FF  ; $0000 (00) - Morton walk A
    db $08,$0A,$0C,$FF,$0E,$10,$12,$FF
    db $FF,$00,$FF,$FF,$02,$04,$06,$FF  ; $0010 (01) - Morton walk B
    db $08,$0A,$0C,$FF,$0E,$14,$16,$FF
    db $FF,$00,$FF,$FF,$02,$04,$06,$FF  ; $0020 (02) - Morton walk C
    db $08,$0A,$0C,$FF,$0E,$18,$1A,$FF
    db $46,$48,$4A,$FF,$4C,$4E,$50,$FF  ; $0030 (03) - Unused (Morton fireballs A)
    db $52,$54,$0C,$FF,$0E,$18,$1A,$FF
    db $FF,$FF,$FF,$FF,$B2,$B4,$06,$FF  ; $0040 (04) - Unused (Morton fireballs B)
    db $D2,$D4,$0C,$FF,$0E,$18,$1A,$FF
    db $FF,$1C,$FF,$FF,$1E,$20,$22,$FF  ; $0050 (05) - Morton turning
    db $24,$26,$28,$FF,$FF,$2A,$2C,$FF
    db $FF,$2E,$30,$FF,$32,$34,$35,$33  ; $0060 (06) - Morton hurt A / falling
    db $36,$38,$39,$37,$42,$44,$45,$43
    db $FF,$2E,$30,$FF,$32,$34,$35,$33  ; $0070 (07) - Morton hurt B
    db $36,$38,$39,$37,$42,$44,$45,$43
    db $FF,$2E,$30,$FF,$32,$34,$35,$33  ; $0080 (08) - Unused (Morton dying?)
    db $36,$38,$39,$37,$3E,$40,$41,$3F
    
    db $5A,$FF,$FF,$FF,$5C,$5E,$06,$FF  ; $0090 (00) - Roy walk A
    db $08,$0A,$0C,$FF,$0E,$10,$12,$FF            
    db $5A,$FF,$FF,$FF,$5C,$5E,$06,$FF  ; $00A0 (01) - Roy walk B
    db $08,$0A,$0C,$FF,$0E,$14,$16,$FF            
    db $5A,$FF,$FF,$FF,$5C,$5E,$06,$FF  ; $00B0 (02) - Roy walk C
    db $08,$0A,$0C,$FF,$0E,$18,$1A,$FF            
    db $6C,$6E,$FF,$FF,$72,$74,$50,$FF  ; $00C0 (03) - Unused (Roy fireballs A)
    db $52,$54,$0C,$FF,$0E,$18,$1A,$FF            
    db $FF,$BE,$FF,$FF,$DC,$DE,$06,$FF  ; $00D0 (04) - Unused (Roy fireballs B)
    db $D2,$D4,$0C,$FF,$0E,$18,$1A,$FF            
    db $60,$62,$FF,$FF,$64,$66,$22,$FF  ; $00E0 (05) - Roy turning
    db $24,$26,$28,$FF,$FF,$2A,$2C,$FF            
    db $FF,$68,$69,$FF,$32,$6A,$6B,$33  ; $00F0 (06) - Roy hurt A / falling
    db $36,$38,$39,$37,$42,$44,$45,$43            
    db $FF,$68,$69,$FF,$32,$6A,$6B,$33  ; $0100 (07) - Roy hurt B
    db $36,$38,$39,$37,$42,$44,$45,$43            
    db $FF,$68,$69,$FF,$32,$6A,$6B,$33  ; $0110 (08) - Unused (Roy dying?)
    db $36,$38,$39,$37,$3E,$40,$41,$3F
    
    db $7A,$7C,$FF,$FF,$7E,$80,$82,$FF  ; $0120 (00) - Ludwig walk A
    db $84,$86,$0C,$FF,$0E,$10,$12,$FF            
    db $7A,$7C,$FF,$FF,$7E,$80,$06,$FF  ; $0130 (01) - Ludwig walk B
    db $84,$86,$0C,$FF,$0E,$14,$16,$FF            
    db $7A,$7C,$FF,$FF,$7E,$80,$06,$FF  ; $0140 (02) - Ludwig walk C
    db $84,$86,$0C,$FF,$0E,$18,$1A,$FF            
    db $A0,$A2,$A4,$FF,$A6,$A8,$AA,$FF  ; $0150 (03) - Ludwig fireballs A
    db $52,$54,$0C,$FF,$0E,$18,$1A,$FF            
    db $FF,$B8,$FF,$FF,$D6,$D8,$DA,$FF  ; $0160 (04) - Ludwig fireballs B
    db $D2,$D4,$0C,$FF,$0E,$18,$1A,$FF            
    db $88,$8A,$8C,$FF,$8E,$90,$92,$FF  ; $0170 (05) - Ludwig turning
    db $94,$96,$28,$FF,$FF,$2A,$2C,$FF            
    db $98,$9A,$9B,$99,$9C,$9E,$9F,$9D  ; $0180 (06) - Ludwig hurt A
    db $36,$38,$39,$37,$42,$44,$45,$43            
    db $98,$9A,$9B,$99,$9C,$9E,$9F,$9D  ; $0190 (07) - Ludwig hurt B
    db $36,$38,$39,$37,$42,$44,$45,$43            
    db $98,$9A,$9B,$99,$9C,$9E,$9F,$9D  ; $01A0 (08) - Unused (Ludwig dying?)
    db $36,$38,$39,$37,$3E,$40,$41,$3F

    db $FF,$FF,$FF,$FF,$FF,$CC,$FF,$FF  ; $01B0 (1B) - Ludwig shell A
    db $C0,$C2,$C4,$FF,$E0,$E2,$E4,$FF
    db $FF,$FF,$FF,$FF,$FF,$CC,$FF,$FF  ; $01C0 (1D) - Ludwig shell B
    db $C6,$C8,$CA,$FF,$E6,$E8,$EA,$FF
    db $FF,$FF,$FF,$FF,$FF,$CD,$FF,$FF  ; $01D0 (1E) - Ludwig shell C
    db $C5,$C3,$C1,$FF,$E5,$E3,$E1,$FF


DATA_03DBBE:                    ;$03DBBE    | Bowser's Mode 7 tilemap, indexed from $03D9DE. Reznor also uses index $02C0.
    db $FF,$90,$92,$94,$96,$FF,$FF,$FF  ; $01E0 (00) - Bowser normal
    db $FF,$B0,$B2,$B4,$B6,$38,$FF,$FF
    db $FF,$D0,$D2,$D4,$D6,$58,$5A,$FF
    db $FF,$F0,$F2,$F4,$F6,$78,$7A,$FF
    db $FF,$90,$92,$94,$96,$FF,$FF,$FF  ; $0200 (02) - Bowser ducking A / blinking A
    db $FF,$98,$9A,$9C,$B6,$38,$FF,$FF
    db $FF,$D0,$D2,$D4,$D6,$58,$5A,$FF
    db $FF,$F0,$F2,$F4,$F6,$78,$7A,$FF
    db $FF,$90,$92,$94,$96,$FF,$FF,$FF  ; $0220 (04) - Bowser ducking B / blinking B
    db $FF,$98,$BA,$BC,$B6,$38,$FF,$FF
    db $FF,$D8,$DA,$DC,$D6,$58,$5A,$FF
    db $FF,$F8,$FA,$FC,$F6,$78,$7A,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $0240 (06) - Bowser ducking C
    db $FF,$FF,$90,$92,$94,$96,$FF,$FF
    db $FF,$FF,$98,$BA,$BC,$B6,$38,$FF
    db $FF,$FF,$D8,$DA,$DC,$D6,$58,$5A
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $0260 (08) - Bowser ducking D
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$90,$92,$94,$96,$FF,$FF
    db $FF,$FF,$98,$BA,$BC,$B6,$38,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $0280 (0A) - Bowser ducking E
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$90,$92,$94,$96,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $02A0 (0C) - Bowser hit
    db $FF,$90,$92,$94,$96,$FF,$FF,$FF
    db $FF,$98,$BA,$BC,$B6,$38,$FF,$FF
    db $FF,$D8,$DA,$DC,$D6,$58,$5A,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  ; $02C0 (0E) - Bowser hidden inside car, Reznor (i.e. don't draw)
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $04,$06,$08,$0A,$0B,$09,$07,$05  ; $02E0 (10) - Bowser hurt A
    db $24,$26,$28,$2A,$2C,$29,$27,$25
    db $FF,$84,$86,$88,$89,$87,$85,$FF
    db $FF,$A4,$A6,$A8,$A9,$A7,$A5,$FF
    db $04,$06,$08,$0A,$0B,$09,$07,$05  ; $0300 (12) - Bowser hurt B
    db $24,$26,$28,$2D,$2B,$29,$27,$25
    db $FF,$84,$86,$88,$89,$87,$85,$FF
    db $FF,$A4,$A6,$0C,$0D,$A7,$A5,$FF
    db $80,$82,$83,$8A,$82,$83,$8C,$8E  ; $0320 (00) - Clown Car row 1 (normal)
    db $A0,$A2,$A3,$C4,$A2,$A3,$AC,$AE
    db $80,$8A,$8A,$8A,$8A,$8A,$8C,$8E  ; $0330 (01) - Clown Car row 1 (blinking)
    db $A0,$60,$61,$C4,$60,$61,$AC,$AE
    db $80,$03,$01,$8A,$00,$02,$8C,$8E  ; $0340 (02) - Clown Car row 1 (hurt)
    db $A0,$23,$21,$C4,$20,$22,$AC,$AE
    db $80,$00,$02,$8A,$03,$01,$AA,$8E  ; $0350 (03) - Clown Car row 1 (angry)
    db $A0,$20,$22,$C4,$23,$21,$AC,$AE
    db $C0,$C2,$C4,$C4,$C4,$CA,$CC,$CE  ; $0360 - Clown Car row 2
    db $E0,$E2,$E4,$E6,$E8,$EA,$EC,$EE
    db $40,$42,$44,$46,$48,$4A,$4C,$4E  ; $0370 - Clown Car row 3
    db $FF,$62,$64,$66,$68,$6A,$6C,$FF
    db $10,$12,$14,$16,$18,$1A,$1C,$1E  ; $0380 - Clown Car green top (with Bowser's hands)
    db $10,$30,$32,$34,$36,$1A,$1C,$1E  ; $0388 - Clown Car green top (without Bowser's hands)

KoopaPalPtrLo:                  ;$03DD6E    | Low byte for the pointers to Morton, Roy, Ludwig, Bowser, and Reznor's wheel palettes.
    db $BC,$A4,$98,$78,$6C

KoopaPalPtrHi:                  ;$03DD73    | High byte for the pointers to Morton, Roy, Bowser, and Reznor's wheel palettes.
    db $B2,$B2,$B2,$B3,$B3

DATA_03DD78:                    ;$03DD78    | Graphics files used for Morton, Roy, Ludwig, and Bowser. Last byte is unused.
    db $0B,$0B,$0B,$21,$00

    ; Misc RAM input:
    ; $C2 - Tilemap to load. 0 = Morton, 1 = Roy, 2 = Ludwig, 3 = Bowser, 4 = Reznor

CODE_03DD7D:                    ;-----------| Routine to load palettes and GFX files for the Mode 7 rooms.
    PHX                         ;$03DD7D    |
    PHB                         ;$03DD7E    |
    PHK                         ;$03DD7F    |
    PLB                         ;$03DD80    |
    LDY $C2,X                   ;$03DD81    |\ 
    STY.w $13FC                 ;$03DD83    || Branch if not Reznor.
    CPY.b #$04                  ;$03DD86    ||
    BNE CODE_03DD97             ;$03DD88    |/
    JSR CODE_03DE8E             ;$03DD8A    | Load Reznor's wheel tilemap.
    LDA.b #$48                  ;$03DD8D    |\\ Y position of the center of rotation for Reznor's wheel.
    STA $2C                     ;$03DD8F    |/
    LDA.b #$14                  ;$03DD91    |\\ Size of Reznor's wheel.
    STA $38                     ;$03DD93    ||
    STA $39                     ;$03DD95    |/
CODE_03DD97:                    ;```````````| Not Reznor.
    LDA.b #$FF                  ;$03DD97    |\ 
    STA $5D                     ;$03DD99    || Clear number of screens in the level.
    INC A                       ;$03DD9B    ||
    STA $5E                     ;$03DD9C    |/
    LDY.w $13FC                 ;$03DD9E    |\ 
    LDX.w DATA_03DD78,Y         ;$03DDA1    ||
    LDA.w KoopaPalPtrLo,Y       ;$03DDA4    || Get index to the palette for the current Mode 7 room.
    STA $00                     ;$03DDA7    ||  Also get the graphics file to use.
    LDA.w KoopaPalPtrHi,Y       ;$03DDA9    ||
    STA $01                     ;$03DDAC    |/
    STZ $02                     ;$03DDAE    |
    LDY.b #$0B                  ;$03DDB0    |\ 
CODE_03DDB2:                    ;           ||
    LDA [$00],Y                 ;$03DDB2    || Upload Mode 7 palette corresponding to the current boss.
    STA.w $0707,Y               ;$03DDB4    ||
    DEY                         ;$03DDB7    ||
    BPL CODE_03DDB2             ;$03DDB8    |/
    LDA.b #$80                  ;$03DDBA    |\ 
    STA.w $2115                 ;$03DDBC    || Set VRAM upload register to increment after writing to $2119,
    STZ.w $2116                 ;$03DDBF    ||  and set VRAM location to 0000 (FG1).
    STZ.w $2117                 ;$03DDC2    |/
    TXY                         ;$03DDC5    |\ If Reznor, skip.
    BEQ CODE_03DDD7             ;$03DDC6    |/
    JSL CODE_00BA28             ;$03DDC8    | Decompress GFX file to RAM.
    LDA.b #$80                  ;$03DDCC    |\ 
    STA $03                     ;$03DDCE    ||
CODE_03DDD0:                    ;           || Upload 0x80 tiles to VRAM.
    JSR CODE_03DDE5             ;$03DDD0    ||
    DEC $03                     ;$03DDD3    ||
    BNE CODE_03DDD0             ;$03DDD5    |/
CODE_03DDD7:                    ;```````````| Reznor returns here (done with the GFX file upload).
    LDX.b #$5F                  ;$03DDD7    |
CODE_03DDD9:                    ;           |
    LDA.b #$FF                  ;$03DDD9    |\ 
    STA.l $7EC680,X             ;$03DDDB    || Clear out Mode 7 tilemap.
    DEX                         ;$03DDDF    ||
    BPL CODE_03DDD9             ;$03DDE0    |/
    PLB                         ;$03DDE2    |
    PLX                         ;$03DDE3    |
    RTL                         ;$03DDE4    |


CODE_03DDE5:                    ;```````````| Subroutine to upload a single Mode 7 8x8 tile to VRAM (technically two: the tile, and its reverse).
    LDX.b #$00                  ;$03DDE5    |  Note that each pixel is 3bpp, rather than actual 8bpp.
    TXY                         ;$03DDE7    |
    LDA.b #$08                  ;$03DDE8    |\ 
    STA $05                     ;$03DDEA    || Upload one 8x8 of the GFX file to VRAM.
CODE_03DDEC:                    ;           ||
    JSR CODE_03DE39             ;$03DDEC    ||\ 
    PHY                         ;$03DDEF    |||
    TYA                         ;$03DDF0    |||
    LSR                         ;$03DDF1    ||| Get one row of pixels (in 3bpp).
    CLC                         ;$03DDF2    |||
    ADC.b #$0F                  ;$03DDF3    |||
    TAY                         ;$03DDF5    |||
    JSR CODE_03DE3C             ;$03DDF6    ||/
    LDY.b #$08                  ;$03DDF9    ||\ 
CODE_03DDFB:                    ;           |||
    LDA.w $1BA3,X               ;$03DDFB    |||
    ASL                         ;$03DDFE    |||
    ROL                         ;$03DDFF    |||
    ROL                         ;$03DE00    ||| Write each pixels's data to VRAM.
    ROL                         ;$03DE01    |||
    AND.b #$07                  ;$03DE02    |||
    STA.w $1BA3,X               ;$03DE04    |||
    STA.w $2119                 ;$03DE07    |||
    INX                         ;$03DE0A    |||
    DEY                         ;$03DE0B    |||
    BNE CODE_03DDFB             ;$03DE0C    ||/
    PLY                         ;$03DE0E    ||\ 
    DEC $05                     ;$03DE0F    ||| Loop for remaining rows.
    BNE CODE_03DDEC             ;$03DE11    |//
    LDA.b #$07                  ;$03DE13    |\ 
CODE_03DE15:                    ;           || Upload another 8x8 of the GFX file to VRAM (the "mirrored" tile).
    TAX                         ;$03DE15    ||
    LDY.b #$08                  ;$03DE16    ||\ 
    STY $05                     ;$03DE18    |||
CODE_03DE1A:                    ;           |||
    LDY.w $1BA3,X               ;$03DE1A    ||| Write each pixel's data to VRAM, in reverse.
    STY.w $2119                 ;$03DE1D    |||
    DEX                         ;$03DE20    |||
    DEC $05                     ;$03DE21    |||
    BNE CODE_03DE1A             ;$03DE23    ||/
    CLC                         ;$03DE25    ||
    ADC.b #$08                  ;$03DE26    ||
    CMP.b #$40                  ;$03DE28    ||
    BCC CODE_03DE15             ;$03DE2A    |/
    REP #$20                    ;$03DE2C    |
    LDA $00                     ;$03DE2E    |\ 
    CLC                         ;$03DE30    || Increase pointer for next tile.
    ADC.w #$0018                ;$03DE31    ||
    STA $00                     ;$03DE34    |/
    SEP #$20                    ;$03DE36    |
    RTS                         ;$03DE38    |


CODE_03DE39:                    ;```````````| Subroutine to get two bits of each pixel's data in a row.
    JSR CODE_03DE3C             ;$03DE39    |
CODE_03DE3C:                    ;```````````| Subroutine to get one bit of each pixel's data in a row.
    PHX                         ;$03DE3C    |
    LDA [$00],Y                 ;$03DE3D    |\ 
    PHY                         ;$03DE3F    ||
    LDY.b #$08                  ;$03DE40    ||
CODE_03DE42:                    ;           ||
    ASL                         ;$03DE42    || Get one bit for each pixel... backwards, for some reason.
    ROR.w $1BA3,X               ;$03DE43    ||
    INX                         ;$03DE46    ||
    DEY                         ;$03DE47    ||
    BNE CODE_03DE42             ;$03DE48    |/
    PLY                         ;$03DE4A    |
    INY                         ;$03DE4B    |
    PLX                         ;$03DE4C    |
    RTS                         ;$03DE4D    |



DATA_03DE4E:                    ;$03DE4E    | Mode 7 tilemap for Reznor's wheel.
    db $40,$41,$42,$43,$44,$45,$46,$47
    db $50,$51,$52,$53,$54,$55,$56,$57
    db $60,$61,$62,$63,$64,$65,$66,$67
    db $70,$71,$72,$73,$74,$75,$76,$77
    db $48,$49,$4A,$4B,$4C,$4D,$4E,$4F
    db $58,$59,$5A,$5B,$5C,$5D,$5E,$5F
    db $68,$69,$6A,$6B,$6C,$6D,$6E,$6F
    db $78,$79,$7A,$7B,$7C,$7D,$7E,$3F

CODE_03DE8E:                    ;-----------| Subroutine to upload Reznor's wheel to VRAM.
    STZ.w $2115                 ;$03DE8E    | Set VRAM upload register to increment after writing to $2118.
    REP #$20                    ;$03DE91    |
    LDA.w #$0A1C                ;$03DE93    |\\ Initial VRAM address.
    STA $00                     ;$03DE96    |/
    LDX.b #$00                  ;$03DE98    |
CODE_03DE9A:                    ;```````````| Upload loop.
    REP #$20                    ;$03DE9A    |
    LDA $00                     ;$03DE9C    |\ 
    CLC                         ;$03DE9E    ||
    ADC.w #$0080                ;$03DE9F    || Increase VRAM address to next row.
    STA $00                     ;$03DEA2    ||
    STA.w $2116                 ;$03DEA4    |/
    SEP #$20                    ;$03DEA7    |
    LDY.b #$08                  ;$03DEA9    |\ 
CODE_03DEAB:                    ;           || Loop through to the tiles in the row.
    LDA.l DATA_03DE4E,X         ;$03DEAB    ||\ Write tile to VRAM.
    STA.w $2118                 ;$03DEAF    ||/
    INX                         ;$03DEB2    ||
    DEY                         ;$03DEB3    ||
    BNE CODE_03DEAB             ;$03DEB4    |/
    CPX.b #$40                  ;$03DEB6    |\ Loop for all of the rows.
    BCC CODE_03DE9A             ;$03DEB8    |/
    RTS                         ;$03DEBA    |



DATA_03DEBB:                    ;$03DEBB    | Offsets for Mode 7's position from a sprite's position.
    dw $0100,$0110                          ; First value is X, second is Y.

DATA_03DEBF:                    ;$03DEBF    | Mode 7 tiles for Bowser's propelor animation (left-most two).
    db $6E,$70
    db $FF,$50
    db $FE,$FE
    db $FF,$57
    
DATA_03DEC7:                    ;$03DEC7    | Mode 7 tiles for Bowser's propelor animation (middle two).
    db $72,$74
    db $52,$54
    db $3C,$3E
    db $55,$53
    
DATA_03DECF:                    ;$03DECF    | Mode 7 tiles for Bowser's propelor animation (right-most two).
    db $76,$56
    db $56,$FF
    db $FF,$FF
    db $51,$FF
    
DATA_03DED7:                    ;$03DED7    | Mode 7 tilemap indices for the eyes of Bowser's clown car.
    dw $0320,$0330,$0340,$0350

CODE_03DEDF:                    ;-----------| Routine to handle the Mode 7 tilemap of Morton/Roy/Ludwig/Bowser.
    PHB                         ;$03DEDF    |   Also run by Reznor, to move the wheel with him.
    PHK                         ;$03DEE0    |
    PLB                         ;$03DEE1    |
    LDA.w $14E0,X               ;$03DEE2    |\ 
    XBA                         ;$03DEE5    ||
    LDA $E4,X                   ;$03DEE6    ||
    LDY.b #$00                  ;$03DEE8    ||
    JSR CODE_03DFAE             ;$03DEEA    || Move Mode 7's position with the sprite's position.
    LDA.w $14D4,X               ;$03DEED    ||
    XBA                         ;$03DEF0    ||
    LDA $D8,X                   ;$03DEF1    ||
    LDY.b #$02                  ;$03DEF3    ||
    JSR CODE_03DFAE             ;$03DEF5    |/
    PHX                         ;$03DEF8    |
    REP #$30                    ;$03DEF9    |
    STZ $06                     ;$03DEFB    |
    LDY.w #$0003                ;$03DEFD    | Number of tiles to write per row for Morton/Roy/Ludwig.
    LDA.w $0D9B                 ;$03DF00    |\ 
    LSR                         ;$03DF03    || Branch if not in Bowser's battle.
    BCC CODE_03DF44             ;$03DF04    ||
    LDA.w $1428                 ;$03DF06    ||\ 
    AND.w #$0003                ;$03DF09    |||
    ASL                         ;$03DF0C    |||
    TAX                         ;$03DF0D    |||
    LDA.l DATA_03DEBF,X         ;$03DF0E    ||| Animate the propeller of Bowser's clown car.
    STA.l $7EC681               ;$03DF12    |||
    LDA.l DATA_03DEC7,X         ;$03DF16    |||
    STA.l $7EC683               ;$03DF1A    |||
    LDA.l DATA_03DECF,X         ;$03DF1E    |||
    STA.l $7EC685               ;$03DF22    ||/
    LDA.w #$0008                ;$03DF26    ||\\ Index to write to in the Mode 7 tilemap for the top of Bowser's clown car.
    STA $06                     ;$03DF29    ||/
    LDX.w #$0380                ;$03DF2B    ||\ 
    LDA.w $1BA2                 ;$03DF2E    |||
    AND.w #$007F                ;$03DF31    ||| Use #$0380 for the top of Bowser's car if his hands are resting on it.
    CMP.w #$002C                ;$03DF34    ||| Use #$0388 if they aren't (hidden and hurt frames).
    BCC CODE_03DF3C             ;$03DF37    |||
    LDX.w #$0388                ;$03DF39    ||/
CODE_03DF3C:                    ;           ||
    TXA                         ;$03DF3C    ||
    LDX.w #$000A                ;$03DF3D    ||| Number of rows to write for Bowser.
    LDY.w #$0007                ;$03DF40    ||| Number of tiles to write per row of Bowser.
    SEC                         ;$03DF43    |/
CODE_03DF44:                    ;```````````| Not in Bowser's batle.
    STY $00                     ;$03DF44    |
    BCS CODE_03DF55             ;$03DF46    |\ 
CODE_03DF48:                    ;```````````|| Tilemap write loop.
    LDA.w $1BA2                 ;$03DF48    ||\ 
    AND.w #$007F                ;$03DF4B    |||
    ASL                         ;$03DF4E    ||| Get tilemap index for the sprite.
    ASL                         ;$03DF4F    |||
    ASL                         ;$03DF50    |||
    ASL                         ;$03DF51    |||
    LDX.w #$0003                ;$03DF52    ||// Number of rows to write for Morton/Ludwig/Bowser's body.
CODE_03DF55:                    ;           ||
    STX $02                     ;$03DF55    ||
    PHA                         ;$03DF57    ||
    LDY.w $1BA1                 ;$03DF58    ||\ 
    BPL CODE_03DF60             ;$03DF5B    ||| Unused.
    CLC                         ;$03DF5D    |||
    ADC $00                     ;$03DF5E    ||/
CODE_03DF60:                    ;           ||
    TAY                         ;$03DF60    ||\ 
    SEP #$20                    ;$03DF61    |||
    LDX $06                     ;$03DF63    ||| 
    LDA $00                     ;$03DF65    ||| Loop to store tiles for the current row.
    STA $04                     ;$03DF67    |||
CODE_03DF69:                    ;           |||
    LDA.w DATA_03D9DE,Y         ;$03DF69    |||\ 
    INY                         ;$03DF6C    ||||
    BIT.w $1BA2                 ;$03DF6D    ||||
    BPL CODE_03DF76             ;$03DF70    |||| Store tile to tilemap, and increment to next tile.
    EOR.b #$01                  ;$03DF72    |||| If high bit of $1BA2 is set, the sprite is X flipped
    DEY                         ;$03DF74    ||||  and tiles are loaded in reverse (right-to-left).
    DEY                         ;$03DF75    ||||
CODE_03DF76:                    ;           ||||
    STA.l $7EC680,X             ;$03DF76    |||/
    INX                         ;$03DF7A    |||\ 
    DEC $04                     ;$03DF7B    |||| Repeat for all tiles.
    BPL CODE_03DF69             ;$03DF7D    |||/
    STX $06                     ;$03DF7F    ||/
    REP #$20                    ;$03DF81    ||
    PLA                         ;$03DF83    ||\ 
    SEC                         ;$03DF84    ||| Move index to next row of the tilemap.
    ADC $00                     ;$03DF85    ||/
    LDX $02                     ;$03DF87    ||\ Handle Bowser's weird assembly.
    CPX.w #$0004                ;$03DF89    |||\ Row #$04 - Switch to Bowser's body.
    BEQ CODE_03DF48             ;$03DF8C    |||/
    CPX.w #$0008                ;$03DF8E    |||\ 
    BNE CODE_03DF96             ;$03DF91    |||| Row #$08 - Switch to the rest of Bowser's clown car.
    LDA.w #$0360                ;$03DF93    |||/
CODE_03DF96:                    ;           |||
    CPX.w #$000A                ;$03DF96    |||\ Row #$0A - Switch to the eyes of Bowser's clown car.
    BNE CODE_03DFA6             ;$03DF99    |||/
    LDA.w $1427                 ;$03DF9B    |||\ 
    AND.w #$0003                ;$03DF9E    ||||
    ASL                         ;$03DFA1    |||| Get the tilemap index for the eyes of Bowser's clown car.
    TAY                         ;$03DFA2    ||||
    LDA.w DATA_03DED7,Y         ;$03DFA3    |///
CODE_03DFA6:                    ;           |
    DEX                         ;$03DFA6    |\ Loop for all rows.
    BPL CODE_03DF55             ;$03DFA7    |/
    SEP #$30                    ;$03DFA9    |
    PLX                         ;$03DFAB    |
    PLB                         ;$03DFAC    |
    RTL                         ;$03DFAD    |


CODE_03DFAE:                    ;-----------| Subroutine to transfer a sprite's X/Y position to the Mode 7 position.
    PHX                         ;$03DFAE    |  Load position in A, and axis (0 = X, 2 = Y) in Y.
    TYX                         ;$03DFAF    |
    REP #$20                    ;$03DFB0    |
    EOR.w #$FFFF                ;$03DFB2    |\ 
    INC A                       ;$03DFB5    ||
    CLC                         ;$03DFB6    ||
    ADC.l DATA_03DEBB,X         ;$03DFB7    || Set Mode 7 position, accounting for screen position.
    CLC                         ;$03DFBB    ||
    ADC $1A,X                   ;$03DFBC    ||
    STA $3A,X                   ;$03DFBE    |/
    SEP #$20                    ;$03DFC0    |
    PLX                         ;$03DFC2    |
    RTS                         ;$03DFC3    |





DATA_03DFC4:                    ;$03DFC4    | Indices to Bowser's palette table.
    db $00,$0E,$1C,$2A,$38,$46,$54,$62

CODE_03DFCC:                    ;-----------| Subroutine to handle Bowser's palettes.
    PHX                         ;$03DFCC    |
    LDX.w $0681                 ;$03DFCD    |\ 
    LDA.b #$10                  ;$03DFD0    ||
    STA.w $0682,X               ;$03DFD2    || Clip back area color to black.
    STZ.w $0683,X               ;$03DFD5    ||
    STZ.w $0684,X               ;$03DFD8    ||
    STZ.w $0685,X               ;$03DFDB    |/
    TXY                         ;$03DFDE    |
    LDX.w $1FFB                 ;$03DFDF    |\ Branch if lightning is flashing.
    BNE CODE_03E01B             ;$03DFE2    |/
    LDA.w $190D                 ;$03DFE4    |\ 
    BEQ CODE_03DFF0             ;$03DFE7    ||
    REP #$20                    ;$03DFE9    || Don't handle lightning anymore once Bowser is defeated.
    LDA.w $0701                 ;$03DFEB    ||
    BRA CODE_03E031             ;$03DFEE    |/

CODE_03DFF0:                    ;```````````| Bowser isn't defeated; wait for a lightning flash.
    LDA $14                     ;$03DFF0    |\ 
    LSR                         ;$03DFF2    ||
    BCC CODE_03E036             ;$03DFF3    || Handle lightning flash timer and branch if not time to flash.
    DEC.w $1FFC                 ;$03DFF5    ||
    BNE CODE_03E036             ;$03DFF8    |/
    TAX                         ;$03DFFA    |\ 
    LDA.l CODE_04F708,X         ;$03DFFB    ||
    AND.b #$07                  ;$03DFFF    ||
    TAX                         ;$03E001    || Store a "random" amount of time to wait until the next flash, and initial intensity of the current flash.
    LDA.l DATA_04F6F8,X         ;$03E002    ||
    STA.w $1FFC                 ;$03E006    ||
    LDA.l DATA_04F700,X         ;$03E009    ||
    STA.w $1FFB                 ;$03E00D    |/
    TAX                         ;$03E010    |
    LDA.b #$08                  ;$03E011    |\ Set initial timer for the palette fade.
    STA.w $1FFD                 ;$03E013    |/
    LDA.b #$18                  ;$03E016    |\ SFX for the lightning in Bowser's fight.
    STA.w $1DFC                 ;$03E018    |/
CODE_03E01B:                    ;```````````| Lightning is flashing.
    DEC.w $1FFD                 ;$03E01B    |\ 
    BPL CODE_03E028             ;$03E01E    ||
    DEC.w $1FFB                 ;$03E020    || Decrease how bright the next flash will be, and set the timer for its length.
    LDA.b #$04                  ;$03E023    ||
    STA.w $1FFD                 ;$03E025    |/
CODE_03E028:                    ;           |
    TXA                         ;$03E028    |\ 
    ASL                         ;$03E029    ||
    TAX                         ;$03E02A    || Get background color for the current step of the flash.
    REP #$20                    ;$03E02B    ||
    LDA.l DATA_00B5DE,X         ;$03E02D    ||
CODE_03E031:                    ;           ||
    STA.w $0684,Y               ;$03E031    ||
    SEP #$20                    ;$03E034    |/
CODE_03E036:                    ;```````````| Done with the lightning flash; now handle Bowser's palette.
    LDX.w $1429                 ;$03E036    |\ 
    LDA.l DATA_03DFC4,X         ;$03E039    || Get index to the current palette.
    TAX                         ;$03E03D    |/
    LDA.b #$0E                  ;$03E03E    |\\ Number of colors to upload.
    STA $00                     ;$03E040    |/
CODE_03E042:                    ;```````````| Bowser palette loop.
    LDA.l DATA_00B69E,X         ;$03E042    |\ Store color.
    STA.w $0686,Y               ;$03E046    |/
    INX                         ;$03E049    |\ 
    INY                         ;$03E04A    || Loop for all colors.
    DEC $00                     ;$03E04B    ||
    BNE CODE_03E042             ;$03E04D    |/
    TYX                         ;$03E04F    |\ Add end sentinel byte. 
    STZ.w $0686,X               ;$03E050    |/
    INX                         ;$03E053    |
    INX                         ;$03E054    |
    INX                         ;$03E055    |
    INX                         ;$03E056    |
    STX.w $0681                 ;$03E057    |
    PLX                         ;$03E05A    |
    RTL                         ;$03E05B    |





Empty03E05C:
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF



    ; SPC data; see https://pastebin.com/raw/NHiUdUAR for a translated pointer dump.
    ; Data starts with the song offsets; first two bytes are the size (-1). Each song is then a one-byte offset and a byte for the size of its pointers.
    ; Each song then lists its phrases, with a one-byte offset and a byte for the size of its pointers; a value of 0000 indicates the end.
    ; Each phrase then contains 16-bit offsets to SPC data for each of the 8 channels (for 16 bytes total per phrase).
    
CreditsMusicData:               ;$03E400    | Music bank 3: Credits
    db $C6,$19
    db $60,$13,$78,$13,$BE,$14,$F2,$14  ; $03E402 - Song pointers. Note that songs are duplicated; only 0-4 actually matter.
    db $1C,$16,$78,$13,$BE,$14,$F2,$14
    db $1C,$16,$78,$13,$BE,$14,$F2,$14
    db $1C,$16

    db $9E,$13,$AE,$13,$BE,$13,$DE,$13  ; $03E41C - Song 1: Staff Roll
    db $CE,$13,$EE,$13,$FE,$13,$0E,$14
    db $1E,$14,$2E,$14,$3E,$14,$4E,$14
    db $5E,$14,$6E,$14,$7E,$14,$8E,$14
    db $9E,$14,$AE,$14,$00,$00
    db $94,$21,$00,$00,$00,$00,$00,$00  ; $03E442 - Phrase 1-0
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $97,$21,$BB,$21,$51,$22,$F7,$21  ; $03E452 - Phrase 1-1
    db $33,$22,$15,$22,$D9,$21,$73,$22
    db $92,$22,$B4,$23,$E2,$23,$00,$00  ; $03E462 - Phrase 1-2
    db $00,$00,$00,$00,$CC,$23,$0F,$24
    db $C9,$22,$B4,$23,$E2,$23,$00,$23  ; $03E472 - Phrase 1-4
    db $00,$00,$1A,$23,$CC,$23,$0F,$24
    db $44,$24,$6B,$24,$AF,$24,$00,$00  ; $03E482 - Phrase 1-3
    db $00,$00,$00,$00,$8E,$24,$DF,$24
    db $35,$25,$6E,$25,$B2,$25,$5C,$25  ; $03E492 - Phrase 1-5
    db $00,$00,$0F,$25,$91,$25,$E2,$25
    db $12,$26,$8D,$26,$B1,$26,$61,$26  ; $03E4A2 - Phrase 1-6
    db $00,$00,$3A,$26,$A0,$26,$E1,$26
    db $11,$27,$7E,$27,$A8,$27,$54,$27  ; $03E4B2 - Phrase 1-7
    db $00,$00,$33,$27,$94,$27,$0F,$24
    db $D1,$22,$B4,$23,$E2,$23,$00,$23  ; $03E4C2 - Phrase 1-8
    db $7E,$23,$50,$23,$CC,$23,$0F,$24
    db $14,$28,$54,$28,$80,$28,$4C,$28  ; $03E4D2 - Phrase 1-9
    db $2C,$28,$FD,$27,$6B,$28,$A4,$28
    db $C8,$28,$E7,$28,$7D,$29,$23,$29  ; $03E4E2 - Phrase 1-A
    db $5F,$29,$41,$29,$05,$29,$9F,$29
    db $D1,$22,$BE,$29,$E2,$23,$00,$23  ; $03E4F2 - Phrase 1-B
    db $7E,$23,$50,$23,$CC,$23,$0F,$24
    db $14,$28,$F5,$29,$0D,$2A,$4C,$28  ; $03E502 - Phrase 1-C
    db $2C,$28,$FD,$27,$6B,$28,$A4,$28
    db $47,$2A,$66,$2A,$00,$2B,$A2,$2A  ; $03E512 - Phrase 1-D
    db $E0,$2A,$C0,$2A,$84,$2A,$24,$2B
    db $79,$2B,$43,$2B,$E2,$23,$00,$23  ; $03E522 - Phrase 1-E
    db $E2,$2B,$AE,$2B,$CC,$23,$0F,$24
    db $47,$2C,$18,$2C,$0D,$2A,$4C,$28  ; $03E532 - Phrase 1-F
    db $5F,$2C,$30,$2C,$6B,$28,$A4,$28
    db $25,$2A,$66,$2A,$00,$2B,$A2,$2A  ; $03E542 - Phrase 1-10
    db $E0,$2A,$C0,$2A,$84,$2A,$24,$2B
    db $7F,$2C,$98,$2C,$0C,$2D,$C8,$2C  ; $03E552 - Phrase 1-11
    db $F6,$2C,$E0,$2C,$B0,$2C,$00,$00

    
    db $C2,$14,$00,$00                  ; $03E562 - Song 2: Thank You!
    db $76,$1E,$C5,$1E,$F0,$1E,$A2,$1E  ; $03E566 - Phrase 2-0
    db $03,$1F,$2A,$1F,$49,$1F,$68,$1F

    
    db $A4,$1F,$0A,$20,$4C,$20,$E9,$1F  ; $03E576 - Phrase 3-0
    db $C8,$1F,$83,$1F,$2C,$20,$7B,$20
    db $A6,$20,$C8,$20,$5A,$21,$04,$21  ; $03E586 - Phrase 3-1
    db $3E,$21,$22,$21,$E6,$20,$7A,$21
    db $D2,$14,$E2,$14,$2C,$15,$4C,$15  ; $03E596 - Song 3: Enemy Credits
    db $3C,$15,$5C,$15,$6C,$15,$7C,$15
    db $8C,$15,$9C,$15,$AC,$15,$CC,$15
    db $BC,$15,$DC,$15,$EC,$15,$AE,$13
    db $4E,$14,$5E,$14,$6E,$14,$7E,$14
    db $8E,$14,$6E,$14,$FC,$15,$6E,$14
    db $7E,$14,$8E,$14,$9E,$14,$0C,$16
    db $00,$00
    db $3D,$16,$93,$17,$BD,$17,$1B,$17  ; $03E5D0 - Phrase 3-2
    db $57,$17,$99,$16,$00,$00,$E7,$17
    db $3D,$16,$93,$17,$BD,$17,$1B,$17  ; $03E5E0 - Phrase 3-4
    db $57,$17,$DE,$16,$00,$00,$E7,$17
    db $00,$18,$EF,$18,$10,$19,$89,$18  ; $03E5F0 - Phrase 3-3
    db $BC,$18,$55,$18,$00,$00,$E7,$17
    db $31,$19,$E4,$19,$05,$1A,$8A,$19  ; $03E600 - Phrase 3-5
    db $B7,$19,$5F,$19,$00,$00,$E7,$17
    db $C8,$1A,$AB,$1B,$CC,$1B,$3F,$1B  ; $03E610 - Phrase 3-6
    db $77,$1B,$91,$1B,$00,$00,$E7,$17
    db $ED,$1B,$6E,$1C,$8F,$1C,$1B,$1C  ; $03E620 - Phrase 3-7
    db $48,$1C,$5B,$1C,$00,$00,$E7,$17
    db $C8,$1A,$AB,$1B,$CC,$1B,$3F,$1B  ; $03E630 - Phrase 3-8
    db $77,$1B,$91,$1B,$01,$1B,$E7,$17
    db $B0,$1C,$70,$1D,$90,$1D,$19,$1D  ; $03E640 - Phrase 3-9
    db $4A,$1D,$5D,$1D,$E2,$1C,$AE,$1D
    db $3D,$16,$93,$17,$BD,$17,$1B,$17  ; $03E650 - Phrase 3-A
    db $57,$17,$99,$16,$7C,$16,$E7,$17
    db $3D,$16,$93,$17,$BD,$17,$1B,$17  ; $03E660 - Phrase 3-C
    db $57,$17,$DE,$16,$7C,$16,$E7,$17
    db $00,$18,$EF,$18,$10,$19,$89,$18  ; $03E670 - Phrase 3-B
    db $BC,$18,$55,$18,$34,$18,$E7,$17
    db $26,$1A,$A6,$1A,$B7,$1A,$4E,$1A  ; $03E680 - Phrase 3-D
    db $67,$1A,$80,$1A,$40,$1A,$E7,$17
    db $32,$16,$00,$00,$00,$00,$00,$00  ; $03E690 - Phrase 3-E
    db $00,$00,$00,$00,$00,$00,$00,$00   ; 1-1, 1-B ~ 1-F, 1-D
    db $3A,$16,$00,$00,$00,$00,$00,$00  ; $03E6A0 - Phrase 3-16
    db $00,$00,$00,$00,$00,$00,$00,$00   ; 1-D ~ 1-10
    db $C1,$1D,$D4,$1D,$58,$1E,$F8,$1D  ; $03E6B0 - Phrase 3-1B
    db $3E,$1E,$0A,$1E,$E6,$1D,$24,$1E

    db $2C,$15,$4C,$15,$2C,$15,$5C,$15  ; $03E6C0 - Song 4: Enemy Credits (looped)
    db $6C,$15,$7C,$15,$6C,$15,$9C,$15   ; 3-2, 3-4, 3-2, 3-5 ~ 3-7
    db $FF,$00,$1C,$16,$00,$00           ; 3-6, 3-9


    ;; $03E6D6 - Actual SPC data begins. At some point maybe I'll actually translate this.
    db $DA,$04,$E2,$16,$E3,$90,$1B,$00  ; 0x1e8d6
    db $E4,$01,$00                      ; 0x1e8de
    db $DA,$12,$E2,$1E,$DB,$0A,$DE,$14  ; 0x1e8e1
    db $19,$27,$0C,$6D,$B4,$0C,$2E,$B7
    db $B9,$30,$6E,$B7,$0C,$2D,$B9,$0C
    db $6E,$BB,$C6,$0C,$2D,$BB,$30,$6E
    db $B9,$0C,$2D,$B3,$0C,$6E,$B4,$0C
    db $2D,$B7,$B9,$30,$6E,$B7,$0C,$2D
    db $B8,$0C,$6E,$B9,$C6,$0C,$2D,$B9
    db $30,$6E,$B7,$0C,$2D,$B8,$00
    db $DA,$12,$DB,$0F,$DE,$14,$14,$20  ; 0x1e920
    db $48,$6D,$B7,$18,$B9,$48,$B7,$0C
    db $B4,$B5,$30,$B7,$0C,$C6,$B9,$B7
    db $B9,$48,$B7,$18,$B4
    db $DA,$00,$DB,$05,$DE,$14,$19,$27  ; 0x1e93d
    db $30,$6B,$C7,$0C,$C7,$B7,$0C,$2C
    db $B9,$BC,$06,$7B,$BB,$BC,$0C,$69
    db $BB,$18,$C6,$0C,$C7,$B3,$0C,$2C
    db $B7,$BB,$06,$7B,$B9,$BB,$0C,$69
    db $B9,$18,$C6,$0C,$C7,$B2,$0C,$2C
    db $B4,$B9,$06,$7B,$B7,$B9,$0C,$69
    db $B7,$18,$C6,$0C,$C7,$06,$4B,$AD
    db $AF,$B0,$B2,$B4,$B5
    db $30,$6B,$B4,$0C,$C7,$B7,$0C,$2C  ; 0x1e982
    db $B9,$BC,$06,$7B,$BB,$BC,$0C,$69
    db $BB,$18,$C6,$0C,$C7,$B3,$0C,$2C
    db $B7,$BB,$06,$7B,$B9,$BB,$0C,$69
    db $B9,$18,$C6,$0C,$C7,$B2,$0C,$2C
    db $B4,$B9,$06,$7B,$B7,$B9,$0C,$69
    db $B7,$18,$C6,$0C,$C7,$06,$4B,$AD
    db $AF,$B0,$B2,$B4,$B5
    db $DA,$12,$DB,$08,$DE,$14,$1F,$25  ; 0x1e9bf
    db $0C,$6D,$B0,$0C,$2E,$B4,$B4,$30
    db $6E,$B4,$0C,$2D,$B4,$0C,$6E,$B7
    db $C6,$0C,$2D,$B7,$30,$6E,$B3,$0C
    db $2D,$AF,$0C,$6E,$AE,$0C,$2D,$B2
    db $B2,$30,$6E,$B2,$0C,$2D,$B2,$0C
    db $6E,$B4,$C6,$0C,$2D,$B4,$30,$6E
    db $B4,$0C,$2D,$B4
    db $DA,$12,$DB,$0C,$DE,$14,$1B,$26  ; 0x1e9fb
    db $0C,$6D,$AB,$0C,$2E,$B0,$B0,$30
    db $6E,$B0,$0C,$2D,$B0,$0C,$6E,$B3
    db $C6,$0C,$2D,$B3,$30,$6E,$AF,$0C
    db $2D,$AB,$0C,$6E,$AB,$0C,$2E,$AE
    db $AE,$30,$6E,$AE,$0C,$2D,$AE,$0C
    db $6E,$B1,$C6,$0C,$2D,$B1,$30,$6E
    db $B1,$0C,$2D,$B1
    db $DA,$04,$DB,$08,$DE,$14,$19,$28  ; 0x1ea37
    db $0C,$3B,$C7,$9C,$C7,$9C,$C7,$9C
    db $C7,$9C,$C7,$9B,$C7,$9B,$C7,$9B
    db $C7,$9B,$C7,$9A,$C7,$9A,$C7,$9A
    db $C7,$9A,$C7,$99,$C7,$99,$C7,$99
    db $C7,$99
    db $DA,$08,$DB,$0C,$DE,$14,$19,$28  ; 0x1ea61
    db $0C,$6E,$98,$9F,$93,$9F,$98,$9F
    db $93,$9F,$97,$9F,$93,$9F,$97,$9F
    db $93,$9F,$96,$9F,$93,$9F,$96,$9F
    db $93,$9F,$95,$9C,$90,$9C,$95,$9C
    db $90,$9C
    db $DA,$05,$DB,$14,$DE,$00,$00,$00  ; 0x1ea8b
    db $E9,$F3,$17,$08,$0C,$4B,$D1,$0C
    db $4C,$D2,$0C,$49,$D1,$0C,$4B,$D2
    db $00
    db $0C,$6E,$B9,$0C,$2D,$BB,$BC,$30  ; 0x1eaa4
    db $6E,$B9,$0C,$2D,$B8,$0C,$6E,$B7
    db $0C,$2D,$B8,$B9,$30,$6E,$B4,$0C
    db $C7,$12,$6E,$B4,$06,$6D,$B3,$0C
    db $2C,$B2,$12,$6E,$B4,$06,$6D,$B3
    db $0C,$2C,$B2,$0C,$2E,$B4,$B2,$30
    db $4E,$B7,$C6,$00
    db $30,$6D,$B0,$0C,$C6,$AF,$C6,$AD  ; 0x1ead8
    db $AB,$AC,$AD,$B4,$30,$C6,$24,$B4
    db $18,$B0,$0C,$AF,$B0,$B1,$30,$B2
    db $06,$C7,$AB,$AD,$AF,$B0,$B2,$B4
    db $B5
    db $06,$7B,$B4,$B5,$0C,$69,$B4,$18  ; 0x1eaf9
    db $C6,$0C,$C7,$06,$4B,$AF,$B0,$B2
    db $B4,$B5,$B6,$06,$7B,$B7,$B9,$0C
    db $69,$B7,$18,$C6,$0C,$C7,$06,$4B
    db $B2,$B4,$B5,$B7,$B9,$BB,$30,$BC
    db $C6,$BB,$0C,$C7,$06,$4B,$BB,$BC
    db $BB,$B9,$B7,$B5
    db $0C,$6E,$B5,$0C,$2D,$B5,$B9,$30  ; 0x1eb2d
    db $6E,$B6,$0C,$2D,$B6,$0C,$6E,$B4
    db $0C,$2D,$B4,$B4,$30,$6E,$B1,$0C
    db $C7,$12,$6E,$AD,$06,$6D,$AD,$0C
    db $2C,$AD,$12,$6E,$AD,$06,$6D,$AD
    db $0C,$2C,$AD,$0C,$2E,$AD,$AD,$30
    db $4E,$B2,$C6
    db $0C,$6E,$B0,$0C,$2D,$B0,$B5,$30  ; 0x1eb60
    db $6E,$B0,$0C,$2D,$B0,$0C,$6E,$B0
    db $0C,$2D,$B0,$B0,$30,$6E,$AB,$0C
    db $C7,$12,$6E,$A9,$06,$6D,$A9,$0C
    db $2C,$A9,$12,$6E,$A9,$06,$6D,$A9
    db $0C,$2C,$A9,$0C,$2E,$A9,$A9,$30
    db $4E,$AF,$C6
    db $0C,$C7,$9D,$C7,$9D,$C7,$9E,$C7  ; 0x1eb93
    db $9E,$C7,$9C,$C7,$9C,$C7,$99,$C7
    db $99,$C7,$9A,$C7,$9A,$C7,$9A,$C7
    db $9A,$C7,$97,$C7,$97,$C7,$97,$C7
    db $97
    db $0C,$91,$A1,$98,$A1,$92,$A1,$98  ; 0x1ebb4
    db $A1,$93,$9F,$98,$9F,$95,$9F,$90
    db $9F,$8E,$9D,$95,$9D,$8E,$9D,$90
    db $91,$93,$9D,$8E,$9D,$93,$9D,$8E
    db $9D
    db $0C,$6E,$B9,$0C,$2D,$BB,$BC,$30  ; 0x1ebd5
    db $6E,$B9,$0C,$2D,$B8,$0C,$6E,$B7
    db $0C,$2D,$B8,$B9,$30,$6E,$C0,$0C
    db $C7,$0C,$6E,$C0,$0C,$2D,$BF,$C0
    db $18,$6E,$BC,$0C,$2E,$BC,$18,$6E
    db $B9,$30,$4E,$BC,$C6,$00
    db $06,$7B,$B4,$B5,$0C,$69,$B4,$18  ; 0x1ec03
    db $C6,$0C,$C7,$06,$4B,$AF,$B0,$B2
    db $B4,$B5,$B6,$06,$7B,$B7,$B9,$0C
    db $69,$B7,$18,$C6,$0C,$C7,$06,$4B
    db $B2,$B4,$B5,$B7,$B9,$BB,$30,$BC
    db $BB,$60,$BC
    db $0C,$6E,$B5,$0C,$2D,$B5,$B9,$30  ; 0x1ec2e
    db $6E,$B6,$0C,$2D,$B6,$0C,$6E,$B4
    db $0C,$2D,$B4,$B4,$30,$6E,$BD,$0C
    db $C7,$0C,$6E,$B9,$0C,$2D,$B9,$B9
    db $18,$6E,$B9,$0C,$2E,$B5,$18,$6E
    db $B5,$30,$4E,$B7,$C6
    db $0C,$6E,$B0,$0C,$2D,$B0,$B5,$30  ; 0x1ec5b
    db $6E,$B0,$0C,$2D,$B0,$0C,$6E,$B0
    db $0C,$2D,$B0,$B0,$30,$6E,$B7,$0C
    db $C7,$0C,$6E,$B5,$0C,$2D,$B5,$B5
    db $18,$6E,$B5,$0C,$2E,$B2,$18,$6E
    db $B2,$30,$4E,$B4,$C6
    db $0C,$C7,$98,$C7,$98,$C7,$98,$C7  ; 0x1ec88
    db $98,$C7,$9C,$C7,$9C,$C7,$99,$C7
    db $99,$C7,$95,$C7,$95,$C7,$97,$C7
    db $97,$C7,$9C,$C7,$9C,$C7,$9C,$C7
    db $9C
    db $0C,$91,$9D,$98,$9D,$92,$9E,$98  ; 0x1eca9
    db $9E,$93,$9F,$9A,$9F,$95,$A1,$9C
    db $A1,$8E,$9A,$95,$9A,$93,$9F,$9A
    db $9F,$98,$9F,$93,$9F,$98,$98,$97
    db $96
    db $0C,$6E,$B9,$0C,$2D,$BB,$BC,$30  ; 0x1ecca
    db $6E,$B9,$0C,$2D,$B8,$0C,$6E,$B7
    db $0C,$2D,$B8,$B9,$30,$6E,$C0,$0C
    db $C7,$00
    db $30,$6D,$B0,$0C,$C6,$AF,$C6,$AD  ; 0x1ece4
    db $AB,$AC,$AD,$B4,$30,$C6
    db $0C,$6E,$B5,$0C,$2D,$B5,$B9,$30  ; 0x1ecf2
    db $6E,$B6,$0C,$2D,$B6,$0C,$6E,$B4
    db $0C,$2D,$B4,$B4,$30,$6E,$BD,$0C
    db $C7
    db $0C,$6E,$B0,$0C,$2D,$B0,$B5,$30  ; 0x1ed0b
    db $6E,$B0,$0C,$2D,$B0,$0C,$6E,$B0
    db $0C,$2D,$B0,$B0,$30,$6E,$B7,$0C
    db $C7
    db $06,$7B,$B4,$B5,$0C,$69,$B4,$18  ; 0x1ed24
    db $C6,$0C,$C7,$06,$4B,$AF,$B0,$B2
    db $B4,$B5,$B6,$06,$7B,$B7,$B9,$0C
    db $69,$B7,$18,$C6,$0C,$C7,$06,$4B
    db $B2,$B4,$B5,$B7,$B9,$BB
    db $0C,$C7,$98,$C7,$98,$C7,$98,$C7  ; 0x1ed4a
    db $98,$C7,$9C,$C7,$9C,$C7,$99,$C7
    db $99
    db $0C,$91,$9D,$98,$9D,$92,$9E,$98  ; 0x1ed5b
    db $9E,$93,$9F,$9A,$9F,$95,$A1,$9C
    db $A1
    db $DA,$12,$18,$6D,$AD,$0C,$B4,$C7  ; 0x1ed6c
    db $C7,$0C,$2D,$B4,$0C,$6E,$B3,$0C
    db $2D,$B4,$0C,$6E,$B5,$0C,$2D,$B4
    db $B1,$30,$6E,$AD,$0C,$2D,$AD,$0C
    db $6E,$B4,$0C,$2D,$B2,$0C,$6D,$B4
    db $0C,$2D,$B2,$0C,$6E,$B4,$0C,$2D
    db $B2,$C7,$0C,$6D,$AD,$30,$C6,$C7
    db $00
    db $DB,$0F,$DE,$14,$14,$20,$DA,$12  ; 0x1eda5
    db $18,$6D,$B9,$0C,$C0,$C7,$C7,$0C
    db $2D,$C0,$0C,$6E,$BF,$0C,$2D,$C0
    db $0C,$6E,$C1,$0C,$2D,$C0,$BD,$30
    db $6E,$B9,$0C,$2D,$B9,$0C,$6E,$C0
    db $0C,$2D,$BE,$0C,$6D,$C0,$0C,$2D
    db $BE,$0C,$6E,$C0,$0C,$2D,$BE,$C7
    db $0C,$6D,$B9,$30,$C6,$C7
    db $DA,$12,$18,$6D,$A8,$0C,$AB,$C7  ; 0x1ede3
    db $C7,$0C,$2D,$AB,$0C,$6E,$AA,$0C
    db $2D,$AB,$0C,$6E,$AD,$0C,$2D,$AB
    db $A8,$30,$6E,$A5,$0C,$2D,$A5,$0C
    db $6E,$AB,$0C,$2D,$AA,$0C,$6D,$AB
    db $0C,$2D,$AA,$0C,$6E,$AB,$0C,$2D
    db $AA,$C7,$0C,$6D,$A4,$30,$C6,$C7
    db $DB,$05,$DE,$19,$19,$35,$DA,$00  ; 0x1ee1b
    db $30,$6B,$A8,$0C,$C6,$A7,$A8,$AD
    db $48,$B4,$0C,$B3,$B4,$30,$B9,$B4
    db $60,$B2
    db $DB,$08,$DE,$19,$18,$34,$DA,$00  ; 0x1ee35
    db $30,$6B,$9F,$0C,$C6,$9E,$9F,$A5
    db $48,$AB,$0C,$AA,$AB,$30,$B4,$AB
    db $60,$AA
    db $0C,$C7,$99,$C7,$99,$C7,$99,$C7  ; 0x1ee4f
    db $99,$C7,$99,$C7,$99,$C7,$99,$C7
    db $99,$C7,$98,$C7,$98,$C7,$98,$C7
    db $98,$C7,$98,$C7,$98,$C7,$98,$C7
    db $98
    db $0C,$95,$9F,$90,$9F,$95,$9F,$90  ; 0x1ee70
    db $9F,$95,$9F,$90,$9F,$95,$9F,$90
    db $8F,$8E,$9E,$95,$9E,$8E,$9E,$95
    db $9E,$8E,$9E,$95,$9E,$8E,$9E,$90
    db $92
    db $18,$6D,$AB,$0C,$B2,$C7,$C7,$0C  ; 0x1ee91
    db $2D,$B2,$0C,$6E,$B1,$0C,$2D,$B2
    db $0C,$6E,$B4,$0C,$2D,$B2,$AF,$30
    db $6E,$AB,$0C,$2D,$B2,$18,$4E,$B0
    db $B0,$10,$6D,$B0,$10,$6E,$B2,$10
    db $6E,$B3,$30,$B4,$C7,$00
    db $18,$6D,$A3,$0C,$A9,$C7,$C7,$0C  ; 0x1eebf
    db $2D,$A9,$0C,$6E,$A8,$0C,$2D,$A9
    db $0C,$6E,$AB,$0C,$2D,$A9,$A6,$30
    db $6E,$A3,$0C,$2D,$A9,$18,$4E,$A8
    db $A8,$10,$6D,$A8,$10,$6E,$A9,$10
    db $6E,$AA,$30,$AC,$C7
    db $30,$69,$AB,$0C,$C6,$A9,$AB,$AF  ; 0x1eeec
    db $48,$B2,$0C,$B0,$B2,$48,$B0,$18
    db $B2,$60,$B4
    db $30,$69,$A3,$0C,$C6,$A3,$A6,$A9  ; 0x1eeff
    db $48,$AB,$0C,$A9,$AB,$48,$A8,$18
    db $AB,$60,$AC
    db $0C,$C7,$97,$C7,$97,$C7,$97,$C7  ; 0x1ef12
    db $97,$C7,$97,$C7,$97,$C7,$97,$C7
    db $97,$C7,$9C,$C7,$9C,$C7,$9C,$C7
    db $9C,$C7,$97,$C7,$97,$C7,$97,$C7
    db $97
    db $0C,$93,$9D,$8E,$9D,$93,$9D,$8E  ; 0x1ef33
    db $9D,$93,$9D,$8E,$9D,$93,$9D,$95
    db $97,$98,$9F,$93,$9F,$98,$9F,$93
    db $9F,$90,$A0,$97,$A0,$90,$A0,$92
    db $94
    db $18,$6D,$AB,$0C,$B2,$C7,$C7,$0C  ; 0x1ef54
    db $2D,$B2,$0C,$6E,$B1,$0C,$2D,$B2
    db $0C,$6E,$B4,$0C,$2D,$B2,$C7,$30
    db $6E,$AB,$0C,$2D,$B2,$18,$4E,$B0
    db $B0,$10,$6D,$B0,$10,$6E,$B2,$10
    db $6E,$B3
    db $18,$2E,$B4,$C7,$30,$4E,$B7,$00  ; 0x1ef86
    db $18,$6D,$B7,$0C,$BE,$C7,$C7,$0C
    db $2D,$BE,$0C,$6E,$BD,$0C,$2D,$BE
    db $0C,$6E,$C0,$0C,$2D,$BE,$C7,$30
    db $6E,$B7,$0C,$2D,$BE,$18,$4E,$BC
    db $BC,$10,$6D,$BC,$10,$6E,$BE,$10
    db $6E,$BF,$18,$2E,$C0,$C7,$06,$C7
    db $AB,$AD,$AF,$B0,$B2,$B4,$B5
    db $18,$6D,$A3,$0C,$A9,$C7,$C7,$0C  ; 0x1efbd
    db $2D,$A9,$0C,$6E,$A8,$0C,$2D,$A9
    db $0C,$6E,$AB,$0C,$2D,$A9,$C7,$30
    db $6E,$A3,$0C,$2D,$A9,$18,$4E,$A8
    db $A8,$10,$6D,$A8,$10,$6E,$A9,$10
    db $6E,$AA,$18,$2E,$AB,$C7,$30,$4E
    db $AF
    db $30,$69,$AB,$0C,$C6,$A9,$AB,$AF  ; 0x1efee
    db $48,$B2,$0C,$B0,$B2,$30,$B0,$B2
    db $30,$B4,$B3,$30,$69,$A3,$0C,$C6
    db $A3,$A6,$A9,$48,$AB,$0C,$A9,$AB
    db $30,$A8,$AB,$30,$AB,$AF
    db $0C,$C7,$97,$C7,$97,$C7,$97,$C7  ; 0x1f014
    db $97,$C7,$97,$C7,$97,$C7,$97,$C7
    db $97,$C7,$9C,$C7,$9C,$C7,$9C,$C7
    db $9C,$DA,$01,$18,$AF,$C7,$A7,$C6
    db $0C,$93,$9D,$8E,$9D,$93,$9D,$8E  ; 0x1f034
    db $9D,$93,$9D,$8E,$9D,$93,$9D,$95
    db $97,$98,$9F,$93,$9F,$98,$9F,$93
    db $9F,$18,$8C,$C7,$93,$C6
    db $DA,$05,$DB,$14,$DE,$00,$00,$00  ; 0x1f052
    db $E9,$F3,$17,$06,$18,$4C,$D1,$C7
    db $30,$6D,$D2
    db $DA,$04,$DB,$0A,$DE,$22,$19,$38  ; 0x1f065
    db $60,$5E,$BC,$C6,$DA,$01,$60,$C6
    db $C6,$C6,$00
    db $DA,$04,$DB,$08,$DE,$20,$18,$36  ; 0x1f078
    db $60,$5D,$B4,$C6,$DA,$01,$60,$C6
    db $C6,$C6
    db $DA,$04,$DB,$0C,$DE,$21,$1A,$37  ; 0x1f08a
    db $60,$5D,$AB,$C6,$DA,$01,$60,$C6
    db $C6,$C6
    db $DA,$04,$DB,$0A,$DE,$22,$18,$36  ; 0x1f09c
    db $60,$5D,$A4,$C6,$DA,$01,$60,$C6
    db $C6,$C6
    db $DA,$04,$DB,$0F,$10,$5D,$B0,$C7  ; 0x1f0ae
    db $B0,$AE,$C7,$AE,$AD,$C7,$AD,$AC
    db $C7,$AC,$30,$AB,$24,$A7,$6C,$A6
    db $60,$C6
    db $DA,$04,$DB,$0F,$10,$5D,$AB,$C7  ; 0x1f0c8
    db $AB,$A8,$C7,$A8,$A9,$C7,$A9,$A9
    db $C7,$A9,$30,$A6,$24,$A3,$6C,$A2
    db $60,$C6
    db $DA,$04,$DB,$0F,$10,$5D,$A8,$C7  ; 0x1f0e2
    db $A8,$A4,$C7,$A4,$A4,$C7,$A4,$A4
    db $C7,$A4,$30,$A3,$24,$9D,$6C,$9C
    db $60,$C6
    db $DA,$08,$DB,$0A,$DE,$22,$19,$38  ; 0x1f0fc
    db $10,$5D,$8C,$8C,$8C,$90,$90,$90
    db $91,$91,$91,$92,$92,$92,$30,$93
    db $24,$93,$6C,$8C,$60,$C6
    db $DA,$01,$E2,$12,$DB,$0A,$DE,$14  ; 0x1f11a
    db $19,$28,$18,$7C,$A7,$0C,$A8,$AB
    db $AD,$30,$AB,$0C,$AD,$AF,$C6,$AF
    db $30,$AD,$0C,$A7,$A8,$AB,$AD,$30
    db $AB,$0C,$AC,$AD,$C6,$AD,$60,$AB
    db $60,$77,$C6,$00
    db $DA,$02,$DB,$0A,$18,$79,$A7,$0C  ; 0x1f146
    db $A8,$AB,$AD,$30,$AB,$0C,$AD,$AF
    db $C6,$AF,$30,$AD,$0C,$A7,$A8,$AB
    db $AD,$30,$AB,$0C,$AC,$AD,$C6,$AD
    db $60,$AB,$C6
    db $DA,$01,$DB,$0C,$DE,$14,$19,$28  ; 0x1f169
    db $06,$C6,$18,$79,$A7,$0C,$A8,$AB
    db $AD,$30,$AB,$0C,$AD,$AF,$C6,$AF
    db $30,$AD,$0C,$A7,$A8,$AB,$AD,$30
    db $AB,$0C,$AC,$AD,$C6,$AD,$60,$AB
    db $60,$75,$C6
    db $DA,$01,$DB,$0A,$DE,$14,$19,$28  ; 0x1f194
    db $18,$7B,$C7,$60,$98,$97,$96,$95
    db $C6,$C6,$C6
    db $DA,$01,$DB,$0A,$DE,$14,$19,$28  ; 0x1f1a7
    db $18,$7B,$C7,$0C,$C7,$24,$9F,$30
    db $B0,$0C,$C7,$24,$9F,$30,$AF,$0C
    db $C7,$24,$9F,$30,$AE,$0C,$C7,$24
    db $9F,$30,$B1,$60,$C6,$C6,$C6
    db $DA,$01,$DB,$0A,$DE,$14,$19,$28  ; 0x1f1ce
    db $18,$7B,$C7,$18,$C7,$48,$A8,$18
    db $C7,$48,$A7,$18,$C7,$48,$A6,$18
    db $C7,$48,$A5,$60,$C6,$C6,$C6
    db $DA,$01,$DB,$0A,$DE,$14,$19,$28  ; 0x1f1ed
    db $18,$7B,$C7,$24,$C7,$3C,$AB,$24
    db $C7,$3C,$AB,$24,$C7,$3C,$AB,$24
    db $C7,$3C,$AB,$60,$C6,$C6,$C6
    db $DA,$01,$DB,$0A,$DE,$14,$19,$28  ; 0x1f20c
    db $18,$7B,$C7,$30,$C7,$B4,$30,$C7
    db $B3,$30,$C7,$B2,$30,$C7,$B4,$60
    db $C6,$C6,$C6
    db $DA,$04,$DB,$08,$DE,$22,$18,$14  ; 0x1f227
    db $08,$5C,$C7,$A9,$C7,$A9,$AD,$C7
    db $24,$AA,$0C,$C7,$08,$A9,$A8,$C7
    db $A8,$A8,$C7,$24,$AB,$0C,$C7,$08
    db $C7
    db $E2,$1C,$DA,$04,$DB,$0A,$DE,$22  ; 0x1f248
    db $18,$14,$08,$5D,$AC,$AD,$C7,$AF
    db $B0,$C7,$24,$AD,$0C,$C7,$08,$AC
    db $AB,$C7,$AC,$AD,$C7,$24,$B4,$0C
    db $C7,$08,$C7,$00
    db $DA,$04,$DB,$0C,$DE,$22,$18,$14  ; 0x1f26c
    db $08,$5C,$C7,$A4,$C7,$A4,$A9,$C7
    db $24,$A4,$0C,$C7,$08,$A4,$A4,$C7
    db $A4,$A4,$C7,$24,$A5,$0C,$C7,$08
    db $C7
    db $DA,$06,$DB,$0A,$DE,$22,$18,$14  ; 0x1f28d
    db $08,$5D,$B8,$B9,$C7,$BB,$BC,$C7
    db $24,$B9,$0C,$C7,$08,$B8,$B7,$C7
    db $B8,$B9,$C7,$24,$C0,$0C,$C7,$08
    db $C7
    db $DA,$0D,$DB,$0F,$DE,$22,$18,$14  ; 0x1f2ae
    db $01,$C7,$08,$C7,$18,$4E,$C7,$9D
    db $C7,$9E,$C7,$9F,$C7,$9F,$18,$9E
    db $08,$C7,$C7,$9D,$18,$C6,$08,$C7
    db $C7,$AB
    db $DA,$0D,$DB,$0F,$DE,$22,$18,$14  ; 0x1f2d0
    db $08,$C7,$18,$4E,$C7,$98,$C7,$98
    db $C7,$9A,$C7,$99,$18,$A1,$08,$C7
    db $C7,$A3,$18,$C6,$08,$C7,$C7,$A4
    db $DA,$08,$DB,$0A,$DE,$22,$18,$14  ; 0x1f2f0
    db $08,$C7,$18,$5F,$91,$08,$C7,$C7
    db $91,$18,$92,$08,$C7,$C7,$92,$18
    db $93,$08,$C7,$C7,$93,$18,$95,$08
    db $95,$90,$8F,$18,$8E,$08,$C6,$C7
    db $93,$18,$C6,$08,$C7,$C7,$98
    db $DA,$04,$DB,$14,$08,$C7,$18,$6C  ; 0x1f31f
    db $D1,$08,$D2,$C7,$D1,$18,$D1,$08
    db $D2,$C7,$D1,$18,$D1,$08,$D2,$C7
    db $D1,$D1,$C7,$D1,$D2,$D1,$D1,$18
    db $D2,$08,$C6,$C7,$D2,$18,$C6,$08
    db $C7,$C7,$D2
    db $DA,$04,$DB,$0A,$DE,$22,$19,$38  ; 0x1f34a
    db $18,$4D,$B4,$08,$C7,$C7,$B4,$E3
    db $60,$18,$18,$B4,$08,$C7,$C7,$B7
    db $18,$B7,$08,$C7,$C7,$B7,$18,$B7
    db $C7,$00
    db $DA,$04,$DB,$08,$DE,$20,$18,$36  ; 0x1f36c
    db $18,$4D,$A4,$08,$C7,$C7,$A4,$18
    db $A4,$08,$C7,$C7,$A7,$18,$A7,$08
    db $C7,$C7,$A7,$18,$A7,$C7
    db $DA,$04,$DB,$0C,$DE,$21,$1A,$37  ; 0x1f38a
    db $18,$4D,$AD,$08,$C7,$C7,$AD,$18
    db $AD,$08,$C7,$C7,$AF,$18,$AF,$08
    db $C7,$C7,$AF,$18,$AF,$C7
    db $DA,$04,$DB,$0A,$DE,$22,$18,$36  ; 0x1f3a8
    db $18,$4D,$A9,$08,$C7,$C7,$A9,$18
    db $A9,$08,$C7,$C7,$AB,$18,$AB,$08
    db $C7,$C7,$AB,$18,$AB,$C7
    db $DA,$04,$DB,$0F,$08,$4D,$C7,$C7  ; 0x1f3c6
    db $9A,$18,$9A,$08,$C7,$C7,$9A,$18
    db $9A,$08,$C7,$C7,$9F,$18,$9F,$18
    db $C7,$18,$7D,$9F
    db $DA,$04,$DB,$0F,$08,$4C,$C7,$C7  ; 0x1f3e2
    db $8E,$18,$8E,$08,$C7,$C7,$8E,$18
    db $8E,$08,$C7,$C7,$93,$18,$93,$18
    db $C7,$18,$7E,$93
    db $DA,$08,$DB,$0A,$DE,$22,$19,$38  ; 0x1f3fe
    db $08,$5F,$C7,$C7,$8E,$18,$8E,$08
    db $C7,$C7,$8E,$18,$8E,$08,$C7,$C7
    db $93,$18,$93,$18,$C7,$18,$7F,$93
    db $DA,$00,$DB,$0A,$08,$6C,$C7,$C7  ; 0x1f41e
    db $D0,$18,$D0,$08,$C7,$C7,$D0,$18
    db $D0,$08,$C7,$C7,$D0,$18,$D0,$18
    db $C7,$D0
    db $24,$C7,$00                      ; 0x1f438
    db $DA,$04,$E2,$16,$E3,$90,$1C,$DB  ; 0x1f43b
    db $0A,$DE,$22,$19,$38,$18,$4C,$B4
    db $08,$C7,$C7,$B4,$18,$B4,$08,$C7
    db $C7,$B7,$18,$B7,$08,$C7,$C7,$B7
    db $18,$B7,$C7,$00
    db $DA,$04,$DB,$08,$DE,$20,$18,$36  ; 0x1f45f
    db $18,$4C,$A4,$08,$C7,$C7,$A4,$18
    db $A4,$08,$C7,$C7,$A7,$18,$A7,$08
    db $C7,$C7,$A7,$18,$A7,$C7
    db $DA,$04,$DB,$0C,$DE,$21,$1A,$37  ; 0x1f47d
    db $18,$4C,$AD,$08,$C7,$C7,$AD,$18
    db $AD,$08,$C7,$C7,$AF,$18,$AF,$08
    db $C7,$C7,$AF,$18,$AF,$C7
    db $DA,$04,$DB,$0A,$DE,$22,$18,$36  ; 0x1f49b
    db $18,$4C,$A9,$08,$C7,$C7,$A9,$18
    db $A9,$08,$C7,$C7,$AB,$18,$AB,$08
    db $C7,$C7,$AB,$18,$AB,$C7
    db $DA,$04,$DB,$0F,$08,$4C,$C7,$C7  ; 0x1f4b9
    db $9A,$18,$9A,$08,$C7,$C7,$9A,$18
    db $9A,$08,$C7,$C7,$9F,$18,$9F,$08
    db $C7,$C7,$C7,$18,$7D,$9F
    db $DA,$04,$DB,$0F,$08,$4B,$C7,$C7  ; 0x1f4d7
    db $8E,$18,$8E,$08,$C7,$C7,$8E,$18
    db $8E,$08,$C7,$C7,$93,$18,$93,$08
    db $C7,$C7,$C7,$18,$7E,$93
    db $DA,$08,$DB,$0A,$DE,$22,$19,$38  ; 0x1f4f5
    db $08,$5E,$C7,$C7,$8E,$18,$8E,$08
    db $C7,$C7,$8E,$18,$8E,$08,$C7,$C7
    db $93,$18,$93,$08,$C7,$C7,$C7,$18
    db $7F,$93
    db $DA,$00,$DB,$0A,$08,$6B,$C7,$C7  ; 0x1f517
    db $D0,$18,$D0,$08,$C7,$C7,$D0,$18
    db $D0,$08,$C7,$C7,$D0,$18,$D0,$C7
    db $08,$D0,$DB,$14,$08,$D1,$D1
    db $DA,$00,$DB,$0A,$DE,$22,$19,$38  ; 0x1f536
    db $08,$5D,$A8,$C7,$AB,$AD,$C7,$24
    db $AB,$0C,$C7,$08,$AD,$AF,$C7,$B0
    db $AF,$AE,$24,$AD,$0C,$C7,$08,$A7
    db $A8,$C7,$AB,$AD,$C7,$24,$AB,$0C
    db $C7,$08,$AC,$AD,$C7,$AE,$AD,$AC
    db $24,$AB,$0C,$C7,$08,$AC,$00
    db $DA,$06,$DB,$0A,$DE,$22,$19,$38  ; 0x1f56d
    db $08,$5D,$A8,$C7,$AB,$AD,$C7,$24  ; 0x1f575
    db $AB,$0C,$C7,$08,$AD,$AF,$C7,$B0
    db $AF,$AE,$24,$AD,$0C,$C7,$08,$A7
    db $A8,$C7,$AB,$AD,$C7,$24,$AB,$0C
    db $C7,$08,$AC,$AD,$C7,$AE,$AD,$AC
    db $24,$AB,$0C,$C7,$08,$AC,$00
    db $DA,$12,$DB,$05,$DE,$22,$19,$28  ; 0x1f5a4
    db $60,$6B,$B4,$30,$B3,$08,$C6,$C6
    db $B3,$BB,$C6,$B9,$48,$B7,$18,$B2
    db $60,$B1
    db $DA,$06,$DB,$08,$DE,$14,$1F,$30  ; 0x1f5be
    db $08,$6B,$A4,$C7,$A4,$A8,$C7,$24
    db $A4,$0C,$C7,$08,$A8,$AB,$C7,$AB
    db $A7,$A7,$24,$A7,$0C,$C7,$08,$A3
    db $A2,$C7,$A6,$A6,$C7,$24,$A6,$0C
    db $C7,$08,$A6,$A8,$C7,$AB,$A8,$A8
    db $24,$A8,$0C,$C7,$08,$A8
    db $08,$6D,$A4,$C7,$A4,$A8,$C7,$24  ; 0x1f5f4
    db $A4,$0C,$C7,$08,$A8,$AB,$C7,$AB
    db $A7,$A7,$24,$A7,$0C,$C7,$08,$A3
    db $A2,$C7,$A6,$A6,$C7,$24,$A6,$0C
    db $C7,$08,$A6,$A8,$C7,$AB,$A8,$A8
    db $24,$A8,$0C,$C7,$08,$A8
    db $DA,$06,$DB,$0C,$DE,$14,$1F,$30  ; 0x1f622
    db $08,$6D,$9F,$C7,$A8,$A4,$C7,$24
    db $A8,$0C,$C7,$08,$A4,$A7,$C7,$A7
    db $AB,$AB,$24,$A3,$0C,$C7,$08,$9F
    db $9F,$C7,$A2,$A2,$C7,$24,$A2,$0C
    db $C7,$08,$A2,$A5,$C7,$A8,$A5,$A5
    db $24,$A5,$0C,$C7,$08,$A5
    db $DA,$0D,$DB,$0F,$01,$C7,$18,$4E  ; 0x1f658
    db $C7,$9F,$C7,$9F,$C7,$9F,$C7,$9F
    db $C7,$9F,$C7,$9F,$C7,$9F,$C7,$9F
    db $DA,$0D,$DB,$0F,$18,$4E,$C7,$9C  ; 0x1f670
    db $C7,$9C,$C7,$9B,$C7,$9B,$C7,$9A
    db $C7,$9A,$C7,$99,$C7,$99
    db $DA,$08,$DB,$0A,$DE,$14,$1F,$30  ; 0x1f686
    db $18,$6F,$98,$C7,$18,$93,$08,$C7
    db $C7,$93,$18,$97,$C7,$18,$93,$08
    db $C7,$C7,$93,$18,$96,$C7,$18,$93
    db $08,$C7,$C7,$93,$18,$95,$C7,$18
    db $90,$08,$C7,$C7,$90
    db $DA,$00,$DB,$14,$18,$6B,$D1,$08  ; 0x1f6b3
    db $D2,$C7,$D1,$18,$D1,$08,$D2,$C7
    db $D1,$18,$D1,$08,$D2,$C7,$D1,$D1
    db $C7,$D1,$D2,$D1,$D1,$18,$D1,$08
    db $D2,$C7,$D1,$18,$D1,$08,$D2,$C7
    db $D1,$18,$D1,$08,$D2,$C7,$D1,$D1
    db $C7,$D1,$D2,$D1,$D1
    db $08,$AD,$C7,$AF,$B0,$C7,$24,$AD  ; 0x1f6e8
    db $0C,$C7,$08,$AC,$AB,$C7,$AC,$AD
    db $C7,$24,$A8,$0C,$C7,$08,$C7,$A8
    db $C7,$A4,$A1,$C7,$A8,$A4,$C7,$A1
    db $A4,$C7,$AB,$30,$C6,$C7,$00
    db $01,$C7,$18,$C7,$9D,$C7,$9E,$C7  ; 0x1f70f
    db $9F,$C7,$9F,$18,$9E,$08,$C7,$C7
    db $9E,$18,$C6,$08,$9E,$C7,$9F,$18
    db $C6,$08,$C7,$C7,$A3,$A4,$C7,$A4
    db $A6,$C7,$A6
    db $18,$C7,$98,$C7,$98,$C7,$9A,$C7  ; 0x1f732
    db $99,$18,$A1,$08,$C7,$C7,$A1,$18
    db $C6,$08,$A1,$C7,$A3,$18,$C6,$08
    db $C7,$C7,$9A,$9C,$C7,$9C,$9D,$C7
    db $9D
    db $18,$91,$08,$C7,$C7,$91,$18,$92  ; 0x1f753
    db $08,$C7,$C7,$92,$18,$93,$08,$C7
    db $C7,$93,$18,$95,$08,$95,$90,$8F
    db $18,$8E,$08,$C6,$C7,$8E,$18,$C6
    db $08,$8E,$C7,$93,$18,$C6,$08,$C7
    db $C7,$93,$95,$C7,$95,$97,$C7,$97
    db $18,$D1,$08,$D2,$C7,$D1,$18,$D1  ; 0x1f783
    db $08,$D2,$C7,$D1,$18,$D1,$08,$D2
    db $C7,$D1,$D1,$C7,$D1,$D2,$D1,$D1
    db $18,$D2,$08,$C6,$C7,$D2,$18,$C6
    db $08,$D2,$C7,$D2,$18,$C6,$08,$C6
    db $C7,$D1,$D2,$C7,$D1,$D2,$D1,$D1
    db $08,$A9,$C7,$A9,$AD,$C7,$24,$AA  ; 0x1f7b3
    db $0C,$C7,$08,$A9,$A8,$C7,$A8,$A8
    db $C7,$24,$AB,$0C,$C7,$08,$C7,$AD
    db $C7,$AD,$AD,$C7,$A9,$C7,$C7,$A9
    db $A9,$C7,$A8,$30,$C6,$C7
    db $08,$AD,$C7,$AF,$B0,$C7,$24,$AD  ; 0x1f7d9
    db $0C,$C7,$08,$AC,$AB,$C7,$AC,$AD
    db $C7,$24,$B4,$0C,$C7,$08,$C7,$B4
    db $C7,$B3,$B4,$C7,$B0,$C7,$C7,$B0
    db $AD,$C7,$B0,$30,$C6,$C7,$00
    db $48,$B0,$08,$AD,$C6,$B0,$48,$B4  ; 0x1f800
    db $08,$B3,$C6,$B4,$30,$B9,$30,$B4
    db $60,$B0
    db $01,$C7,$18,$C7,$9D,$C7,$9E,$C7  ; 0x1f812
    db $9F,$C7,$9F,$18,$9E,$08,$C7,$C7
    db $9D,$18,$C6,$08,$C7,$C7,$AB,$18
    db $C6,$08,$B0,$C7,$B0,$AF,$C7,$AF
    db $AE,$C7,$AE
    db $18,$C7,$98,$C7,$98,$C7,$9A,$C7  ; 0x1f835
    db $99,$18,$A1,$08,$C7,$C7,$A3,$18
    db $C6,$08,$C7,$C7,$A4,$18,$C6,$08
    db $A8,$C7,$A8,$A7,$C7,$A7,$A6,$C7
    db $A6
    db $18,$91,$08,$C7,$C7,$91,$18,$92  ; 0x1f856
    db $08,$C7,$C7,$92,$18,$93,$08,$C7
    db $C7,$93,$18,$95,$08,$95,$90,$8F
    db $18,$8E,$08,$C6,$C7,$93,$18,$C6
    db $08,$C7,$C7,$98,$18,$C6,$08,$98
    db $C7,$98,$97,$C7,$97,$96,$C7,$96
    db $18,$D1,$08,$D2,$C7,$D1,$18,$D1  ; 0x1f886
    db $08,$D2,$C7,$D1,$18,$D1,$08,$D2
    db $C7,$D1,$D1,$C7,$D1,$D2,$D1,$D1
    db $18,$D2,$08,$C6,$C7,$D2,$18,$C6
    db $08,$C7,$C7,$D2,$18,$C6,$08,$D2
    db $C7,$D1,$D2,$C7,$D1,$D2,$C7,$D1
    db $DA,$04,$18,$6C,$AD,$B4,$08,$B4  ; 0x1f8b6
    db $C7,$B4,$B3,$C7,$B4,$B5,$C6,$B4
    db $B1,$C7,$24,$AD,$0C,$C7,$08,$AD
    db $B4,$C6,$B2,$B4,$C6,$B2,$B4,$C6
    db $B2,$B0,$C7,$AD,$30,$C6,$C7,$00
    db $DA,$04,$18,$6B,$A8,$AB,$08,$AB  ; 0x1f8de
    db $C7,$AB,$AA,$C7,$AB,$AD,$C6,$AB
    db $A8,$C7,$24,$A5,$0C,$C7,$08,$A5
    db $AB,$C6,$AA,$AB,$C6,$AA,$AB,$C6
    db $AA,$A8,$C7,$A4,$30,$C6,$C7
    db $18,$C7,$08,$AD,$C6,$AC,$AD,$C6  ; 0x1f905
    db $B4,$C6,$C6,$AD,$AD,$C6,$AC,$AD
    db $C6,$B4,$C6,$C6,$AD,$AF,$C6,$B1
    db $18,$C7,$08,$AD,$C6,$AC,$AD,$C6
    db $B2,$C6,$C6,$AD,$AD,$C6,$AC,$AD
    db $C6,$B2,$30,$C6
    db $01,$C7,$18,$C7,$9F,$C7,$9F,$C7  ; 0x1f931
    db $9F,$C7,$9F,$C7,$9E,$C7,$9E,$C7
    db $9E,$C7,$9E
    db $18,$C7,$99,$C7,$99,$C7,$99,$C7  ; 0x1f944
    db $99,$C7,$98,$C7,$98,$C7,$98,$C7
    db $98
    db $18,$95,$08,$C7,$C7,$95,$18,$90  ; 0x1f955
    db $08,$C7,$C7,$90,$18,$95,$08,$C7
    db $C7,$95,$18,$95,$08,$95,$90,$8F
    db $18,$8E,$08,$C7,$C7,$8E,$18,$95
    db $08,$C7,$C7,$95,$18,$8E,$08,$C7
    db $C7,$8E,$8E,$C7,$8E,$90,$C7,$92
    db $18,$D1,$08,$D2,$C7,$D1,$18,$D1  ; 0x1f985
    db $08,$D2,$C7,$D1,$18,$D1,$08,$D2
    db $C7,$D1,$D1,$C7,$D1,$D2,$D1,$D1
    db $18,$D1,$08,$D2,$C7,$D1,$18,$D1
    db $08,$D2,$C7,$D1,$18,$D1,$08,$D2
    db $C7,$D1,$D2,$C7,$D1,$D2,$C7,$D1
    db $18,$AB,$B2,$08,$B2,$C7,$B2,$B1  ; 0x1f9b5
    db $C7,$B2,$B4,$C6,$B2,$AF,$C7,$24
    db $AB,$0C,$C7,$08,$B2,$18,$B0,$B0
    db $10,$B0,$B2,$B3,$18,$B4,$C7,$AB
    db $C6,$00
    db $18,$A3,$A9,$08,$A9,$C7,$A9,$A8  ; 0x1f9d7
    db $C7,$A9,$AB,$C6,$A9,$A6,$C7,$24
    db $A3,$0C,$C7,$08,$A9,$18,$A8,$A8
    db $10,$A8,$A9,$AA,$18,$AB,$C7,$A3
    db $C6
    db $18,$C7,$08,$AB,$C6,$AA,$AB,$C6  ; 0x1f9f8
    db $B2,$C6,$C6,$AB,$AB,$C6,$AA,$AB
    db $C6,$B2,$C6,$C6,$AB,$AD,$C6,$AF
    db $30,$B0,$10,$B0,$AF,$AD,$AB,$06
    db $AD,$AF,$B0,$B2,$B3,$B4,$B5,$B6
    db $30,$B7
    db $01,$C7,$18,$C7,$9D,$C7,$9D,$C7  ; 0x1fa22
    db $9D,$C7,$9D,$C7,$9C,$10,$9C,$9D
    db $9E,$18,$9F,$C7,$9B,$C6
    db $18,$C7,$97,$C7,$97,$C7,$97,$C7  ; 0x1fa38
    db $97,$C7,$9F,$10,$9F,$A0,$A1,$18
    db $A3,$C7,$A3,$C6
    db $18,$93,$08,$C7,$C7,$93,$18,$8E  ; 0x1fa4c
    db $08,$C7,$C7,$8E,$18,$93,$08,$C7
    db $C7,$93,$18,$93,$08,$93,$95,$97
    db $18,$98,$08,$C7,$C7,$98,$10,$98
    db $9A,$9B,$18,$9C,$C7,$93,$C6,$18
    db $D1,$08,$D2,$C7,$D1,$18,$D1,$08
    db $D2,$C7,$D1,$18,$D1,$08,$D2,$C7
    db $D1,$D1,$C7,$D1,$D2,$D1,$D1,$18
    db $D1,$08,$D2,$C7,$D1,$10,$D2,$D2
    db $D2,$18,$D1,$08,$D2,$C7,$D1,$D2
    db $C7,$D1,$D2,$D1,$D1
    db $08,$A9,$C7,$A9,$AD,$C7,$24,$AA  ; 0x1faa1
    db $0C,$C7,$08,$A9,$A8,$C7,$A8,$A8
    db $C7,$24,$AB,$0C,$C7,$08,$C7
    db $08,$AD,$C7,$AF,$B0,$C7,$24,$AD  ; 0x1fab8
    db $0C,$C7,$08,$AC,$AB,$C7,$AC,$AD
    db $C7,$24,$B4,$0C,$C7,$08,$C7,$00
    db $DA,$04,$DB,$0C,$DE,$22,$18,$14  ; 0x1fad0
    db $08,$5C,$A4,$C7,$A4,$A9,$C7,$24
    db $A4,$0C,$C7,$08,$A4,$A4,$C7,$A4
    db $A4,$C7,$24,$A5,$0C,$C7,$08,$C7
    db $48,$B0,$08,$AD,$C6,$B0,$60,$B4  ; 0x1faf0
    db $01,$C7,$18,$C7,$9D,$C7,$9E,$C7  ; 0x1faf8
    db $9F,$C7,$9F,$18,$9E,$08,$C7,$C7
    db $9D,$18,$C6,$08,$C7,$C7,$AB
    db $18,$C7,$98,$C7,$98,$C7,$9A,$C7  ; 0x1fb0f
    db $99,$18,$A1,$08,$C7,$C7,$A3,$18
    db $C6,$08,$C7,$C7,$A4
    db $18,$91,$08,$C7,$C7,$91,$18,$92  ; 0x1fb24
    db $08,$C7,$C7,$92,$18,$93,$08,$C7
    db $C7,$93,$18,$95,$08,$95,$90,$8F
    db $18,$8E,$08,$C6,$C7,$93,$18,$C6
    db $08,$C7,$C7,$98
    db $18,$D1,$08,$D2,$C7,$D1,$18,$D1  ; 0x1fb48
    db $08,$D2,$C7,$D1,$18,$D1,$08,$D2
    db $C7,$D1,$D1,$C7,$D1,$D2,$D1,$D1
    db $18,$D2,$08,$C6,$C7,$D2,$18,$C6
    db $08,$C7,$C7,$D2
    db $DA,$04,$DB,$0A,$DE,$22,$19,$38  ; 0x1fb6c
    db $18,$4D,$B4,$08,$C7,$C7,$B4,$18
    db $B4,$08,$C7,$C7,$B7,$18,$B7,$08
    db $C7,$C7,$B7,$18,$B7,$C7,$00
    db $DA,$04,$DB,$08,$DE,$20,$18,$36  ; 0x1fb8b
    db $18,$4D,$A4,$08,$C7,$C7,$A4,$18
    db $A4,$08,$C7,$C7,$A7,$18,$A7,$08
    db $C7,$C7,$A7,$18,$A7,$C7
    db $DA,$04,$DB,$0C,$DE,$21,$1A,$37  ; 0x1fba9
    db $18,$4D,$AD,$08,$C7,$C7,$AD,$18
    db $AD,$08,$C7,$C7,$AF,$18,$AF,$08
    db $C7,$C7,$AF,$18,$AF,$C7
    db $DA,$04,$DB,$0A,$DE,$22,$18,$36  ; 0x1fbc7
    db $18,$4D,$A9,$08,$C7,$C7,$A9,$18
    db $A9,$08,$C7,$C7,$AB,$18,$AB,$08
    db $C7,$C7,$AB,$18,$AB,$C7
    db $DA,$04,$DB,$0F,$08,$4D,$C7,$C7  ; 0x1fbe5
    db $9A,$18,$9A,$08,$C7,$C7,$9A,$18
    db $9A,$08,$C7,$C7,$9F,$18,$9F,$08
    db $C7,$C7,$C7,$18,$7D,$9F
    db $DA,$04,$DB,$0F,$08,$4C,$C7,$C7  ; 0x1fc03
    db $8E,$18,$8E,$08,$C7,$C7,$8E,$18
    db $8E,$08,$C7,$C7,$93,$18,$93,$08
    db $C7,$C7,$C7,$18,$7E,$93
    db $DA,$08,$DB,$0A,$DE,$22,$19,$38  ; 0x1fc21
    db $08,$5F,$C7,$C7,$8E,$18,$8E,$08
    db $C7,$C7,$8E,$18,$8E,$08,$C7,$C7
    db $93,$18,$93,$08,$C7,$C7,$C7,$18
    db $7F,$93
    db $DA,$00,$DB,$0A,$08,$6C,$C7,$C7  ; 0x1fc43
    db $D0,$18,$D0,$08,$C7,$C7,$D0,$18
    db $D0,$08,$C7,$C7,$D0,$18,$D0,$C7
    db $08,$D0,$DB,$14,$08,$D1,$D1
    db $DA,$06,$DB,$0A,$DE,$22,$19,$38  ; 0x1fc62
    db $08,$6F,$B4,$C7,$B7,$B9,$C7,$24
    db $B7,$0C,$C7,$08,$B9,$BB,$C7,$BC
    db $BB,$BA,$24,$B9,$0C,$C7,$08,$B3
    db $B4,$C7,$B7,$B9,$C7,$24,$B7,$0C
    db $C7,$08,$B8,$B9,$C7,$BA,$B9,$B8
    db $24,$B7,$0C,$C7,$08,$B8,$00
    db $08,$B9,$C7,$BB,$BC,$C7,$24,$B9  ; 0x1fc99
    db $0C,$C7,$08,$B8,$B7,$C7,$B8,$B9
    db $C7,$24,$C0,$0C,$C7,$08,$C7,$00
    db $18,$91,$08,$C7,$C7,$91,$18,$92  ; 0x1fcb1
    db $08,$C7,$C7,$92,$18,$93,$08,$C7
    db $C7,$93,$18,$95,$08,$C7,$C7,$95
    db $DA,$04,$DB,$0A,$DE,$22,$19,$38  ; 0x1fcc9
    db $18,$5D,$C0,$08,$C7,$C7,$C0,$E3
    db $78,$18,$18,$C0,$08,$C7,$C7,$C3
    db $18,$C3,$08,$C7,$C7,$C3,$18,$C3
    db $C3,$00
    db $DA,$04,$DB,$0A,$DE,$22,$19,$38  ; 0x1fceb
    db $18,$5D,$C0,$08,$C7,$C7,$C0,$18
    db $C0,$08,$C7,$C7,$C3,$18,$C3,$08
    db $C7,$C7,$C3,$18,$C3,$C3,$00
    db $DA,$04,$DB,$08,$DE,$20,$18,$36  ; 0x1fd0a
    db $18,$5D,$A4,$08,$C7,$C7,$A4,$18
    db $A4,$08,$C7,$C7,$A7,$18,$A7,$08
    db $C7,$C7,$A7,$18,$A7,$A7
    db $DA,$04,$DB,$0C,$DE,$21,$1A,$37  ; 0x1fd28
    db $18,$5D,$B9,$08,$C7,$C7,$B9,$18
    db $B9,$08,$C7,$C7,$BB,$18,$BB,$08
    db $C7,$C7,$BB,$18,$BB,$BB
    db $DA,$04,$DB,$0A,$DE,$22,$18,$36  ; 0x1fd46
    db $18,$5D,$A9,$08,$C7,$C7,$A9,$18
    db $A9,$08,$C7,$C7,$AB,$18,$AB,$08
    db $C7,$C7,$AB,$18,$AB,$AB
    db $DA,$04,$DB,$0F,$08,$5D,$C7,$C7  ; 0x1fd64
    db $9A,$18,$9A,$08,$C7,$C7,$9A,$18
    db $9A,$08,$C7,$C7,$9F,$18,$9F,$08
    db $C7,$C7,$9F,$08,$7D,$C7,$C7,$9F
    db $DA,$04,$DB,$0F,$08,$5C,$C7,$C7  ; 0x1fd84
    db $8E,$18,$8E,$08,$C7,$C7,$8E,$18
    db $8E,$08,$C7,$C7,$93,$18,$93,$08
    db $C7,$C7,$93,$08,$7E,$C7,$C7,$93
    db $DA,$08,$DB,$0A,$DE,$22,$19,$38  ; 0x1fda4
    db $08,$5F,$C7,$C7,$8E,$18,$8E,$08
    db $C7,$C7,$8E,$18,$8E,$08,$C7,$C7
    db $93,$18,$93,$08,$C7,$C7,$C7,$08
    db $7F,$C7,$C7,$93
    db $DA,$00,$DB,$0A,$08,$6C,$C7,$C7  ; 0x1fdc8
    db $D0,$18,$D0,$08,$C7,$C7,$D0,$18
    db $D0,$08,$C7,$C7,$D0,$18,$D0,$C7
    db $08,$D0,$DB,$14,$08,$D1,$D1
    db $DA,$04,$DE,$14,$19,$30,$DB,$0A  ; 0x1fde7
    db $08,$4F,$B9,$C6,$B7,$B9,$C6,$24
    db $B7,$0C,$C6,$08,$B9,$BB,$C6,$C7
    db $BB,$C6,$24,$B9,$0C,$C6,$08,$C6
    db $B9,$C6,$B7,$B9,$C6,$24,$B7,$0C
    db $C6,$08,$B8,$B9,$C6,$C7,$B9,$C6
    db $24,$B7,$0C,$C6,$08,$B8
    db $DE,$16,$18,$30,$DB,$0A,$08,$4E  ; 0x1fe1d
    db $AD,$C6,$AB,$AD,$C6,$24,$AB,$0C
    db $C6,$08,$AD,$AF,$C6,$C7,$AF,$C6
    db $24,$AD,$0C,$C6,$08,$C6,$AD,$C6
    db $AB,$AD,$C6,$24,$AB,$0C,$C7,$08
    db $AC,$AD,$C6,$C7,$AD,$C6,$24,$AB
    db $0C,$C6,$08,$AC,$00
    db $DE,$15,$19,$31,$DB,$08,$08,$4E  ; 0x1fe52
    db $A8,$C6,$A4,$A8,$C6,$24,$A8,$0C
    db $C6,$08,$A8,$AB,$C6,$C7,$AB,$C6
    db $24,$A7,$0C,$C6,$08,$C6,$A6,$C6
    db $A6,$A6,$C6,$24,$A6,$0C,$C6,$08
    db $A6,$A8,$C6,$C7,$A8,$C6,$24,$A8
    db $0C,$C6,$08,$A8
    db $DA,$06,$DB,$0C,$DE,$14,$1A,$30  ; 0x1fe86
    db $08,$4E,$A4,$C6,$A4,$A4,$C6,$24
    db $A4,$0C,$C6,$08,$A4,$A7,$C6,$C7
    db $A7,$C6,$24,$A3,$0C,$C6,$08,$C6
    db $A2,$C6,$A2,$A2,$C6,$24,$A2,$0C
    db $C6,$08,$A2,$A5,$C6,$C7,$A5,$C6
    db $24,$A5,$0C,$C6,$08,$A5
    db $08,$B9,$C6,$BB,$BC,$C6,$24,$B9  ; 0x1febc
    db $0C,$C6,$08,$B8,$B7,$C6,$B8,$B9
    db $C6,$24,$C0,$0C,$C6,$08,$C6,$00
    db $08,$A9,$C6,$A9,$AD,$C6,$24,$AA  ; 0x1fed4
    db $0C,$C6,$08,$A9,$A8,$C6,$A8,$A8
    db $C6,$24,$AB,$0C,$C6,$08,$C6
    db $08,$AD,$C6,$AF,$B0,$C6,$24,$AD  ; 0x1feeb
    db $0C,$C6,$08,$AC,$AB,$C6,$AC,$AD
    db $C6,$24,$B4,$0C,$C6,$08,$C6,$00
    db $DA,$04,$DB,$0C,$DE,$22,$18,$14  ; 0x1ff03
    db $08,$5C,$A4,$C6,$A4,$A9,$C6,$24
    db $A4,$0C,$C6,$08,$A4,$A4,$C6,$A4
    db $A4,$C6,$24,$A5,$0C,$C6,$08,$C6
    db $DA,$04,$DB,$0A,$DE,$22,$19,$38  ; 0x1ff23
    db $60,$5E,$BC,$C6,$DA,$01,$10,$9F
    db $C6,$C6,$C6,$AF,$C6,$60,$C6,$C6
    db $00
    db $DA,$04,$DB,$08,$DE,$20,$18,$36  ; 0x1ff3c
    db $60,$5D,$B4,$C6,$DA,$01,$10,$C7
    db $A3,$C6,$C6,$C6,$B3,$60,$C6,$C6
    db $DA,$04,$DB,$0C,$DE,$21,$1A,$37  ; 0x1ff54
    db $60,$5D,$AB,$C6,$DA,$01,$10,$C7
    db $C7,$A7,$C6,$C6,$C6,$60,$B7,$C6
    db $DA,$04,$DB,$0A,$DE,$22,$18,$36  ; 0x1ff6c
    db $60,$5D,$A4,$C6,$DA,$01,$10,$C7
    db $C7,$C7,$AB,$C6,$C6,$60,$C6,$C6
    db $DA,$04,$DB,$0F,$10,$5D,$A4,$C7  ; 0x1ff84
    db $A4,$A2,$C7,$A2,$A1,$C7,$A1,$A0
    db $C7,$A0,$60,$9F,$9B,$C6
    db $DA,$0D,$DB,$0F,$10,$5D,$9C,$C7  ; 0x1ff9a
    db $9C,$9C,$C7,$9C,$98,$C7,$98,$98
    db $C7,$98,$60,$97,$97,$C6
    db $DA,$08,$DB,$0A,$DE,$22,$19,$38  ; 0x1ffb0
    db $10,$5D,$98,$C7,$98,$96,$C7,$96
    db $95,$C7,$95,$94,$C7,$94,$60,$93
    db $93,$C6,$00,$00,$00,$05,$E8,$00
    db $00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$00,$00,$00,$00,$00,$00





Empyy03FDE0:
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
