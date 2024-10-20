; Code added by Lunar Magic to add a bank byte to the sprite data pointers.
;=======================================================================
if read1($00FFD5) == $23
	sa1rom
endif
;=======================================================================

org $05D8F5
	JSL GetSpriteBankByte

org $0EF300
GetSpriteBankByte:
	PHB : PHK : PLB
	LDY $0E
	LDA.w SpriteBankBytes,y
	STA $D0
	PLB
	RTL

org $05F100
SpriteBankBytes:
	for i = 0..$200 : db $07 : endfor