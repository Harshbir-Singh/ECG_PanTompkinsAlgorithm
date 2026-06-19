`timescale 1ns / 1ps
module IIR_low #(
  parameter FIXED_POINT = 16
)
( input rst_n,
  input clk,
  input logic in_valid_iir_low,
  input logic signed [FIXED_POINT - 1:0] data_in_iir_low,
  output logic out_valid_iir_low,
  output logic signed [FIXED_POINT - 1:0] data_out_iir_low
);

  logic [12:0] valid_shift;
  logic signed [FIXED_POINT - 1:0] shift [0:11];
  logic signed [FIXED_POINT - 1:0] temp [0:1];
  always_ff@(posedge clk)
    begin
      if(rst_n == 1'b0)
        begin
          for(int i = 0; i<12; i++)
            shift[i] <= '0;
        end
      else
        begin
          if(in_valid_iir_low)
            begin
              shift[0] <= data_in_iir_low; //x(n) = data_in_iir_low;
              shift[1] <= shift[0]; //x(n-1) = shift[0]
              shift[2] <= shift[1]; //x(n-2) = shift[1]
              shift[3] <= shift[2];
              shift[4] <= shift[3];
              shift[5] <= shift[4];
              shift[6] <= shift[5];
              shift[7] <= shift[6];
              shift[8] <= shift[7];
              shift[9] <= shift[8];
              shift[10] <= shift[9];
              shift[11] <= shift[10]; //x(n-12) = shift[11]
            end  
        end  
    end
    
    always_ff@(posedge clk)
      begin
        if(rst_n == 1'b0)
          begin
            temp[0] <= '0; 
            temp[1] <= '0; 
          end
        else if(in_valid_iir_low)
          begin
            temp[0] <= data_out_iir_low; //y(n-1)
            temp[1] <= temp[0]; //y(n-2)
          end
      end
      
    // y = 1/32(2y(n-1) - y(n-2) + x(n) - 2x(n-6) + x(n-12))  
    always_ff@(posedge clk)
      begin
        if(rst_n == 1'b0) 
          begin
            valid_shift <= 13'd0;
            data_out_iir_low <= '0;
            out_valid_iir_low <= 0;
          end
        else
          begin
            valid_shift <= {valid_shift[11:0],in_valid_iir_low}; //Left Shift
            data_out_iir_low <= ((temp[0]<<<1) - temp[1] + data_in_iir_low - (shift[5]<<<1) + shift[11])>>>5;
            out_valid_iir_low <= valid_shift[12];
          end
      end
    
endmodule