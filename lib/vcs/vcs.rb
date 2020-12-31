require "../r6502"
include R6502

TIA_BASE_ADDRESS = 0
TIA_BASE_READ_ADDRESS = TIA_BASE_ADDRESS
TIA_BASE_WRITE_ADDRESS = TIA_BASE_ADDRESS

Org[TIA_BASE_WRITE_ADDRESS]

Label[:VSYNC, 1]    # $00   0000 00x0   Vertical Sync Set-Clear
Label[:VBLANK, 1]   # $01   xx00 00x0   Vertical Blank Set-Clear
Label[:WSYNC, 1]    # $02   ---- ----   Wait for Horizontal Blank
Label[:RSYNC, 1]    # $03   ---- ----   Reset Horizontal Sync Counter
Label[:NUSIZ0, 1]   # $04   00xx 0xxx   Number-Size player/missle 0
Label[:NUSIZ1, 1]   # $05   00xx 0xxx   Number-Size player/missle 1
Label[:COLUP0, 1]   # $06   xxxx xxx0   Color-Luminance Player 0
Label[:COLUP1, 1]   # $07   xxxx xxx0   Color-Luminance Player 1
Label[:COLUPF, 1]   # $08   xxxx xxx0   Color-Luminance Playfield
Label[:COLUBK, 1]   # $09   xxxx xxx0   Color-Luminance Background
Label[:CTRLPF, 1]   # $0A   00xx 0xxx   Control Playfield, Ball, Collisions
Label[:REFP0, 1]    # $0B   0000 x000   Reflection Player 0
Label[:REFP1, 1]    # $0C   0000 x000   Reflection Player 1
Label[:PF0, 1]      # $0D   xxxx 0000   Playfield Register Byte 0
Label[:PF1, 1]      # $0E   xxxx xxxx   Playfield Register Byte 1
Label[:PF2, 1]      # $0F   xxxx xxxx   Playfield Register Byte 2
Label[:RESP0, 1]    # $10   ---- ----   Reset Player 0
Label[:RESP1, 1]    # $11   ---- ----   Reset Player 1
Label[:RESM0, 1]    # $12   ---- ----   Reset Missle 0
Label[:RESM1, 1]    # $13   ---- ----   Reset Missle 1
Label[:RESBL, 1]    # $14   ---- ----   Reset Ball
Label[:AUDC0, 1]    # $15   0000 xxxx   Audio Control 0
Label[:AUDC1, 1]    # $16   0000 xxxx   Audio Control 1
Label[:AUDF0, 1]    # $17   000x xxxx   Audio Frequency 0
Label[:AUDF1, 1]    # $18   000x xxxx   Audio Frequency 1
Label[:AUDV0, 1]    # $19   0000 xxxx   Audio Volume 0
Label[:AUDV1, 1]    # $1A   0000 xxxx   Audio Volume 1
Label[:GRP0, 1]     # $1B   xxxx xxxx   Graphics Register Player 0
Label[:GRP1, 1]     # $1C   xxxx xxxx   Graphics Register Player 1
Label[:ENAM0, 1]    # $1D   0000 00x0   Graphics Enable Missle 0
Label[:ENAM1, 1]    # $1E   0000 00x0   Graphics Enable Missle 1
Label[:ENABL, 1]    # $1F   0000 00x0   Graphics Enable Ball
Label[:HMP0, 1]     # $20   xxxx 0000   Horizontal Motion Player 0
Label[:HMP1, 1]     # $21   xxxx 0000   Horizontal Motion Player 1
Label[:HMM0, 1]     # $22   xxxx 0000   Horizontal Motion Missle 0
Label[:HMM1, 1]     # $23   xxxx 0000   Horizontal Motion Missle 1
Label[:HMBL, 1]     # $24   xxxx 0000   Horizontal Motion Ball
Label[:VDELP0, 1]   # $25   0000 000x   Vertical Delay Player 0
Label[:VDELP1, 1]   # $26   0000 000x   Vertical Delay Player 1
Label[:VDELBL, 1]   # $27   0000 000x   Vertical Delay Ball
Label[:RESMP0, 1]   # $28   0000 00x0   Reset Missle 0 to Player 0
Label[:RESMP1, 1]   # $29   0000 00x0   Reset Missle 1 to Player 1
Label[:HMOVE, 1]    # $2A   ---- ----   Apply Horizontal Motion
Label[:HMCLR, 1]    # $2B   ---- ----   Clear Horizontal Move Registers
Label[:CXCLR, 1]    # $2C   ---- ----   Clear Collision Latches

Org[TIA_BASE_READ_ADDRESS]

Label[:CXM0P, 1]    # $00       xx00 0000       Read Collision  M0-P1   M0-P0
Label[:CXM1P, 1]    # $01       xx00 0000                       M1-P0   M1-P1
Label[:CXP0FB, 1]   # $02       xx00 0000                       P0-PF   P0-BL
Label[:CXP1FB, 1]   # $03       xx00 0000                       P1-PF   P1-BL
Label[:CXM0FB, 1]   # $04       xx00 0000                       M0-PF   M0-BL
Label[:CXM1FB, 1]   # $05       xx00 0000                       M1-PF   M1-BL
Label[:CXBLPF, 1]   # $06       x000 0000                       BL-PF   -----
Label[:CXPPMM, 1]   # $07       xx00 0000                       P0-P1   M0-M1
Label[:INPT0, 1]    # $08       x000 0000       Read Pot Port 0
Label[:INPT1, 1]    # $09       x000 0000       Read Pot Port 1
Label[:INPT2, 1]    # $0A       x000 0000       Read Pot Port 2
Label[:INPT3, 1]    # $0B       x000 0000       Read Pot Port 3
Label[:INPT4, 1]    # $0C       x000 0000       Read Input (Trigger) 0
Label[:INPT5, 1]    # $0D       x000 0000       Read Input (Trigger) 1

Org[0x280]

Label[:SWCHA, 1]    # $280      Port A data register for joysticks:
                    #           Bits 4-7 for player 1.  Bits 0-3 for player 2.

Label[:SWACNT, 1]   # $281      Port A data direction register (DDR)
Label[:SWCHB, 1]    # $282      Port B data (console switches)
Label[:SWBCNT, 1]   # $283      Port B DDR
Label[:INTIM, 1]    # $284      Timer output

Label[:TIMINT, 1]   # $285

# Unused/undefined registers ($285-$294)
Label[nil, 14]

Label[:TIM1T, 1]    # $294      set 1 clock interval
Label[:TIM8T, 1]    # $295      set 8 clock interval
Label[:TIM64T, 1]   # $296      set 64 clock interval
Label[:T1024T, 1]   # $297      set 1024 clock interval
