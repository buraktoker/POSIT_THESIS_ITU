`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2021 01:16:20 PM
// Design Name: 
// Module Name: Int_to_Posit
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


module Int_to_Posit(
in,
out
    );
parameter N = 32;
parameter es = 2;	//ES_max = E-1
input [N-1:0] in;
output [N-1:0] out;

wire sign=in[N-1];
wire [es-1:0] exp_bits,exp_bits_rounded;
wire [N-1:0] mant_bits,mant_bits_remain,mant_bits_remain_lsb,mant_bits_lsb;
wire [N:0] mant_bits_accurate,mant_round;
wire round_up;
wire [$clog2(N)-1:0] round_threshold;
wire [$clog2(N)-1:0] regime_bits;
wire [N-1:0] useed;
wire [$clog2(1<<es):0] useed_exp;
wire [2*N+es:0] before_shift,posit_number_after_shifting;
wire [N-2:0] posit_except_sign,posit_sign_value;
//1 find leading one

//3 get fraction
wire[$clog2(N)-1:0] leading_one_reverse;
wire[$clog2(N)-1:0] leading_one;
wire [N-1:0] in_complement;
assign in_complement= sign? -in: in;
LOD_N #(.N(N)) uut (.in(in_complement), .out(leading_one_reverse));


assign leading_one=N-leading_one_reverse-1;
//2 e+k*2^es = leading one
assign exp_bits = leading_one[es-1:0];
assign useed_exp=(1<<es);
assign useed=(1<<useed_exp);
//assign regime_bits = leading_one/useed_exp;
    assign regime_bits = leading_one>>es;
assign mant_bits=in_complement<<(N-leading_one);
wire [N-1:0] one_const={N{1'b1}};
/*
wire round_last_mantissa=round_threshold<((regime_bits+2+es)-N);
wire [N-1:0] msb_mantissa = 1<<(diff_b+1+es);
wire [N-1:0] rounded_mantissa = round_last_mantissa? mant_tmp+msb_mantissa : mant_tmp ;
*/
/*genvar n;
generate
for ( n=0 ; n < N ; n=n+1 ) begin 
assign mant_bits_reverse[n] = mant_bits[N-1-n]; // Reverse video data buss bit order 
end 
endgenerate*/
//assign mant_bits_remain=mant_bits_reverse>>(N-1-1-regime_bits-es-1);
assign mant_bits_lsb=mant_bits<<(N-regime_bits-es-4);
wire mant_bits_lsb_bit= mant_bits_lsb[N-1];
/*assign mant_bits_remain=mant_bits<<(N-regime_bits-es-3);
wire mant_remaining_bits = |mant_bits_remain[N-2:0];
wire g_bit=mant_bits_remain[N-1];*/
wire r_bit = |mant_bits_lsb[N-3:0];
wire g_bit=mant_bits_lsb[N-2];
assign round_up= ((g_bit) & (r_bit)) | (g_bit & !(r_bit) & mant_bits_lsb_bit) ;
/*assign mant_bits_remain_lsb=mant_bits_remain>>(N-1-1-regime_bits-es-1);
assign mant_bits_lsb=mant_bits<<(N-1-regime_bits-es-1);
assign mant_bits_even = {mant_bits_lsb[N-1],{(N-1){!mant_bits_lsb[N-1]}}};*/
//assign mant_bits_even_shifted=mant_bits_even>>(N-3-regime_bits-es) | mant_bits_remain_lsb;
assign mant_round=mant_bits+(1<<(regime_bits+es+3)) ;
assign mant_bits_accurate = round_up ? mant_round : {1'b0,mant_bits};
//LSB bit 0 olsun diye mi kontrol edilmeli
//assign posit_number_before_shifting = {one_const,1'b0,exp_bits,mant_bits}; //N-1+1+es+N-1
assign exp_bits_rounded= mant_bits_accurate[N]? exp_bits+1'b1 : exp_bits;
assign before_shift = {one_const,1'b0,exp_bits_rounded,mant_bits_accurate[N-1:0]}; //N-1+1+es+N-1
assign posit_number_after_shifting = before_shift<<(N-regime_bits-1);
assign posit_except_sign=posit_number_after_shifting[2*N+es:N+es+2];
assign posit_sign_value = sign?-posit_except_sign:posit_except_sign;
assign out= in_complement==0 ? 32'h0 : {sign,posit_sign_value};
endmodule
