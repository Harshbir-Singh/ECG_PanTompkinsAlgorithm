`timescale 1ns / 1ps
module square_tb;
  parameter FIXED_POINT  = 16;
  parameter APPROX = 0;
  
  logic clk, rst_n;
  logic signed [FIXED_POINT-1:0] data_in_s;
  logic in_valid_s;
  logic signed [FIXED_POINT*2-1:0] data_out_s;
  logic out_valid_s;

  Squaring #(
    .FIXED_POINT(FIXED_POINT),
    .APPROX(APPROX)
)   DUT
(
    .clk(clk),
    .rst_n(rst_n),
    .data_in_s(data_in_s),
    .in_valid_s(in_valid_s),
    .data_out_s(data_out_s),
    .out_valid_s(out_valid_s)
);

  initial clk = 0;
  always #10 clk = ~clk;
  
  initial
    begin
      data_in_s = 0;
      @(posedge clk);
      rst_n = 0;
      repeat(2)@(posedge clk)
      rst_n = 1;
      in_valid_s = 1;
      data_in_s = -76;
      
      repeat(10)@(posedge clk);
      $display("DATA OUT = %0d",data_out_s);
      $finish();
    end
  
endmodule
