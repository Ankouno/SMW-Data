# MWL File Format
The MWL file format is developed by FuSoYa for extracting and inserting individual Super Mario World levels in a hack.
This file is intended for documenting its format, since FuSoYa himself provides none (and also apparently doesn't remember most of the format anyway).

Note that this file is only intended to document the general format; for more-specific details on the data, see [this page](https://smwspeedruns.com/Level_Data_Format).

This format is accurate as of Lunar Magic v2.53.

## Header
The file begins with a 0x40 byte header.  

The first four bytes are the characters "LM" followed by the Lunar Magic version used to create the MWL, as a two-byte value.

The next four bytes are a 32-bit offset (little endian) within the file to the data pointer list.
4 more bytes after this form a 32-bit value (little endian) for the number of bytes used by the data pointers.

After this are four bytes for special information flags:  
&nbsp;&nbsp;&nbsp;&nbsp;Bit 0 of byte 0 indicates the current level is exported from SMA2.  
&nbsp;&nbsp;&nbsp;&nbsp;All other bits are currently unknown/unused (U/J/SMAS are not indicated, nor is FastROM, SA-1, or SuperFX).  

Finally, there is the following 48-byte string (vertical bars used for spacing):
```
|Lunar Magic x.xx|
|  @yyyy Fusoya  |
|Defender of Relm|
```
With ``x.xx`` as the version number of Lunar Magic used to create the MWL, and ``yyyy`` being its year of publishing.



## Data Pointer List
The data pointer list are pointed to by the header as mentioned before; generally, they'll just be located immediately after the header.

Currently, there are 8 pointers, each consisting of 8 bytes for a total of 0x40 bytes:
1. Level information (level number, secondary header)
2. Layer 1 data
3. Layer 2 data
4. Sprite data
5. Palette data
6. Secondary entrances
7. ExAnimation data
8. ExGFX and bypass information

The first four bytes of each pointer are the offset within the file to that data (32-bit, little endian). The next four bytes are the size of that data (also 32-bit, little endian), in bytes.



## Data
### Level Information
The first two bytes are the source level number. The next four are the secondary level header.

After this are three bytes with additional primary entrance information. The first byte comes directly from the table at $05DE00; the other two are currently unused/unknown.

Following that are the three bytes of the midway point's data tables.

All remaining bytes in this section appear to just be padding for now.



### Layer 1/2 Data and Sprite Data
Layer 1/2 data and sprite data are all preceded by an 8-byte header.  
&nbsp;&nbsp;Bytes 4-6 in all three indicate the source address of the data in the original ROM, but do not seem to be actually used.  
&nbsp;&nbsp;Byte 0 of Layer 1 has the first bit set if a custom palette is in use.  
&nbsp;&nbsp;Byte 0 of Layer 2 contains the value stored to $0EF310.

Following the header is the raw data directly from the ROM, except when Layer 2 is being used as a BG tilemap, in which case it is written as a list of 16-bit Map16 tiles (all in little endian). This is unlike in the ROM, where the high and low bytes are stored in seperate blocks. Also, while the ROM's data is compressed in the LC-RLE1 format, the MWL leaves it uncompressed. The order of the tiles is otherwise the same (so the left half of the tilemap is written first, then the right).

It should also be noted that, for sprite data, the extension data size is not stored anywhere in the MWL, which means any sprite can potentially use anywhere between 3 and 7 bytes of data. If the source ROM is available, check the byte at $0EF30F; if equal to 0x42, you can determine each sprite's data size from a table pointed to by $0EF30C. Otherwise, I recommend just assuming 3 bytes per sprite.


### Palette Data
Palette data is preceded by an 8-byte header. Bytes 4-6 of this are the source address of the data from the original ROM, but do not seem to actually be used for anything. If no custom palette is used, this value is just 000000.

After this are direct 16-bit SNES RGB values for all of the colors (regardless of whether a custom palette is in use). The final color is the back area color.



### Secondary Entrances
Has an (unused?) 8-byte header, followed by 8 bytes for each secondary entrance present in the level.  
The first two bytes of the data is the secondary entrance's ID (16-bit, little endian). Following this are three bytes for its values in the secondary exit tables $05FA00, $05FC00, and $05FE00 ($05F800 is implied by the level ID). The remaining three bytes appear to be unused for now.



### ExAnimation Data
The data starts with an 8-byte header. Byte 0 of this header contains the value for $03FE00, while the rest of the bytes seem unused.

The format of the actual ExAnimation data is identical to that of the ROM, which is documented [here](https://smwspeedruns.com/Level_Data_Format#ExAnimation_Data). Global ExAnimation data is not written to the MWL.



### ExGFX And Bypass Information
This data consists solely of sixteen 16-bit values, with one ExGFX file per value.
The sixteen ExGFX files are ordered as follows, each in little endian:
```
AN2, LT3,
BG3, BG2, FG3, BG1, FG2, FG1,
SP4, SP3, SP2, SP1,
LG4, LG3, LG2, LG1
```
Some of the files also have additional information written with them for various bypass-related information. See [here](https://smwspeedruns.com/Level_Data_Format#ExGFX_Files) for more details on the format.
