module data_extract_v1(in, rc, regime, exp, mant);
function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction

parameter N=16;
parameter Bs=log2(N);
parameter es = 2;

input [N-1:0] in;
output rc;
output [Bs-1:0] regime;
output [es-1:0] exp;
output [N-es-1:0] mant;

wire [N-1:0] xin = in;
assign rc = xin[N-2];

wire [N-1:0] xin_r = rc ? ~xin : xin;

wire [Bs-1:0] lod;
LOD_N #(.N(N)) xinst_k(.in({xin_r[N-2:0],rc^1'b0}), .out(lod));

assign regime = rc ? lod-1 : lod;

wire [N-1:0] xin_shifted_res;
wire [N-1:0] xin_shifted_input;
assign xin_shifted_input = {xin[N-3:0],2'b0};
DSR_left_N_S #(.N(N), .S(Bs)) ls (.a(xin_shifted_input),.b(lod),.c(xin_shifted_res));

assign exp= xin_shifted_res[N-1:N-es];
assign mant= xin_shifted_res[N-es-1:0];

endmodule

module sub_N (a,b,c);
parameter N=10;
input [N-1:0] a,b;
output [N:0] c;
wire [N:0] ain = {1'b0,a};
wire [N:0] bin = {1'b0,b};
sub_N_in #(.N(N)) s1 (ain,bin,c);
endmodule
module add_N (a,b,c);
parameter N=10;
input [N-1:0] a,b;
output [N:0] c;
wire [N:0] ain = {1'b0,a};
wire [N:0] bin = {1'b0,b};
add_N_in #(.N(N)) a1 (ain,bin,c);
endmodule
module add_N_with_Sign (a,b,c,sub);
parameter N=10;
input [N-1:0] a,b;
input sub;
output [N:0] c;
wire [N:0] ain = {1'b0,a};
wire [N:0] bin = {1'b0,b};
assign c= sub ? ain-bin : ain+bin;
endmodule
module sub_N_in (a,b,c);
parameter N=10;
input [N:0] a,b;
output [N:0] c;
assign c = a - b;
endmodule
module add_N_in (a,b,c);
parameter N=10;
input [N:0] a,b;
output [N:0] c;
assign c = a + b;
endmodule
module add_sub_N (op,a,b,c);
parameter N=10;
input op;
input [N-1:0] a,b;
output [N:0] c;
wire [N:0] c_add, c_sub;
add_N #(.N(N)) a11 (a,b,c_add);
sub_N #(.N(N)) s11 (a,b,c_sub);
assign c = op ? c_add : c_sub;
endmodule
module add_1 (a,mant_ovf,c);
parameter N=10;
input [N:0] a;
input mant_ovf;
output [N:0] c;
assign c = a + mant_ovf;
endmodule
module abs_regime (rc, regime, regime_N);
parameter N = 10;
input rc;
input [N-1:0] regime;
output [N:0] regime_N;
assign regime_N = rc ? {1'b0,regime} : -{1'b0,regime};
endmodule
module conv_2c (a,c);
parameter N=10;
input [N:0] a;
output [N:0] c;
assign c = a + 1'b1;
endmodule
module reg_exp_op (exp_o, e_o, r_o);
parameter es=3;
parameter Bs=5;
input [es+Bs:0] exp_o;
output [es-1:0] e_o;
output [Bs-1:0] r_o;
assign e_o = exp_o[es-1:0];
wire [es+Bs:0] exp_oN_tmp;
conv_2c #(.N(es+Bs)) uut_conv_2c1 (~exp_o[es+Bs:0],exp_oN_tmp);
wire [es+Bs:0] exp_oN = exp_o[es+Bs] ? exp_oN_tmp[es+Bs:0] : exp_o[es+Bs:0];
assign r_o = (~exp_o[es+Bs] || |(exp_oN[es-1:0])) ? exp_oN[es+Bs-1:es] + 1 : exp_oN[es+Bs-1:es];
endmodule
module DSR_left_N_S(a,b,c);
        parameter N=16;
        parameter S=4;
        input [N-1:0] a;
        input [S-1:0] b;
        output [N-1:0] c;

wire [N-1:0] tmp [S-1:0];
assign tmp[0]  = b[0] ? a << 7'd1  : a; 
genvar i;
generate
	for (i=1; i<S; i=i+1)begin:loop_blk
		assign tmp[i] = b[i] ? tmp[i-1] << 2**i : tmp[i-1];
	end
endgenerate
assign c = tmp[S-1];
endmodule
module DSR_right_N_S(a,b,c);
        parameter N=16;
        parameter S=4;
        input [N-1:0] a;
        input [S-1:0] b;
        output [N-1:0] c;

wire [N-1:0] tmp [S-1:0];
assign tmp[0]  = b[0] ? a >> 7'd1  : a; 
genvar i;
generate
	for (i=1; i<S; i=i+1)begin:loop_blk
		assign tmp[i] = b[i] ? tmp[i-1] >> 2**i : tmp[i-1];
	end
endgenerate
assign c = tmp[S-1];
endmodule
module LOD_N (in, out);

  function [31:0] log2;
    input reg [31:0] value;
    begin
      value = value-1;
      for (log2=0; value>0; log2=log2+1)
	value = value>>1;
    end
  endfunction
parameter N = 64;
parameter S = log2(N); 
input [N-1:0] in;
output [S-1:0] out;
wire vld;
LOD #(.N(N)) l1 (in, out, vld);
endmodule
module LOD (in, out, vld);
  function [31:0] log2;
    input reg [31:0] value;
    begin
      value = value-1;
      for (log2=0; value>0; log2=log2+1)
	value = value>>1;
    end
  endfunction
parameter N = 64;
parameter S = log2(N);
   input [N-1:0] in;
   output [S-1:0] out;
   output vld;

  generate
    if (N == 2)
      begin
	assign vld = |in;
	assign out = ~in[1] & in[0];
      end
    else if (N & (N-1))
      //LOD #(1<<S) LOD ({1<<S {1'b0}} | in,out,vld);
      LOD #(1<<S) LOD ({in,{((1<<S) - N) {1'b0}}},out,vld);
    else
      begin
	wire [S-2:0] out_l, out_h;
	wire out_vl, out_vh;
	LOD #(N>>1) l(in[(N>>1)-1:0],out_l,out_vl);
	LOD #(N>>1) h(in[N-1:N>>1],out_h,out_vh);
	assign vld = out_vl | out_vh;
	assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
      end
  endgenerate
endmodule
module sub_N_Bin (a,b,bin,c);
parameter N=10;
input [N:0] a,b;
input bin;
output [N:0] c;
assign c = a - b - bin;
endmodule
module add_N_Cin (a,b,cin,c);
parameter N=10;
input [N:0] a,b;
input cin;
output [N:0] c;
assign c = a + b + cin;
endmodule
module data_extract(in, rc, regime, exp, mant, Lshift);
function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction
parameter N=16;
parameter Bs=log2(N);
parameter es = 2;
input [N-1:0] in;
output rc;
output [Bs-1:0] regime, Lshift;
output [es-1:0] exp;
output [N-es-1:0] mant;
wire [N-1:0] xin = in;
assign rc = xin[N-2];
wire [Bs-1:0] k0, k1;
LOD_N #(.N(N)) xinst_k0(.in({xin[N-2:0],1'b0}), .out(k0));
LZD_N #(.N(N)) xinst_k1(.in({xin[N-3:0],2'b0}), .out(k1));
assign regime = xin[N-2] ? k1 : k0;
assign Lshift = xin[N-2] ? k1+1 : k0;
wire [N-1:0] xin_tmp;
DSR_left_N_S #(.N(N), .S(Bs)) ls (.a({xin[N-3:0],2'b0}),.b(Lshift),.c(xin_tmp));
assign exp= xin_tmp[N-1:N-es];
assign mant= xin_tmp[N-es-1:0];
endmodule
module LZD_N (in, out);
  function [31:0] log2;
    input reg [31:0] value;
    begin
      value = value-1;
      for (log2=0; value>0; log2=log2+1)
	value = value>>1;
    end
  endfunction
parameter N = 64;
parameter S = log2(N); 
input [N-1:0] in;
output [S-1:0] out;
wire vld;
LZD #(.N(N)) l1 (in, out, vld);
endmodule
module LZD (in, out, vld);

  function [31:0] log2;
    input reg [31:0] value;
    begin
      value = value-1;
      for (log2=0; value>0; log2=log2+1)
	value = value>>1;
    end
  endfunction
parameter N = 64;
parameter S = log2(N);
   input [N-1:0] in;
   output [S-1:0] out;
   output vld;
  generate
    if (N == 2)
      begin
	assign vld = ~&in;
	assign out = in[1] & ~in[0];
      end
    else if (N & (N-1))
      LZD #(1<<S) LZD ({1<<S {1'b0}} | in,out,vld);
    else
      begin
	wire [S-2:0] out_l;
	wire [S-2:0] out_h;
	wire out_vl, out_vh;
	LZD #(N>>1) l(in[(N>>1)-1:0],out_l,out_vl);
	LZD #(N>>1) h(in[N-1:N>>1],out_h,out_vh);
	assign vld = out_vl | out_vh;
	assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
      end
  endgenerate
endmodule
module sub_part_generate(in,rc,regime,exp,mant);
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
output rc;
output [Bs-1:0] regime;
output [es-1:0] exp;
output [N-es-1:0] mant;
wire sign_bit= in[N-1];
wire [N-1:0] twos_comp_in= sign_bit ? -in : in;
wire regime_bit_val= twos_comp_in[N-2];
wire [N-2:0] prio_in = regime_bit_val ? ~twos_comp_in[N-2:0] : twos_comp_in[N-2:0];
wire [Bs-1:0] prio_out;
wire not_all_zero_one;
wire [N-1:0] shifted_twos_comp_in;
wire found;
assign regime = regime_bit_val ? (N-3-prio_out) : (N-2-prio_out);
assign rc=regime_bit_val;
assign shifted_twos_comp_in=twos_comp_in<<(N-prio_out);
prio_encoder #(.LINES(N-1)) pe0(.in(prio_in), .out(prio_out),.found(found));
assign exp=shifted_twos_comp_in[N-1:N-es];
assign mant=shifted_twos_comp_in[N-es-1:0];
endmodule
module prio_encoder(in, out,found);
parameter LINES=128;
parameter WIDTH=$clog2(LINES);
input wire [(LINES-1):0] in;
output reg [(WIDTH-1):0] out;
output reg found;
integer I;
always @(in)
begin
    out=0;
    found=0;
    for(I=0;I<LINES;I=I+1) begin
        if(in[I]) begin
            out=I;
            found=1;
        end
    end
end
endmodule