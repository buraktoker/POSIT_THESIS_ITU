`timescale 1ns / 1ps
module FP_to_posit(in, out);
function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction
parameter N = 16;
parameter E = 5;
parameter es = 2;	//ES_max = E-1
parameter M = N-E-1;
parameter BIAS = (2**(E-1))-1;
parameter Bs = log2(N);
input [N-1:0] in;
output [N-1:0] out;
wire s_in = in[N-1];
wire [E-1:0] exp_in = in[N-2:N-1-E];
wire [M-1:0] mant_in = in[M-1:0];
wire zero_in = ~|{exp_in,mant_in};
wire inf_in = (&exp_in);
wire [M:0] mant = {|exp_in, mant_in};
wire [N-1:0] LOD_in = {mant,{E{1'b0}}};
wire[Bs-1:0] Lshift;
LOD_N #(.N(N)) uut (.in(LOD_in), .out(Lshift));
wire[N-1:0] mant_tmp;
wire [Bs:0] mant_shifting_index;
wire [E-es-1:0] r_o ;
wire [Bs-1:0] diff_b;
DSR_left_N_S #(.N(N), .S(Bs)) ls (.a(LOD_in),.b(Lshift),.c(mant_tmp));
wire [N-2:0] mant_remaining,mant_last_bit;
wire [N-2:0] float_mant=mant_tmp[N-2:0];
assign mant_shifting_index=r_o+2+es<(N+1)?(N-r_o-2-es):0; //sayÄ± iÃ§erisinde mantissa var mÄ± yok mu?
assign mant_remaining=float_mant<<(mant_shifting_index);
assign mant_last_bit=float_mant<<(mant_shifting_index==0?0:mant_shifting_index-1);
wire near_one=mant_remaining[N-2] & (|mant_remaining[N-3:0]);
wire equal_and_odd = mant_remaining[N-2] & !(|mant_remaining[N-3:0]) & mant_last_bit[N-2] ;
wire [N-2:0] msb_mantissa_ind=diff_b+1+es>N-2 ?N-2 :diff_b+es+1;
wire [N-2:0] msb_mantissa = 1<<(msb_mantissa_ind);
wire [N-1:0] rounded_mantissa = (equal_and_odd | near_one) ? float_mant+msb_mantissa : float_mant ;
wire [E:0] exp = {exp_in[E-1:1], exp_in[0] | (~|exp_in)} - BIAS - Lshift;
wire [E:0] exp_N = exp[E] ? -exp : exp;
wire [es:0] e_o_mant_round;
wire check_exp_is_neg_exp_N_is_not_zero = exp[E] & |exp_N[es-1:0];
wire check_exp_is_neg_exp_N_is_zero = exp[E] & !(|exp_N[es-1:0]);
wire [es-1:0] e_o = (exp[E] & |exp_N[es-1:0]) ? exp[es-1:0] : exp_N[es-1:0];
wire [es-1:0] e_o_2 = !exp[E] ? exp[es-1:0] :(|exp_N[es-1:0] ? exp[es-1:0] : exp_N[es-1:0]);
assign r_o = (~exp[E] || (check_exp_is_neg_exp_N_is_not_zero)) ? {{Bs{1'b0}},exp_N[E-1:es]} + 1'b1 : {{Bs{1'b0}},exp_N[E-1:es]};
assign e_o_mant_round=e_o+rounded_mantissa[N-1];
wire [2*N-1:0]tmp_o_original = { {N{~exp[E]}}, exp[E], e_o, float_mant[N-2:es]};
wire [2*N-1:0]tmp_o = { {N{~exp[E]}}, exp[E], e_o_mant_round[es-1:0], rounded_mantissa[N-2:es]};
wire [2*N-1:0] tmp1_o,tmp1_original;
wire [3*N-1:0] tmp_shifted,tmp_shifted_n;
wire r_o_smaller_N_1 = (r_o < N-1) ; 
assign diff_b = ( r_o_smaller_N_1 ) ? r_o[Bs-1:0] : (N-1) ;
DSR_right_N_S #(.N(3*N), .S(Bs)) dsr2_original (.a({tmp_o_original,{N{1'b0}}}), .b(diff_b), .c(tmp_shifted));
assign tmp_shifted_n=s_in ? -tmp_shifted :tmp_shifted ;
wire lsb =  (diff_b == 'd31) ? tmp_shifted_n[N-1] : tmp_shifted_n[N+1];
wire g = (diff_b == 'd31)? tmp_shifted_n[N-2]:tmp_shifted_n[N];
wire remain = (diff_b == 'd31) ? |tmp_shifted_n[N-3:0]:|tmp_shifted_n[N-1:0];
wire round_up = (g & remain) | (lsb & g & !remain);
wire [N-2:0] tmp_shifted_n_slice = tmp_shifted_n[2*N-1:N+1];
wire [N-1:0] rounded_tmp_shifted_n = tmp_shifted_n_slice+ {{N-2{1'b0}},round_up & (r_o_smaller_N_1 | (exp[E]^s_in) )};
wire mant_tmp_msb_n = ~mant_tmp[N-1];
wire [N-1:0] out_2 = inf_in|zero_in ? {inf_in,{N-1{1'b0}}} : {s_in, rounded_tmp_shifted_n[N-2:0]};
assign out = out_2;
endmodule