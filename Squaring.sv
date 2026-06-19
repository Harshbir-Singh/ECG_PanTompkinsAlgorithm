`timescale 1ns / 1ps
module Squaring #(
    parameter FIXED_POINT = 16,
    parameter APPROX = 0
)(
    input logic clk,
    input logic rst_n,
    input logic signed [FIXED_POINT-1:0] data_in_s,
    input logic in_valid_s,
    output logic signed [FIXED_POINT*2-1:0] data_out_s,
    output logic out_valid_s
);
    logic [FIXED_POINT-1:0] abs_value;
    assign abs_value = data_in_s[FIXED_POINT-1]? -data_in_s: data_in_s;
    
    logic signed [FIXED_POINT*2-1:0] partial [0:FIXED_POINT-1-APPROX];

    always_comb begin
        partial[0] = abs_value[0] ? {{FIXED_POINT{1'b0}}, abs_value} : '0; //Checking A for odd and even ; Assigning B = 0 for odd
    end

    // Generate remaining stages
    genvar i;
    generate
        for (i = 1; i < FIXED_POINT-APPROX; i++) 
          begin : Russian_Peasant
            always_comb 
              begin
                // A bits checked ----> similar to bit shift by 1 to right and then checking for odd or even
                // B multiplied by 2 at every stage
                partial[i] = partial[i-1] + (abs_value[i]? 
                            ($signed({{FIXED_POINT{1'b0}}, abs_value}) <<< i) : 
                            '0);
              end
          end
    endgenerate

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            data_out_s  <= '0;
        end else if (in_valid_s) begin
            data_out_s  <= partial[FIXED_POINT-1-APPROX]; //APPROX ===> approximates the multiplication results by ignoring the later LSB's of A
        end
    end

    logic valid_delay;
    always_ff @(posedge clk) 
      begin
        if (!rst_n) valid_delay <= '0;
        else valid_delay <= in_valid_s;  //One Delay only needed as Multiplication is combinational
      end
    assign out_valid_s = valid_delay;

endmodule