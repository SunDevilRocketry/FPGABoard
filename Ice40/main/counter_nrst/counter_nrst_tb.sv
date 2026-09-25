module counter_nrst_tb();

    logic reset; logic enable; logic clk; 
    logic [2:0] count;
    logic done;
    counter_nrst #(3) tester (.clk(clk), .enable(enable), .reset(reset), .count(count), .done(done));


    initial begin
        $dumpvars(0, counter_nrst_tb);
        clk = 1'b0; reset = 1'b1; enable = 1'b1; #5;
        clk = 1'b1; reset = 1'b0; enable = 1'b1; #5;
        repeat(40) begin
            clk = ~clk; #5;
        end
    end

endmodule
