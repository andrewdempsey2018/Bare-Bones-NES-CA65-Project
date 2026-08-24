.include "header.asm"
.include "macros.asm"
.include "constants.asm"

.segment "ZEROPAGE"
sprite_y: .res 1
sleeping: .res 1

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
  lda #128
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
