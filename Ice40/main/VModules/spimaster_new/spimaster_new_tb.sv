//----------------------------------------------------------------------------//
// New SPI Module Testbench
// Last updated: 2026-10-18
//----------------------------------------------------------------------------//

`timescale 1ns/1ps
module spimaster_new_tb();

    logic clk, reset, start, MISO;
    logic [6:0] addr;

    logic busy, done, MOSI, SCLK, NCS;
    logic [7:0] rdata;

    logic dummytester;
    logic [15:0] dummy;
    logic [4:0] count;

    spimaster_new #(
        .CLK_HZ(12_000_000),
        .CLK_DIV(4),
        .N_BYTES(1),
        .CPOL(1'b0)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .addr(addr),
        .MISO(MISO),
        .busy(busy),
        .done(done),
        .rdata(rdata),
        .MOSI(MOSI),
        .SCLK(SCLK),
        .NCS(NCS)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Dummy sensor data
    assign dummy = 16'b0000000010110110;
    assign dummytester = (count < 16) ? dummy[15-count] : 1'b0;
    assign MISO = dummytester;

    // Simulated SPI slave
    always @(negedge SCLK or posedge NCS) begin
        if (NCS)
            count <= 0;
        else if (count < 15)
            count <= count + 1'b1;
    end

    initial begin
        $dumpvars(0, spimaster_new_tb);

        clk = 1'b0;
        reset = 1'b1;
        start = 1'b0;
        addr = 7'b0111010;
        count = 0;

        #20;
        reset = 1'b0;

        // First transaction
        #20;
        start = 1'b1;
        #10;
        start = 1'b0;

        // Wait for first transaction to finish
        wait(done == 1'b1);
        #10;

        if (rdata == 8'b10110110)
            $display("TEST 1 PASSED: rdata = %b", rdata);
        else
            $display("TEST 1 FAILED: rdata = %b", rdata);

        // Second transaction
        #100;
        addr = 7'b1100111;
        start = 1'b1;
        #10;
        start = 1'b0;

        wait(done == 1'b1);
        #10;

        if (rdata == 8'b10110110)
            $display("Test 2 passed:  rdata = %b", rdata);
        else
            $display("Test 2 failed: rdata = %b", rdata);
        #100;
        $finish;
    end

    // Timeout protection
    initial begin
        #10000;
        $display("ERROR: Simulation timeout");
        $finish;
    end

endmodule
