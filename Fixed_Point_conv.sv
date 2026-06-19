`timescale 1ns / 1ps
//16 - Q9.7
//32 - Q9.23
module Fixed_Point_conv #(
  parameter FIXED_POINT = 16
  )
  (input logic [11:0] data_in, 
  output logic signed [FIXED_POINT - 1:0] data_out
  );
  
  logic signed [12:0] temp1;
  logic signed [FIXED_POINT-1:0] temp2;
  always_comb
    begin
      temp1 = $signed({1'b0,data_in}) - $signed(13'd1024);
      temp2 = {{(FIXED_POINT - 13){temp1[12]}},temp1};
      data_out = temp2<<<(FIXED_POINT-9);
    end
endmodule
