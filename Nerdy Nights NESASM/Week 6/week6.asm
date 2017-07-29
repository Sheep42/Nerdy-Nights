	.inesprg 1   ; 1x 16KB PRG code
	.ineschr 1   ; 1x  8KB CHR data
	.inesmap 0   ; mapper 0 = NROM, no bank swapping
	.inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;

	.bank 0
	.org $C000

RESET:
	SEI 		;Disable IRQs
	CLD			;Disable decimal mode
	LDX #$40	;Load hex 40 into register X
	STX $4017	;Disable APU frame IRQ
	TXS			;Set up stack
	INX			;X = 0
	STX $2000	;Disable NMI
	STX $2001	;Disable rendering
	STX $4010	;Disable DMC IRQs

vblankwait1:	;Wait for V-Blank to make sure the PPU is ready
	BIT $2002
	BPL vblankwait1

clrmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0200, x
	INX
	BNE clrmem

vblankwait2:	;Second wait for V-Blank, PPU is ready
	BIT $2002
	BPL vblankwait2

LoadPalettes:
	LDA $2002	;Read PPU status to reset the high/low latch
	LDA #$3F	
	STA $2006	;Write the high byte of $3F00 address
	LDA #$00
	STA $2006 	;write the low byte of $3F00 address
	LDX	#$00	;X = 0

LoadPalettesLoop:
	LDA palette, x  		;loop through and load data from address (palette + value in x)
	STA $2007				;write to PPU
	INX
	CPX #$20				;Compare X to hex $20 (decimal 32) 32 colors
	BNE LoadPalettesLoop	;Loop til X = 32

LoadSprites:
	LDX #$00				;Start at 0

LoadSpritesLoop:
	LDA sprites, x  		;load data from address (sprites + x)
	STA $0200, x 			;Store into RAM address starting at 0200, + x for each pass
	INX						;Increment x
	CPX #$10				;Compare X to $10 (decimal 16)
	BNE LoadSpritesLoop		;Loop if compare was not 0
							;if X = 16 keep going

LoadBackground:
	LDA $2002				;Read PPU status to reset high/low latch
	LDA #$20				
	STA $2006				;Write the high byte of $2000
	LDA #$00				
	STA $2006				;Write the low byte of $2000
	LDX #$00				;X = 0

LoadBackgroundLoop:
	LDA background, x 		;background + X
	STA $2007				;Write to PPU
	INX 					;Increment X
	CPX #$80				;Compare X to $80 (dec 128) - copying 128 bytes
	BNE LoadBackgroundLoop  ;Loop til X = 128

LoadAttribute:
	LDA $2002				;Read PPU status to reset high/low latch
	LDA #$23
	STA $2006				;Write the high byte of $23C0
	LDA #$C0 				
	STA $2006				;Write the low byte of $23C0
	LDX #$00 				;X = 0

LoadAttributeLoop:
	LDA attribute, x 		;A = attribute + X
	STA $2007				;Write A to PPU
	INX						;Increment X
	CPX #$08				;if(x == 8) - copying 8 bytes
	BNE LoadAttributeLoop 	;Loop til x == 8

	;enable NMI, sprites from pattern table 0, bg from pattern table 1
	LDA #%10010000			
	STA $2000	

	;enable sprites, enable bg, no clipping on left side
	LDA #%00011110
	STA $2001

;Infinite Loop
Forever:
	JMP Forever


NMI:
	;Set the low byte of $0200
	LDA #$00 
	STA $2003 	

	;Set the high byte of $0200
	LDA #$02
	STA $4014

LatchController:
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016


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

;PPU clean up section
;Makes sure rendering the next frame starts properly

	; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
	LDA #%10010000
	STA $2000

	; enable sprites, enable background, no clipping on left side
	LDA #%00011110   
	STA $2001

	;tell the ppu there is no background scrolling
	LDA #$00
	STA $2005
	STA $2005

	RTI             ; return from interrupt

	.bank 1
	.org $E000
palette:
	.db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;background color palette
	.db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;sprite color palette

sprites:
		;vert 	tile 	attr 	horiz
	.db $80, 	$32, 	$00, 	$80   ;sprite 0
	.db $80, 	$33, 	$00, 	$88   ;sprite 1
	.db $88, 	$34, 	$00, 	$80   ;sprite 2
	.db $88, 	$35, 	$00, 	$88   ;sprite 3

background:
	.db $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24  ;;row 1
	.db $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24  ;;all sky

	.db $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24  ;;row 2
	.db $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24  ;;all sky

	.db $24,$24,$24,$24, $45,$45,$24,$24, $45,$45,$45,$45, $45,$45,$24,$24  ;;row 3
	.db $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24, $53,$54,$24,$24  ;;some brick tops

	.db $24,$24,$24,$24, $47,$47,$24,$24, $47,$47,$47,$47, $47,$47,$24,$24  ;;row 4
	.db $24,$24,$24,$24, $24,$24,$24,$24, $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms

attribute:
	.db %00000000, %00010000, %01010000, %00010000, %00000000, %00000000, %00000000, %00110000
	.db $24,$24,$24,$24, $47,$47,$24,$24 ,$47,$47,$47,$47, $47,$47,$24,$24 ,$24,$24,$24,$24 ,$24,$24,$24,$24, $24,$24,$24,$24, $55,$56,$24,$24  ;;brick bottoms

	;Vectors
	.org $FFFA
	.dw NMI 	;Jump to NMI label when NMI happens (once per frame)

	.dw RESET  	;Jump to RESET label when game starts or is reset

	.dw 0

;;;;;;;;;;;;;;;;
	
	.bank 2
	.org $0000
	.incbin "mario.chr"