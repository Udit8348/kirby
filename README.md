# Kirby

## Overview
Develop a *peripheral device* to inteface with a simple computer (*SCOMP*) implemented in vhdl and executed on an FPGA. The project is framed as a pitch to "investors" who are looking for a simple device to address the problem statement given below. As an additional bonus additional features are favorable. Judging is done based on a practical product pitch and a technical demo of the device's functionality in the form of a playable game. 

**Problem Statement**: Simplify addressing individual leds arranged in an array. The challeging aspect of this task is the zig-zagged orientation of the led strips as shown below. Therefore, the proposed perhiperal needs to make using the led-array more intuitive. To prove the quality of the peripheral an interactive game needs to be developed that utilizes the peripheral to drive the led-array. The game needs to be written in assembly based on the SCOMP ISA.

**Contributors**
- Yuhan Li
- Benjamin Mitchell Iglesia
- Chulhyung Park

**Note**:
*Aspects of this repo have been redacted to maintain the integrity of the primary class assignment. This repo serves to showcase our group's contributions so only essential files have been kept.*

## Directory Structure

`Documentation`: Pitch deck and final report

`Resources`: images taken during hardware testing

`SCOMP/vhd`: VHDL source code for SCOMP and associated perihperals, including ours: [COordinate CONVert](SCOMP/vhd/COCONV.vhd) (*stylized: COCONV*)

`SCOMP/asm`: SCOMP ISA assembly files for testing & developing our game and assembler wrapper bash scripts

## Coordinate Convert (COCONV)

This is our solution to the problem statement above. It implements the core algorithm in VHDL as described in our [pitch deck](Documentation/Project-Demo-Supporting-Slides.pdf). We also implemented additional functionality that checks for array out of bounds errors and sets a non-zero errno if so. The next section describes the RTL API for COCONV that we utilized in our assembly game.

## Register Transfer Level Documentation

SCOMP uses two basic I/O instructions: `IN` and `OUT`. By convention these instructions are in the context of SCOMP. For example, `IN` indicates data coming *in* from a peripheral to SCOMP.

Our peripheral adds the following registers at the following addresses

|   address  |   alias      |   description             |   IN                            |   OUT                               |
|------------|--------------|---------------------------|---------------------------------|-------------------------------------|
|   &H0A0    |   COL_EN     |   column register enable  |   set col register              |   get col reg or associated errno using 8 bit mask  |
|   &H0A1    |   ROW_EN     |   row register enable     |   set row register              |   get row reg or associated errno using 8 bit mask  |
|   &H0A2    |   NEO_IDX_R  |   neopixel index read     |   get linearized display index  |   —                                 |
|   &H0A3    |   MAX_COL_EN     |   max col enable     |   set max number of cols              |   get max number of cols  |
|   &H0A4    |   MAX_ROW_EN     |   max row enable     |   set max number of rows              |   get max number of rows |


The general flow for using this API is as follows:

1. Game initializes by sending `OUT` the max col and row dimensions to our peripheral.
2. Game determines a pair of coordinates for a pixel to illuminate or reset. The game is programmed using an intuitive coordinate system.
3. The requested coordinates' corresponding col is sent `OUT` to our peripheral
4. The requested coordinates' corresponding row is sent `OUT` to our peripheral
5. The peripheral completes the mapping within one clock cycle, so the next instruction can read `IN` the col and row errnos for any out of bounds errors.
6. If the errnos are zero, the mapping was successful and vaild and the physical index of the neopixel array can be read `IN`. Addressess for rows and columns fit within 8 bits each, and the IO bus is 16 bits. Therefore, the value received here needs to be masked for the corresponding row and col indices.
7. Addressess for rows and columns fit within 8 bits each, and the IO bus is 16 bits. Therefore, the value received in step 6 needs to be masked for the corresponding row and col indices. Finally, the game has the correct physical index for the requested led and can toggle it as needed.

In order for SCOMP to communicate with these registers, we had to modify the `IO_Decoder.vhd` by adding more chip select signals that match the corresponding register addresses.

## Assembly Demo Game (Kirby)

We developed a simple game to demonstrate the key features of our *COCONV* peripheral. The original idea for the game was to start as a 1x1 sized pixel character then use switches on the FPGA to move the player towards food. Each food item "eaten" would cause the player's size to grow. In some sense how Kirby can eat its opponents and take on its ability. Growing the size of the player took more effort than time permitted, so the game was simplified to just 2D movement and collecting food, one by one. Recalling that the game's purpose was to demo the peripheral, this minimum viable product still allows us to demonstrate intuitive led indexing on the neopixel display array and checking for out-of-bounds coordinates if the player tries to move off of the screen. In which case, a set of error leds are set on the FPGA based on the errno value.

Kirby [source code](SCOMP/asm/kirby.asm)
