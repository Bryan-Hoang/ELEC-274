# LB2PRT2.S [170121]
# QECE ELEC274 Lab exercise 2, part 2
###############################################################################
# Program converts bytes from lower case to upper case
# and displays result on on terminal window.
# Author:
#    David Athersych, P.Eng.
# History:
#	170121	1.0	DA	Original release based on LB1PRT2.S
#
# Actual assembly code starts here:
#
# Directives - configuration information to the assembler.

# Symbol definitions
	.equ	LAST_RAM_WORD,	0x007FFFFC
	.equ	JTAG_UART_BASE,	0x10001000	# base address of JTAG UART
	.equ	OFFSET_DATA,	0			# offset from base for data register
	.equ	OFFSET_STATUS,	4			# offset from base for status register
	.equ	WSPACE_MASK,	0xFFFF		# 16 bit mask used to get status bits

# Object module configuration.
	.text				# tell assembler that this is code segment
	.global	_start		# tell assembler that _start is visible to linker

	.org	0x00000000	# starting address for following code

_start:
	# Initialize stack pointer to point to last word in memory. Stack is
	# used by hardware to store return address during function call. Stack
	# may also be used for temporary variables.
	movia	sp, LAST_RAM_WORD
	
	movui r4, 'a'
	movui r5, 'z'

	# Remember in C when we said using just the name of an array (without any
	# square brackets) was equivalent to a pointer to array?  Well, at the
	# assembly language level, all labels are just symbols associated with an
	# address, so moving value of a symbol into a register is same as
	# moving address of data into the register.

	# Step 0. Show string before change (not actually lab requirement)
	movia	r3, MSG
loop0:
	ldb		r2, 0(r3)		# fetch the byte pointed to by r3
	beq		r2, r0, done0	# if byte value is 0, we're done.
	call	PrintChar		# print character in r2
	addi	r3, r3, 1		# increment r3 pointer
	br		loop0			# do next character
done0:
	# add a newline character to the end
	movi	r2, '\n'		# just like C
	call	PrintChar

	# Step 1. Convert all characters in string to upper case
	movia	r3, MSG			# point to MSG again
loop1:
	ldb		r2, 0(r3)		# fetch the byte pointed to by r3
	beq		r2, r0, done1	# if byte value is 0, we're done.
	## --- <SNIP> ---

	bltu	r2, r4, increment
	bgtu	r2, r5, increment
	subi	r2, r2, 0x20
	# Or like this:
	# subi	r2, r2, 'a'
	# addi    r2, r2, 'A'
	
	## --- <SNIP> ---
	# increment the pointer to the string
increment:
	stb		r2, 0(r3)
	addi	r3, r3, 1		# increment r3 pointer
	br		loop1			# do next character
done1:

	# Step 2. Show string after change (not actually lab requirement)
	movia	r3, MSG
loop:
	ldb		r2, 0(r3)		# fetch the byte pointed to by r3
	beq		r2, r0, done	# if byte value is 0, branch to done.
	call	PrintChar		# print character in r2
	addi	r3, r3, 1		# increment r3 pointer
	br		loop			# do next character
done:
	# add a newline character to the end
	movi	r2, '\n'		# just like C
	call	PrintChar
_end:
	br		_end		# nothing else to do and nowhere else to go.

#==============================================================================
# Subroutine PrintChar
# Parameters:
#	R2	- contains character to be displayed
# Return value:
#	nothing

PrintChar:
	subi	sp, sp, 8	# room to save two registers
	stw		r3, 4(sp)	# save contents of r3
	stw		r4, 0(sp)	# and r4.
	movia	r3, JTAG_UART_BASE		# r3 -> base of UART device registers
chkrdy:
	ldwio	r4, OFFSET_STATUS(r3)	# fetch contents of status register
	andhi	r4, r4, WSPACE_MASK		# keep only low-order 16 bits
	beq		r4, r0, chkrdy			# all 0? Try again
	# Get here when READY bit turns on
	stwio	r2, OFFSET_DATA(r3)		# Write character to data register
	# our work accomplished; restore register values
	ldw		r3, 4(sp)
	ldw		r4, 0(sp)
	addi	sp, sp, 8	# add 8 to sp, effectively discarding space on stack
	ret					# go back to calling site, all registers preserved

#==============================================================================

	.org	0x00001000	# where this code is to go in memory
MSG:.asciz	">> hello TA <<"	# some lowercase, some uppercase, some
								# non-letter characters

	.end				# tells assembler this is the end

