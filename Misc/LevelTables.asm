;; This ASM file reads a ROM and outputs the locations of all level-related data tables,
;;  including any hijacked by Lunar Magic.
;;
;; May be useful for helping understand how Lunar Magic moves them,
;;  as well as checking whether or not a relevant hijack has been applied yet.

	print ""
	
	; These tables are literally never moved.
org $05E000
	print "Layer 1 pointer table: ",pc
org $05E600
	print "Layer 2 pointer table: ",pc
org $05EC00
	print "Sprite pointer table: ",pc
if read1($05D8F5) == $22
	org $0EF100
		print "Sprite pointer table, bank bytes: ",pc
endif
	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org $05F000
	print "Secondary level header, byte 1: ",pc
org $05F200
	print "Secondary level header, byte 2: ",pc
org $05F400
	print "Secondary level header, byte 3: ",pc
org $05F600
	print "Secondary level header, byte 4: ",pc

if read1($05D97D) == $22
	org $05<<16+read2(read3($05D97E)+5) ; $05DE00
		print "Secondary level header, byte 5: ",pc
else
	print "Secondary level header expansion is not applied."
endif
	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($05D9E3) == $22
	org read3(read3($05D9E4)+$0A)
		print "Midway entrance data, byte 1: ",pc
	org read3(read3($05D9E4)+$29)
		print "Midway entrance data, byte 2: ",pc
	org read3(read3($05D9E4)+$39)
		print "Midway entrance data, byte 3: ",pc
else
	print "Midway entrance hijack is not applied."
endif
	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($05D7E3) == $22
	org read3(read3($05D7E4)+1)		; read3($0DE191)
		print "Secondary entrance data, byte 1: ",pc
	org read3(read3($05D7EC)+1)		; read3($0DE198)
		print "Secondary entrance data, byte 2: ",pc
	org read3(read3($05D81E)+1)		; read3($0DE19F)
		print "Secondary entrance data, byte 3: ",pc
	org read3(read3($05D838)+1)		; read3($05DC81)
		print "Secondary entrance data, byte 4: ",pc
else
	print "Secondary entrance hijack is not applied."
	org $05F800
		print "Secondary entrance data, byte 1: ",pc
	org $05FA00
		print "Secondary entrance data, byte 2: ",pc
	org $05FC00
		print "Secondary entrance data, byte 3: ",pc
	org $05FE00
		print "Secondary entrance data, byte 4: ",pc
endif

	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($058030) == $5C
	org $0EF310
		print "BG tilemap info: ",pc
else
	print "BG tilemap hijack not applied."
endif

	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($0583AD) == $22
	org read3(read3($0583AE)+$EA)
		print "Level ExAnimation pointers: ",pc
		
	if read2(read3($0583AE)+$5B) != 0
		org read3(read2(read3($0583AE)+$5B)<<8 | (read2($0583AE)+$65))
			print "Global ExAnimation data: ",pc
	else
		print "No global level ExAnimation data found."
	endif
	
	org $03FE00
		print "Animation settings: ",pc
else
	print "Level ExAnimation hijack is not applied."
endif
	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($0583B8) == $22
	org read3(read3($0583B9)+$0F)
		print "ExGFX files: ",pc
else
	print "ExGFX file hijack is not applied."
endif

org $0EF600
	print "Palette data table: ",pc