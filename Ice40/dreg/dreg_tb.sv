module dreg_tb();

    logic clk, reset, enable;
    logic [3:0] in;

    logic [3:0] out;

    dreg register (in, clk, enable, reset, out);

    initial begin
        $dumpvars(0, dreg_tb);
        clk = 1'b0; reset = 1'b1; enable = 1'b1; in = 4'd11; #5;
        clk = 1'b1; reset = 1'b1; enable = 1'b0; #5;
        clk = 1'b0; reset = 1'b0; #5;
        clk = 1'b1; reset = 1'b0; #5;
        clk = 1'b0; reset = 1'b0; #5;
        clk = 1'b1; reset = 1'b0; enable = 1'b1; #5;
        clk = 1'b0; reset = 1'b1; #5;
    end

endmodule