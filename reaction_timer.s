; Winter 2013 term
; Abhiraam Kananathaligam	(akananat)
; November 13, 2013
; Lab 3 Simple Counter from 0 to 255 
				THUMB 		; Thumb instruction set 
                AREA 		My_code, CODE, READONLY
                EXPORT 		__MAIN
				ENTRY  
__MAIN

; The following lines are similar to Lab-1 but use a defined address to make it easier.
; They just turn off all LEDs 
				LDR			R10, =LED_BASE_ADR		; R10 is a permenant pointer to the base address for the LEDs, offset of 0x20 and 0x40 for the ports

				MOV 		R3, #0xB0000000		; Turn off three LEDs on port 1  
				STR 		R3, [r10, #0x20]
				MOV 		R3, #0x0000007C
				STR 		R3, [R10, #0x40] 	; Turn off five LEDs on port 2 

; This line is very important in your main program
; Initializes R11 to a 16-bit non-zero value and NOTHING else can write to R11 !!

loop 		
				MOV 		R4, #0x0		;initial value is 0
				MOV 		R7, #0xFF		;intial value to run the loop 255 times
COUNTER_LOOP	
				ADD 		R4,#0x1			;increment counter from 0 to 255
				BL 			DISPLAY_NUM		
				MOV 		R0, #0x000003E8
				BL 			DELAY
				SUBS		R7, #0x1
				BNE			COUNTER_LOOP
				B loop

;
; Display the number in R3 onto the 8 LEDs
DISPLAY_NUM		STMFD		R13!,{R1, R2, R14}
				MOV        R3,R4
				MOV			R0,#0x0
				MOV			R1,#0x0
				MOV			R2,#0x0
				MOV			R5,#0x0

				;BFI 		R5, R3, #0, #8 			; Replace bit 0 to bit 7 (8 bits) of R5 with
													; bit 0 to bit 7 from R4

				BFI 		R2, R3, #0, #5 			;P2 ORDER: 2,3,4,5,6. Take the first 5 bits and store it in R2
				
				LSR 		R3, R3, #5				;shifting the 5 bits that are put into R2
				BFI 		R1, R3, #0, #3 			;P1 ORDER: 28,29,31. Take the MSB 3 bits and store it in R1
				
				
				RBIT 		R1, R1 					; Reverse the order of bits in R1 (P1 ORDER: 31,29,28)
				RBIT 		R2, R2 					; Reverse the order of the bits in R2 (P2 ORDER: 6,5,4,3,2,1)
				
				LSR 		R1, R1, #1 				; Shift R1 bits to the right by 1 bit (31st bit is now at 30th bit location)
				LSR 		R2, R2, #25  			; Shift R2 bits to the right by 26 bits 
				
				ADD 		R1,#0x40000000			; ADDS 1 to the 30th bit to brings the ("31st" bit to the 31st location)
											
				EOR 		R1,#0xFFFFFFFF			;0 becomes 1 and 1 becomes 0:	Register for Port 1 is complete
				EOR 		R2,#0xFFFFFFFF			;0 becomes 1 and 1 becomes 0:	Register for Port 2 complete
				
				STR 		R1, [r10, #0x20]
				STR 		R2, [R10, #0x40]
				
								  
				;MOV 		R0,#0x00004E20 ;change the delay to random number 
				;BL DELAY
				;LSR 		R3, R3, #8    			;shifting the counter by 8 bits after the bits are taken
				;TEQ 		R3,#0x0					;CHECK IF THERE IS A POINT IN DISPLAYING THE REST OF THE BITS
				;BNE loopDisplay
				;AFTER SHOWING 32 BITS
				
				;MOV 	 	R1,#0x32 		;run the loop (fiveSecondWait) below 50 times     
				
exitDisplay		LDMFD		R13!,{R1, R2, R15}

;
;		Delay 0.1ms (100us) * R0 times
; 		aim for better than 10% accuracy
DELAY			STMFD		R13!,{R2, R14}
OUTERDELAY
				TEQ R0,#0x0
				BEQ exitDelay
				
				MOV  R2,#0x007D ; R2 is counter for the 100us delay
				MOVT R2,#0x0000
MULTIPLEDELAY
				SUBS R2,#1
				BNE MULTIPLEDELAY
				
				SUBS R0,#1
				BNE OUTERDELAY
				
exitDelay		LDMFD		R13!,{R2, R15}
			

LED_BASE_ADR	EQU 	0x2009c000 		; Base address of the memory that controls the LEDs 
PINSEL3			EQU 	0x4002c00c 		; Address of Pin Select Register 3 for P1[31:16]
PINSEL4			EQU 	0x4002c010 		; Address of Pin Select Register 4 for P2[15:0]
;	Usefull GPIO Registers
;	FIODIR  - register to set individual pins as input or output
;	FIOPIN  - register to read and write pins
;	FIOSET  - register to set I/O pins to 1 by writing a 1
;	FIOCLR  - register to clr I/O pins to 0 by writing a 1

				ALIGN 

				END 
	
