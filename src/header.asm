.segment "HEADER"
  .byte $4E, $45, $53, $1A ; (ASCII "NES" followed by MS-DOS end-of-file)
  .byte $02 ; PRG ROM size in 16KB units
  .byte $01 ; CHR ROM size in 8KB units
  .byte %00000000 ; Flags 6 Mapper, mirroring, battery, trainer
  .byte %00000000 ; Flags 7 Mapper, VS/Playchoice, NES 2.0
  .byte $00 ; Flags 8 PRG-RAM size (rarely used extension)
  .byte $00 ; Flags 9 TV system (rarely used extension)
  .byte $00 ; Flags 10 TV system, PRG-RAM presence (unofficial, rarely used extension)
  .byte $00, $00, $00, $00, $00 ; Padding