`timescale 1ns / 1ps

module Threshold_Search #(
    parameter FIXED_POINT = 16,          
    parameter RR_LIMIT = 597,         
    parameter REFRACTORY = 72,          
    parameter FRAC_BITS = 14,          
    parameter LEARN_LEN = 720          
)(
    input logic clk,
    input logic rst_n,
    input logic signed [FIXED_POINT*2-1:0] data_in_ts,
    input logic in_valid_ts,
    output logic qrs_detected,
    output logic signed [FIXED_POINT*2-1:0] data_out_ts  
);             
    localparam ONE = (1 << FRAC_BITS);            

    localparam LEARN = 2'b00;   
    localparam BLANKING = 2'b01;  
    localparam DETECT = 2'b10;   
    localparam SEARCHBACK = 2'b11;   

    logic [1:0] state;

    logic signed [FIXED_POINT*2-1:0] s0, s1, s2;
    logic is_peak;

    assign is_peak = (s1 >= s0) && (s1 > s2) && (s1 > 0);

    logic signed [FIXED_POINT*2-1:0] SPKI, NPKI, THR1, THR2;        
    logic signed [FIXED_POINT*2-1:0] spki_npki_diff;
    
    assign spki_npki_diff = (SPKI > NPKI) ? (SPKI - NPKI) : '0;
    assign THR1 = NPKI + (spki_npki_diff >>> 2); 
    assign THR2 = THR1 >>> 1;                     

    int refractory_cnt;
    int rr_cnt;         
    int learn_cnt;        

    logic signed [FIXED_POINT*2-1:0] sb_peak_val;   
    logic signed [FIXED_POINT*2-1:0] sb_peak_idx;   

    function logic signed [FIXED_POINT*2-1:0] ht_update(
        input logic signed [FIXED_POINT*2-1:0] old_est,
        input logic signed [FIXED_POINT*2-1:0] new_val
    );
        ht_update = old_est - (old_est >>> 3) + (new_val >>> 3);
    endfunction

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s0 <= '0;
            s1 <= '0;
            s2 <= '0;
            SPKI <= '0;
            NPKI <= '0;
            qrs_detected <= 1'b0;
            data_out_ts <= '0;
            refractory_cnt<= 0;
            rr_cnt <= 0;
            learn_cnt <= 0;
            sb_peak_val <= '0;
            state <= LEARN;
        end
        else if (in_valid_ts) begin

            s0 <= data_in_ts;
            s1 <= s0;
            s2 <= s1;

            qrs_detected <= 1'b0;

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
                        rr_cnt  <= 0;
                        state   <= DETECT;
                    end
                end

                BLANKING: begin // Prevents the detection for next 72 samples after one detection.
                    refractory_cnt <= refractory_cnt + 1;
                    rr_cnt <= rr_cnt + 1;
                    if (refractory_cnt == REFRACTORY - 1) begin
                        refractory_cnt <= 0;
                        sb_peak_val <= '0;   
                        state <= DETECT;
                    end
                end

                DETECT: begin
                    rr_cnt <= rr_cnt + 1;

                    if (is_peak) begin
                        if (s1 > THR1) begin
                            qrs_detected <= 1'b1;
                            data_out_ts <= s1;
                            SPKI <= ht_update(SPKI, s1);
                            rr_cnt <= 0;
                            refractory_cnt <= 0;
                            state <= BLANKING;
                        end
                        else begin
                            NPKI <= ht_update(NPKI, s1);
                            if (s1 > sb_peak_val)
                                sb_peak_val <= s1;
                        end
                    end

                    if (rr_cnt >= RR_LIMIT) begin
                        rr_cnt <= 0;
                        state  <= SEARCHBACK;
                    end
                end

                SEARCHBACK: begin
                    rr_cnt <= rr_cnt + 1;

                    if (is_peak && (s1 > THR2)) begin
                        qrs_detected  <= 1'b1;
                        data_out_ts   <= s1;
                        SPKI <= ht_update(SPKI, s1 >>> 1);
                        rr_cnt <= 0;
                        refractory_cnt <= 0;
                        sb_peak_val <= '0;
                        state <= BLANKING;
                    end
                    else if (is_peak) begin
                        NPKI <= ht_update(NPKI, s1);
                    end

                    if (rr_cnt >= RR_LIMIT) begin
                        rr_cnt <= 0;
                        state  <= DETECT;
                    end
                end

                default: state <= LEARN;
            endcase
        end
    end

endmodule