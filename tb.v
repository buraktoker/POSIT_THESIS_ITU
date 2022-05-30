`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.01.2022 18:21:57
// Design Name: 
// Module Name: tb
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
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2021 11:36:01 AM
// Design Name: 
// Module Name: tb
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
//`define log
`define NULL 0   
`define PYTHON
module tb(

    );
parameter N=32;
reg start; 
reg clk;
wire [N-1:0] out,out2;
wire inf, zero;
wire done;
integer               data_file,data_file_2    ; // file handler
integer               scan_file,scan_file_2    ; // file handler
reg [N-1:0] log_inp1;
reg [N-1:0] log_inp2;
reg [N-1:0] log_inp2_reg,log_inp1_reg;
reg reset;
reg [N-1:0] captured_data;

posit_add #(.N(32),.es(2)) dut(log_inp1, log_inp2, clk, start, out, done);
//posit_mult #(.N(32),.es(2)) dut(log_inp1, log_inp2, clk, start, out, done);
reg op;
/*
bct_posit_div#(.N(32),.es(2)) dut 
(
.in1 (log_inp1), 
.in2 (log_inp2), 
.clock (clk),
.reset (reset),
.start (start), 
.op(op),
.out (out), 
.done (done));
wire done2;
wire [31:0] out2;
PositDivSqrt dut2(
  .clock(clk),
  .reset(reset),
  .io_validIn(start),
  .io_readyIn(),
  .io_num1(log_inp1),
  .io_validOut_sqrt(done2),
  .io_out(out2)
);
 sqrt dut3 (      // width of radicand
    .clk(clk),
    .start(start),             // start signal
    .busy(),              // calculation in progress
    .valid(),             // root and rem are valid
    .rad(28'hf600000),   // radicand
    .root(),  // root
    .rem ()   // remainder
    );*/
/*posit_to_float #(.N(32),.es(2)) dut(log_inp1,out);
FP_to_posit #(.N(32), .E(8), .es(2)) accumulator_FP_to_posit ( // @[LazyRoCC.scala 162:27]
    .in(log_inp1),
    .out(out2)
  );*/
