//Module for framing data packets into the SPI

/*
Timestamp: 64 bit timecount               = 64 bit
IMU:       48 bit acc + 48 bit gyro       = 96 bit
BARO:      24 bit pressure + 24 bit temp  = 48 bit
---------------------------------------------------
Total:                                    = 208 bit
Rounding:                                 = 256 bit
*/

/*
IDLE:     1kHz
LAUNCH:   1kHz
COAST:    1kHz
APOGEE:   500Hz
DESCENT:  500Hz
LANDED:   0Hz
*/
module framer 
#(
    parameter int CLK_HZ = 12_000_000,
    parameter int FAST_RATE = 1_000,
    parameter int SLOW_RATE = 500
)
(
    input logic [255:0] datain, 
    input logic [2:0] state,
    input logic enable, reset, clk,

    output logic ready,
    output logic [255:0] dataout
);

    function automatic int hz2count(input int hz);
        hz2count = (CLK_HZ + (hz - 1)) / hz;
    endfunction

    typedef enum logic [2:0]  {
        IDLE, LAUNCH, COAST, APOGEE, DESCENT, LANDED
    } state_type;

    localparam MAXBIT = $clog2(hz2count(SLOW_RATE));

    logic [MAXBIT-1:0] maxval, count;
    logic tick;
    
    count_up_to #(MAXBIT) counter (
        .maxval(maxval), .clk(clk), .rst(reset), .count(count)
    );

    dreg #(256) saver (
        .in(datain), .clk(clk), .enable(tick), .reset(reset), 

        .out(dataout)
    );

    assign tick = (count == maxval) && (state != LANDED) && (enable);

    assign maxval = (state == IDLE || state == LAUNCH || state == COAST) ? MAXBIT'(hz2count(FAST_RATE) - 1) : 
                        (state == APOGEE || state == DESCENT) ? MAXBIT'(hz2count(SLOW_RATE) - 1): 
                            '0;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            ready <= '0;
        else
            ready <= tick;
    end

endmodule