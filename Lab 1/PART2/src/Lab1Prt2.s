# LAB1PART2.S [170101]
# QECE ELEC274 Lab exercise 1, part 2
###############################################################################
# Program displays "hello, world" on terminal window.
# Author:
#    Dr. Naraig Manjikian, P.Eng.
# Modifications:
#    David Athersych, P.Eng.
# History:
#	1.0	NM	Original release
#	2.0	DA	Reformat, add comments
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

	.org	0x00000000	# starting address for the following code

_start:
	# Initialize stack pointer to point to last word in memory. Stack is
	# used by hardware to store return address during function call. Stack
	# may also be used for temporary variables.
	movia	sp, LAST_RAM_WORD

	# Design in C-like code
	#	for (r3=MSG; *r3 != '\0'; r3++)
	#	{
	#		r2 = *r3;
	#		PrintChar (r2);
	#	}
	#		== OR ==
	#
	#	r3=MSG;
	#	while (*r3 != '\0')
	#	{
	#		r2 = *r3;
	#		PrintChar (r2);
	#		r3++;
	#	}

	# Remember in C when we said using just the name of an array (without any
	# square brackets) was equivalent to a pointer to an array?  Well, at the
	# assembly language level, all labels are just symbols associated with an
	# address, so moving the value of a symbol into a register is the same as
	# moving the address of tha data into the register.
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

# Design in C-like code:
#	void Printchar (void)
#	{
#		int		tmp1, tmp2;
#		tmp1 = r3;
#		tmp2 = r4;
#		r3 = JTAG_UART_BASE;
#		do	{
#			r4 = *(r3+OFFSET_STATUS);  OR  r4 = r3[OFFSET_STATUS];
#			r4 = r4 & WSPACE_MASK;
#		} while (r4 == 0);
#		r3[OFFSET_DATA] = r2;
#		r3 = tmp1;
#		r4 = tmp2;
#	}

PrintChar:
	subi	sp, sp, 8	# subtract 4 from sp, making room for a word.
	stw		r3, 4(sp)	# save contents of r3
	stw		r4, 0(sp)	# and r4.
	movia	r3, JTAG_UART_BASE	# r3 points to base of UART device registers
loop2:
	ldwio	r4, OFFSET_STATUS(r3)	# fetch contents of status register
	andhi	r4, r4, WSPACE_MASK		# keep only low-order 16 bits
	beq		r4, r0, loop2			# all 0? Try again
	# Get here when READY bit turns on
	stwio	r2, OFFSET_DATA(r3)		# Write character to data register
	# our work accomplished; restore register values
	ldw		r3, 4(sp)
	ldw		r4, 0(sp)
	addi	sp, sp, 8	# add 8 to sp, effectively discarding space on stack
	ret					# go back to calling site, all registers preserved

#==============================================================================

	.org	0x00001000	# where this code is to go in memory
MSG:.asciz	"Bonjour, Monde / Hello, World"		# Canadian version

	.end				# tells assembler this is the end

