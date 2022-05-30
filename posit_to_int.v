module posit_to_int(
in,
out,
overflow
    );
parameter N = 32;
parameter out_N = 32;
parameter Bs = $clog2(N); 
parameter es = 2;	//ES_max = E-1
input [N-1:0] in;
output [out_N-1:0] out;
output overflow;
wire s = in[N-1];
wire [Bs-1:0] rgm,regime1, Lshift;
wire [es-1:0] e,e1;
wire [N-1:0] xin = s ? -in : in;
wire rc,rc1;
wire [N-es-1:0] mant,mant1;
wire [Bs+es:0]two_exponent_shift,regime_value_signed,regime_value,regime_value_n,out_constant;
wire [out_N-2:0] out_value,out_value_overflow;
data_extract_v1 #(.N(N),.es(es)) uut_de12(.in(xin), .rc(rc), .regime(rgm), .exp(e), .mant(mant));
assign regime_value=(1<<es)*rgm;
assign regime_value_signed = rc ? regime_value : -regime_value;
assign two_exponent_shift = e+regime_value_signed;
assign out_constant=out_N-2;
wire [out_N-1:0]one_constant = 1;
wire [out_N+N-es-1:0] pre_mant_shift,after_mant_shift_positive,after_mant_shift_negative,before_cat,final_res_before_cat_signed;
wire [out_N-1:0] final_res,out_final;
wire R,G,LSB,round;
assign pre_mant_shift= {one_constant,mant};
assign after_mant_shift_positive = pre_mant_shift << two_exponent_shift;
assign after_mant_shift_negative = pre_mant_shift >> (-two_exponent_shift);
assign before_cat = !two_exponent_shift[Bs+es]?after_mant_shift_positive:after_mant_shift_negative;
assign final_res_before_cat_signed = s ? -before_cat : before_cat;
assign LSB=final_res_before_cat_signed[N-es];
assign G=final_res_before_cat_signed[N-es-1];
assign R=|final_res_before_cat_signed[N-es-2:0];
assign round = ((G & (R)) | (LSB & G & ~(R)));
assign final_res = final_res_before_cat_signed[out_N+N-es-2:N-es]+{{(out_N-2){1'b0}},round};
wire overflow_wire = ((two_exponent_shift > (out_N -1))& !two_exponent_shift[Bs+es]) | (final_res[out_N-1]) ; 
assign out = overflow_wire ? {s,{(out_N-1){1'b1}}}: {s,final_res[out_N-2:0]};
assign overflow= overflow_wire;
endmodule
