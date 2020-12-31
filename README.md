# r6502

Write 6502 assembly with Ruby code.

This gem was specifically built to write Atari2600 games and comes packages with some the Ruby equivalent of the `vcs.h` and `macro.h` files. It is also in a very early stage
of development and should be considered as a proof of concept.

## Usage

Ruby is quite a powerful language when it comes to building DSL like configuration files... or 6502 assembly. Let's take an example from https://8bitworkshop.com:

```
; https://8bitworkshop.com/v3.7.0/?file=examples%2Fplayfield.a&platform=vcs

  processor 6502
	include "vcs.h"
	include "macro.h"

	org  $f000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
; We're going to mess with the playfield registers, PF0, PF1 and PF2.
; Between them, they represent 20 bits of bitmap information
; which are replicated over 40 wide pixels for each scanline.
; By changing the registers before each scanline, we can draw bitmaps.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Counter	equ $81

Start	CLEAN_START

NextFrame
; This macro efficiently gives us 1 + 3 lines of VSYNC
	VERTICAL_SYNC
	
; 36 lines of VBLANK
	ldx #36
LVBlank	sta WSYNC
	dex
	bne LVBlank
; Disable VBLANK
        stx VBLANK
; Set foreground color
	lda #$82
        sta COLUPF
; Draw the 192 scanlines
	ldx #192
	lda #0		; changes every scanline
        ;lda Counter    ; uncomment to scroll!
ScanLoop
	sta WSYNC	; wait for next scanline
	sta PF0		; set the PF1 playfield pattern register
	sta PF1		; set the PF1 playfield pattern register
	sta PF2		; set the PF2 playfield pattern register
	stx COLUBK	; set the background color
	adc #1		; increment A
	dex
	bne ScanLoop

; Reenable VBLANK for bottom (and top of next frame)
	lda #2
        sta VBLANK
; 30 lines of overscan
	ldx #30
LVOver	sta WSYNC
	dex
	bne LVOver
	
; Go back and do another frame
	inc Counter
	jmp NextFrame
	
	org $fffc
	.word Start
	.word Start
```

The same code written using r6502 will be something like:

```ruby
require "r6502"
include R6502

require 'r6502/vcs'

# We're going to mess with the playfield registers, PF0, PF1 and PF2.
# Between them, they represent 20 bits of bitmap information
# which are replicated over 40 wide pixels for each scanline.
# By changing the registers before each scanline, we can draw bitmaps.

Org[0x0080]
Label[:counter, 1]

Output[ARGV[0]] do
  Org[0xf000]
  Label[:reset]

    clean_start

  Label[:next_frame]
    # This macro efficiently gives us 1 + 3 lines of VSYNC
    vertical_sync

    # 36 lines of VBLANK
    ldx 36

  Label[:lv_blank]

    sta :WSYNC
    dex
    bne :lv_blank
    
    # Disable VBLANK
    stx :VBLANK

    # Set foreground color
    lda 0x82
    sta :COLUPF

    # Draw the 192 scanline
    ldx 192
    lda 0 # changes every scanline

  Label[:scan_loop]

    sta :WSYNC  # wait for next scanline
    sta :PF0    # set the PF0 playfield pattern register
    sta :PF1    # set the PF1 playfield pattern register
    sta :PF2    # set the PF1 playfield pattern register
    stx :COLUBK # set the background color
    adc 1       # increment A
    dex
    bne :scan_loop

    # Reenable VBLANK for bottom (and top of next fram
    lda 2
    sta :VBLANK

    #  30 lines of overscan
    ldx 30

  Label[:lv_over]
    sta :WSYNC
    dex
    bne :lv_over

    # Go back and do another frame
    inc :counter
    jmp :next_frame

  Org[0xfffa]

  Mem[2] = :reset
  Mem[2] = :reset
  Mem[2] = :reset
end
```
