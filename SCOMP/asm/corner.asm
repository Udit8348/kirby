; Simple test for the NeoPixel peripheral
; Used to verify that we can save values into the peripheral's registers,
; then use HEX display to see mapped value


ORG 0
    ;; test Top Left as DimWhite ;;
    LOAD    ColTL
    OUT     COL

	LOAD   RowTL
    OUT    ROW
	
    ; get the converted index back
    ; and set target address
    IN      NEO_IDX
	OUT    PXL_A

    ; choose a color and write to addr
    LOAD DimWhite
    OUT PXL_RGB

    ;; test Top Right as RED ;;
    LOAD    ColTR
    OUT     COL

	LOAD   RowTR
    OUT    ROW
	
    ; get the converted index back
    ; and set target address
    IN      NEO_IDX
	OUT    PXL_A

    ; choose a color and write to addr
    LOAD RED
    OUT PXL_RGB

    ;; test Bottom Left as GREEN ;;
    LOAD    ColBL
    OUT     COL

	LOAD   RowBL
    OUT    ROW
	
    ; get the converted index back
    ; and set target address
    IN      NEO_IDX
	OUT    PXL_A

    ; choose a color and write to addr
    LOAD GREEN
    OUT PXL_RGB

    ;; test BOTTOM RIGHT as BLUE ;;
    LOAD    ColBR
    OUT     COL

	LOAD   RowBR
    OUT    ROW
	
    ; get the converted index back
    ; and set target address
    IN      NEO_IDX
	OUT    PXL_A

    ; choose a color and write to addr
    LOAD BLUE
    OUT PXL_RGB

HERE: JUMP HERE

DimWhite:   DW  &B0000100001000001
RED:        DW  &B1111100000000000
GREEN:      DW  &B0000011111100000
BLUE:       DW  &B0000000000011111

; constants for testing
ColTL: DW 0
RowTL: DW 0

ColTR: DW 31
RowTR: DW 0

ColBL: DW 0
RowBL: DW 5

ColBR: DW 31
RowBR: DW 5

; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005

COL:        EQU &H0A0
ROW:        EQU &H0A1
NEO_IDX:    EQU &H0A2

PXL_A:     EQU &H0B0
PXL_RGB:   EQU &H0B1
PXL_ALL:   EQU &H0B2
PXL_R:     EQU &H0B3
PXL_G:     EQU &H0B4
PXL_B:     EQU &H0B5