wire sqrt_ready,sqrt_valid;
//PositDivSqrter32_2 dut(clk,reset,sqrt_ready,start,log_inp1,sqrt_valid,out);
wire io_readyIn,io_isZero,io_isNaR,io_validOut_div,io_validOut_sqrt,io_exceptions,io_out;
//posit_to_int #(.N(32),.es(2)) dut (.in(log_inp1),.out(out),.overflow(overflow));
/*
Int_to_Posit #(.N(32),.es(2)) dut(
.in(log_inp1),
.out(out)
);*/
/*PositDivSqrt dut2(
  clk,
  reset,
  start,
  io_readyIn,
  1'b1,
  log_inp1,
  log_inp2,
  io_isZero,
  io_isNaR,
  io_validOut_div,
  io_validOut_sqrt,
  io_exceptions,
  io_out
);*/
always begin #10 clk=!clk;
end
/*
Step 3: If the partial remainder is greater than zero, the
quotient/root is 1, else it is 0. The resulting
quotient/root is concatenated with the existing
quotient/root (qi/si).
Step 4: In case of division, the divisor remains constant
through the computation whereas, in square root, the
divisor is changed on each iteration. The divisor in case
of square root is dependent on the root generated si. If
the last bit of root generated is 1, the divisor is si + 2-
(i+2), else the divisor is si - 2-(i+2).
Step 5: If the partial remainder is greater than zero, the
partial remainder is shifted left once and the divisor is
subtracted from the partial remainder, else the partial
remainder is shifted left once and the divisor is added to
the partial remainder. The shifted one bit is the resultant
quotient / root for this stage, resulting remainder is the
partial remainder input to the next stage.
*/
/*
parameter M=27;
reg start_reg;
wire [M:0] m1 = 28'hf600000;
wire [M:0] divisor_next;
reg  [M:0] divisor_reg;
wire [M+1:0] partial_remainder_loop_initial = m1-28'h8000000;
wire q_0;
assign q_0 = ~partial_remainder_loop_initial[M+1];
wire [M:0] divisor_initial = q_0 ? {q_0<<2,2'b01} : {q_0 <<2, 2'b11};

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
//reg [M:0] shifted_q_res_reg;
reg [5:0] loop_counter;
wire [M+1:0] q_res_next_shifted;
assign partial_remainder_loop_shifted_next=partial_remainder_loop_reg<<1;
assign partial_remainder_loop_substract_next=partial_remainder_loop_shifted_next-divisor_reg;
assign partial_remainder_loop_addition_next=partial_remainder_loop_shifted_next+divisor_reg;
assign partial_remainder_loop_next = (partial_remainder_loop_reg[M+1]==0) ? partial_remainder_loop_substract_next: partial_remainder_loop_addition_next ;
assign shifted_q_res_next = q_res_reg<<1;
assign q_res_next = {q_res_reg[M:0],(!partial_remainder_loop_next[M+1])};
assign q_res_next_shifted = q_res_next << 2;
assign divisor_next = (!partial_remainder_loop_next[M+1]) ? {q_res_next[M-2:0], 2'b01} : { q_res_next[M-2:0], 2'b11};
reg finish_count,finish_count_reg;
always @(posedge clk) begin
    if(start_reg) begin
        //shifted_q_res_reg<=0;
        q_res_reg<={{M{1'b0}},q_0};
        partial_remainder_loop_addition_reg<=0;
        partial_remainder_loop_substract_reg<=0;
        partial_remainder_loop_shifted_reg<=0;
        partial_remainder_loop_reg<=partial_remainder_loop_initial; 
        divisor_reg <= divisor_initial;     
    end
    else begin
        if(!finish_count) begin
        //shifted_q_res_reg<=shifted_q_res_next;
        q_res_reg<=q_res_next;
        partial_remainder_loop_addition_reg<=partial_remainder_loop_addition_next;
        partial_remainder_loop_substract_reg<=partial_remainder_loop_substract_next;
        partial_remainder_loop_shifted_reg<=partial_remainder_loop_shifted_next;
        partial_remainder_loop_reg<=partial_remainder_loop_next;
        divisor_reg <= divisor_next;
    end      
    end
end

always @(posedge clk) begin
        start_reg<=start;
end
*/
//always @(posedge clk) begin
//    if (reset) begin
//        loop_counter<=0;
//        finish_count<=0;
//    end
//    else begin      
        //if(start_reg) begin
          //  loop_counter <=0;
           // finish_count <=0;
        //end
       // else if (loop_counter < (M+1)) begin //'h1d
       //     loop_counter <= loop_counter+1;    
       // end
        /*else begin
            if(!finish_count) begin
                loop_counter <= loop_counter+1;
            end
            if(loop_counter=='h1c) begin
                finish_count <=1;
            end
        end*/
   // end
