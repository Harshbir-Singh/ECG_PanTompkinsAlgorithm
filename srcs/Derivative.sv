`timescale 1ns / 1ps
module Derivative #(
  parameter FIXED_POINT = 16
)
(  input logic clk,
   input logic rst_n,
   input logic signed [FIXED_POINT-1:0] data_in_d,
   input logic in_valid_d,
   output logic out_valid_d,
   output logic signed [FIXED_POINT-1:0] data_out_d
);
  logic signed [FIXED_POINT - 1:0] shift [0:3];
  logic [4:0] valid_shift;
  always_ff@(posedge clk)
    begin
      if(rst_n == 1'b0)
        begin
          for(int i = 0; i<4; i++)
            shift[i] <= '0;
        end
      else if(in_valid_d)
        begin
          shift[0] <= data_in_d; //data_in_d = x(n)
          shift[1] <= shift[0];  //shift[0] = x(n-1)
          shift[2] <= shift[1];
          shift[3] <= shift[2];  //shift[3] = x(n-4)
        end
    end
  //y(n) = 1/8(2x(n) + x(n-1) - x(n-3) - 2x(n-4))
  always_ff@(posedge clk)
    begin
      if(rst_n == 1'b0)
        begin
          valid_shift <= '0;
          data_out_d <= '0;
          out_valid_d <= 1'b0;
        end
      else
        begin
          valid_shift <= {valid_shift[3:0],in_valid_d}; //Left shift
          data_out_d <= ((data_in_d<<<1) + shift[0] - shift[2] - (shift[3]<<<1))>>>3;
          out_valid_d <= valid_shift[4];
        end 
    end

endmodule
