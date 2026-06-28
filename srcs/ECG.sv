`timescale 1ns / 1ps
module ECG #(
  parameter FIXED_POINT = 16,
  parameter APPROX = 0,
  parameter N = 54,
  parameter LOG2_N = 6,
  parameter RR_LIMIT = 597,
  parameter REFRACTORY = 72
)
(  input logic clk,
   input logic rst_n,
   input logic [11:0] data_in,
   output logic signed [FIXED_POINT*2-1:0] data_out,
   output logic qrs_detected
);
  
  logic signed [FIXED_POINT - 1:0] data_out_fb, data_out_bd, data_out_ds;  
  logic signed [FIXED_POINT*2-1:0] data_out_si, data_out_it ;
  logic out_valid_bd, out_valid_ds, out_valid_si, out_valid_it ;
  
  Fixed_Point_conv #(
  .FIXED_POINT(FIXED_POINT)
)  FF_Conversion
( .data_in(data_in), 
  .data_out(data_out_fb)
);
  
    
  Bandpass_Filter #(
  .FIXED_POINT(FIXED_POINT)
)  BandPass_Stage
( .rst_n(rst_n),
  .clk(clk),
  .data_in_bp(data_out_fb),
  .in_valid_bp(1'b1),
  .data_out_bp(data_out_bd),
  .out_valid_bp(out_valid_bd)
);

  Derivative #(
  .FIXED_POINT(FIXED_POINT)
)   Derivative_Stage
(  .clk(clk),
   .rst_n(rst_n),
   .data_in_d(data_out_bd),
   .in_valid_d(out_valid_bd),
   .out_valid_d(out_valid_ds),
   .data_out_d(data_out_ds)
);

   Squaring #(
   .FIXED_POINT(FIXED_POINT),
   .APPROX(APPROX)
)    Squaring_Stage
(   .clk(clk),
    .rst_n(rst_n),
    .data_in_s(data_out_ds),
    .in_valid_s(out_valid_ds),
    .data_out_s(data_out_si),
    .out_valid_s(out_valid_si)
);

   MWI #(
    .FIXED_POINT(FIXED_POINT),
    .N(N),
    .LOG2_N(LOG2_N)
)    MWI_Stage
(   .clk(clk),
    .rst_n(rst_n),
    .data_in_i(data_out_si),
    .in_valid_i(out_valid_si),
    .data_out_i(data_out_it),
    .out_valid_i(out_valid_it)
);

   Threshold_Search #(
    .FIXED_POINT(FIXED_POINT),
    .RR_LIMIT(RR_LIMIT),
    .REFRACTORY(REFRACTORY)
)    TS_Stage
(   .clk(clk),
    .rst_n(rst_n),
    .data_in_ts(data_out_it),
    .in_valid_ts(out_valid_it),
    .qrs_detected(qrs_detected),
    .data_out_ts(data_out)
);
endmodule
