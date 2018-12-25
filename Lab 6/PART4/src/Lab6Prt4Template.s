
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
# CONSTANT DEFINITIONS

# Improve readability
	.equ	BIT0, 0x01		# mask for bit 0
	.equ	BIT1, 0x02		# mask for bit 1
	.equ	BIT2, 0x04		# mask for bit 2
	.equ	BIT3, 0x08		# mask for bit 3

# Last word in RAM - initial stack pointer value
	.equ	LAST_RAM_WORD, 0x007FFFFC

# Addresses, offsets and bit masks for I/O devices
    .equ 	TIMER_BASE_ADDR, 0x10002000
	.equ	LED_ADDR,0x10000010		# address of 10 bit LED output port
	.equ	SWITCH_ADDR, 0x10000040	# address of 10 slider switches input port
	.equ	BTNBASE, 0x10000050		# base address for button parallel port
	.equ	BTNDATAOFF, 0x00		# Data register offset
	.equ	BTNMASKOFF, 0x08		# Mask register offset from base
	.equ	BTNEDGEOFF, 0x0C		# Edge register offset
	.equ	BUTTON0, 0x01			# Button 0 is bit 1
	.equ	BUTTON1, 0x02			# Button 1 is bit 2
	.equ	BUTTON2, 0x04			# Button 2 is bit 3

	.equ 	TIMER_INTERVAL, 50000000


################################################################################
# EXCEPTIONS SECTION - Code resident at address 0x20. Exceptions cause transfer
# to this location.  Code here has to determine cause and handle appropriately.
	.org	0x00000020
	.global EXCEPTION_HANDLER
EXCEPTION_HANDLER:
	subi	sp, sp, 16		# room to save 4 registers
	stw		et, 0(sp)		# et is "exception temporary"
	subi	ea, ea, 4		# decrement ea by one instruction
	stw		ea, 4(sp)		# if nested interrupts
	stw		ra, 8(sp)		# if int handler does call
	stw		r22, 12(sp)		# scratch register 
	rdctl	et, ctl4		# wait - have I not already done this?
	bne		et, r0, CHECK_LEVEL_0	# start checking external interrupt sources
NOT_EI:
	# Not external interrupt - must be instruction exception or trap.
	# This simple version does not handle these situations.
	br		END_ISR

CHECK_LEVEL_0:				# IRQ0 is timer interrupt
	andi	r22, et, BIT0	# Check if bit0 set
	beq r22, r0, CHECK_LEVEL_1		# No - check next level
	call	INTERVAL_TIMER_ISR		# Call timer interrupt routine
	br		END_ISR			# and we're done

CHECK_LEVEL_1:				# IRQ1 is pushbutton port
	andi	r22, et, BIT1	# See if bit 1 set
	beq		r22, r0, END_ISR	# No - we don't handle any other sources
	call	PUSHBUTTON_ISR	# Call pushbutton interrupt routine

	# End of interrupt handler
END_ISR:
	ldw		et, 0(sp)		# restore et
	ldw		ea, 4(sp)		# restore (interrupt) return address
	ldw		ra, 8(sp)		# restore (call) return address
	ldw		r22, 12(sp)		# restore scratch register
	addi	sp, sp, 16		# adjust stack pointer
	eret					# and return from interrupt


EXTINT_ENABLE:
	# Enable external interrupts.
	subi	sp, sp, 4		# room for a saved register
	stw		r10, 0(sp)		# save scratch register
	movi	r10, BIT0		# enable IRQ0 - timer interrupt
	ori		r10, r10, BIT1	# enable IRQ1 - pushbutton interrupts
	wrctl	ienable, r10	# write mask to interrupt enable control register
	movi	r10, BIT0		# IE bit is bit 0 in status register
	wrctl	status, r10		# enable external interrupts
	ldw		r10, 0(sp)		# restore register
	addi	sp, sp, 4		# discard stack space
	ret

################################################################################
# PUSHBUTTON CODE - Interrupt handler and initialization for pushbutton press
# This version only deals with press of button 2.
# Buttons are attached to button parallel port.  Need to set mask bits to 1 to 
# enable. On interrupt, read edge register to see which one; write to edge
# register to acknowledge interrupt and allow next request

	.global PUSHBUTTON_ENABLE
