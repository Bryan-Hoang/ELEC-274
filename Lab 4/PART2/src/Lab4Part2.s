# LAB4PRT2.S [170225]
# QECE ELEC274 Lab exercise 4, part 2

###############################################################################
# Code to demonstrate I/O and character manipulation.
# Author:
#    David Athersych, P.Eng.
# History:
# 170225 DA	Original release
# 180207 DA Modified for winter 2018
#
#==============================================================================
#
# Directives - configuration information to the assembler.

# Symbol definitions
	.equ	LAST_RAM_WORD,	0x007FFFFC

# Object module configuration.
	.text				# tell assembler that this is code segment
	.global	_start		# tell assembler that _start is visible to linker

	.org	0x00000400	# starting address for the following code

_start:
	movia	sp, LAST_RAM_WORD	# set up pointer to last word in RAM
#---<SNIP>---

	movia 	r4, Prompt1
	call 	PrintString
	
	movia 	r4, InBuff
	movi 	r3, 64
	call 	GetString

	movia 	r3, InBuff
	movia 	r4, OtherBf
	call 	strcpy
	
	movia 	r4, Prompt2
	call 	PrintString
	
	movia 	r4, InBuff
	movi 	r3, 64
	call 	GetString
	
	movia 	r3, OtherBf
	movia 	r4, InBuff
	call 	strcmp
	
	bne		r5, r0, not_same
	movia 	r4, Same
	call 	PrintString
	br		_end
not_same:
	bgt		r5, r0, more
	movia 	r4, Srcless
	call 	PrintString
	br		_end
more:
	movia 	r4, Dstless
	call 	PrintString
	
#---<SNIP>---
_end:
	br		_end		# nothing else to do and nowhere else to go.


### CODE TO BE FILLED IN

#==============================================================================
# Subroutine strcpy
# Copies contents of one string to another location.  Does not check for issues
# such as copying a string to itself or to a location that won't work.
#
# Parameters:
#	R3	- address of source string
#	R4	- address of destination
# Return value:
#	Both R3 and R4 point to ends of source and destination string respectively
#


strcpy:
#---<SNIP>---
subi	sp, sp, 4		# room to save 1 register
	stw		r5, 0(sp)		# save contents of r5
	
loop1:
	ldb		r5, 0(r3)		# fetch the byte pointed to by r3
	stb		r5, 0(r4)		
	addi	r3, r3, 1		# increment r3 pointer
	addi	r4, r4, 1		# increment r4 pointer
	bne		r5, r0, loop1	# if char value is not 0, keep looping
	
	ldw		r5, 0(sp)
	addi	sp, sp, 4	# add 4 to sp, effectively discarding space on stack
#---<SNIP>---
	ret

#==============================================================================
# Subroutine strcmp
# Compares contents of one string to contents of another.
#
# Parameters:
#	R3	- address of source string
#	R4	- address of destination
# Return value:
#	Both R3 and R4 modified - if strings same length, both will point to NUL
#	terminators of respective strings.
#	R5	- 0 if strings same, negative if src < dst, positive if src > dst

strcmp:
#---<SNIP>---
	subi	sp, sp, 8		# room to save 2 registers
	stw		r6, 4(sp)		# save contents of r6
	stw		r7, 0(sp)		# save contents of r7
	
loop_:
	ldb		r6, 0(r3)		# fetch the byte pointed to by r3
	ldb		r7, 0(r4)		# fetch the byte pointed to by r4
	addi	r3, r3, 1		# increment r3 pointer
	addi	r4, r4, 1		# increment r4 pointer
	beq		r6, r0, done_	# if char value 1 is 0, we're done.
	beq		r7, r0, done_	# if char value 2 is 0, we're done.
	beq		r6, r7, loop_	# if char values match, do next character
done_:
	sub		r5, r6, r7
	
	ldw		r6, 4(sp)
	ldw		r7, 0(sp)
	addi	sp, sp, 8	# add 4 to sp, effectively discarding space on stack
#---<SNIP>---
	ret



# Code from previous work

###############################################################################
# JTAGPOLL - Code to handle reading and writing JTAG UART in polled mode.
#
# Author:
# David Athersych, P.Eng. Cynosure Computer Technologies Inc.
#
# HISTORY:
# 170114 DFA	First release, based on code found in Altera documentation
#				and on several websites.  Intended for QECE ELEC274.
# 170222 DFA	Added echo to read character routine
###############################################################################

# Prevent this code from being included twice

# Define base address for device, offsets and register masks.
	.equ	JTAG_UART_BASE,	0x10001000	# base address of JTAG UART
	.equ	OFFSET_DATA,	0			# offset from base for data register
	.equ	OFFSET_STATUS,	4			# offset from base for status register
	.equ	WSPACE_MASK,	0xFFFF		# 16 bit mask used to get status bits
	.equ	RVALID,			0x8000		# Read data available bit in data reg.
	.equ	DATA_IN_MASK,	0x00FF		# input data in bottom byte


#==============================================================================
# Subroutine PutJTAG
# Write character to JTAG output port.  Characters written to this port will
# be displayed on monitor screen.
# Parameters:
#	R2	- contains character to be displayed
# Return value:
#	nothing

	.global	PutJTAG

PutJTAG:
	subi	sp, sp, 8				# make room for two words
	stw		r3, 4(sp)				# save contents of r3
	stw		r4, 0(sp)				# and r4.
	movia	r3, JTAG_UART_BASE		# r3 points to base of UART registers
