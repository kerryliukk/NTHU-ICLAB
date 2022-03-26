// synopsys translate_off
`timescale  1ns/1ps
// synopsys translate_on

`define Rtype   6'b00_0000
`define NOP 	6'b00_0000
`define ADD 	6'b10_0000
`define SUB 	6'b10_0010
`define AND 	6'b10_0100
`define OR  	6'b10_0101
`define XOR 	6'b10_1000
`define	SLT	6'b10_1010
`define ABS	6'b10_1100
`define SLL	6'b00_0011
`define SRL	6'b00_0010

`define ADDI	6'b00_1000
`define LW	6'b10_0011
`define SW      6'b10_1011
`define BEQ	6'b00_0100
`define SET	6'b00_0001




//`define Rtype   6'b10_0000
//`define NOP 	5'b0_1001
//`define ADD 	5'b0_0000
//`define SUB 	5'b0_0001
//`define AND 	5'b0_0010
//`define OR  	5'b0_0100
//`define XOR 	5'b0_0011
//`define	SRLI	5'b0_1001
//`define SLLI	5'b0_1000
//`define ROTRI	5'b0_1011
