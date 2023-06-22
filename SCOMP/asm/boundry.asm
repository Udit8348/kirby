; A test program for dynamically setting the display size.
; This sets the size to 4 x 4 (default: 6 x 32)

ORG 0
INIT:
    ; 4 x 4 map (dimensions are 1 indexed)
    LOADI   4
    OUT     MAX_COL
    OUT     MAX_ROW 

    IN      Switches
	STORE   currSwitch

MAIN:
    LOAD    currSwitch
    ; display on hex
	CALL	PrintPOS
	
    ; mask switch vector for column input
	LOAD 	currSwitch
	AND     colMask
	SHIFT	-3
    ; AC currently has the user inputted col
    STORE	currCol

    ; test if (MAX_COL - currCol > 0)
    ; fail on zero, negative
    IN      MAX_COL
    ADDI    -1
    SUB     currCol
    JPOS    VALID_COL

    ; handle invalid column by using the last valid one
    LOAD    validCol

VALID_COL:

    ; update the lastest validCol & send to coconv
    STORE   validCol
    OUT     Col
	
    ; mask switch vector for row input
    LOAD    currSwitch
    AND     rowMask

    ; AC currently has the user inputted row
	STORE	currRow

    ; test if (MAX_ROW - currRow > 0)
    ; fail on zero, negative
    IN      MAX_ROW
    ADDI    -1
    SUB     currRow
    JPOS    VALID_ROW

    ; handle invalid row by using the last valid one
    LOAD    validRow

VALID_ROW:

    ; update the lastest validRow & send to coconv
    STORE   validRow
    OUT     Row
	
    ; do coconv to set target address
	IN		NEO_IDX
	OUT		PXL_A

    ; illuminate target pixel
	LOAD	BLUE
	OUT		PXL_RGB

    ; delay
    LOADI	5			; Load 5 into AC to delay 5*0.1 seconds
	CALL	DelayAC		; Call DelayAC Subroutine to delay 0.5 seconds

    ; check for movement, otherwise loop to main
    IN 		Switches
	SUB		currSwitch
	JZERO 	Main
	
    ; turn off old position if it is different
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
	
	JUMP	INIT

; draw bounds and place food within bounds

; 6 x 16 map (dimensions are 1 indexed)

; 6 x 32 map (dimensions are 1 indexed)

; Useful Subroutine

; todo (add a draw wall subroutine)

BuildMap:
    CALL    DrawBottom

    CALL    DrawRight

    ; current state: boundaries are done

    CALL    GenerateFruit

    RETURN

DrawBottom:
    IN      MAX_ROW
    OUT     Row
    CALL    DrawBottomPixel

    RETURN

DrawBottomPixel:
    LOAD    colBuilder
    OUT     Col
    ADDI    1
    STORE   colBuilder

    IN		NEO_IDX
	OUT		PXL_A

    LOAD	DimWhite
	OUT		PXL_RGB

    IN      MAX_COL
    SUB     colBuilder
    JPOS    DrawBottomPixel

    RETURN 

DrawRight:
    IN      MAX_COL
    OUT     Col
    CALL    DrawRightPixel

    RETURN

DrawRightPixel:
    LOAD    rowBuilder
    OUT     Row
    ADDI    1
    STORE   rowBuilder

    IN		NEO_IDX
	OUT		PXL_A

    LOAD	DimWhite
	OUT		PXL_RGB

    IN      MAX_ROW
    SUB     rowBuilder
    JPOS    DrawRightPixel

    RETURN 

; todo: randomly generate 1 fruit 
GenerateFruit:
    LOAD    randNum
    ADDI    1
    STORE   randNum

    IN      Switches
    AND     randConfirmMask

    JZERO   GenerateFruit

    ; state: fruit location confirmed
    LOAD    prevFruitLocation
    SUB     randNum
    JZERO   GenerateFruit

    IN      MAX_ROW
    STORE   maxRow

    IN      MAX_COL
    STORE   maxCol

    LOAD    randNum
    AND     rowMask
    STORE   fruitRow
    CALL    CalibrateRow

    OUT     Row

    LOAD    randNum
    AND     colMask
    STORE   fruitCol
    CALL    CalibrateCol

    OUT     Col


    ; print the fruit
    IN		NEO_IDX
	OUT		PXL_A

    LOAD	RED
	OUT		PXL_RGB

    ; update current fruit location to be the previous fruit location
    LOAD    randNum
    STORE   prevFruitLocation
    
    RETURN

CalibrateRow:
    LOAD    fruitRow   
    SUB     maxRow
    STORE   fruitRow
    JPOS    CalibrateRow
    JZERO   CalibrateRow

    ADD     maxRow
    RETURN

CalibrateCol:
    LOAD    fruitCol  
    SUB     maxCol
    STORE   fruitCol
    JPOS    CalibrateCol
    JZERO   CalibrateCol

    ADD     maxCol
    RETURN


; PRINT POS SUBROUTINE
PrintPOS:
	LOAD 	currSwitch 		
    AND     MASK_ROW
    OUT     Hex0

    LOAD    currSwitch
    AND     MASK_COL
    SHIFT   -3
    OUT     Hex1

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

; regular constants
ZERO:       DW 0

;   Constants for storing info
currSwitch:  DW 0
colMask:     DW &B0000000011111000
rowMask:     DW &B0000000000000111

currCol:	 DW 0
currRow:	 DW 0
validRow:     DW 0
validCol:     DW 0

colBuilder:      DW 0
rowBuilder:     DW 0

fruitCol:       DW 0
fruitRow:       DW 0

prevFruitLocation:  DW 0

maxRow:         DW 0
maxCol:         DW 0

randNum:    DW &B00000000

; use sw9 to generate fruit
randConfirmMask:    DW &B1000000000

; use sw8 to move Kirby
roundGoMask:        DW &B0100000000

; Colors
; TODO: find more interesting colors (for kirby, food, and walls)
DimWhite:   DW  &B0000100001000001
RED:        DW  &B1111100000000000
GREEN:      DW  &B0000011111100000
BLUE:       DW  &B0000000000011111
OFF:		DW  &B0000000000000000
MASK_ROW:   DW  &B0000000111
MASK_COL:   DW  &B0011111000

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