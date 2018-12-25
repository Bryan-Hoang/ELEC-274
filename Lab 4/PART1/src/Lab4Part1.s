# LAB4PART1.S [170114]
# Code for part 1 of ELEC274 Lab 4

###############################################################################
#
# Code based on JTAGPOLL.S.
#
# Author:
# David Athersych, P.Eng. Cynosure Computer Technologies Inc.
#
# HISTORY:
# 170114 DFA	First release, based on code found in Altera documentation
#				and on several websites.  Intended for QECE ELEC274.
# 170222 DFA	Added echo to read character routine.
# 180207 DFA	Minor code cleanup; removed redundant code
###############################################################################


# Define base address for device, offsets and register masks.
	.equ	JTAG_UART_BASE,	0x10001000	# base address of JTAG UART
	.equ	OFFSET_DATA,	0			# offset from base for data register
	.equ	OFFSET_STATUS,	4			# offset from base for status register
	.equ	WSPACE_MASK,	0xFFFF		# 16 bit mask used to get status bits
	.equ	RVALID,			0x8000		# Read data available bit in data reg.



	.equ	LAST_RAM_WORD,	0x007FFFFC #memory location for stack pointer start

	.text
	.global _start
	.org 0x0

_start:
	movia	sp, LAST_RAM_WORD	#set up stack pointer
	# Your code goes here
#---<SNIP>---

	movia 	r4, INTRO
	call 	PrintString
	
	movia 	r4, STR
	movi 	r3, 24
	call 	GetString
	
	movia 	r4, STR
	call 	PrintString
	
#---<SNIP>---
_end:
	br _end
	
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
	subi	sp, sp, 8	# subtract 8 from sp, making room for two words
	stw		r3, 4(sp)	# save contents of r3
	stw		r4, 0(sp)	# and r4.
	movia	r3, JTAG_UART_BASE	# r3 points to base of UART device registers
loop2:
	ldwio	r4, OFFSET_STATUS(r3)	# fetch contents of status register
	andhi	r4, r4, WSPACE_MASK		# keep only low-order 16 bits
	beq		r4, r0, loop2			# all 0? Try again
	# Get here when READY bit turns on
	stwio	r2, OFFSET_DATA(r3)		# Write character to data register
eggsit:
	# our work accomplished; restore register values
	ldw		r3, 4(sp)
	ldw		r4, 0(sp)
	addi	sp, sp, 8	# add 8 to sp, effectively discarding space on stack
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
	subi	sp, sp, 8	# two words on stack
	stw		r3, 4(sp)
	stw		r4, 0(sp)
	movia	r3, JTAG_UART_BASE	# point to JTAG base register
loop3:
	ldwio	r2, 0(r3)			# read JTAG register
	andi	r4, r2, RVALID		# check if data available
	beq		r4, r0, loop3		# if no data, check again
	# character returned in r2
	andi	r2, r2, 0x00ff		# data in least significant byte
	# handle echo, so human can see what was typed.  Assume output is ready,
	# (fairly safe assumption if JTAG being used for human input) so just
	# write character to output port
	stwio	r2, OFFSET_DATA(r3)	# write character to data register
	# restore saved registers
	br	eggsit					# use existing exit code in PutJTAG
	
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
	cmpeqi	r5, r2, '\n'		# was it return key?
	bne		r5, r0, gsdone		# r5 non-zero if r2 == LF
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
	# add a newline character to output
	movi	r2, '\n'			# just like C
	call	PutJTAG
	# restore saved r2 contents
	ldw		r2, 0(sp)			# value at top of stack is saved r2
	ldw		ra, 4(sp)			# value below that is saved ra
	addi	sp, sp, 8			# two words off stack pointer
	ret							# return to address in ra
	

#==============================================================================

	

	.org 0x1000
INTRO:	.asciz	"Please enter a word then press RETURN."
STR:	.skip	24				#buffer for entered string
EXIT:	.asciz	"You entered: "	

.end
