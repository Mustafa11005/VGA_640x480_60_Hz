module vga_640x480_tb ();

    parameter INPUT_CLK_FREQ_MHZ = 25;
    parameter CLK_PERIOD = (1000 / INPUT_CLK_FREQ_MHZ);

    parameter USE_IMAGE_MEM = 1;

    parameter BPP = 8;
    
    parameter H_ACTIVE = 640;
    parameter H_FRONT_PORCH = 16;
    parameter H_SYNC_PORCH = 96;
    parameter H_BACK_PORCH = 48;

    parameter V_ACTIVE = 480;
    parameter V_FRONT_PORCH = 10;
    parameter V_SYNC_PORCH = 2;
    parameter V_BACK_PORCH = 33;

    localparam H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC_PORCH + H_BACK_PORCH;
    localparam V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC_PORCH + V_BACK_PORCH;
    localparam SIM_CYCLES = (H_TOTAL * V_TOTAL * 2);

    logic clk;
    logic rstn;

    logic h_sync;
    logic v_sync;

    logic video_on;

    logic [BPP - 1 : 0] rgb;

    int tb_x;
    int tb_y;
    int error_count;

    logic exp_h_sync = 1;
    logic exp_v_sync = 1;
    logic exp_video_on = 1;
    logic exp_video_on_d;  

    vga_640x480 #(
        .INPUT_CLK_FREQ_MHZ(INPUT_CLK_FREQ_MHZ),
        .USE_IMAGE_MEM(USE_IMAGE_MEM),
        .BPP(BPP),
        .H_ACTIVE(H_ACTIVE),
        .H_FRONT_PORCH(H_FRONT_PORCH),
        .H_SYNC_PORCH(H_SYNC_PORCH),
        .H_BACK_PORCH(H_BACK_PORCH),
        .V_ACTIVE(V_ACTIVE),
        .V_FRONT_PORCH(V_FRONT_PORCH),
        .V_SYNC_PORCH(V_SYNC_PORCH),
        .V_BACK_PORCH(V_BACK_PORCH)
    ) DUT (
        .clk(clk),
        .rstn(rstn),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .video_on(video_on),
        .rgb(rgb)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #(CLK_PERIOD / 2) clk = ~clk;
        end
    end

    always @(*) begin
        exp_h_sync = ((tb_x < (H_ACTIVE + H_FRONT_PORCH)) || (tb_x > (H_ACTIVE + H_FRONT_PORCH + H_SYNC_PORCH - 1)));
        exp_v_sync = ((tb_y < (V_ACTIVE + V_FRONT_PORCH)) || (tb_y > (V_ACTIVE + V_FRONT_PORCH + V_SYNC_PORCH - 1)));
        exp_video_on = ((tb_x < H_ACTIVE) && (tb_y < V_ACTIVE));
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            tb_x <= 0;
            tb_y <= 0;
            exp_video_on_d <= 1'b0;
        end else begin
            if(h_sync !== exp_h_sync) begin
                report_mismatch("h_sync", h_sync, exp_h_sync);
            end

            if(v_sync !== exp_v_sync) begin
                report_mismatch("v_sync", v_sync, exp_v_sync);
            end

            if(video_on !== exp_video_on) begin
                report_mismatch("video_on", video_on, exp_video_on);
            end

            if(USE_IMAGE_MEM == 1) begin
                if((!exp_video_on_d) && (rgb !== {BPP{1'b0}})) begin
                    error_count <= error_count + 1;
                    $display("[ERROR][%0t] rgb must be zero in blanking (mem mode): rgb=%0h x=%0d y=%0d", $time, rgb, tb_x, tb_y);
                end
            end else begin
                if((!exp_video_on) && (rgb !== {BPP{1'b0}})) begin
                    error_count <= error_count + 1;
                    $display("[ERROR][%0t] rgb must be zero in blanking: rgb=%0h x=%0d y=%0d", $time, rgb, tb_x, tb_y);
                end
            end

            exp_video_on_d <= exp_video_on;

            if(tb_x == (H_TOTAL - 1)) begin
                tb_x <= 0;
                if(tb_y == (V_TOTAL - 1)) begin
                    tb_y <= 0;
                end else begin
                    tb_y <= tb_y + 1;
                end
            end else begin
                tb_x <= tb_x + 1;
            end
        end
    end

    initial begin
        tb_x = 0;
        tb_y = 0;
        error_count = 0;

        rstn = 1'b0;
        repeat(5) @(negedge clk);

        rstn = 1'b1;
        repeat(SIM_CYCLES) @(posedge clk);

        if(error_count == 0) begin
            $display("[PASS] VGA testing completed with no mismatches.");
        end else begin
            $display("[FAIL] VGA testing found %0d mismatches.", error_count);
        end

        $stop;
    end

    task report_mismatch(
        input string signal_name,
        input logic got_val,
        input logic exp_val
    );
        error_count = error_count + 1;
        $display("[ERROR][%0t] %s mismatch: got=%0b exp=%0b x=%0d y=%0d", $time, signal_name, got_val, exp_val, tb_x, tb_y);
    endtask

endmodule