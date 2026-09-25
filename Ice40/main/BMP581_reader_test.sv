module BMP581_reader_test (input wire MISO, output wire MOSI, SCLK, NCS, led_green, led_blue, led_red);

    //Lattice premade OSC block connected to clk, think this is like 48MHz?
    wire clk;
    SB_HFOSC HIGH_FREQ_OSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

    //SPIblock inbetweens
    //INs
    logic enable, reset, ready;
    logic [7:0] addy, writedata;

    //OUTs
    logic dataready;
    logic [7:0] read;

    assign addy = 8'h01;
    assign ready = ~(read == 8'b01010000);

    spimaster #(6) TALKER (.clk(clk), .enable(1'b1), .reset(1'b0), .MISO(MISO), .ready(ready), .address(addy), .writedata(8'd0), 

    .read(read), .dataready(dataready), .MOSI(MOSI), .SCLK(SCLK), .NCS(NCS));


    //ch0 is green, ch2 is red
    SB_RGBA_DRV #(
        .CURRENT_MODE("0b1"), //0b0 is full, 0b1 is half
        .RGB0_CURRENT("0b000001"), //like 1mA ish
        .RGB1_CURRENT("0b000001"),
        .RGB2_CURRENT("0b000001")
    ) RGB_DRIVER (
        .RGBLEDEN(1'b1                  ), //enable LEDS
        .RGB0PWM (read == 8'b01010000   ), //green if read = chip code of the BMI581 at red 0x01
        .RGB1PWM (1'b0                  ), //never turn on blue
        .RGB2PWM (~(read == 8'b01010000)), // red if read != chip code
        .CURREN  (1'b1                  ), //enable internal current ref
        .RGB0    (led_green             ), //Actual Hardware connection
        .RGB1    (led_blue              ),
        .RGB2    (led_red               )
    );



endmodule


/*
module spimaster #(parameter clkscale = 4) (
    input logic clk, enable, reset, MISO, ready, input logic [7:0] address, writedata, 

    output logic [7:0] read, output logic dataready, MOSI, SCLK, NCS
);

*/
