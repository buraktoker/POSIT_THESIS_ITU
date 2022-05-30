`timescale 1ns / 1ps
`define NULL 0   
//`define log

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2021 11:06:30 AM
// Design Name: 
// Module Name: div_tb
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


module div_tb(

    );
parameter N=32;
reg [N-1:0] in1, in2;
reg start; 
reg clk;
wire [N-1:0] out,out_bct;
wire inf, zero;
wire done;
integer               data_file,data_file_2    ; // file handler
integer               scan_file,scan_file_2    ; // file handler
reg [N-1:0] log_inp1;
reg [N-1:0] log_inp2;
reg [N-1:0] log_inp2_reg,log_inp1_reg;
wire        io_diviValid;
wire        io_sqrtValid;
wire        io_invalidExc;
wire [31:0] io_Q;
reg [N-1:0] captured_data;
reg io_inValid;
reg reset;
bct_posit_div #(.N(32),.es(2),.NR_Iter(2)) bct_dut(log_inp1, log_inp2,clk, start, out_bct, inf, zero, done);
/*
PositDivSqrter32_2 chisel(
  .clock(clk),
  .reset(reset),
  .io_inValid(io_inValid),
  .io_sqrtOp(1'b0),
  .io_A(log_inp1),
  .io_B(log_inp2),
  .io_diviValid(io_diviValid),
  .io_sqrtValid(io_sqrtValid),
  .io_invalidExc(io_invalidExc),
  .io_Q(io_Q)
);*/
always begin #10 clk=!clk;
end


initial begin
    reset<=1'b1;
    #500;
    reset<=1'b0;
    #5000000;
end

integer f;
initial begin
clk<=1;
`ifdef log
 f = $fopen("/home/burakt/Documents/POSIT_ISLEM/pacogen_div_comparison/bct_module_vivado_log.txt","w");
 `endif
 `ifndef log
start<=1'h1;
log_inp1<=32'h0fc679c5;
log_inp2<=32'h381c8f04;
start<=1'h1;
#20;
start<=0;
#1000;
start<=1;
log_inp1<=32'h70000000;
log_inp2<=32'h60000000;
#20;
start<=0;
#1000;
log_inp1<=32'h71000000;
log_inp2<=32'h62000000;
start<=1'h1;
#20;
start<=0;
#20;
start<=0;

#100000;start<=1'h1;
log_inp1<=32'h63e34c83;
log_inp2<=32'h51f37f7d;
io_inValid<=1'b1;
#20;
start<=0;
io_inValid<=1'b0;
#100000;start<=1'h1;
log_inp1<=32'h61e0eb85;
log_inp2<=32'h76D2CF48;
io_inValid<=1'b1;
#20;
start<=0;
io_inValid<=1'b0;

#100000;
start<=1'h1;
log_inp1<=32'h59532382;
log_inp2<=32'h1b465135;
io_inValid<=1'b1;
#20;
start<=0;
io_inValid<=1'b0;

#100000;
start<=1'h1;
log_inp1<=32'h341bdec0;
log_inp2<=32'h1fcd5104;
io_inValid<=1'b1;
#20;
start<=0;
io_inValid<=1'b0;

#100000;
`endif
/*#100;
in1<=32'h60000000;
in2<=32'h60000000;
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

 `ifdef log
initial begin
  data_file = $fopen("/home/burakt/Documents/POSIT_ISLEM/pacogen_div_comparison/inp1.dat", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    `ifdef log
        $fclose(f);
    `endif
    $finish;
  end
end

always @(posedge clk) begin
  scan_file = $fscanf(data_file, "%d\n", log_inp1);
  if (!$feof(data_file)) begin
    $display("log_inp1 0x%8h" ,log_inp1);
    //use captured_data as you would any other wire or reg value;
  end
end

initial begin
  data_file_2 = $fopen("/home/burakt/Documents/POSIT_ISLEM/pacogen_div_comparison/inp2.dat", "r");
  if (data_file_2 == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end
end

always @(posedge clk) begin
  scan_file_2 = $fscanf(data_file_2, "%d\n", log_inp2);
  if (!$feof(data_file_2)) begin
    $display("log_inp2 0x%8h" ,log_inp2);
    //use captured_data as you would any other wire or reg value;
  end
end
//input1: 0x5bef68c3 input2: 0x1ab87667 result: 0x5bf62139
initial begin
	$monitor("t=%3d input1=0x%8h,input2=0x%8h,result=0x%8h \n",$time,log_inp1,log_inp2,out );
	`ifdef log
	$fmonitor(f, "input1: 0x%8h  input2: 0x%8h  result: 0x%8h",log_inp1,log_inp2,out_bct );
	`endif
end
`endif

always @(posedge clk) begin
log_inp1_reg<=log_inp1;
log_inp2_reg<=log_inp2;
if( log_inp1_reg==log_inp1 & log_inp2_reg==log_inp2 ) begin
    `ifdef log
    $finish;
    `endif
end
end


endmodule
