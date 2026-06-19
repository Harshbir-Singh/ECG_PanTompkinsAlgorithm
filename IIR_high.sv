`timescale 1ns / 1ps
module IIR_high #(
  parameter FIXED_POINT = 16
)
( input rst_n,
  input clk,
  input logic in_valid_iir_high,
  input logic signed [FIXED_POINT - 1:0] data_in_iir_high,
  output logic out_valid_iir_high,
  output logic signed [FIXED_POINT - 1:0] data_out_iir_high
);

  logic [32:0] valid_shift;
  logic signed [FIXED_POINT - 1:0] shift [0:31];
  logic signed [FIXED_POINT - 1:0] temp;
  always_ff@(posedge clk)
    begin
      if(rst_n == 1'b0)
        begin
          for(int i = 0; i<32; i++)
            shift[i] <= '0;
        end
      else
        begin
          if(in_valid_iir_high)
            begin
              shift[0] <= data_in_iir_high; //x(n) = data_in_iir_high;
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
              shift[11] <= shift[10]; 
              shift[12] <= shift[11]; 
              shift[13] <= shift[12]; 
              shift[14] <= shift[13]; 
              shift[15] <= shift[14];
              shift[16] <= shift[15];
              shift[17] <= shift[16];
              shift[18] <= shift[17];
              shift[19] <= shift[18];
              shift[20] <= shift[19];
              shift[21] <= shift[20];
              shift[22] <= shift[21];
              shift[23] <= shift[22]; 
              shift[24] <= shift[23]; 
              shift[25] <= shift[24];
              shift[26] <= shift[25];
              shift[27] <= shift[26];
              shift[28] <= shift[27];
              shift[29] <= shift[28];
              shift[30] <= shift[29];
              shift[31] <= shift[30];//x(n-32) = shift[31]
            end  
        end  
    end
    
    always_ff@(posedge clk)
      begin
        if(rst_n == 1'b0)
          begin
            temp <= '0; 
          end
        else if(in_valid_iir_high)
          begin
            temp <= data_out_iir_high; //y(n-1)
          end
      end
      
    // y = y(n-1) - x(n)/32 + x(n-16) - x(n-17) + x(n-32)/32  
    always_ff@(posedge clk)
      begin
        if(rst_n == 1'b0) 
          begin
            valid_shift <= '0;
            data_out_iir_high <= '0;
            out_valid_iir_high <= 1'b0;
          end
        
        else
          begin
            valid_shift <= {valid_shift[31:0],in_valid_iir_high}; //Left Shift
            data_out_iir_high <= temp - (data_in_iir_high>>>5) + shift[15] - shift[16] + (shift[31]>>>5);
            out_valid_iir_high <= valid_shift[32];
          end
      end
    
endmodule
