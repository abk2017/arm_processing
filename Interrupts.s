;*-------------------------------------------------------------------
;* Name:    	lab_4_program.s 
;* Purpose: 	Interrupts
;* Term:		Winter 2013
;*-------------------------------------------------------------------
;R5 is our counter bit placed in delay
;R6 is our flag that we went into delay

				THUMB 								; Declare THUMB instruction set 
				AREA 	My_code, CODE, READONLY 	; 
				EXPORT 		__MAIN 					; Label __MAIN is used externally 
				;EXPORT 		EINT3_IRQHandler 		; The ISR will be known to the startup_LPC17xx.s program 

				ENTRY 

__MAIN

; The following lines are similar to previous labs.
; They just turn off all LEDs 


				LDR			R4, =ISER0
				MOV			R8, #0x200000
				STR			R8, [R4]					;sets the 21st bit of ISER0 to enable EINT3
				
				LDR			R4, =IO2IntEnf
				MOV			R8, #0x400
				STR			R8, [R4]					;sets the 10th bit of IO2IntEnf to enable the falling edge interrupt of the 
														;push button
				
; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!
				MOV			R11, #0xABCD		; Init the random number generator with a non-zero number	

				
LOOP 			BL 			RNG 
														
				MOV   		R6,#0x1						;setting the flag
				
					
				MOV			R5,#0x0				;RESETS THE 32-COUNTER
				MOV			R4,#0x0				;resets R4 to zero
				BFI 		R4, R11, #0, #4		; Replace bit 0 to bit 4 (5 bits) of R4 with bits from the random number (R11)
												;lowest possible number is 1 (0.5 seconds)
				ADD			R4,#0x3				;runs the loop 3 times (1.5 seconds)
												;therefore 2 seconds guarenteed
				
