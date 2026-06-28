`timescale 1ns / 1ps

module Threshold_Search #(
    parameter FIXED_POINT = 16,
    parameter RR_LIMIT = 597,   
    parameter REFRACTORY = 72,    
    parameter T_CHECK_LIMIT = 130,  
    parameter WEAK_RR_LIMIT = 180,   
    parameter FRAC_BITS = 10,
    parameter LEARN_LEN = 720
)(
    input logic clk,
    input logic rst_n,

    input logic signed [FIXED_POINT*2-1:0] data_in_ts,
    input logic in_valid_ts,

    output logic qrs_detected,
    output logic signed [FIXED_POINT*2-1:0] data_out_ts
);
    localparam DW  = FIXED_POINT*2;
    localparam ONE = (1 << FRAC_BITS);
    localparam LEARN = 2'b00;
    localparam BLANKING = 2'b01;
    localparam DETECT = 2'b10;
    localparam SEARCHBACK = 2'b11;
    logic [1:0] state;
    logic signed [DW-1:0] s0, s1, s2;
    logic is_peak;
    
    assign is_peak = (s1 >= s0) && (s1 > s2) && (s1 > 0);

    logic signed [DW-1:0] SPKI, NPKI;
    logic signed [DW-1:0] THR1, THR2, THR_WEAK;
    logic signed [DW-1:0] spki_npki_diff;

    assign spki_npki_diff = (SPKI > NPKI) ? (SPKI - NPKI) : '0;


    assign THR1 = NPKI + (spki_npki_diff >>> 2);
    assign THR2 = THR1 >>> 1;
    assign THR_WEAK = NPKI
                    + (spki_npki_diff >>> 4)
                    + (spki_npki_diff >>> 5);

    int refractory_cnt;
    int rr_cnt;
    int learn_cnt;

    logic signed [DW-1:0] last_qrs_peak;

    function automatic logic signed [DW-1:0] ht_update(
        input logic signed [DW-1:0] old_est,
        input logic signed [DW-1:0] new_val
    );
        begin
            ht_update = old_est - (old_est >>> 3) + (new_val >>> 3);
        end
    endfunction

    logic close_peak_region;
    logic close_peak_reject;

    assign close_peak_region = (rr_cnt < T_CHECK_LIMIT);

    always_comb begin
        close_peak_reject = 1'b0;

        if (close_peak_region && (last_qrs_peak > 0)) begin
            if (s1 < (last_qrs_peak >>> 1))
                close_peak_reject = 1'b1;
        end
    end

    always_ff @(posedge clk) begin

        logic detected_this_cycle;

        if (!rst_n) begin
            s0 <= '0;
            s1 <= '0;
            s2 <= '0;
            SPKI <= '0;
            NPKI <= '0;
            qrs_detected <= 1'b0;
            data_out_ts  <= '0;
            refractory_cnt <= 0;
            rr_cnt         <= 0;
            learn_cnt      <= 0;
            last_qrs_peak <= '0;
            state <= LEARN;
        end

        else if (in_valid_ts) begin

            s0 <= data_in_ts;
            s1 <= s0;
            s2 <= s1;

            qrs_detected <= 1'b0;
            detected_this_cycle = 1'b0;

            case (state)
                LEARN: begin
                    learn_cnt <= learn_cnt + 1;

                    if (is_peak) begin
                        if (s1 > (SPKI >>> 1))
                            SPKI <= ht_update(SPKI, s1);
                        else
                            NPKI <= ht_update(NPKI, s1);
                    end

                    if (learn_cnt == LEARN_LEN - 1) begin
                        if (SPKI == '0)
                            SPKI <= ONE;

                        rr_cnt <= 0;
                        refractory_cnt <= 0;
                        last_qrs_peak <= SPKI;

                        state <= DETECT;
                    end
                end

                BLANKING: begin
                    refractory_cnt <= refractory_cnt + 1;
                    rr_cnt <= rr_cnt + 1;

                    if (is_peak) begin
                        NPKI <= ht_update(NPKI, s1);
                    end

                    if (refractory_cnt == REFRACTORY - 1) begin
                        refractory_cnt <= 0;
                        state <= DETECT;
                    end
                end

                DETECT: begin
                    rr_cnt <= rr_cnt + 1;

                    if (is_peak) begin

                        if ((s1 > THR1) && (!close_peak_reject)) begin
                            qrs_detected <= 1'b1;
                            data_out_ts  <= s1;

                            SPKI <= ht_update(SPKI, s1);
                            last_qrs_peak <= s1;

                            rr_cnt <= 0;
                            refractory_cnt <= 0;

                            state <= BLANKING;
                            detected_this_cycle = 1'b1;
                        end

                        else if ((rr_cnt >= WEAK_RR_LIMIT) &&
                                 (s1 > THR_WEAK)) begin
                            qrs_detected <= 1'b1;
                            data_out_ts  <= s1;
                            SPKI <= ht_update(SPKI, s1 >>> 1);
                            last_qrs_peak <= s1;

                            rr_cnt <= 0;
                            refractory_cnt <= 0;

                            state <= BLANKING;
                            detected_this_cycle = 1'b1;
                        end

                        else begin
                            NPKI <= ht_update(NPKI, s1);
                        end
                    end

                    if (!detected_this_cycle) begin
                        if (rr_cnt >= RR_LIMIT) begin
                            rr_cnt <= 0;
                            state  <= SEARCHBACK;
                        end
                    end
                end

                SEARCHBACK: begin
                    rr_cnt <= rr_cnt + 1;

                    if (is_peak) begin

                        if ((s1 > THR2) && (!close_peak_reject)) begin
                            qrs_detected <= 1'b1;
                            data_out_ts  <= s1;
                            SPKI <= ht_update(SPKI, s1 >>> 1);
                            last_qrs_peak <= s1;
                            rr_cnt <= 0;
                            refractory_cnt <= 0;
                            state <= BLANKING;
                            detected_this_cycle = 1'b1;
                        end
                        else begin
                            NPKI <= ht_update(NPKI, s1);
                        end
                    end
                    if (!detected_this_cycle) begin
                        if (rr_cnt >= RR_LIMIT) begin
                            rr_cnt <= 0;
                            state <= DETECT;
                        end
                    end
                end
                default: begin
                    state <= LEARN;
                end

            endcase
        end
    end

endmodule