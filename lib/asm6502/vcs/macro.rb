# MACRO.H
# Version 1.06, 3/SEPTEMBER/2004

VERSION_MACRO = 106

#
# THIS FILE IS EXPLICITLY SUPPORTED AS A DASM-PREFERRED COMPANION FILE
# PLEASE DO *NOT* REDISTRIBUTE MODIFIED VERSIONS OF THIS FILE!
#
# This file defines DASM macros useful for development for the Atari 2600.
# It is distributed as a companion machine-specific support package
# for the DASM compiler. Updates to this file, DASM, and associated tools are
# available at at http://www.atari2600.org/dasm
#
# Many thanks to the people who have contributed.  If you take issue with the
# contents, or would like to add something, please write to me
# (atari2600@taswegian.com) with your contribution.
#
# Latest Revisions...
#
# 1.06  03/SEP/2004     - nice revision of VERTICAL_BLANK (Edwin Blink)
# 1.05  14/NOV/2003     - Added VERSION_MACRO equate (which will reflect 100x version #)
#                         This will allow conditional code to verify MACRO.H being
#                         used for code assembly.
# 1.04  13/NOV/2003     - SET_POINTER macro added (16-bit address load)
#
# 1.03  23/JUN/2003     - CLEAN_START macro added - clears TIA, RAM, registers
#
# 1.02  14/JUN/2003     - VERTICAL_SYNC macro added
#                         (standardised macro for vertical synch code)
# 1.01  22/MAR/2003     - SLEEP macro added. 
#                       - NO_ILLEGAL_OPCODES switch implemented
# 1.0 22/MAR/2003   Initial release

# Note: These macros use illegal opcodes.  To disable illegal opcode usage, 
#   define the symbol NO_ILLEGAL_OPCODES (-DNO_ILLEGAL_OPCODES=1 on command-line).
#   If you do not allow illegal opcode usage, you must include this file 
#   *after* including VCS.H (as the non-illegal opcodes access hardware
#   registers and require them to be defined first).

# Available macros...
#   SLEEP n             - sleep for n cycles
#   VERTICAL_SYNC       - correct 3 scanline vertical synch code
#   CLEAN_START         - set machine to known state on startup
#   SET_POINTER         - load a 16-bit absolute to a 16-bit variable

#-------------------------------------------------------------------------------
# SLEEP duration
# Original author: Thomas Jentzsch
# Inserts code which takes the specified number of cycles to execute.  This is
# useful for code where precise timing is required.
# ILLEGAL-OPCODE VERSION DOES NOT AFFECT FLAGS OR REGISTERS.
# LEGAL OPCODE VERSION MAY AFFECT FLAGS
# Uses illegal opcode (DASM 2.20.01 onwards).

def sleep(cycles)  #usage: sleep n (n>1)
  if cycles < 2
    raise "MACRO ERROR: 'SLEEP': Duration must be > 1"
  end

  if cycles & 1
    bit :VSYNC
  end

  cycles -= 3

  (cycles / 2).times do
    nop
  end
end

#-------------------------------------------------------------------------------
# VERTICAL_SYNC
# revised version by Edwin Blink -- saves bytes!
# Inserts the code required for a proper 3 scanline vertical sync sequence
# Note: Alters the accumulator

# OUT: A = 0

def vertical_sync
  lda 0b1110         #%1110          # each '1' bits generate a VSYNC ON line (bits 1..3)
Label[:VSLP1]
  sta :WSYNC         # 1st '0' bit resets Vsync, 2nd '0' bit exit loop
  sta :VSYNC
  lsr
  bne :VSLP1         # branch until VYSNC has been reset
end

#-------------------------------------------------------------------------------
# CLEAN_START
# Original author: Andrew Davie
# Standardised start-up code, clears stack, all TIA registers and RAM to 0
# Sets stack pointer to $FF, and all registers to 0
# Sets decimal mode off, sets interrupt flag (kind of un-necessary)
# Use as very first section of code on boot (ie: at reset)
# Code written to minimise total ROM usage - uses weird 6502 knowledge :)

def clean_start
  sei
  cld

  ldx 0
  txa
  tay
Label[:CLEAR_STACK]
  dex
  txs
  pha
  bne :CLEAR_STACK     # SP=$FF, X = A = Y = 0
end

#-------------------------------------------------------
# SET_POINTER
# Original author: Manuel Rotschkar
#
# Sets a 2 byte RAM pointer to an absolute address.
#
# Usage: SET_POINTER pointer, address
# Example: SET_POINTER SpritePTR, SpriteData
#
# Note: Alters the accumulator, NZ flags
# IN 1: 2 byte RAM location reserved for pointer
# IN 2: absolute address

def set_pointer(pointer, address)
  lda address & 0xff  # Get Lowbyte of Address
  sta pointer         # Store in pointer
  lda address >> 8    # Get Hibyte of Address
  sta pointer + 1     # Store in pointer + 1
end

#-------------------------------------------------------
# BOUNDARY byte#
# Original author: Denis Debro (borrowed from Bob Smith / Thomas)
#
# Push data to a certain position inside a page and keep count of how
# many free bytes the programmer will have.
#
# eg: BOUNDARY 5    # position at byte #5 in page

def boundary(position)
  free_bytes = 0
  256.times do
    if (Asm6502.org & 0xff) == position
      break
    else
      free_bytes += 1
      Mem[:byte] = 0
    end
  end
end
