module pixel_rgb_gen #(
    parameter BPP = 8
)(
    clk,
    rstn,
    addr,
    rgb
);

    input clk;
    input rstn;

    input [18 : 0] addr;

    output reg [BPP - 1 : 0] rgb;

    reg [BPP - 1 : 0] img_mem [307199 : 0];

    initial begin
        $readmemh("img_hex.mem", img_mem);
    end

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            rgb <= {BPP{1'b0}};
        end else begin
            if(addr < 307200) begin
                rgb <= img_mem[addr];
            end else begin
                rgb <= {BPP{1'b0}};
            end
        end
    end

endmodule