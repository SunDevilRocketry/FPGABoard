module shiftreg_tb();

    logic clk, reset, enable, bitin;
    logic [7:0] bufout;

    logic done, bitout, dummytester;
    logic [7:0] bufin;
    logic[15:0] dummy;

    logic [3:0] count;

    shiftreg tester (.clk(clk), .enable(enable), .reset(reset), .bitin(dummy[count]), .bufout(bufout), .done(done), .bitout(bitout), .bufin(bufin));
    counter #(4) timerbuf (.clk(~clk), .enable(enable), .reset(reset), .count(count));

    assign dummy = 16'b0000000010101010;
    assign dummytester = dummy[count];

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