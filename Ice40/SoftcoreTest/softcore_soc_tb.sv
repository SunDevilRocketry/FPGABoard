// Clocks the SoC and records the bus.

`timescale 1ns/1ps

module softcore_soc_tb;
    wire [2:0] leds;
    reg clk = 1'b0;

    softcore_soc dut(.clk(clk), .leds(leds));

    always #5 clk = ~clk; // 100 MHz, not 12.

    initial begin
        $dumpvars(0, softcore_soc_tb); #3000;
        $finish;
    end
endmodule