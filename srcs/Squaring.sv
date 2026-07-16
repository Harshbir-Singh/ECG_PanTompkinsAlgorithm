`timescale 1ns / 1ps

module Squaring #(
  parameter FIXED_POINT = 16,
  parameter APPROX = 0
)
(
  input logic clk,
  input logic rst_n,
  input logic signed [FIXED_POINT-1:0] data_in_s,
  input logic in_valid_s,
  output logic signed [FIXED_POINT*2-1:0] data_out_s,
  output logic out_valid_s
);

  localparam integer DER_W = FIXED_POINT - 3;
  localparam integer EXACT_SQ_W = (2*DER_W) - 1;

  logic valid_delay;

  always_ff @(posedge clk) begin
    if (!rst_n)
      valid_delay <= 1'b0;
    else
      valid_delay <= in_valid_s;
  end

  assign out_valid_s = valid_delay;

  generate
    if (APPROX == 0) begin : Exact_Optimized_Squarer
      logic signed [DER_W-1:0] derivative_narrow;
      logic [DER_W-1:0] abs_value_narrow;
      logic [(2*DER_W)-1:0] abs_value_ext;
      logic [(2*DER_W)-1:0] square_full;
      logic [EXACT_SQ_W-1:0] square_reg;

      assign derivative_narrow = data_in_s[DER_W-1:0];

      assign abs_value_narrow = derivative_narrow[DER_W-1] ? $unsigned(-derivative_narrow) : $unsigned( derivative_narrow);

      assign abs_value_ext = {{DER_W{1'b0}}, abs_value_narrow};


      assign square_full = abs_value_ext * abs_value_narrow;

      always_ff @(posedge clk) begin
        if (!rst_n)
          square_reg <= '0;
        else if (in_valid_s)
          square_reg <= square_full[EXACT_SQ_W-1:0];
      end

      assign data_out_s = {{((FIXED_POINT*2)-EXACT_SQ_W){1'b0}}, square_reg};

    end
    else begin : Russian_Peasant

      logic [FIXED_POINT-1:0] abs_value;
      logic signed [FIXED_POINT*2-1:0] partial [0:FIXED_POINT-1-APPROX];

      assign abs_value = data_in_s[FIXED_POINT-1] ? -data_in_s : data_in_s;

      always_comb begin
        partial[0] = abs_value[0] ? {{FIXED_POINT{1'b0}}, abs_value} : '0;
      end

      genvar i;
      for (i = 1; i < FIXED_POINT-APPROX; i++) begin : Russian_Peasant
        always_comb begin
          partial[i] = partial[i-1] + (abs_value[i] ? ($signed({{FIXED_POINT{1'b0}}, abs_value}) <<< i) : '0);
        end
      end

      logic signed [FIXED_POINT*2-1:0] square_reg;

      always_ff @(posedge clk) begin
        if (!rst_n)
          square_reg <= '0;
        else if (in_valid_s)
          square_reg <= partial[FIXED_POINT-1-APPROX];
      end

      assign data_out_s = square_reg;

    end
  endgenerate

endmodule
