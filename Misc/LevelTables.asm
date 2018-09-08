;; This ASM file reads a ROM and outputs the locations of all level-related data tables,
;;  including any hijacked by Lunar Magic. This list is complete as of LM v2.53.
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
if read1($0EF100) != $00
	org $0EF100
		print "Sprite pointer table, bank bytes: ",pc
endif
if read1($0EF30F) == $42
	org read3($0EF30C)
		print "Sprite data sizes: ",pc
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
		org read1(read3($0583AE)+$5C)<<16|read2(read3($0583AE)+$65)
			
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
	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($058A65) == $22
	print "Map16 tilemap data tables:"
  org read1($06F557)<<16|(read2($06F553)+$1000&$FFFF)
	print "  Pages 02-0F: ",pc
  org read1($06F560)<<16|(read2($06F55C)+$8000&$FFFF)
	print "  Pages 10-1F: ",pc
  org read1($06F56B)<<16|read2($06F567)+1
	print "  Pages 20-3F: ",pc
  org read1($06F574)<<16|(read2($06F570)+$8000&$FFFF)+1
	print "  Pages 30-3F: ",pc
  org read1($06F598)<<16|read2($06F594)
	print "  Pages 40-4F: ",pc
  org read1($06F5A1)<<16|(read2($06F59D)+$8000&$FFFF)
	print "  Pages 50-5F: ",pc
  org read1($06F5AC)<<16|read2($06F5A8)+1
	print "  Pages 60-6F: ",pc
  org read1($06F5B5)<<16|(read2($06F5B1)+$8000&$FFFF)+1
	print "  Pages 70-7F: ",pc
  
  if read1($06F547) != $00
    org read1($06F58A)<<16|(read2($06F586)+$1000&$FFFF)
	  print "  Tileset-specific Map16 for page 2: ",pc
  else
	print "  Tileset-specific Map16 for page 2 is not enabled on this ROM."
  endif
  
  org read3($06F624)
	print "Map16 Acts-Like Settings (pages 00-3F): ",pc
  org read3($06F63A)
	print "Map16 Acts-Like Settings (pages 40-7F): ",pc
else
	print "Map16 VRAM modification has not been applied."
endif
