module spimaster_tb();

    logic clk, reset, enable, MISO, ready;
    logic [7:0] address, writedata;

    logic dataready, MOSI, dummytester, benable, SCLK, NCS;
    logic [7:0] read;
    logic[15:0] dummy;

    logic [3:0] count;

    spimaster uut (clk, enable, reset, MISO, ready, address, writedata, read, dataready, MOSI, SCLK, NCS);
    counter #(4) timerbuf (.clk(~clk), .enable(benable), .reset(reset), .count(count));
    dreg #(1) buffer (.clk(clk), .reset(reset), .enable(enable), .in(enable), .out(benable));


    assign dummy = 16'b0000000010110110;
    assign dummytester = dummy['d15-count];
    assign writedata = 8'b10010111;
    assign address = 8'b10111010;
    assign MISO = dummytester;

    initial begin
        $dumpvars(0, spimaster_tb);
        clk = 1'b0; reset = 1'b1; enable = 1'b1; ready = 1'b0; #5;
        clk = 1'b1; reset = 1'b1; enable = 1'b1; #5;
        clk = 1'b0; reset = 1'b0; #5;
        repeat(40) begin
            clk = ~clk; #5;
        end
    end

endmodule