OnOffLoop		MOV 		R0,#0xFA			; Runs the delay for 0.25 second delay
				BL			DELAY
				MOV 		R3, #0x4FFFFFFF		; Turns ON three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0xFB
				STR 		R3, [R10, #0x40] 	; Turn OFF the left 3 LEDs on port 2
				MOV 		R0,#0xFA			; Runs the delay for 0.25 second delay
				BL			DELAY	
				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x4
				STR 		R3, [R10, #0x40] 	; Turn ON the left 4 LEDs on port 2
				SUBS		R4,#0x1				
				BNE 		OnOffLoop
				
				
				
				LDR			R3, [r10, #0x20]					;Grabs the Port 1 values 
				MOV			R8, #0x4FFFFFFF						
				AND			R8,R3								;Sets the appropriate LED bits to 0 in PORT 1
				STR			R8, [r10, #0x20]					
				
				
				LDR			R3, [r10, #0x40]					;Grabs the Port 2 values 
				MOV			R9, #0xFFFFFF83
				AND			R9,R3								;Sets the appropriate LED bits to 0 in PORT 2
				STR			R9, [r10, #0x40]					
				
				
				
HIGH				;high frequency flashing loop 
														
				 STR 		R8, [r10, #0x20]	;SETS THE LEDS
				 STR 		R9, [R10, #0x40] 	
				
				MOV 		R7,#0x20	;creates a 32ms delay for high frequency flashing
OnOffDelay		ADD			R5,#0x1
				MOV			R0,#0x1
				BL			DELAY
				SUBS		R7,#0x1
				BNE OnOffDelay
				
				 ;after 32ms
				 EOR			R8,#0xB0000000		;ONLY Flips LED bits to turn off/on the LEDs for PORT 1
				 EOR			R9,#0x7C		;ONLY Flips LED bits to turn off/on the LEDs for PORT 2	
				 TEQ		R6,#0
				 BNE		HIGH
				;ONLY GETS OUT AFTER GOING TO INTERUPT
				;display bits
				BL DISPLAY_NUM
				
				B 			LOOP
								
;*------------------------------------------------------------------- 
; Subroutine RNG ... Generates a pseudo-Random Number in R11 
;*------------------------------------------------------------------- 
; R11 holds a random number as per the Linear feedback shift register (Fibonacci) on WikiPedia
; R11 MUST be initialized to a non-zero 16-bit value at the start of the program
; R11 can be read anywhere in the code but must only be written to by this subroutine
RNG 			STMFD		R13!,{R1-R3, R14} 	; Random Number Generator 
				AND			R1, R11, #0x8000
				AND			R2, R11, #0x2000
				LSL			R2, #2
				EOR			R3, R1, R2
				AND			R1, R11, #0x1000
				LSL			R1, #3
				EOR			R3, R3, R1
				AND			R1, R11, #0x0400
				LSL			R1, #5
				EOR			R3, R3, R1			; The new bit to go into the LSB is present
				LSR			R3, #15
				LSL			R11, #1
				ORR			R11, R11, R3
				LDMFD		R13!,{R1-R3, R15}

;*------------------------------------------------------------------- 
; Subroutine DELAY ... Causes a delay of 1ms * R0 times
;*------------------------------------------------------------------- 
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}

OUTERDELAY
				TEQ R0,#0x0
				BEQ exitDelay
				
				MOV  R2,#0x0514					; R2 is counter for the 1ms delay
				
				MOVT R2,#0x0000
MULTIPLEDELAY

				SUBS R2,#1
				BNE MULTIPLEDELAY
				
				SUBS R0,#1
				BNE OUTERDELAY
				
exitDelay		LDMFD		R13!,{R2, R15}

					

DISPLAY_NUM		STMFD		R13!,{R1, R2, R14}
loopDisplaySTART MOV        R3,R5
loopDisplay		MOV			R0,#0x0
				MOV			R1,#0x0
				MOV			R2,#0x0
				MOV			R4,#0x0

				BFI 		R4, R3, #0, #8 			; Replace bit 0 to bit 7 (8 bits) of R5 with
													; bit 0 to bit 7 from R3

				BFI 		R2, R4, #0, #5 			;P2 ORDER: 2,3,4,5,6. Take the first 5 bits and store it in R2
				
				LSR 		R4, R4, #5				;shifting the 5 bits that are put into R2
				BFI 		R1, R4, #0, #3 			;P1 ORDER: 28,29,31. Take the MSB 3 bits and store it in R1
				
				
				RBIT 		R1, R1 					; Reverse the order of bits in R1 (P1 ORDER: 31,29,28)
				RBIT 		R2, R2 					; Reverse the order of the bits in R2 (P2 ORDER: 6,5,4,3,2,1)
				
				LSR 		R1, R1, #1 				; Shift R1 bits to the right by 1 bit (31st bit is now at 30th bit location)
				LSR 		R2, R2, #25  			; Shift R2 bits to the right by 26 bits 
				
				ADD 		R1,#0x40000000			; ADDS 1 to the 30th bit to brings the ("31st" bit to the 31st location)
											
				EOR 		R1,#0xFFFFFFFF			;0 becomes 1 and 1 becomes 0:	Register for Port 1 is complete
				EOR 		R2,#0xFFFFFFFF			;0 becomes 1 and 1 becomes 0:	Register for Port 2 complete
				
				STR 		R1, [r10, #0x20]
				STR 		R2, [R10, #0x40]
				
								  
				MOV 		R0,#0x000007D0 			;2 second delay between every 8 bits
				BL DELAY
				LSR 		R3, R3, #8    			;shifting the counter by 8 bits after the bits are taken
				TEQ 		R3,#0x0					;CHECK IF THERE IS A POINT IN DISPLAYING THE REST OF THE BITS
				BNE loopDisplay
				;AFTER SHOWING 32 BITS
				;Show a 3 second delay
				
				MOV 		R0,#0x00001388			;5 second delay after showing 32 bits
				BL DELAY
				
				
												
exitDisplay		LDMFD		R13!,{R1, R2, R15}



;*-------------------------------------------------------------------
; Below is a list of useful registers with their respective memory addresses.
;*------------------------------------------------------------------- 
LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002C00C 		; Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002C010 		; Pin Select Register 4 for P2[15:0]
FIO1DIR			EQU		0x2009C020 		; Fast Input Output Direction Register for Port 1 
FIO2DIR			EQU		0x2009C040 		; Fast Input Output Direction Register for Port 2 
FIO1SET			EQU		0x2009C038 		; Fast Input Output Set Register for Port 1 
FIO2SET			EQU		0x2009C058 		; Fast Input Output Set Register for Port 2 
FIO1CLR			EQU		0x2009C03C 		; Fast Input Output Clear Register for Port 1 
FIO2CLR			EQU		0x2009C05C 		; Fast Input Output Clear Register for Port 2 
IO2IntEnf		EQU		0x400280B4		; GPIO Interrupt Enable for port 2 Falling Edge 
ISER0			EQU		0xE000E100		; Interrupt Set-Enable Register 0

IO2IntClr		EQU		0x400280AC		; GPIO Interrupt clear Port 2 set 10th bit to 1


				ALIGN 

				END 
