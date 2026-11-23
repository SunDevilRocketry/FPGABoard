// Clocks the SoC and records the bus.

`timescale 1ns/1ps

module softcore_soc_tb;
    wire [2:0] leds;
    reg clk = 1'b0;

    wire cs;
    wire sck;
    wire mosi;
    wire miso;
    wire uart_rx, uart_tx, uart_mode;
    integer errors = 0, tx_edges = 0;

    spiflash flash (
        .csb(cs),
        .clk(sck),
        .io0(mosi),
        .io1(miso),
        .io2(),
        .io3()
    );

    softcore_soc dut(
        .clk(clk),
        .leds(leds),
        .spi_ssn(cs),
        .spi_sck(sck),
        .spi_mosi(mosi),
        .spi_miso(miso),
        .uart_rx(1'b1),
        .uart_tx(uart_tx),
        .uart_mode(uart_mode)
        );

    always #5 clk = ~clk; // 100 MHz, not 12.

    initial begin
        $dumpvars(0, softcore_soc_tb); #450000;   // divider 1250: ~125 us per char
        if (!uart_mode)    begin $display("FAIL: app never set uart_mode"); errors = errors + 1; end
        if (tx_edges == 0) begin $display("FAIL: no UART output on pin 14"); errors = errors + 1; end
        if (errors == 0) $display("PASS: pins 14/15 handed to the UART, %0d edges on pin 14", tx_edges);
        $finish;
    end

    always @(posedge clk)
        if (dut.mem_valid && dut.mem_ready && |dut.mem_wstrb)
            $display("store addr=%h data=%h", dut.mem_addr, dut.mem_wdata);

    // Once uart_mode is set -> flash remains deselected
    always @(posedge clk)
        if (uart_mode) begin
            if (!cs)                 begin $display("FAIL %t: flash selected in UART mode", $time); errors = errors + 1; end
            if (mosi !== uart_tx)    begin $display("FAIL %t: pin 14 != uart_tx", $time); errors = errors + 1; end
            if (dut.flash_valid)     begin $display("FAIL %t: flash access in UART mode", $time); errors = errors + 1; end
        end
    always @(negedge mosi) if (uart_mode) tx_edges = tx_edges + 1;
endmodule