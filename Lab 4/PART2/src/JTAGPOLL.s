# JTAGPOLL.S [170114]

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
.ifndef	JTAGPOLL_S
.equ	JTAGPOLL_S, 1

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
.endif
