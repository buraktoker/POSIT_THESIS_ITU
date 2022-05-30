`timescale 1ns / 1ps
module posit_add (in1, in2, clock, start, out, done);
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
parameter es = 2;
input [N-1:0] in1, in2;
input start; 
input clock;
output [N-1:0] out;
output done;
wire inf, zero;
reg [N-1:0] in1_reg,in2_reg;
wire [N-1:0] out_int;
reg start1_reg;
reg start2_reg;
reg start3_reg;
always @(posedge clock) begin
    if(start) begin
        in1_reg<=in1;
        in2_reg<=in2;
    end
    start1_reg<=start;
    start2_reg<=start1_reg;
    start3_reg<=start2_reg;
end
wire start0= start2_reg;
wire s1 = in1_reg[N-1];
reg  s1_reg;
wire s2 = in2_reg[N-1];
reg  s2_reg;
wire zero_tmp1 = |in1_reg[N-2:0];
reg zero_tmp1_reg;
wire zero_tmp2 = |in2_reg[N-2:0];
reg zero_tmp2_reg;
wire inf1 = s1_reg & (~zero_tmp1_reg),
	inf2 = s2_reg & (~zero_tmp2_reg);
wire zero1 = ~(s1_reg | zero_tmp1_reg),
	zero2 = ~(s2_reg | zero_tmp2_reg);
assign inf = inf1 | inf2,
	zero = zero1 & zero2;
wire rc1, rc2;
wire [Bs-1:0] regime1, regime2;
wire [es-1:0] e1, e2;
wire [N-es-1:0] mant1, mant2;
wire [N-1:0] xin1 = s1 ? -in1_reg : in1_reg;
wire [N-1:0] xin2 = s2 ? -in2_reg : in2_reg;
data_extract_v1 #(.N(N),.es(es)) uut_de1(.in(xin1), .rc(rc1), .regime(regime1), .exp(e1), .mant(mant1));
data_extract_v1 #(.N(N),.es(es)) uut_de2(.in(xin2), .rc(rc2), .regime(regime2), .exp(e2), .mant(mant2));
wire [N-es:0] m1 = {zero_tmp1,mant1}, 
	m2 = {zero_tmp2,mant2};
wire in1_gt_in2 = (xin1[N-2:0] >= xin2[N-2:0]) ? 1'b1 : 1'b0;
reg in1_gt_in2_reg;
wire ls = in1_gt_in2_reg ? s1_reg : s2_reg;
wire op = s1 ~^ s2;
wire lrc = in1_gt_in2 ? rc1 : rc2;
wire src = in1_gt_in2 ? rc2 : rc1;
wire [Bs-1:0] lr = in1_gt_in2 ? regime1 : regime2;
wire [Bs-1:0] sr = in1_gt_in2 ? regime2 : regime1;
wire [es-1:0] le = in1_gt_in2 ? e1 : e2;
reg [es-1:0] le_reg;
wire [es-1:0] se = in1_gt_in2 ? e2 : e1;
wire [N-es:0] lm = in1_gt_in2 ? m1 : m2;
wire [N-es:0] sm = in1_gt_in2 ? m2 : m1;
wire [es+Bs+1:0] diff;
wire [Bs:0] lr_N;
reg [Bs:0] lr_N_reg;
wire [Bs:0] sr_N;
abs_regime #(.N(Bs)) uut_abs_regime1 (lrc, lr, lr_N);
abs_regime #(.N(Bs)) uut_abs_regime2 (src, sr, sr_N);
sub_N #(.N(es+Bs+1)) uut_ediff ({lr_N,le}, {sr_N, se}, diff);
wire [Bs-1:0] exp_diff = (|diff[es+Bs:Bs]) ? {Bs{1'b1}} : diff[Bs-1:0];
wire [N-1:0] DSR_right_in;
generate
	if (es >= 2) 
	assign DSR_right_in = {sm,{es-1{1'b0}}};
	else 
	assign DSR_right_in = sm;
endgenerate
wire [Bs-1:0] DSR_e_diff  = exp_diff;
wire [2*N-1:0] DSR_right_in_extended,r_shift_mant;
assign DSR_right_in_extended = {DSR_right_in,{N{1'b0}}};
DSR_right_N_S #(.N(2*N), .S(Bs))  dsr1_ext(.a(DSR_right_in_extended), .b(DSR_e_diff), .c(r_shift_mant));
wire [N-1:0] add_m_in1;
generate
	if (es >= 2) 
	assign add_m_in1 = {lm,{es-1{1'b0}}};
	else 
	assign add_m_in1 = lm;
endgenerate
wire [2*N-1:0] add_m_in1_extended;
wire [2*N:0] add_m;
reg [2*N:0] add_m_extended_reg;
assign add_m_in1_extended = {add_m_in1,{N{1'b0}}};
add_sub_N #(.N(2*N)) uut_add_sub_N_ext (op, add_m_in1_extended, r_shift_mant, add_m);
always @(posedge clock) begin
    //add_m_reg<=add_m;
    add_m_extended_reg <= add_m;
	le_reg<=le;
	lr_N_reg<=lr_N;
	s1_reg<=s1;
	s2_reg<=s2;
	zero_tmp1_reg <= zero_tmp1;
	zero_tmp2_reg <= zero_tmp2;
	in1_gt_in2_reg <= in1_gt_in2;
end
wire mant_ovf_extended = add_m_extended_reg[2*N];
wire [2*N-1:0] LOD_in_extended = {(add_m_extended_reg[2*N] | add_m_extended_reg[2*N-1]), add_m_extended_reg[2*N-2:0]};
wire [Bs-1:0] left_shift;
wire [Bs-1:0] left_shift_extended;
LOD_N #(.N(2*N)) l2_ext(.in(LOD_in_extended), .out(left_shift_extended));
wire [N:0] DSR_left_out_t;
wire [2*N:0] l_shift_m_e;
DSR_left_N_S #(.N(2*N+1), .S(Bs)) dsl2(.a(add_m_extended_reg), .b(left_shift_extended), .c(l_shift_m_e));
wire [2*N:0] l_shift_mant = l_shift_m_e[2*N] ? l_shift_m_e[2*N:0] : {l_shift_m_e[2*N-1:0],1'b0};
wire [es+Bs+1:0] le_o_tmp, le_o;
sub_N #(.N(es+Bs+1)) sub3 ({lr_N_reg,le_reg}, {{es+1{1'b0}},left_shift_extended}, le_o_tmp);
add_1 #(.N(es+Bs+1)) uut_add_mantovf (le_o_tmp, mant_ovf_extended, le_o);
wire [es-1:0] e_o;
wire [Bs-1:0] r_o;
reg_exp_op #(.es(es), .Bs(Bs)) uut_reg_ro (le_o[es+Bs:0], e_o, r_o);
wire [3*N-1+3:0] f_array;
wire lrc_o = le_o[es+Bs];
generate
	if(es > 2)
		assign f_array = { {N{~lrc_o}}, lrc_o, e_o, l_shift_mant[2*N-2:es-2], |l_shift_mant[es-3:0]};
	else 
		assign f_array = { {N{~lrc_o}}, lrc_o, e_o, l_shift_mant[2*N-1:0], {2-es{1'b0}} };

endgenerate
wire [4*N-1+3:0] f_array_s; 
DSR_right_N_S #(.N(4*N+3), .S(Bs)) dsr2_extended (.a({f_array,{N{1'b0}}}), .b(r_o), .c(f_array_s));
wire [4*N-1+3:0] f_array_s_t = ls ? -f_array_s : f_array_s;
wire L_n = f_array_s_t[2*N+4], G_n = f_array_s_t[2*N+3], St_n = (|f_array_s_t[2*N+2:0]),
     ulp_n_extended = ((G_n & (St_n)) | (L_n & G_n & ~(St_n)));
wire [N-2:0] out_posit_slice=f_array_s_t[3*N-1+3:2*N+4];
wire [N-1:0] out_posit_slice_r;
add_N_with_Sign #(.N(N-1)) uut_add_ulp_N_2 (out_posit_slice,{{N-2{1'b0}},ulp_n_extended},out_posit_slice_r,0);

wire [N-2:0] out_slice = (r_o < N-es-2) ? out_posit_slice_r[N-2:0] :out_posit_slice ;
wire [N-1:0] out_new_extended = {ls,out_slice};
wire ins_equal_sub = (xin1==xin2) & !(op); 
assign out = inf|zero|(ins_equal_sub) ? {inf,{N-1{1'b0}}} : {out_new_extended},
	done = start0;
endmodule
