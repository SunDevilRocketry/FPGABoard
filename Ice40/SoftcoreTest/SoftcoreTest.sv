// Board wrapper. Only place for SB_ primitives so softcore_soc can be simulated.
module SoftcoreTest (
    output wire led_red,
    output wire led_green,
    output wire led_blue
);

    // 48 MHz internal osc / 4 = 12 MHz
    wire clk;
    wire [2:0] leds;

    SB_HFOSC #(.CLKHF_DIV("0b10")) osc (
        .CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk)
    );

    softcore_soc soc_inst (
        .clk(clk), 
        .leds(leds)
    );

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