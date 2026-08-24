# A note on AI contributions:

This project is intentionally written and maintained by humans. Please don't use AI coding agents or code-generation tools to modify the project. This isn't an anti-AI statement, it's simply a choice I'm making for this project. Thanks for respecting it.

# Bare Bones NES CA65 Project

This is a bare bones NES starter project intended as a jumping off point for NES 6502 assembly development using the CA65 assembler. See below for detailed code breakdown. This starter project does not include a mapper, see my other repository 'name here' for an MMC3 example.

# Code conventions

File names: lower case with underscores eg. my_code.asm.  
Zero page variables: prefix and description with underscores eg. zp_player_x  
Ram variables: Omit the prefix eg. player_lives  
Label names: lower case with underscore (verbs for routines, nouns for data) eg. load_palette, palette_data  
Tables: lower case with underscore, end with _table eg. sin_table  
Constants: all caps with underscores eg. PLAYER_SPEED  
Macros: all caps with underscores eg. LOAD_POINTER  
Local labels: eg. @loop:  
Hardware Registers: always name them after NES docs: rg. PPUCTRL, PPUMASK, PPUSTATUS, OAMDATA, PPUADDR, PPUDATA  
Structured pairs: eg. zp_sprite_lo, zp_sprite_hi  
Procedures: use verbs, lower case, underscores eg. update_player  
Instructions: lower case eg. lda, clc  

Pointers: use assembly time aliases eg.  
  -  ptr:    .res 2  
  -  ptr_lo = ptr  
  -  ptr_hi = ptr+1  

# Order of segments

General order in source files:

1. .segment "HEADER"
2. .segment "ZEROPAGE"
3. .segment "BSS"
4. .segment "RODATA"
5. .segment "CODE"
6. .segment "VECTORS"
7. .segment "CHR"

Do not include empty segments.

# Makefile / how to assemble

```
begin_build:
echo " DEBUG build start ->"
ca65 src/main.asm -g -o main.o
ld65 -o output.nes -C ld65.cfg main.o --dbgfile output.dbg
ld65 -C ld65.cfg -o output.nes main.o --mapfile output.map
echo "------- DEBUG build S-U-C-C-E-S-S.-------"
```

# Detailed code breakdown

### ld65.cfg

TODO

### output.nes

Files with .nes extensions are ROM files for use with NES emulators.

### test_gfx.chr

TODO

### constants.asm

TODO

### header.asm

TODO

### macros.asm

TODO

### main.asm

```
.include "header.asm"
.include "macros.asm"
.include "constants.asm"
```

Puts the entire contents of these files here.

```
.segment "ZEROPAGE"
sprite_y: .res 1
sleeping: .res 1
```

Reserve two bytes in zeropage. 'sprite_y' will be used for moving a sprite vertically. 'sleeping' will be used to control the speed of the main game loop.

.segment "RODATA"
palette_table:
; background
  .byte $0F,$00,$10,$30
  .byte $0F,$01,$21,$31
  .byte $0F,$06,$16,$26
  .byte $0F,$09,$19,$29
; sprites
  .byte $0F,$00,$10,$30
  .byte $0F,$01,$21,$31
  .byte $0F,$06,$16,$26
  .byte $0F,$09,$19,$29
  
.segment "CODE"
reset:
; --------------------------------------------------
; Disable maskable interrupts
; Clear decimal mode
; --------------------------------------------------
  sei
  cld

; --------------------------------------------------
; Disable nmi/rendering
; --------------------------------------------------
  ldx #$00
  stx PPUCTRL
  stx PPUMASK

  WAIT_VBLANK

  lda #%01000000
  sta APU_FRAME_COUNTER

; --------------------------------------------------
; clear vram
; --------------------------------------------------
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldx #$00
  lda #$00
clear_loop:
  sta PPUDATA
  inx
  bne clear_loop

; --------------------------------------------------
; Init game memory
; --------------------------------------------------
  lda #$80
  sta sprite_y
  sta sleeping

; --------------------------------------------------
; Finished resetting, go to main loop
; --------------------------------------------------
  jmp main

main:
; --------------------------------------------------
; Disable nmi/rendering
; --------------------------------------------------
  ldx #$00
  stx PPUCTRL
  stx PPUMASK

; --------------------------------------------------
; Load initial palette
; --------------------------------------------------
  ldx PPUSTATUS
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR

  ldx #$00
:
  lda palette_table, x
  sta PPUDATA
  inx
  cpx #$20
  bne :-

; --------------------------------------------------
; Enable maskable interrupts
; --------------------------------------------------
  cli

; --------------------------------------------------
; Enable sprites and background
; --------------------------------------------------
  lda #%00011000 
  sta PPUMASK

; --------------------------------------------------
; NMI on, background is at $1000 sprites are at $0000
; -------------------------------------------------
  lda #%10010000
  sta PPUCTRL

main_loop:
  inc sprite_y

; --------------------------------------------------
; Draw a sprite: Ypos, Tile, Attributes, Xpos
; --------------------------------------------------
  lda sprite_y
  sta $0200
  lda #$01
  sta $0201
  lda #$00
  sta $0202
  lda #$10
  sta $0203

; --------------------------------------------------
; Wait until NMI resets 'sleeping' to 0
; --------------------------------------------------
  lda #$01
  sta sleeping

sleep:
  lda sleeping
  bne sleep

  jmp main_loop

nmi:
  SAVE_REGISTERS
; --------------------------------------------------
; Trigger sprite DMA transfer
; --------------------------------------------------
  lda #$02
  sta OAMDMA

; --------------------------------------------------
; Reset OAM address
; --------------------------------------------------
  lda #$00
  sta OAMADDR

; --------------------------------------------------
; Set scroll
; --------------------------------------------------
  lda #$00
  sta PPUSCROLL
  sta PPUSCROLL

; --------------------------------------------------
; NMI on, background at $1000 sprites at $0000
; --------------------------------------------------
  lda #%10010000
  sta PPUCTRL

; --------------------------------------------------
; Toggle sleeping flag
; --------------------------------------------------
  lda #$00
  sta sleeping

  RESTORE_REGISTERS
  
  rti

irq:
  rti

.segment "VECTORS"
  .word nmi
  .word reset
  .word irq

.segment "CHRROM"
  .incbin "test_gfx.chr"

