# JTAGSTRS.S [170224]

##### DISCLAIMER ###############################################################
# This code has been provided by David Athersych primarily to support students
# in QECE ELEC274. The receiver of this code may use it without charge, subject
# to the following conditions: (a) the receiver acknowledges that this code has
# been received without warranty or guarantee of any kind; (b) the receiver
# acknowledges that the receiver shall make the determination whether this code
# is suitable for the receiver's needs; and (c) the receiver agrees that all
# responsibility for loss or damage due to the use of the code lies with the
# receiver. Professional courtesy would suggest that the receiver report any
# errors found, and that the receiver acknowledge the source of the code. See
# more information at www.cynosurecomputer.ca or
#     https://gitlab.com/david.athersych/ELEC274Code.git
################################################################################

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


# Prevent this code from being included twice
.ifndef	JTAGPOLL_S
.equ	JTAGPOLL_S, 1


# Uses PrintChar and GetChar from JTAGPOLL.
		.include	JTAGPOLL.S

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
	call	PrintChar			# print character in r2
	addi	r4, r4, 1			# increment r4 pointer
	br		loop				# do next character
done:
	# add a newline character to the end
	movi	r2, '\n'			# just like C
	call	PrintChar
	# restore saved r2 contents
	ldw		r2, 0(sp)			# value at top of stack is saved r2
	ldw		ra, 4(sp)			# value below that is saved ra
	addi	sp, sp, 8			# two words off stack pointer
	ret							# return to address in ra

#==============================================================================
.endif
