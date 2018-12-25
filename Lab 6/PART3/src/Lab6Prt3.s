# LB6PRT3.s
# Purpose:
#	Code illustrates simple interrupt handler for DE0 board.  Button press
#	interrupts are detected and count incremented.  Count is displayed using
#	LEDs.
#	This part is similar to part 1, except that in this part, pressing button 2
#	causes count (and hence LED display) to increase and pressing button 1
#	causes count to decrease.
#	
# Authors:
#	David Athersych, Rony Besprozvanny, Henry Li
#	Thank you to Rony and Henry for testing and improving this code.
# History:
#	170310	DFA		First draft part 1
#	170322	RB,HL	First debugged (and simplified) version part 1
#	170324	DFA		More comments, directions to students part 1



# directives to define symbolic labels for addresses/constants

	.equ    LAST_RAM_WORD,  0x007FFFFC	# last available memory word

	.equ	GREEN_LEDS, 0x10000010	    # LED output port address
	.equ	SWITCHES, 0x10000040		# slider switches input port address

	.equ	BUTTONS_PORT, 0x10000050	# base address pushbotton port
	.equ	BUTTONS_DATA, 0x10000050    # pushbutton parallel port
	.equ	BUTTONS_MASK, 0x10000058    # register addresses
	.equ	BUTTONS_EDGE, 0x1000005C
	.equ	OFFSET_MASK, 0x0008			# offset of mask register
	.equ	OFFSET_EDGE, 0x000C			# offset of edge register

	.equ	BUTTON1_BIT, 0x02			# mask bit button 1
	.equ	BUTTON2_BIT, 0x04			# mask bit button 2

	.equ	BUTTONS_IE, 0x02			# bit in processor ienable reg. to
										# recognize pushbutton interrupts
	.equ	NIOS2_IE, 0x1		        # bit in processor status reg. for
										# global recognition all interrupts

################################################################################
# Start of program

	.text							# start a code segment
	.global	_start					# make label visible for linker 

	# Startup code located at address 0x000000
	.org	0x0000					# reset address 
_start:
	br	init						# initialization code - main program 


	# Interrupt entry point.  When an exception occurs (trap instruction,
	# hardware interrupt or instruction exception), system status is saved
	# and program counter is loaded with 0x00000020

	.org	0x0020					# exception/interrupt routine address for
									# Nios II 
	br	ISR							# branch to actual start of service routine 
									# (rather than placing all service code here)

#################################################################################

	.org	0x0040					# reasonable position for start of program 

	# Perform all necessary initialization code, setting up stack, enabling
	# interrupts, initializing state of LEDs, etc.

init:
	# set up stack pointer 
	movia	sp, LAST_RAM_WORD		# set up stack at end of available memory

	# turn off all green LEDs 
	movia	r3, GREEN_LEDS			# address of LED parallel port
	stwio	r0, 0(r3)				# turn off all LEDs

	# Enable interrupts from buttons by writing 1 to appropriate mask bits.
	# (See DE0_Basic_Computer.pdf sections 2.3.4 and 3.1.1 for more information
	# on parallel port. IMPORTANT - Note that button 0 is used as a reset
	# button and should not be used by your program.)

	movi	r3, 0x06				# set up mask to enable interrupts	
	movia	r2, BUTTONS_DATA		# base address of buttons parallel port
	stwio	r3, OFFSET_EDGE(r2)		# writing anything to EDGE register 
									# de-asserts interrupt requests
	movi	r3, 0x06				# set up mask to enable interrupts	
    stwio	r3, OFFSET_MASK(r2)		# enable interrupts from buttons

	# Button(s) are now enabled to request interrupts.  Next step is to
	# enable processor to take interrupts. This is done by writing 1 to
	# appropriate bit in interrupt enable register.  Note use of wrctl
	# to set control registers.

	movi	r3, 0x02				# bit to enable button interrupts
									# (bit 0 is timer interrupt; bit 1 is
									# button interrupt.)
	wrctl	ienable, r3				# allow interrupts from buttons

	# modify status register in processor to recognize all interrupts 
	movi	r3, NIOS2_IE			# master interrupt control
	wrctl	status, r3				# processor will now take hardware
									# interrupts.

    # Main program goes here. Main routine will continue running
    # until interupt occurs. When interrupt occurs, ISR is called and 
    # executed. After ISR finishes execution, program returns to main routine.
main:

	####
	####  YOUR MAIN CODE GOES HERE
	####   
    
_end:
    
    br _end
	
#################################################################################

# Interrupt Service Routine - SIMPLIFIED VERSION.
# This code assumes that only exception comes from hardware interrupts.  It does
# not do a full analysis of exception source.
#
# Button Interrupts cause transfer to this location.
# Code here performs the specified functions (incrementing COUNT and displaying
# COUNT on LEDs).
# Returns to last point of execution before interrupt occured after ISR finishes.

ISR:
	subi	ea, ea, 4				# Saved pc value is one instruction too
									# far in case of hardware interrupt. Need to
									# adjust back
	subi	sp, sp, 12				# make room to save registers used in this
									# ISR
	stw		r3, 0(sp)				# obvious comment - save r3
	stw		r2, 4(sp)				# obvious comment - save r2
	stw		ra, 8(sp)				# obvious comment - save ra


	# To determine which button pressed, need to fetch EDGE register. After
	# reading register, MUST write something to register to clear current
	# interrupt request.
	movia	r2, BUTTONS_PORT		# base address for buttons parallel port
	ldwio	r3, OFFSET_EDGE(r2)		# which button pressed
	stwio	r3, OFFSET_EDGE(r2)		# clear button interrupt request
	
	# perform application-specific interrupt processing (increment COUNT
	# and display COUNT on LEDs)

	andi	r2, r3, 2
    beq		r2, r0, Not_Button_0

	ldw		r2, COUNT(r0)
    subi	r2, r2, 1
    stw		r2, COUNT(r0)
    call	UpdLEDs
	
Not_Button_0:
	andi	r2, r3, 4  
    beq		r2, r0, Not_Button_1   
    
	ldw		r2, COUNT(r0)
    addi	r2, r2, 1
    stw		r2, COUNT(r0)
    call	UpdLEDs
    
Not_Button_1:

	movi 	r2,	20000
LoopD:
	subi 	r2, r2, 1
	bne 	r2, r0, LoopD
	
	# restore registers from stack 
	ldw		ra, 8(sp)
	ldw		r2, 4(sp)
	ldw		r3, 0(sp)
	addi	sp, sp, 12
	eret							# return from interrupt - uses ea and
									# restores status

#==============================================================================
# Subroutine UpdLEDs
# Update all 10 LEDs
#
# Parameters:
#	R2	- contains 10 bit value to be displayed on LEDs
# Return value:
#	R2	- unchanged

# movi r2, 10

UpdLEDs:
	subi	sp, sp, 4		# space for saved register value
	stw		r3, 0(sp)		# save R3
	movia	r3, GREEN_LEDS	# Address of LED output port
	stwio	r2, 0(r3)		# write parameter value to LED port
	movia	r3, LEDS		# get address of saved copy
	stw		r2, 0(r3)		# keep it - used by LEDbits (future code addition)
	ldw		r3, 0(sp)		# restore register
	addi	sp, sp, 4		# discard stack space
    ret

#################################################################################
 
	.org	0x1000                          #  start of program data 

	#  define variables here 
COUNT:	.word 0
LEDS:	.word	0		# save value currently on display in LEDs
#################################################################################

	.end