loop2:
	ldwio	r4, OFFSET_STATUS(r3)	# fetch contents of status register
	andhi	r4, r4, WSPACE_MASK		# keep only high-order 16 bits
	beq		r4, r0, loop2			# all 0? Ready bit off, so try again
	# Get here when READY bit turns on
	stwio	r2, OFFSET_DATA(r3)		# Write character to data register
eggsit:
	# our work accomplished; restore register values
	ldw		r3, 4(sp)				# restore previous r3 value
	ldw		r4, 0(sp)				# restore previous r4 value
	addi	sp, sp, 8				# discard space on stack
	ret					# go back to calling site, all registers preserved

#==============================================================================
# Subroutine GetJTAG
# Read character from JTAG input port.  Characters read from this port will
# also be echoed back, that is, displayed on monitor screen.
# Parameters:
#	none
# Return value:
#	R2	- contains character read

	.global	GetJTAG

GetJTAG:
	subi	sp, sp, 8			# two words on stack
	stw		r3, 4(sp)			# save contents R3
	stw		r4, 0(sp)			# and R4
	movia	r3, JTAG_UART_BASE	# point to JTAG base register
loop3:
	ldwio	r2, OFFSET_DATA(r3)	# read JTAG data register
	andi	r4, r2, RVALID		# isolate bit 15 - set when character(s) avail.
	beq		r4, r0, loop3		# if no data, check again
	# character in bottom 8 bits - returned in r2
	andi	r2, r2, DATA_IN_MASK	# data in least significant byte
	# handle echo, so human can see what was typed.  Assume output is ready,
	# (fairly safe assumption if JTAG being used for human input) so just
	# write character to output port
	stwio	r2, OFFSET_DATA(r3)	# write character to data register
	# restore saved registers
	br	eggsit					# use existing exit code in PutJTAG
	
#==============================================================================

###############################################################################
# Read strings from and write strings to the JTAG port.  Works with code found
# in JTAGPOLL.s.
#
# Author:
# David Athersych, P.Eng. Cynosure Computer Technologies Inc.
#
# HISTORY:
# 170224 DFA	First release
# 180205 DFA	Added ifndef to prevent multiple includes
###############################################################################

#==============================================================================
# Subroutine GetString
# Reads characters from serial port and stores them in supplied buffer. Stops
# when buffer is full or when CR character found. End of input marked with
# NUL character.
#
# Uses:
#	GetJTAG - fetches one character from serial port
#
# Parameters:
#	R4	- Address of buffer to fill.
#	R3	- length of buffer
# Returns:

GetString:
	# Save registers
	subi	sp, sp, 12			# space for three registers
	stw		ra, 8(sp)			# return address
	stw		r2, 4(sp)			# working register
	stw		r5, 0(sp)			# working register
	# r4 points to buffer, r3 holds max length. Neither will be preserved.
gsloop:
	cmplei	r5, r3, 1			# make sure r3 greater than 1
	bne		r5, r0, gsdone		# r5 non-zero if r3 <= 1
	call	GetJTAG				# returns with character in R2
	cmpeqi	r5, r2, '\n'		# was it NL? (Translated by emulator)
	bne		r5, r0, gsdone		# r5 non-zero if r2 == CR
	stb		r2, 0(r4)			# store character read where r4 points
	addi	r4, r4, 1			# move buffer pointer by 1 character
	subi	r3, r3, 1			# one less place in buffer
	br		gsloop				# do it again
gsdone:
	# Either r3 says only one more byte left, or just read CR character
	# Store end-of-string marker in buffer, restore registers and return
	stb		r0, 0(r4)			# NUL byte for end of string
	ldw		r5, 0(sp)			# restore R5
	ldw		r2, 4(sp)
	ldw		ra, 8(sp)
	addi	sp, sp, 12
	ret
	
#==============================================================================
# Subroutine PrintString
# Print ASCIZ string to output device.  This code uses the PrintChar function
# so it needs to save ra.  Note that this code will keep outputting characters
# until NUL found - it does not have any length checking.

# Parameters:
#	R4	- contains address of string to be displayed
# Return value:
#	R4	- point to end of string (i.e. null character at end.

PrintString:
	# We will call another function, so we need to save contents of ra
	subi	sp, sp, 8			# decrement stack pointer by 2 words
	stw		ra, 4(sp)			# store ra on stack
	stw		r2, 0(sp)			# Use R2 to pass character to PrintChar
	# r4 points to ASCIZ string, but we won't preserve it
loop:
	ldb		r2, 0(r4)			# fetch the byte pointed to by r4
	beq		r2, r0, done		# if byte value is 0, branch to done.
	call	PutJTAG				# print character in r2
	addi	r4, r4, 1			# increment r4 pointer
	br		loop				# do next character
done:
	# add a newline character to the end
	movi	r2, '\n'			# just like C
	call	PutJTAG
	# restore saved r2 contents
	ldw		r2, 0(sp)			# value at top of stack is saved r2
	ldw		ra, 4(sp)			# value below that is saved ra
	addi	sp, sp, 8			# two words off stack pointer
	ret							# return to address in ra

#==============================================================================


# Static data.
Prompt1:	.asciz	"Enter first word, terminated by return key:"
Prompt2:	.asciz	"Enter second word:"
Same:		.asciz	"Words same."
Srcless:	.asciz	"First one less than second"
Dstless:	.asciz	"Second one less than first"

CRLF:	.byte	0x0D, 0x0A, 0x00
#==============================================================================

	.org	0x00001000	# where this data is to go in memory
InBuff:		.skip	64	# 64 byte buffer should be big enough
OtherBf:	.skip	64	# another 64 byte buffer

	.end				# tells assembler this is the end

