`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/27/2021 08:14:40 PM
// Design Name: 
// Module Name: posit_to_float
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module posit_to_float(in,out);
function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction
parameter N=32;
parameter Bs=log2(N);
parameter es = 2;

input [N-1:0] in;
output [N-1:0] out;
/*wire rc;
wire [Bs-1:0] regime;
wire [es-1:0] exp;
wire [N-es-1:0] mant;
wire [N-1:0] xin = in[N-1] ? -in : in;

sub_part_generate sub_part_gen
(.in(in),
.rc(rc),
.regime(regime),
.exp(exp),
.mant(mant));*/
wire rc;
wire [Bs-1:0] regime;
wire [es-1:0] exp;
wire [N-es-1:0] mant;

wire [N-1:0] xin = in[N-1] ? -in : in;
data_extract_v1 #(.N(N),.es(es)) uut_de1(.in(xin), .rc(rc), .regime(regime), .exp(exp), .mant(mant));

generate 

  if (N==16) begin
    
    // logic filled in here
  end

  if (N==32) begin
    wire [15:0] float_exponent_added;
    wire [7:0] float_exponent;
    wire [22:0] float_mantissa;
    wire [23:0] float_mantissa_rounded;
    wire [22:0] float_mantissa_denormalized;
    wire check_inf;
    wire sign_float;
    wire g;
    wire add_one;
    wire mant_lsb;
    wire rm;
    assign check_inf = in[N-1]==1 & (|in[N-2:0]==0);
    // logic filled in here
    assign float_mantissa=mant[N-es-1:N-23-es]; //N=32
    assign mant_lsb = mant[N-23-es];
    assign g=mant[N-24-es];
    assign rm=|mant[N-25-es:0];
    assign add_one= (g & (rm) | (g & !(rm) & mant_lsb) );
    assign float_mantissa_rounded=float_mantissa + add_one;
    assign float_exponent_added=in==0?0:(check_inf?16'hff:(rc==1?exp+127+regime*(1<<es):exp+127-regime*(1<<es)));
    assign float_exponent = float_exponent_added[15] == 1'b1 ? 0 : (float_exponent_added>255 ? 8'hff : float_exponent_added[7:0]);
    assign sign_float = check_inf?0:in[N-1];
    assign float_mantissa_denormalized = float_exponent_added[15] == 1'b1 ? float_mantissa_rounded[22:0]<<1 | {22'h1} : float_mantissa_rounded[22:0];
    assign out={sign_float,float_exponent,float_mantissa_denormalized};
  end


endgenerate
endmodule
