;; This ASM file reads a ROM and outputs the locations of all overworld-related data tables,
;;  including any hijacked by Lunar Magic.
;;
;; May be useful for helping understand how Lunar Magic moves them,
;;  as well as checking whether or not a relevant hijack has been applied yet.


	print ""

if read1($04D807) == $A9
	org (read1($04D808)<<16)|read2($04D803)
		print "Translevels: ",pc," (LC_LZ2/3)"
else
	print "Translevel hijack is not applied."
endif

if read1($049549) = $22
	org read3($03BB57)
		print "Level names: ",pc
else
	print "Level names hijack is not applied."
	org $049AC5
		print "Level name strings: ",pc
endif

if read1($009F19) == $22
	org $05DDA0
		print "Initial flags: ",pc
else
	print "Initial level flags hijack is not applied."
	org $009EE0
		print "Initial flags: ",pc
endif

	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($04D826) == $A9
	org (read1($04D827)<<16)|read2($04D822)
		print "Layer 1 high bytes: ",pc," (LC_LZ2/3)"
else
	print "Layer 1 high byte hijack is not applied."
endif

org read3($04EDBE)
	print "Layer 1 event data: ",pc
org read3($04EDB8)
	print "Layer 1 event VRAM data: ",pc

	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org (read1($04DC79)<<16)|read2($04DC72)
	print "Layer 2 tile numbers: ",pc," (LC_RLE2)"
org (read1($04DC79)<<16)|read2($04DC8D)
	print "Layer 2 yxpccctt: ",pc," (LC_RLE2)"

org read3($04EAF5)
	print "Layer 2 event tilemap tile numbers: ",pc
org (read1($04DD4A)<<16)|read2($04DD45)
	print "Layer 2 event tilemap yxpccctt: ",pc," (LC_RLE1)"
org read3($04E49F)
	print "Layer 2 event data: ",pc
	
	print ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org $04F625
	print "Main sprite data table: ",pc

if read3($0EF55D) != $FFFFFF
	org read3($0EF55D)
		print "Custom sprite data table: ",pc
else
	print "Custom sprite data hijack not applied."
endif

	print ""


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($04E9F7) == $22
	org read3(read3($04E9F8)+13)
		print "Silent event dividers: ",pc
	org read3(read3($04E9F8)+$22)
		print "Silent event tiles: ",pc
	org read3(read3($04E9F8)+$28)
		print "Silent event locations: ",pc
	org read3(read3($04E9F8)+$34)
		print "Silent event layers: ",pc
else
	print "Silent event hijack is not applied."
	org $04E8E4
		print "Silent event numbers: ",pc
	org $04E994
		print "Silent event tiles: ",pc
	org $04E93C
		print "Silent event locations: ",pc
	org $04E910
		print "Silent event layers: ",pc
endif

	print ""
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($048509) == $22
	org read3(read3($04850A)+$14)
		print "Star warp source X positions: ",pc
	org read3(read3($04850A)+$24)
		print "Star warp source Y positions: ",pc
	org read3(read3($048567)+$07)
		print "Star warp destination X positions: ",pc
	org read3(read3($048567)+$19)
		print "Star warp destination Y positions: ",pc
else
	print "Pipe/star warp hijack is not applied."
	org $048431
		print "Star warp source X positions: ",pc
	org $048467
		print "Star warp source Y positions: ",pc
	org $04849D
		print "Star warp destination X positions: ",pc
	org $0484D3
		print "Star warp destination Y positions: ",pc
endif

	print ""
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($049A35) == $22
	org read3(read3($049A36)+$11)
		print "Exit path entrance positions: ",pc
	org read3(read3($049A36)+$2C)
		print "Exit path exit positions: ",pc
	org read3(read3($049A36)+$48)
		print "Exit path tile positions: ",pc
else
	print "Exit path hijack is not applied."
	org $049964
		print "Exit path entrance positions: ",pc
	org $0499AA
		print "Exit path exit positions: ",pc
	org $0499F0
		print "Exit path tile positions: ",pc
endif

	print ""
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org read3($04E67C)
	print "Destruction events: ",pc
	
org read3($04E69C)
	print "Destruction locations: ",pc
	
org read3($04EEC9)
	print "Destruction VRAM locations: ",pc
	
	print ""
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($00A141) == $22
	org (read1(read3($00A141)+$12)<<16)|read2(read3($00A141)+$09)
		print "ExGFX files: ",pc
else
	print "ExGFX file hijack is not applied."
endif

if read1($00AD32) == $22
	org (read1(read3($00AD33)+$1E)<<16)|read2(read3($00AD33)+$12)
		print "Palettes: ",pc
else
	print "Palette data hijack is not applied."
endif

if read1($048086) == $22
	org read3(read3($048087)+$E1)
		print "Submap ExAnimation pointers: ",pc
	
	if read2(read3($048087)+$61) != 0
		org (read1(read3($048087)+$58)<<16)|read2(read3($048087)+$61)
			print "Global ExAnimation data: ",pc
	else
		print "No global overworld ExAnimation data found."
	endif
	
	org read3(read3($048087)+$4A)
		print "Animation settings: ",pc
else
	print "Overworld ExAnimation hijack is not applied."
endif
	print ""



	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

if read1($05B1A3) == $22
	org read3($03BC0B)
		print "Message box text: ",pc
else
	org $05A5D9
		print "Message box text: ",pc
endif

org read3($0084F1)
	print "Castle destruction text: ",pc
