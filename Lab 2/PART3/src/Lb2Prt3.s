# LB2PRT3.S [170121]
# QECE ELEC274 Lab exercise 2, part 3
###############################################################################
# Code to show some computation and a simple loop, working through a structure
# Author:
#    David Athersych, P.Eng.
# History:
#	170121	1.0	DA	Original release, based on LB2PRT1.S
#
#==============================================================================
# Actual assembly code starts here:
#
# Directives - configuration information to the assembler.

# Symbol definitions - equivalent to #define LAST_RAM_WORD  0x007FFFFC
	.equ	LAST_RAM_WORD,	0x007FFFFC

# Object module configuration.
	.text				# tell assembler that this is code segment
	.global	_start		# tell assembler that _start is visible to linker

	.org	0x00000000	# starting address for the following code

_start:
	# Initialize stack pointer to point to last word in memory. Stack is
	# used by hardware to store return address during function call. Stack
	# may also be used for temporary variables.
	movia	sp, LAST_RAM_WORD
	# Pointer to start of array
	movia	r2, M
	# Initial guesses for BIG and SMALL would be first value in array
	ldw		r7, 4(r2)	# Get value in M[0].mark
	stw		r7, BIG(r0)	# Initial value of BIG
	stw		r7, SMALL(r0)	# Initial value of SMALL
	# Now, don't need to look at first one any more, so move array pointer
	addi	r2, r2, 8	# point to M[1]
	movi	r3, 9		# Store count in r3 (we'll count down)
	# Now go through remaining elements
loop:
	# Pehaps a bit odd, but check if we're done
	beq		r3, r0, done	# counter down to 0; we have done 9 elements
	## YOUR CODE GOES HERE
	## ---<SNIP>---
	ldw		r7, 4(r2)	# Get value in M[i].mark
	ldw 	r5, BIG(r0)
	ldw 	r4, SMALL(r0)
	blt 	r7, r5, not_bigger
	stw		r7, BIG(r0)
	br 		endloop
not_bigger:
	bgt 	r7, r4, endloop
	stw		r7, SMALL(r0)
	## ---<SNIP>---
endloop:
	# dealt with current element; decrement counter and increment pointer
	subi	r3, r3, 1		# one less to look at
	addi	r2, r2, 8		# each structure is 8 bytes
	br		loop			# remember, completion check done at start

done:
	ldw 	r5, BIG(r0)
	ldw 	r4, SMALL(r0)
	br		done			# nothing else to do and nowhere else to go.

#==============================================================================

	.org	0x00001000	# where this code is to go in memory
M:		.word	12345, 56
		.word	13733, 87
		.word	10563, 64
		.word	19222, 12
		.word	8766,  92
		.word	13366, 67
		.word	14562, 71
		.word	10030, 80
		.word	11034, 78
		.word	15003, 62
BIG:	.skip	4		# set aside 4 bytes, but don't initialize
SMALL:	.skip	4

	.end				# tells assembler this is the end

