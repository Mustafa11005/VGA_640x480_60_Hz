module clk_gen #(
    parameter INPUT_CLK_FREQ_MHZ = 25
)(
    input clk,
    input rstn,

    output reg clk_25_MHz_out
);

    localparam VALID_PARAM  = (INPUT_CLK_FREQ_MHZ >= 50) && ((INPUT_CLK_FREQ_MHZ % 50) == 0);

    localparam TOGGLE_COUNT = VALID_PARAM ? (INPUT_CLK_FREQ_MHZ / 50) : 1;
    
    localparam COUNTER_WIDTH = (TOGGLE_COUNT > 1) ? $clog2(TOGGLE_COUNT) : 1;

    reg [COUNTER_WIDTH - 1 : 0] counter;


    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin

            clk_25_MHz_out <= 1'b0;

            counter <= {COUNTER_WIDTH{1'b0}};

        end else if (!VALID_PARAM) begin
            
            clk_25_MHz_out <= 1'b0;
            
            counter <= {COUNTER_WIDTH{1'b0}};

        end else if (counter == (TOGGLE_COUNT - 1)) begin
            
            clk_25_MHz_out <= ~clk_25_MHz_out;
            
            counter <= {COUNTER_WIDTH{1'b0}};

        end else begin
            
            counter <= counter + 1;

        end
    end
    
endmodule