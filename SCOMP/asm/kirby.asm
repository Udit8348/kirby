; Demo game for coconv Peripheral
; Incorporates all aspects of other asm files into one demo.

ORG 0
INIT: 
    ; Set all the pixels dim white
	LOAD   OFF
	OUT    PXL_ALL
	; Wait for the set-all to complete
	CALL   WaitSetAll

Main:

    LOADI	6
	OUT		MAX_ROW
	LOADI	32
	OUT		MAX_COL

    ;; draw a food
    LOAD   FOODROW
    OUT ROW

    LOAD   FOODCOL
    OUT COL

    IN		NEO_IDX
	OUT		PXL_A

    LOAD	GREEN
	OUT		PXL_RGB

    ;; end draw food


    IN      Switches
	STORE   currSwitch

	CALL	PrintPOS
	
	LOAD 	currSwitch
	; AND     colMask -- if we keep this then we cannot overflow
	SHIFT	-3
	STORE	currCol
    OUT     Col
	
    LOAD    currSwitch
    AND     rowMask
	STORE	currRow
    OUT     Row
	
	IN		NEO_IDX
	OUT		PXL_A
	
	LOAD	CurrentColor
	OUT		PXL_RGB

	CALL BOUNDS

    CALL CHECKCOLISION

	; de-10 led output
	CALL	DisplayLEDS
	
	LOADI	5			; Load 5 into AC to delay 5*0.1 seconds
	CALL	DelayAC		; Call DelayAC Subroutine to delay 0.5 seconds

	; looping logic when we need to erase or not
	IN 		Switches
	SUB		currSwitch
	JZERO 	Main
    JUMP    updatePrev
	
updatePrev:
	LOAD	currCol
	OUT		Col
	
	LOAD	currRow
	OUT		Row
	
	IN		NEO_IDX
	OUT		PXL_A
	
	LOAD	OFF
	OUT		PXL_RGB
	
	JUMP	Main

; PRINT POS SUBROUTINE
PrintPOS:
	LOAD 	currSwitch 		
    AND     MASK_ROW
    OUT     Hex1

    LOAD    currSwitch
    ; AND     MASK_COL
    SHIFT   -3
    OUT     Hex0

    RETURN

CHECKCOLISION:
    LOAD currRow
    SUB FOODROW
    JZERO   CHECK_COL_NOW
    JUMP FAILURE

    CHECK_COL_NOW:
    LOAD currCol
    SUB FOODCOL
    JZERO WIN
    JUMP FAILURE

    WIN:
    JUMP WINSCREEN

    FAILURE:
    RETURN

; BOUNDS CHECK SUBROUTINE
Bounds:
	IN			COL
	AND			ERRNO_MASK
	JPOS		YES_COL_ERROR
	JZERO		NO_COL_ERROR

	YES_COL_ERROR:
		; clear led at led[7]
		LOAD LEDVals
		OR	 Bit7
		STORE LEDVals

		LOAD RED
		STORE CurrentColor

		JUMP ROW_CHECK_BOUNDS

	NO_COL_ERROR:
		; clear led at led[7]
		LOAD LEDVals
		AND	 ClearBit7
		STORE LEDVals

		LOAD Kirby
		STORE CurrentColor

		

	ROW_CHECK_BOUNDS:
	IN			ROW
	AND			ERRNO_MASK
	JPOS		YES_ROW_ERROR
	JZERO		NO_ROW_ERROR

	YES_ROW_ERROR:
		; clear led at led[2]
		LOAD LEDVals
		OR	 Bit2
		STORE LEDVals

		LOAD RED
		STORE CurrentColor

		JUMP END_CHECK_BOUNDS

	NO_ROW_ERROR:
		; clear led at led[2]
		LOAD LEDVals
		AND	 ClearBit2
		STORE LEDVals

		LOAD Kirby
		STORE CurrentColor

	END_CHECK_BOUNDS:
		RETURN

DisplayLEDS:
	LOAD LEDVals
	OUT LEDs
	RETURN 

WaitSetAll:
	IN     PXL_ALL
	; Peripheral responds with 1 when busy
	JPOS   WaitSetAll
	RETURN

; DELAY SUBROUTINE
DelayAC:
	STORE  DelayTime   ; Save the desired delay
	OUT    Timer       ; Reset the timer
WaitingLoop:
	IN     Timer       ; Get the current timer value
	SUB    DelayTime
	JNEG   WaitingLoop ; Repeat until timer = delay value
	RETURN
DelayTime: DW 0

