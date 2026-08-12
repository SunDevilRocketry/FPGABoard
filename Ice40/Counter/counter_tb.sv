module counter_tb();

    logic reset; logic enable; logic clk; 
    logic [2:0] count;

    counter #(3) tester (.clk(clk), .enable(enable), .reset(reset), .count(count));


    initial begin
        $dumpvars(0, counter_tb);
        clk = 1'b0; reset = 1'b1; enable = 1'b1; #5;
        clk = 1'b1; reset = 1'b0; enable = 1'b1; #5;
        repeat(20) begin
            clk = ~clk; #5;
        end
    end

endmodule