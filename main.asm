;Created by Jesse Arstein

;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
  	BIC.W #00000001b, PM5CTL0 ;Turns off low power mode.
	BIS.W #BIT2, P5DIR ;Set port 5.2 as output.
	BIS.W #BIT2, P5OUT ;Pull port 5.2 to high.

	BIS.W #BIT4, P3DIR ;Set port 3.4 as output.
	BIS.W #BIT4, P3OUT ;Pull port 3.4 to high.

main:
	call #startCommand
	call #loadAddress
	call #txByte
	call #sendACK
	call #counterSetup
	call #stopCommand
	call #longDelaySetup
	call #longDelaySetup
	call #longDelaySetup
	JMP main


addressQ:
	RET

startCommand:
	MOV.B #01d, R11 ;Set read/write bit
	BIS.W #BIT4, P3DIR ;Assure we are on output.
	BIC.W #BIT4, P3OUT ;Pull SDA to low
	MOV.W #07d, R6 ; Move 7 to R6 for 7 bits of data for slave.
	nop
	nop
	bic.w #BIT2, P5OUT ;Pull SCL low.
	call #setupDelay
	RET
stopCommand:
	BIS.W #BIT4,P3OUT ;Pull SDA to HIGH
	nop
	nop
	bis.w #BIT2, P5OUT ;pull scl to high
	RET
setupDelay:
	MOV.W #0FFFFh, R4;
delay:
	DEC.w R4
	JNZ delay
	RET

longDelaySetup:
	MOV.W #010d, R4
	MOV.W #0FFFFh, R5

longDelay:

longDelayInner:
	DEC.W R5
	JNZ longDelayInner
	MOV.W #0FFFFh, R5
	DEC.W R4
	JNZ longDelay;
	RET
loadAddress:
	MOV.b #060h, R7;Moves 60 hex into r7.

	RET

txByte:
	bis.w #BIT2, P5OUT ;pull scl to high
I2CNextBit:
	clrc
	RLC.b R7
	JC sendHigh
sendLow:
	BIC.W #BIT4, P3OUT ;Send 0
	JMP TXcontinue
sendHigh:
	BIS.W #BIT4,P3OUT ;Pull SDA to HIGH
	JMP TXcontinue
TXcontinue:

		call #setupDelay
		bic.w #BIT2, P5OUT;set clock to low.
		call #setupDelay
		dec.w R6
		JNZ txByte
	    clrc
		CMP #01d, R11 ;Do we need R/W?
		JNC endTX ;
needRW:
		bis.w #BIT2, P5OUT ;pull scl to high
		MOV.W #00d,R8 ;Want to send a 0 for read.
	    clrc
		CMP #0d, R8 ;is R8 = 0?
		JNC write ;no? JMP to write a 1
read:
	BIC.W #BIT4, P3OUT ;Pull SDA to low
	JMP endReadWrite
write:
	BIS.W #BIT4,P3OUT ;Pull SDA to HIGH
endReadWrite:
		MOV.B #00d, R11 ;sets need read write to off.
endTX:
		call #setupDelay
		bic.w #BIT2, P5OUT;set clock to low.
		call #setupDelay

		RET

sendACK:
	bis.w #BIT2, P5OUT ;pull scl to high
	BIS.W #BIT4,P3OUT ;Pull SDA to HIGH
	call #setupDelay
	bic.w #BIT2, P5OUT;set clock to low.
	call #setupDelay
	RET

counterSetup:
	MOV.B #10d, R9 ; Move max counter to R9.
	MOV.B #00d, R10 ;Move count to R10.
	MOV.B #08d, R6 ;we want to send 8 bits now.
loadCounter:
	MOV.B R10, R7 ; Moves count to R6.
	call #txByte ;Send one byte of data.
	inc R10
	clrc
	MOV.B #08d, R6 ;we want to send 8 bits now.
	call #sendACK
	call #setupDelay
	CMP.b R9, R10 ;Are we at 10?
	JNC loadCounter ;Jump back and loop if we are not at 10.

	RET
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
