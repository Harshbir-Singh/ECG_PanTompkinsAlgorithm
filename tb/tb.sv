
`timescale 1ns / 1ps

module tb;
    parameter int FIXED_POINT_TB = 16;
    parameter int APPROX_TB = 0;
    parameter int N_TB = 54;
    parameter int LOG2_N_TB  = 6;
    parameter int RR_LIMIT_TB = 597;
    parameter int REFRACTORY_TB = 72;
    parameter int PIPELINE_DELAY = 107;  
    parameter int FLUSH_CYCLES = PIPELINE_DELAY + 50;
    parameter int TOTAL_SAMPLES = 650000;

    logic clk_tb;
    logic rst_n;
    logic [11:0] in;
    logic signed [FIXED_POINT_TB*2-1:0] out;
    logic qrs_detected;


    logic [11:0] mem [0:TOTAL_SAMPLES-1];
    initial $readmemh("ecg_data.hex", mem);

 
    int i;
    int qrs_count;
    int last_qrs_sample;
    int cur_qrs_sample;
    int rr_interval;

   
    initial clk_tb = 0;
    always #5 clk_tb = ~clk_tb; //100MHZ

 
    initial begin
        rst_n = 1'b0;
        in = 12'h000;
        repeat(10) @(posedge clk_tb);
        rst_n = 1'b1;
    end

   
    integer fp_qrs;

    initial begin
        qrs_count       = 0;
        last_qrs_sample = 0;

        fp_qrs = $fopen("rtl_qrs_locations.txt", "w");
        if (fp_qrs == 0) begin
            $display("ERROR: Cannot open rtl_qrs_locations.txt");
            $finish;
        end

 
        wait (rst_n === 1'b1);
        @(posedge clk_tb);

        for (i = 0; i < TOTAL_SAMPLES; i++) begin

            in = mem[i];
            @(posedge clk_tb);

           
            #1;

            if (qrs_detected) begin
                qrs_count = qrs_count + 1;

                cur_qrs_sample = i - PIPELINE_DELAY;
                if (cur_qrs_sample < 0) cur_qrs_sample = 0;

                rr_interval = cur_qrs_sample - last_qrs_sample;

                $fwrite(fp_qrs, "%0d\n", cur_qrs_sample);

                $display("=== QRS #%0d ===", qrs_count);
                $display("  Adjusted sample : %0d  (raw %0d - delay %0d)",
                         cur_qrs_sample, i, PIPELINE_DELAY);
                $display("  RR interval     : %0d samples (%.1f ms)",
                         rr_interval, rr_interval * (1000.0/360.0));
                $display("  MWI out (s1) : %0d", DUT.TS_Stage.s1);
                $display("  SPKI : %0d", DUT.TS_Stage.SPKI);
                $display("  NPKI : %0d", DUT.TS_Stage.NPKI);
                $display("  THR1 : %0d", DUT.TS_Stage.THR1);
                $display("  THR2 : %0d", DUT.TS_Stage.THR2);
                $display("  State : %0d", DUT.TS_Stage.state);
                $display("--------------------------------------------");

                if (qrs_count > 1) begin
                    if (rr_interval < 50)
                        $display("  *** WARNING: RR=%0d - possible double detection ***",
                                 rr_interval);
                    if (rr_interval > 600)
                        $display("  *** WARNING: RR=%0d - possible missed beat ***",
                                 rr_interval);
                end

                last_qrs_sample = cur_qrs_sample;
            end

            if (i < 20)
                $display("sample[%0d]  in=%0d  mwi_out=%0d",
                         i, mem[i], DUT.data_out_it);

        end 
        repeat(FLUSH_CYCLES) @(posedge clk_tb);
        $fclose(fp_qrs);
        $finish;
    end


    ECG #(
        .FIXED_POINT(FIXED_POINT_TB),
        .APPROX(APPROX_TB),
        .N(N_TB),
        .LOG2_N(LOG2_N_TB),
        .RR_LIMIT(RR_LIMIT_TB),
        .REFRACTORY(REFRACTORY_TB)
    ) DUT (
        .clk(clk_tb),
        .rst_n(rst_n),
        .data_in(in),
        .data_out(out),
        .qrs_detected(qrs_detected)
    );

endmodule
