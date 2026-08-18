module shiftreg_tb();

    logic clk, reset, enable, bitin;
    logic [7:0] bufout;

    logic done, bitout, dummytester, benable;
    logic [7:0] bufin;
    logic[15:0] dummy;

    logic [3:0] count;

    shiftreg tester (.clk(clk), .enable(enable), .reset(reset), .bitin(dummy['d15-count]), .bufout(bufout), .done(done), .bitout(bitout), .bufin(bufin));
    counter #(4) timerbuf (.clk(~clk), .enable(benable), .reset(reset), .count(count));
    dreg #(1) buffer (.clk(clk), .reset(reset), .enable(enable), .in(enable), .out(benable));


    assign dummy = 16'b0000000010110110;
    assign dummytester = dummy['d15-count];

    initial begin
        $dumpvars(0, shiftreg_tb);
        clk = 1'b0; reset = 1'b1; enable = 1'b1; bufout = 8'b10010001; #5;
        clk = 1'b1; reset = 1'b1; enable = 1'b1; #5;
        clk = 1'b0; reset = 1'b0; #5;
        repeat(40) begin
            clk = ~clk; #5;
        end
    end

endmodule