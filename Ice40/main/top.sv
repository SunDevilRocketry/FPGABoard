// Board wrapper. Only place for SB_ primitives (w/ no sim model) so softcore_soc can be simulated.
module top (
    output wire led_red,
    output wire led_green,
    output wire led_blue,
    output wire spi_ssn, spi_mosi,  // pin 14 is also FT232H RXD (UART TX), muxed in softcore_soc
    inout  wire spi_sck,            // pin 15: flash SCK out, then FT232H TXD in (UART RX)
    input  wire spi_miso
);

    // 48 MHz internal osc / 4 = 12 MHz
    wire clk;
    wire [2:0] leds;
    wire sck_out, uart_rx, uart_mode;

    /* verilator lint_off PINMISSING */
    SB_HFOSC #(.CLKHF_DIV("0b10")) osc (
        .CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk)
    );
    /* verilator lint_on PINMISSING */

    softcore_soc soc_inst (
        .clk(clk), 
        .leds(leds),
        .spi_ssn(spi_ssn),
        .spi_sck(sck_out),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .uart_rx(uart_rx),
        .uart_tx(),
        .uart_mode(uart_mode)
    );

    // Pin 15 changes direction: driven as flash SCK during boot, released (pulled up) for UART RX after
    /* verilator lint_off PINMISSING */
    SB_IO #(
        .PIN_TYPE(6'b1010_01),  // output with enable, plain input
        .PULLUP(1'b1)
    ) sck_io (
        .PACKAGE_PIN(spi_sck),
        .OUTPUT_ENABLE(!uart_mode),
        .D_OUT_0(sck_out),
        .D_IN_0(uart_rx)
    );
    /* verilator lint_on PINMISSING */

    // LED pins are current sinks (driven through this block). leds[i] = 1 is ON
    SB_RGBA_DRV #(
        .CURRENT_MODE("0b1"),
        .RGB0_CURRENT("0b000001"),
        .RGB1_CURRENT("0b000001"),
        .RGB2_CURRENT("0b000001")
    ) rgb (
        .CURREN(1'b1), .RGBLEDEN(1'b1),
        .RGB0PWM(leds[0]), .RGB1PWM(leds[1]), .RGB2PWM(leds[2]),
        .RGB0(led_green), .RGB1(led_blue), .RGB2(led_red)
    );

endmodule