WINSCREEN:
    LOADI   0
    OUT     PXL_ALL		; Clear all pixels
    LOADI   2
    CALL    DelayAC		; Delay 0.2 seconds

	; "YOU WIN"
	; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
	; 0 0 0 0 X 0 X 0 X X X 0 X 0 X 0 0 X 0 0 0 X 0 X 0 X 0 0 X 0 0 0 0
	; 0 0 0 0 X 0 X 0 X 0 X 0 X 0 X 0 0 X 0 0 0 X 0 X 0 X X 0 X 0 0 0 0
	; 0 0 0 0 0 X 0 0 X 0 X 0 X 0 X 0 0 X 0 X 0 X 0 X 0 X 0 X X 0 0 0 0
	; 0 0 0 0 0 X 0 0 X X X 0 X X X 0 0 0 X 0 X 0 0 X 0 X 0 0 X 0 0 0 0
	; 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
	
	; "Y"
	LOADI	1
	OUT		ROW
	LOADI	4
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	2
	OUT		ROW
	LOADI	4
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	3
	OUT		ROW
	LOADI	5
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	4
	OUT		ROW
	LOADI	5
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	1
	OUT		ROW
	LOADI	6
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	2
	OUT		ROW
	LOADI	6
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	; "O"
	LOADI	1
	OUT		ROW
	LOADI	8
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	2
	OUT		ROW
	LOADI	8
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	3
	OUT		ROW
	LOADI	8
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	4
	OUT		ROW
	LOADI	8
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	1
	OUT		ROW
	LOADI	9
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	4
	OUT		ROW
	LOADI	9
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	1
	OUT		ROW
	LOADI	10
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	2
	OUT		ROW
	LOADI	10
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	3
	OUT		ROW
	LOADI	10
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	4
	OUT		ROW
	LOADI	10
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	; "U"
	LOADI	1
	OUT		ROW
	LOADI	12
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	2
	OUT		ROW
	LOADI	12
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	3
	OUT		ROW
	LOADI	12
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	4
	OUT		ROW
	LOADI	12
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	4
	OUT		ROW
	LOADI	13
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	1
	OUT		ROW
	LOADI	14
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	2
	OUT		ROW
	LOADI	14
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	3
	OUT		ROW
	LOADI	14
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB

	LOADI	4
	OUT		ROW
	LOADI	14
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	; "W"
	LOADI	1
	OUT		ROW
	LOADI	17
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	2
	OUT		ROW
	LOADI	17
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	3
	OUT		ROW
	LOADI	17
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	4
	OUT		ROW
	LOADI	18
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	3
	OUT		ROW
	LOADI	19
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	4
	OUT		ROW
	LOADI	20
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	1
	OUT		ROW
	LOADI	21
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	2
	OUT		ROW
	LOADI	21
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	3
	OUT		ROW
	LOADI	21
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	; "I"
	LOADI	1
	OUT		ROW
	LOADI	23
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	2
	OUT		ROW
	LOADI	23
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	3
	OUT		ROW
	LOADI	23
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	4
	OUT		ROW
	LOADI	23
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	; "W"
	LOADI	1
	OUT		ROW
	LOADI	25
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	2
	OUT		ROW
	LOADI	25
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	3
	OUT		ROW
	LOADI	25
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	4
	OUT		ROW
	LOADI	25
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	2
	OUT		ROW
	LOADI	26
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	3
	OUT		ROW
	LOADI	27
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	1
	OUT		ROW
	LOADI	28
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	2
	OUT		ROW
	LOADI	28
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	3
	OUT		ROW
	LOADI	28
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
	LOADI	4
	OUT		ROW
	LOADI	28
	OUT		COL
	IN		NEO_IDX
	OUT		PXL_A
	LOAD	GREEN
	OUT		PXL_RGB
	
End:
	JUMP	End

;   Constants for storing info
Bit0:      DW &B0000000001
Bit1:      DW &B0000000010
Bit2:      DW &B0000000100
Bit3:      DW &B0000001000
Bit4:      DW &B0000010000
Bit5:      DW &B0000100000
Bit6:      DW &B0001000000
Bit7:      DW &B0010000000
Bit8:      DW &B0100000000
Bit9:      DW &B1000000000

ClearBit0:      DW &B1111111110
ClearBit1:      DW &B1111111101
ClearBit2:      DW &B1111111011
ClearBit3:      DW &B1111110111
ClearBit4:      DW &B1111101111
ClearBit5:      DW &B1111011111
ClearBit6:      DW &B1110111111
ClearBit7:      DW &B1101111111
ClearBit8:      DW &B1011111111
ClearBit9:      DW &B0111111111

currSwitch:  DW 0
colMask:     DW &B0000000011111000
rowMask:     DW &B0000000000000111

currCol:	 DW 0
currRow:	 DW 0

FOODROW:    DW 3
FOODCOL:    DW 16

CurrentColor: DW &HFC18

Kirby:		DW  &HFC18
DimWhite:   DW  &B0000100001000001
RED:        DW  &B1111100000000000
GREEN:      DW  &B0000011111100000
BLUE:       DW  &B0000000000011111
OFF:		DW  &B0000000000000000
MASK_ROW:   DW  &B0000000111
MASK_COL:   DW  &B0011111000

LEDVals:	DW	&B0000000000

MAX_COL_IDX: DW 31
MAX_ROW_IDX: DW 5
ERRNO_MASK:  DW &B0000000011111111
; ERRNO_MASK:  DW &B0000000011111111

; IO address constants
Switches:  EQU &H000
LEDs:      EQU &H001
Timer:     EQU &H002
Hex0:      EQU &H004
Hex1:      EQU &H005

COL:        EQU &H0A0
ROW:        EQU &H0A1
NEO_IDX:    EQU &H0A2
MAX_COL:    EQU &H0A3
MAX_ROW:    EQU &H0A4

PXL_A:     EQU &H0B0
PXL_RGB:   EQU &H0B1
PXL_ALL:   EQU &H0B2
PXL_R:     EQU &H0B3
PXL_G:     EQU &H0B4
PXL_B:     EQU &H0B5