PUSHBUTTON_ENABLE:
	subi	sp, sp, 8				# room for 2 register
	stw		r10, 0(sp)				# use r10 as scratch
	stw		r9,	4(sp)				# use r9 as pointer
	movia	r9, BTNBASE				# r9 points to base register for buttons
	mov		r10, r0					# zero scratch register
	ori		r10, r10, BUTTON2		# set button 2 bit
	stwio	r10, BTNMASKOFF(r9)		# store mask register value
	ldw		r9, 4(sp)				# restore register
	ldw		r10, 0(sp)				# restore register
	addi	sp, sp, 8		# discard stack space
	ret								# now it is enabled


	.global PUSHBUTTON_ISR
	# PUSHBUTTON_ISR is called from interrupt handler to deal with button
	# press interrupt.
	# Note - this code has been cut back from original code that handled all
	# three pushbuttons.
PUSHBUTTON_ISR:
	subi	sp, sp, 20				# save space for 5 registers
	stw		ra, 0(sp)				# needed in case a call required
	stw		r10, 4(sp)				# review for your particular requirements
	stw		r11, 8(sp)
	stw		r12, 12(sp)
	stw		r13, 16(sp)
	movia	r10, BTNBASE			# point to button parallel port
	ldwio	r11, BTNEDGEOFF(r10)	# find out which button was pressed
	stwio	r11, BTNEDGEOFF(r10)		# clear int request (any write cycle)

CHECK_KEY2:			# check if key 2 (shouldn't be anything else ...)
	andi	r13, r11, BUTTON2
	beq		r13, r0, END_PUSHBUTTON_ISR	# not set? Dunno what happened

	###
	### INSERT CODE HERE TO DO WHAT REQUIRED WHEN BUTTON PRESSED
	###
	###	Example: just count button presses

	movia	r12, COUNT				# address of counter
	ldw		r13, 0(r12)				# get current count
	mov		r13, r0				
	stw		r13, 0(r12)				# save value in memory
	movia	r12, LED_ADDR			# address of LED port
	stwio	r13, 0(r12)				# put count on display

	### End of example code

	br		END_PUSHBUTTON_ISR

END_PUSHBUTTON_ISR:
	ldw		ra, 0(sp)				# restore saved registers
	ldw		r10, 4(sp)
	ldw		r11, 8(sp)
	ldw		r12, 12(sp)
	ldw		r13, 16(sp)
	addi	sp, sp, 20
	ret								# returns to ISR handler
	
	# Device-specific code for interval timer interrupt source
INTERVAL_TIMER_ISR:
	subi 	sp, sp, 12
    stw		r11, 0(sp)
	stw		r12, 4(sp)
	stw		r13, 8(sp)
    
    movia 	r11, TIMER_BASE_ADDR	# Interval timer base address
	sthio 	r0, 0(r11) 				# Clear the interrupt
    
	movia	r12, COUNT				# address of counter
	ldw		r13, 0(r12)				# get current count
	addi	r13, r13, 1				# one mor button press
	stw		r13, 0(r12)				# save value in memory
	movia	r12, LED_ADDR			# address of LED port
	stwio	r13, 0(r12)				# put count on display
    
    ldw		r11, 0(sp)
	ldw		r12, 4(sp)
	ldw		r13, 8(sp)
    addi 	sp, sp, 12
	ret 								# Return from the ISR

###############################################################################
# MAIN PROGRAM goes here




	.text
	.org	0x400
	.global	_start
_start:
	# Initialize stack pointer
	movia	sp, LAST_RAM_WORD		# points to last word in available RAM

	# Setup interval timer
    movia 	r13, TIMER_BASE_ADDR		# Internal timer base address
    movia 	r12, TIMER_INTERVAL				# 1/(50 MHz) x (2500000) = 50 msec
    sthio 	r12, 8(r13) 				# Store the low halfword of counter start value
    srli 	r12, r12, 16
    sthio 	r12, 12(r13) 				# High halfword of counter start value
    
    # Start interval timer, enable its interrupts
    movi 	r15, 0b0111 				# START = 1, CONT = 1, ITO = 1
    sthio 	r15, 4(r13)
	
	# Enable pushbutton to generate interrupts
	call	PUSHBUTTON_ENABLE

	# Enable external interrupts
	call	EXTINT_ENABLE

	# All work done in interrupt handler
LOOP:
	br		LOOP

	.data

COUNT:	.word	0					# count button presses
	.end
