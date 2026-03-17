module clk_gen_tb ();

    parameter INPUT_CLK_FREQ_MHz = 100;

    parameter CLK_PERIOD = (1000 / INPUT_CLK_FREQ_MHz);
    
    logic clk;
    logic rst_n;
    
    logic clk_25_MHz_out;

    clk_gen #(
        .INPUT_CLK_FREQ_MHz(INPUT_CLK_FREQ_MHz)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .clk_25_MHz_out(clk_25_MHz_out)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #(CLK_PERIOD / 2) clk = ~clk;
        end
    end

    initial begin
        rst_n = 1'b0;
        repeat(5) @(negedge clk);

        rst_n = 1'b1;
        repeat(50) @(negedge clk);

        $stop;
    end

endmodule