// Clocks the SoC and records the bus.

`timescale 1ns/1ps

module softcore_soc_tb;
    wire [2:0] leds;
    reg clk = 1'b0;

    wire cs;
    wire sck;
    wire mosi;
    reg miso = 1'b0;

    softcore_soc dut(
        .clk(clk),
        .leds(leds),
        .spi_ssn(cs),
        .spi_sck(sck),
        .spi_mosi(mosi),
        .spi_miso(miso)
        );

    always #5 clk = ~clk; // 100 MHz, not 12.

    initial begin
        $dumpvars(0, softcore_soc_tb); #6000;
        $finish;   
    end

    always @(posedge clk)
        if (dut.mem_valid && dut.mem_ready && |dut.mem_wstrb)
            $display("store addr=%h data=%h", dut.mem_addr, dut.mem_wdata);
endmodule