	.inesprg 1 		;1x 16kb bank of PRG node
	.ineschr 1		;1x 8kb bank of CHR data
	.inesmap 0		;mapper 0 = NROM, no bank swapping
	.inesmir 1		;background mirroring (ignore for now)

	;NESASM arranges everything in 8KB code and 8KB graphics banks. 
	;To fill the 16KB PRG space 2 banks are needed. Like most things in computing, the numbering starts at 0. 
	;For each bank you have to tell the assembler where in memory it will start.

	.bank 0
	.org $C000

RESET:
	SEI				;disable IRQs
	CLD				;disable decimal mode
	LDX	#$40		;load the hex value 40 into X
	STX	$4017		;disable APU frame IRQ
	LDX	#$FF		;load the hex value FF into X
	TXS				;Set up the stack
	INX				;Now X = 0
	STX	$2000		;disable NMI
	STX	$2001		;disable rendering
	STX	$4010		;disabel DMC IRQs

vblankwait1:		;First wait for vblank to make sure PPU is ready
	BIT	$2002
	BPL	vblankwait1

clrmem:
	LDA	#$00		;Load 00 into Accumulator
	STA $0000, x
	STA $0100, x
	STA $0200, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0300, x
	INX
	BNE clrmem

vblankwait2:		;Second wait for vblank, PPU is ready after this
	BIT $2002
	BPL vblankwait2

	LDA #$40	;intensify greens %01000000
	STA $2001

Forever:
	JMP Forever		;Jump back to Forever (infinite loop)

NMI:
	RTI


;;;;;;;;;;;;;;;;;;;;;


	.bank 1
	.org $FFFA
	.dw NMI			;When an NMI happens (once per frame) the processor will jump to the label NMI

	.dw RESET		;When the processor first turns on or is reset it will jump to the label RESET

	.dw	0			;external interupt IRW is not used in this tutorial


;;;;;;;;;;;;;;;;;;;;;


	.bank 2
	.org $0000
	.incbin "mario.chr"		;includes 8kb graphics file from SMB1