`timescale 1ns / 1ps
module bct_posit_div(in1, in2, clock ,reset,start, op, out, done);
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
parameter M = N-es;
input [N-1:0] in1, in2;
input start;
input clock; 
input reset;
input op; //operation 1 bolme,0 karekok
reg [N-1:0] out_reg;
output   [N-1:0] out;
wire inf, zero;
output done;
reg start_reg;
reg [N-1:0] in1_reg, in2_reg;
reg op_reg;
always @(posedge clock)
begin
    out_reg<=out;
    if(reset) begin
        start_reg<=0;
        op_reg <= 0;
    end else begin
        start_reg<=start;
        if(start) begin
            op_reg <= op;
            in1_reg<=in1;
            in2_reg<=in2;
        end
    end
end
wire start0= start;
wire s1 = in1_reg[N-1];
wire s2 = in2_reg[N-1];
wire zero_tmp1 = |in1_reg[N-2:0];
wire zero_tmp2 = |in2_reg[N-2:0] & (op | op_reg);
wire inf1 = in1_reg[N-1] & (~zero_tmp1),
	inf2 = in2_reg[N-1] & (~zero_tmp2) & (op | op_reg);
wire zero1 = ~(in1_reg[N-1] | zero_tmp1),
	zero2 = ~(in2_reg[N-1] | zero_tmp2) & (op | op_reg);
assign inf = inf1 | zero2,
	zero = zero1 | inf2;
wire rc1, rc2;
wire [Bs-1:0] regime1, regime2;
wire [es-1:0] e1, e2;
wire [M-1:0] mant1, mant2;
wire [N-1:0] xin1 = s1 ? -in1_reg : in1_reg;
wire [N-1:0] xin2 = s2 ? -in2_reg : in2_reg;
data_extract_v1 #(.N(N),.es(es)) uut_de1(.in(xin1), .rc(rc1), .regime(regime1), .exp(e1), .mant(mant1));
data_extract_v1 #(.N(N),.es(es)) uut_de2(.in(xin2), .rc(rc2), .regime(regime2), .exp(e2), .mant(mant2));
wire [M:0] m1 = {zero_tmp1,mant1}, 
	m2 = {zero_tmp2,mant2};
wire [M:0] quotient;
wire div_s = op_reg ? s1 ^ s2 : s1 ; //karekokte sadece s1 var
wire [Bs+1:0] r1 = rc1 ? {2'b0,regime1} : -regime1;
wire [Bs+1:0] r2 = rc2 ? {2'b0,regime2} : -regime2;
wire div_mN_in_tmp_o[N+1-es:0] ;
wire m1_small_m2= op_reg ? m1<m2 : 0;
wire [M+1:0] fixed_point_q,fixed_point_r;
wire [M+1:0] partial_remainder=m1-m2;
wire [M:0] divisor=m1_small_m2 ? m2>>1 :m2;
wire [M+1:0] partial_remainder_loop;
wire [M+1:0] m2_twos_comp= -divisor;
wire [M+1:0] partial_remainder_loop_initial = m1-divisor;
wire q_0;
assign q_0 = ~partial_remainder_loop_initial[M+1];
wire [M+1:0] partial_remainder_loop_next;
reg  [M+1:0] partial_remainder_loop_reg;
wire [M+1:0] partial_remainder_loop_shifted_next;
reg [M+1:0] partial_remainder_loop_shifted_reg;
wire [M+1:0] partial_remainder_loop_substract_next;
reg [M+1:0] partial_remainder_loop_substract_reg;
wire [M+1:0] partial_remainder_loop_addition_next;
reg [M+1:0] partial_remainder_loop_addition_reg;
wire [M+1:0] q_res_next;
reg [M+1:0] q_res_reg;
wire [M:0] shifted_q_res_next;
reg [5:0] loop_counter;
assign partial_remainder_loop_shifted_next=partial_remainder_loop_reg<<1;
assign partial_remainder_loop_substract_next=partial_remainder_loop_shifted_next+(m2_twos_comp);
assign partial_remainder_loop_addition_next=partial_remainder_loop_shifted_next+divisor;
assign partial_remainder_loop_next = (partial_remainder_loop_reg[M+1]==0) ? partial_remainder_loop_substract_next: partial_remainder_loop_addition_next ;
assign shifted_q_res_next = q_res_reg<<1;
assign q_res_next = {q_res_reg[M:0],(!partial_remainder_loop_next[M+1])};
reg finish_count,finish_count_reg;
always @(posedge clock) begin
    if(start_reg) begin
        q_res_reg<={{M{1'b0}},q_0};
        partial_remainder_loop_addition_reg<=0;
        partial_remainder_loop_substract_reg<=0;
        partial_remainder_loop_shifted_reg<=0;
        partial_remainder_loop_reg<=partial_remainder_loop_initial;      
    end
    else begin
        if(!finish_count) begin
        q_res_reg<=q_res_next;
        partial_remainder_loop_addition_reg<=partial_remainder_loop_addition_next;
        partial_remainder_loop_substract_reg<=partial_remainder_loop_substract_next;
        partial_remainder_loop_shifted_reg<=partial_remainder_loop_shifted_next;
        partial_remainder_loop_reg<=partial_remainder_loop_next;
    end      
    end
end
always @(posedge clock) begin
    if (reset) begin
        loop_counter<=0;
        finish_count<=0;
    end
    else begin      
        if(start_reg) begin
            loop_counter <=0;
            finish_count <=0;
        end
        else if (loop_counter < (N-es-1)) begin //'h1d
            loop_counter <= loop_counter+1;    
        end

    end
end
always @ (posedge clock) begin
    if(reset) begin
       finish_count_reg<=0; 
       finish_count<=0;
    end
    else begin  
        finish_count_reg<=finish_count;   
        if(start_reg) begin
            finish_count <=0;
        end
        if(loop_counter==(N-es-2)) begin //'h1c
            finish_count <=1;
        end
    end   
end
wire square_root_valid,square_root_busy;
wire [M+1:0] sqrt_root,sqrt_rem;
wire [M+1:0] square_root_in ;
assign square_root_in = div_e[0] ? {m1,1'b0} : {1'b0,m1};
sqrt #(.WIDTH(M+2),.FBITS(M+1)) square_root(
    .clk(clock),
    .start(start_reg & (op_reg==0)),             // start signal
    .reset(reset),
    .busy(square_root_busy),              // calculation in progress
    .valid(square_root_valid),             // root and rem are valid
    .rad(square_root_in),   // radicand
    .root(sqrt_root),  // root
    .rem(sqrt_rem)    // remainder
    );
wire [M+1:0] fused_res,rounded_fused_res;
wire [M+1:0] sqrt_root_extended; //31:0 bit
assign sqrt_root_extended = {sqrt_root,sqrt_rem[M-2:M-4]};
assign fused_res = op_reg ? q_res_next<<1 : sqrt_root<<1 ;
wire rounded_val = op_reg ? partial_remainder_loop_next[M+1]: 1'b0;
assign rounded_fused_res = rounded_val & (1'b1) ? (fused_res+1) : fused_res;

wire [Bs+es+1:0] div_e,s_div_e,div_e_2,abs_div_e,shifted_div_e,shifted_div_e_n,subtracted_value;
assign subtracted_value = op_reg ? {r2,e2} : 0;
sub_N_Bin #(.N(Bs+es+1)) uut_div_e ({r1,e1}, subtracted_value, m1_small_m2 && op_reg, div_e);
assign abs_div_e = div_e[es+Bs+1] ? -div_e : div_e;
assign shifted_div_e = abs_div_e >> 1;
assign shifted_div_e_n = div_e[es+Bs+1] ? -shifted_div_e : shifted_div_e;
assign s_div_e = (div_e >> 1);
assign div_e_2 = op_reg ? div_e :{div_e[es+Bs+1],s_div_e[es+Bs:0]};
wire [es-1:0] e_o;
reg [es-1:0] e_o_reg;
wire [Bs:0] r_o;
reg [Bs:0] r_o_reg;
reg_exp_op_mul #(.es(es), .Bs(Bs)) uut_reg_ro (div_e_2[es+Bs+1:0], e_o, r_o);
always @(posedge clock)
begin
    e_o_reg<=e_o;
    r_o_reg<=r_o;
end
wire tmp_o_last_bit = op_reg ? |partial_remainder_loop_next :|sqrt_rem;
wire [2*N-1+3:0]tmp_o = {{N{~div_e_2[es+Bs+1]}},div_e_2[es+Bs+1],e_o_reg,fused_res[M:0],tmp_o_last_bit};
wire [3*N-1+3:0] tmp1_o,tmp1_o_n;
DSR_right_N_S #(.N(3*N+3), .S(Bs+1)) dsr2 (.a({tmp_o,{N{1'b0}}}), .b(r_o_reg[Bs] ? {Bs{1'b1}} : r_o_reg), .c(tmp1_o));
assign tmp1_o_n = div_s ? -tmp1_o : tmp1_o;
wire L = tmp1_o_n[N+4], G = tmp1_o_n[N+3], R = tmp1_o_n[N+2], St = |tmp1_o_n[N+1:0],
     ulp = ((G & (R | St)) | (L & G & ~(R | St)));
wire [N-1:0] rnd_ulp = {{N-1{1'b0}},ulp};
wire [N:0] tmp1_o_rnd_ulp;
add_N #(.N(N)) uut_add_ulp (tmp1_o_n[2*N-1+3:N+3], rnd_ulp, tmp1_o_rnd_ulp);
wire [N-1:0] tmp1_o_rnd = (r_o_reg < M-2) ? tmp1_o_rnd_ulp[N-1:0] : tmp1_o_n[2*N-1+3:N+3];
wire [N-1:0] tmp1_oN = tmp1_o_rnd;
assign out = inf|zero ? {inf,{N-1{1'b0}}} : {div_s, tmp1_oN[N-1:1]},
done = (op_reg) ? (finish_count) & (!finish_count_reg) : square_root_valid ;

endmodule