	.inesprg 1   ; 1x 16KB PRG code
	.ineschr 1   ; 1x  8KB CHR data
	.inesmap 0   ; mapper 0 = NROM, no bank swapping
	.inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;

    
	.bank 0
	.org $C000 
RESET:
	SEI          ; disable IRQs
	CLD          ; disable decimal mode
	LDX #$40
	STX $4017    ; disable APU frame IRQ
	LDX #$FF
	TXS          ; Set up stack
	INX          ; now X = 0
	STX $2000    ; disable NMI
	STX $2001    ; disable rendering
	STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
	BIT $2002
	BPL vblankwait1

clrmem:
	LDA #$00
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
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
	BIT $2002
	BPL vblankwait2

LoadPalettes: 
	LDA $2002		;read PPU status to reset the high/low
	LDA #$3F
	STA $2006		;write the high byte of $3F00 address
	LDA	#$00
	STA $2006		;write the low byte of $3F00 address
	LDX #$00		;start out at 0

LoadPalettesLoop:
	LDA palette, x 			;load data from address (palette + the value in x)
							;1st time palette+0, 2nd palette+1, etc...
	STA $2007				;write to PPU
	INX						;Increment X
	CPX #$20				;Compare X to hex $20 (decimal 32)
	BNE LoadPalettesLoop	;Loop til X = 32, jump to LoadSpritesLoop


LoadSprites:
	LDX #$00

LoadSpritesLoop:
	LDA sprites, x
	STA $0200, x
	INX
	CPX #$20
	BNE LoadSpritesLoop


	LDA #%10000000	;enable NMI, sprites from pattern table 1
	STA $2000		

	LDA #%00010000	;enable sprites
	STA $2001

Forever:
	JMP Forever		;loop forever

NMI:
	LDA #$00
	STA $2003		;set the low byte (00) of the RAM address
	LDA #$02
	STA $4014		;set the high byte (02) of the RAM address

;; Read inputs ;;

LatchController:
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016		;Tell both controllers to latch buttons


;; A, B, SELECT, START, UP, DOWN, LEFT, RIGHT ;;


ReadA:
	LDA $4016		;player 1 - A
	AND #%00000001	;only look at bit 0
	BEQ ReadADone	;loop while button is pressed
ReadADone:

ReadB:
	LDA $4016		;player 1 - B
	AND #%00000001	;only look at bit 0
	BEQ ReadBDone	;loop while button is pressed
ReadBDone:

ReadSel:
	LDA $4016		;player 1 - SELECT
	AND #%00000001	;only look at bit 0
	BEQ ReadSelDone	;loop while button is pressed
ReadSelDone:

ReadStart:
	LDA $4016		;player 1 - START
	AND #%00000001	;only look at bit 0
	BEQ ReadStartDone	;loop while button is pressed
ReadStartDone:

ReadUp:
	LDA $4016		;player 1 - Up
	AND #%00000001	;only look at bit 0
	BEQ ReadUpDone	;loop while button is pressed

	LDA $0200		;load sprte 1 Y pos
	SEC 			;Make sure carry flag is set
	SBC #$02		;A -= 2
	STA $0200		;save sprite X pos

	LDA $0204		;load sprte 2 Y pos
	SEC 			;Make sure carry flag is set
	SBC #$02		;A -= 2
	STA $0204		;save sprite X pos

	LDA $0208		;load sprte 3 Y pos
	SEC 			;Make sure carry flag is set
	SBC #$02		;A -= 2
	STA $0208		;save sprite X pos

	LDA $020C		;load sprte 4 Y pos
	SEC 			;Make sure carry flag is set
	SBC #$02		;A -= 2
	STA $020C		;save sprite X pos
ReadUpDone:

ReadDn:
	LDA $4016		;player 1 - Down
	AND #%00000001	;only look at bit 0
	BEQ ReadDnDone	;loop while button is pressed

	LDA $0200		;load sprite 1 Y pos
	CLC
	ADC #$02		;A += 2
	STA $0200		;save sprite Y pos

	LDA $0204		;load sprite 2 Y pos
	CLC
	ADC #$02		;A += 2
	STA $0204		;save sprite Y pos

	LDA $0208		;load sprite 3 Y pos
	CLC
	ADC #$02		;A += 2
	STA $0208		;save sprite Y pos

	LDA $020C		;load sprite 4 Y pos
	CLC
	ADC #$02		;A += 2
	STA $020C		;save sprite Y pos
ReadDnDone:

ReadLeft:
	LDA $4016		;player 1 - Right
	AND #%00000001	;only look at bit 0
	BEQ ReadLeftDone	;loop while button is pressed

	LDA $0203		;load sprte X pos
	SEC 			;Make sure carry flag is set
	SBC #$02		;A -= 2
	STA $0203		;save sprite X pos

	LDA $0207		;load sprite x pos
	SEC
	SBC #$02		;A -= 2
	STA $0207		;save sprite x pos

	LDA $020B		;load sprite x pos
	SEC
	SBC #$02		;A -= 2
	STA $020B		;save sprite x pos

	LDA $020F		;load sprite x pos
	SEC
	SBC #$02		;A -= 2
	STA $020F		;save sprite x pos
ReadLeftDone:			;finish handling this button
	
ReadRight:
	LDA $4016		;player 1 - Left
	AND #%00000001	;only look at bit 0
	BEQ ReadRightDone	;loop while button is pressed

	LDA $0203		;load sprite 1 x pos
	CLC				;clear the carry flag
	ADC #$02		;A += 2
	STA $0203		;save sprite x pos

	LDA $0207		;load sprite 2 x pos
	CLC				;clear the carry flag
	ADC #$02		;A += 2
	STA $0207		;save sprite x pos

	LDA $020B		;load sprite 3 x pos
	CLC				;clear the carry flag
	ADC #$02		;A += 2
	STA $020B		;save sprite x pos	

	LDA $020F		;load sprite 4 x pos
	CLC				;clear the carry flag
	ADC #$02		;A += 2
	STA $020F		;save sprite x pos	
ReadRightDone:


	RTI				;Return from interupt


;;;;;;;;;;;;;;;;;;;;;


	.bank 1
	.org $E000

palette:
	.db $0F,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$0F ;background palette
	.db $0F,$1C,$15,$14,$31,$02,$38,$3C,$0F,$1C,$15,$14,$31,$02,$38,$3C ;sprites palette

sprites:
		;vert 	tile 	attr 	horiz
	.db $80, 	$32, 	$00, 	$80   ;sprite 0
	.db $80, 	$33, 	$00, 	$88   ;sprite 1
	.db $88, 	$34, 	$00, 	$80   ;sprite 2
	.db $88, 	$35, 	$00, 	$88   ;sprite 3

	.org $FFFA				 ;First of the three vectors starts here
	.dw  NMI

	.dw RESET

	.dw 0


;;;;;;;;;;;;;;;;;;;;;;;


	.bank 2
	.org $0000
	.incbin	"mario.chr"