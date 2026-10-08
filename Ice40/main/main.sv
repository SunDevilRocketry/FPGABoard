module main (
    input logic MOSI_MCU, SCLK_MCU, NCS_MCU, MISO_CHIP,
    
    output logic MOSI_CHIP, SCLK_CHIP, NCS_CHIP, MISO_MCU
    );
    assign MOSI_CHIP = MOSI_MCU;
    assign MISO_MCU = MISO_CHIP;
    assign SCLK_CHIP = SCLK_MCU;
    assign NCS_CHIP = NCS_MCU;

endmodule