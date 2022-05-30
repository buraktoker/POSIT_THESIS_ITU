`timescale 1ns / 1ps
module posit_mult(in1, in2, clock,start, out, done);
function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction
parameter N = 32;
parameter Bs = log2(N); 
parameter es = 3;
input [N-1:0] in1, in2;
input clock;
input start; 
output [N-1:0] out;
wire inf, zero;
output done;
wire [N-1:0] out_int;
reg [N-1:0] in1_reg, in2_reg;
reg start1_reg;
reg start2_reg;
reg start3_reg;
always @(posedge clock) begin
    if(start) begin
        in1_reg<=in1;
        in2_reg<=in2;
    end
    //out<=out_int;
    start1_reg<=start;
    start2_reg<=start1_reg;
    start3_reg<=start2_reg;
end
wire start0= start2_reg;
wire s1 = in1_reg[N-1];
reg s1_reg;
wire s2 = in2_reg[N-1];
reg s2_reg;
wire zero_tmp1 = |in1_reg[N-2:0];
reg zero_tmp1_reg;
wire zero_tmp2 = |in2_reg[N-2:0];
reg zero_tmp2_reg;
always @(posedge clock) begin
    s1_reg<=s1;
    s2_reg<=s2;
    zero_tmp1_reg<=zero_tmp1;
    zero_tmp2_reg<=zero_tmp2;
end

wire inf1 = s1_reg & (~zero_tmp1_reg),
	inf2 = s2_reg & (~zero_tmp2_reg);
wire zero1 = ~(s1_reg | zero_tmp1_reg),
	zero2 = ~(s2_reg | zero_tmp2_reg);
assign inf = inf1 | inf2,
	zero = zero1 & zero2;
wire rc1, rc2;
wire [Bs-1:0] regime1, regime2;
wire [es-1:0] e1, e2;
reg [es-1:0] e1_reg, e2_reg;
wire [N-es-1:0] mant1, mant2;
wire [N-1:0] xin1 = s1 ? -in1_reg : in1_reg;
wire [N-1:0] xin2 = s2 ? -in2_reg : in2_reg;
data_extract_v1 #(.N(N),.es(es)) uut_de1(.in(xin1), .rc(rc1), .regime(regime1), .exp(e1), .mant(mant1));
data_extract_v1 #(.N(N),.es(es)) uut_de2(.in(xin2), .rc(rc2), .regime(regime2), .exp(e2), .mant(mant2));

wire [N-es:0] m1 = {zero_tmp1,mant1}, 
	m2 = {zero_tmp2,mant2};
always @(posedge clock) begin
    e1_reg<=e1;
    e2_reg<=e2;
end
wire mult_s = s1_reg ^ s2_reg;
wire [2*(N-es)+1:0] mult_m = m1*m2;
reg [2*(N-es)+1:0] mult_m_reg ;
always @(posedge clock) begin
    mult_m_reg<=mult_m;
end
wire mult_m_ovf = mult_m_reg[2*(N-es)+1];
wire [2*(N-es)+1:0] mult_mN = ~mult_m_ovf ? mult_m_reg << 1'b1 : mult_m_reg;
wire [Bs+1:0] r1 = rc1 ? {2'b0,regime1} : -regime1;
reg  [Bs+1:0] r1_reg;
wire [Bs+1:0] r2 = rc2 ? {2'b0,regime2} : -regime2;
reg [Bs+1:0] r2_reg;
wire [Bs+es+1:0] mult_e;
always @(posedge clock) begin
    r1_reg<=r1;
    r2_reg<=r2;
end
add_N_Cin #(.N(Bs+es+1)) uut_add_exp ({r1_reg,e1_reg}, {r2_reg,e2_reg}, mult_m_ovf, mult_e);
wire [es-1:0] e_o;
wire [Bs:0] r_o;
reg_exp_op_mul #(.es(es), .Bs(Bs)) uut_reg_ro (mult_e[es+Bs+1:0], e_o, r_o);
wire [2*N-1+3:0]tmp_o = {{N{~mult_e[es+Bs+1]}},mult_e[es+Bs+1],e_o,mult_mN[2*(N-es):2*(N-es)-(N-es-1)-1], |mult_mN[2*(N-es)-(N-es-1)-2:0] }; 
wire [3*N-1+3:0] tmp1_o;
DSR_right_N_S #(.N(3*N+3), .S(Bs+1)) dsr2 (.a({tmp_o,{N{1'b0}}}), .b(r_o[Bs] ? {Bs{1'b1}} : r_o), .c(tmp1_o));
wire [3:0] shifting_res;
DSR_right_N_S #(.N(4), .S(Bs+1)) dsr2_deneme (.a(4'h8), .b(r_o[Bs] ? {Bs{1'b1}} : r_o), .c(shifting_res));
wire L = tmp1_o[N+4], G = tmp1_o[N+3], R = |tmp1_o[N+2:0],
     ulp = ((G & (R )) | (L & G & ~(R)));
wire [N-1:0] rnd_ulp = {{N-1{1'b0}},ulp};
wire [N:0] tmp1_o_rnd_ulp;
add_N #(.N(N)) uut_add_ulp (tmp1_o[2*N-1+3:N+3], rnd_ulp, tmp1_o_rnd_ulp);
wire [N-1:0] tmp1_o_rnd = (r_o < N-es-2) ? tmp1_o_rnd_ulp[N-1:0] : tmp1_o[2*N-1+3:N+3];
wire [N-1:0] tmp1_oN = mult_s ? -tmp1_o_rnd : tmp1_o_rnd;
assign out = inf|zero|(~mult_mN[2*(N-es)+1]) ? {inf,{N-1{1'b0}}} : {mult_s, tmp1_oN[N-1:1]},
	done = start0;
endmodule

module reg_exp_op_mul (exp_o, e_o, r_o);
parameter es=3;
parameter Bs=5;
input [es+Bs+1:0] exp_o;
output [es-1:0] e_o;
output [Bs:0] r_o;

assign e_o = exp_o[es-1:0];

wire [es+Bs:0] exp_oN_tmp;
conv_2c #(.N(es+Bs)) uut_conv_2c1 (~exp_o[es+Bs:0],exp_oN_tmp);
wire [es+Bs:0] exp_oN = exp_o[es+Bs+1] ? exp_oN_tmp[es+Bs:0] : exp_o[es+Bs:0];

assign r_o = (~exp_o[es+Bs+1] || |(exp_oN[es-1:0])) ? exp_oN[es+Bs:es] + 1 : exp_oN[es+Bs:es];
endmodule