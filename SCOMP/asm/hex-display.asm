; Simple test reading the FPGA switches and displaying on hex display.
; Adapted into the final gameplay.

ORG 0

HEX:
    IN      Switches
    STORE   SW_VAL

    AND     MASK_ROW
    OUT     Hex0

    LOAD    SW_VAL
    AND     MASK_COL
    SHIFT   -3
    OUT     Hex1

    RETURN

DimWhite:   DW  &B0000100001000001
RED:        DW  &B1111100000000000
GREEN:      DW  &B0000011111100000
BLUE:       DW  &B0000000000011111
MASK_ROW:   DW  &B0000000111
MASK_COL:   DW  &B0011111000

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

SW_VAL     EQU &H0CA