//end
/*
always @ (posedge clk) begin
    if(reset) begin
       finish_count_reg<=0; 
       finish_count<=0;
    end
    else begin  
        finish_count_reg<=finish_count;   
        if(start_reg) begin
            finish_count <=0;
        end
        if(loop_counter==(M)) begin //'h1c
            finish_count <=1;
        end
    end   
end
*/
integer f;
initial begin
clk<=1;
reset<=1;
start<=0;
log_inp1<=32'h0;
log_inp2<=32'h0;
op<=0;
`ifdef log
 f = $fopen("D:/POSIT/Posit_modules_timing_v2/posit_add_database/vivado_res.dat","w");
 `endif
 /*
#500;
reset<=0;
start<=1'h0;
log_inp1<=32'h0;
log_inp2<=32'h0;*/
#500;
reset<=0;
start<=1;
`ifndef PYTHON

//log_inp1 <= 32'h68000000;
#500;
reset<=0;
start<=1;
#20;
/*
log_inp1<=32'hbef5382d;
log_inp2<=-(32'he84d4c01);*/
//log_inp1<=32'hb6dd5bad;
start<=1;
log_inp1<=32'h55aa5658;
log_inp2<=32'hff653721;
#20;
start<=0;
#2000;
start<=1;
log_inp1<=32'h67b00000;
log_inp2<=32'h67a00000;
#20;
start<=0;
#2000;
start<=1;
log_inp1<=32'h64000000;
log_inp2<=32'h42000000;
#20;
start<=0;
#2000;
start<=1;
log_inp1<=32'h7FFFFFFB;
log_inp2<=32'h7FFFFFFB;
#20;
start<=0;
#2000;
start<=1;
log_inp1<=32'h14800000;
log_inp2<=32'h001c0000;
#20;
start<=0;
#2000;
start<=1;
log_inp1<=32'h6d823556;
log_inp2<=-32'h65800000;
#20;
start<=0;
#2000;
start<=1;
log_inp1<=32'h50ed29bb;
log_inp2<=32'haf12d645;
#20;
start<=0;
#2000;
/*
start<=0;
#500;*/
//for pipeline test
log_inp1<=32'h2f000000;
log_inp2<=32'h2f000000;
start<=1;
#20;
start<=0;
#2000;
log_inp1<=32'h0;
log_inp2<=32'h0;
#5000;
log_inp1<=32'hbd01bdc1;
log_inp2<=32'h3145317d;
start<=1;
#20;
start<=0;
#5000;
start<=1;
log_inp1<=32'h18dc2c44;
log_inp2<=32'h50e6b300;
#20;
start<=0;
log_inp1<=32'hXXXXXXXX;
log_inp2<=32'hXXXXXXXX;
#5000;
start<=1;
log_inp1<=32'hb680d51e;
log_inp2<=-(32'hb6839bb9); //olmasý gereken sonuç 0xf1396600
#20;
start<=0;
log_inp1<=32'hXXXXXXXX;
log_inp2<=32'hXXXXXXXX;
#5000;
start<=1;
log_inp1<=32'hb680d527;
log_inp2<=(32'h0ec6887d); //olmasý gereken sonuç 0xb6839baf
#20;
start<=0;
/*log_inp1<=32'h4fa9f398;
log_inp2<=32'h22d2d222;
start<=1'h1;
#10;
start<=1'h0;
#1000;
log_inp1<=32'h7e55adcc;
log_inp2<=32'h3bfea44c;start<=1'h1;
#10;
start<=1'h0;
#1000;
log_inp1<=32'h49c3554f;
log_inp2<=32'h6ee2b502;
start<=1'h1;
#10;
start<=1'h0;*/
#1000;


`endif
/*#100;
log_inp1<=32'h1f716460;
log_inp2<=32'h01274360;
#100;
#100;
in1<=32'h65000000;
in2<=32'h64800000;
#100;
in1<=32'h65045000;
in2<=32'h76023000;
#100;
in1<=32'h65000000;
in2<=32'h72400000;
#100;
*/
end

`ifdef PYTHON
initial begin
  data_file = $fopen("D:/POSIT/Posit_modules_timing_v2/posit_add_database/inp1.dat", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    `ifdef log
        $fclose(f);
    `endif
    $finish;
  end
end

always @(posedge clk) begin
  if(!reset) begin
    scan_file = $fscanf(data_file, "%h\n", log_inp1);
    if (!$feof(data_file)) begin
        $display("scan_file log_inp1 0x%8h" ,log_inp1);
        //use captured_data as you would any other wire or reg value;
    end
  end
end

initial begin
  data_file_2 = $fopen("D:/POSIT/Posit_modules_timing_v2/posit_add_database/inp2.dat", "r");
  if (data_file_2 == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end
end

always @(posedge clk) begin
    if(!reset) begin
        scan_file_2 = $fscanf(data_file_2, "%x\n", log_inp2);
        if (!$feof(data_file_2)) begin
            $display("scan_file log_inp2 0x%8h" ,log_inp2);
        //use captured_data as you would any other wire or reg value;
        end
    end
end
//input1: 0x5bef68c3 input2: 0x1ab87667 result: 0x5bf62139
/*
initial begin
	$monitor("t=%3d input1=0x%8h,input2=0x%8h,result=0x%8h \n",$time,log_inp1,log_inp2,out2 );
	`ifdef log
	$fmonitor(f, "input1: 0x%8h  input2: 0x%8h  result: 0x%8h",log_inp1,log_inp2,out2 );
	`endif
end
*/
always @(negedge clk) begin
  if(done) begin
    $fwrite(f, "%x\n", out);
  end
end

/*
always @(posedge clk) begin
log_inp1_reg<=log_inp1;
log_inp2_reg<=log_inp2;
if( log_inp1_reg==log_inp1 & log_inp2_reg==log_inp2 ) begin
    $finish;
end
end
*/
always @(negedge clk) begin
if( !(log_inp2==out2) ) begin
    $display("log_inp2 0x%8h out2 0x%8h " ,log_inp2,out2);
   // $finish;
end
end
`endif

endmodule
