`timescale 1ns / 1ps
module Bandpass_Filter #(
  parameter FIXED_POINT = 16
)
( input logic rst_n,
  input logic clk,
  input logic signed [FIXED_POINT-1:0] data_in_bp,
  input logic in_valid_bp,
  output logic signed [FIXED_POINT-1:0] data_out_bp,
  output logic out_valid_bp
);
  
  logic signed [FIXED_POINT-1:0] data_lh;
  logic valid;
  IIR_low #(
  .FIXED_POINT(FIXED_POINT)
)
  Low_Pass
( .rst_n(rst_n),
  .clk(clk),
  .in_valid_iir_low(in_valid_bp),
  .data_in_iir_low(data_in_bp),
  .out_valid_iir_low(valid),
  .data_out_iir_low(data_lh)
);
  
  IIR_high #(
  .FIXED_POINT(FIXED_POINT)
)
  High_Pass
( .rst_n(rst_n),
  .clk(clk),
  .in_valid_iir_high(valid),
  .data_in_iir_high(data_lh),
  .out_valid_iir_high(out_valid_bp),
  .data_out_iir_high(data_out_bp)
);
  
endmodule
