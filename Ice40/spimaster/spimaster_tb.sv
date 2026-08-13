module spimaster_tb();

    logic clk, reset, enable, MISO;
    logic [7:0] address, writedata;

    logic dataready, MOSI, dummytester;
    logic [7:0] read;
    logic[15:0] dummy;

    logic [3:0] count;

    spimaster uut (clk, enable, reset, MISO, address, writedata, read, dataready, MOSI);
    counter #(4) timerbuf (.clk(~clk), .enable(enable), .reset(reset), .count(count));

    assign dummy = 16'b0000000010110110;
    assign dummytester = dummy['d15-count];
    assign writedata = 8'b10010111;
    assign address = 8'b10111010;
    assign MISO = dummytester;

    initial begin
        $dumpvars(0, spimaster_tb);
        clk = 1'b0; reset = 1'b1; enable = 1'b1; #5;
        clk = 1'b1; reset = 1'b1; enable = 1'b1; #5;
        clk = 1'b0; reset = 1'b0; #5;
        repeat(40) begin
            clk = ~clk; #5;
        end
    end

endmodule