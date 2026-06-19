`timescale 1ns / 1ps
module MWI #(
    parameter FIXED_POINT = 16,
    parameter N = 54,
    parameter LOG2_N = 6   
)(
    input logic clk,
    input logic rst_n,
    input logic signed [FIXED_POINT*2-1:0] data_in_i,
    input logic in_valid_i,
    output logic signed [FIXED_POINT*2-1:0] data_out_i,
    output logic out_valid_i
);

    logic signed [FIXED_POINT*2-1:0] shift [0:N-2];

    logic [N-2:0] valid_shift;

    logic signed [FIXED_POINT*2+5:0] sum;

    always_ff @(posedge clk) 
      begin
        if (!rst_n) 
          begin
            for (int i = 0; i < N-1; i++)
              shift[i] <= '0;
          end 
        else if (in_valid_i) 
          begin
            shift[0] <= data_in_i;
            for (int j = 1; j < N-1; j++)
              shift[j] <= shift[j-1];
          end
      end
    always_ff @(posedge clk) begin
        if (!rst_n) 
          sum <= '0;
        else if (in_valid_i)
          sum <= sum + data_in_i - shift[N-2]; 
    end

    always_ff @(posedge clk) begin
        if (!rst_n) valid_shift <= '0;
        else valid_shift <= {valid_shift[N-3:0], in_valid_i};  //Left Shift
    end
    //y(n) = 1/N(x(n-(N-1) + x(n-(N-2))....... + x(n))
    assign data_out_i = sum >>> LOG2_N;
    assign out_valid_i = valid_shift[N-2];

endmodule