module vga_640x480 #(
    parameter INPUT_CLK_FREQ_MHZ = 25,

    parameter USE_IMAGE_MEM = 0,

    parameter BPP = 8,
    
    parameter H_ACTIVE = 640,
    parameter H_FRONT_PORCH = 16,
    parameter H_SYNC_PORCH = 96,
    parameter H_BACK_PORCH = 48,

    parameter V_ACTIVE = 480,
    parameter V_FRONT_PORCH = 10,
    parameter V_SYNC_PORCH = 2,
    parameter V_BACK_PORCH = 33
)(
    clk,
    rstn,

    h_sync,
    v_sync,

    video_on,

    rgb
);

    localparam H_FRONT_PORCH_TOTAL_COUNT = H_ACTIVE + H_FRONT_PORCH;
    localparam H_SYNC_PORCH_TOTAL_COUNT = H_ACTIVE + H_FRONT_PORCH + H_SYNC_PORCH;
    localparam H_BACK_PORCH_TOTAL_COUNT = H_ACTIVE + H_FRONT_PORCH + H_SYNC_PORCH + H_BACK_PORCH;

    localparam V_FRONT_PORCH_TOTAL_COUNT = V_ACTIVE + V_FRONT_PORCH;
    localparam V_SYNC_PORCH_TOTAL_COUNT = V_ACTIVE + V_FRONT_PORCH + V_SYNC_PORCH;
    localparam V_BACK_PORCH_TOTAL_COUNT = V_ACTIVE + V_FRONT_PORCH + V_SYNC_PORCH + V_BACK_PORCH;

    input clk;
    input rstn;

    output wire h_sync;
    output wire v_sync;

    output wire video_on;

    output wire [BPP - 1 : 0] rgb;

    wire clk_sys;

    reg [9 : 0] pixel_x;
    reg [9 : 0] pixel_y;
    reg video_on_d;

    wire row_done;

    generate
        if(INPUT_CLK_FREQ_MHZ < 50) begin
            assign clk_sys = clk;
        end else begin
            clk_gen #(
                .INPUT_CLK_FREQ_MHZ (INPUT_CLK_FREQ_MHZ)
            ) SYSTEM_CLK_GENERATOR (
                .clk (clk),
                .rstn (rstn),
                .clk_25_MHz_out (clk_sys)
            );
        end
    endgenerate

    generate
        if(USE_IMAGE_MEM == 1) begin
            wire [18 : 0] rgb_gen_addr;
            wire [BPP - 1 : 0] rgb_gen_out;

            assign rgb_gen_addr = (video_on) ? ((pixel_y * H_ACTIVE) + pixel_x) : 19'd0;

            pixel_rgb_gen #(
                .BPP(BPP)
            ) RGB_GEN (
                .clk(clk_sys),
                .rstn(rstn),
                .addr(rgb_gen_addr),
                .rgb(rgb_gen_out)
            );

            assign rgb = (video_on_d) ?  rgb_gen_out : {BPP{1'b0}};
        end else begin
            assign rgb = (video_on) ? {BPP{1'b1}} : {BPP{1'b0}};
        end
    endgenerate

    always @(posedge clk_sys or negedge rstn) begin
        if(!rstn) begin
            pixel_x <= 10'b00_0000_0000;
        end else if (pixel_x == (H_BACK_PORCH_TOTAL_COUNT - 1)) begin
            pixel_x <= 10'b00_0000_0000;
        end else begin
            pixel_x <= pixel_x + 1'b1;
        end
    end

    always @(posedge clk_sys or negedge rstn) begin
        if(!rstn) begin
            pixel_y <= 10'b0_0000_0000;
        end else if(row_done) begin
            if(pixel_y == (V_BACK_PORCH_TOTAL_COUNT - 1)) begin
                pixel_y <= 10'b0_0000_0000;
            end else begin
                pixel_y <= pixel_y + 1'b1;
            end
        end
    end

    always @(posedge clk_sys or negedge rstn) begin
        if(!rstn) begin
            video_on_d <= 1'b0;
        end else begin
            video_on_d <= video_on;
        end
    end

    assign h_sync = ((pixel_x < (H_FRONT_PORCH_TOTAL_COUNT)) || (pixel_x > (H_SYNC_PORCH_TOTAL_COUNT - 1))) ? 1'b1 : 1'b0;
    assign v_sync = ((pixel_y < (V_FRONT_PORCH_TOTAL_COUNT)) || (pixel_y > (V_SYNC_PORCH_TOTAL_COUNT - 1))) ? 1'b1 : 1'b0;

    assign video_on = ((pixel_x < H_ACTIVE) && (pixel_y < V_ACTIVE)) ? 1'b1 : 1'b0;

    assign row_done = (pixel_x == (H_BACK_PORCH_TOTAL_COUNT - 1)) ? 1'b1 : 1'b0;

endmodule