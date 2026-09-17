//spimaster is kinda misleading, this is more of a spi reader that someone tried to have write too

module spimaster #(parameter clkscale = 4) (
    input logic clk, enable, reset, MISO, ready, input logic [7:0] address, writedata, 

    output logic [7:0] read, output logic dataready, MOSI, SCLK, NCS
);

    //shorthands for address state and readwrite state
    localparam IDLE = 1'b0, RW = 1'b1;

    //out, switches between writing address and data
    logic [7:0] IN;
    logic [15:0] OUT;

    //state machine stuff
    logic state, nextstate;
    logic done, cdone, ccdone;
    logic [3:0] pcounter, pncounter;

    //While idle, set NCS high
    assign NCS = (state == IDLE)?(1'b1):(1'b0);

    //using the clk scale parameter, generate a signal that scales down the sclk by that amount
    //$clog2 returns ceil log2(x), so in the default case where clkscale = 4, returns 2
    logic [$clog2(clkscale)-1:0] SCLKCount;
    counter #($clog2(clkscale)) SCLKOut (.clk(clk), .reset(reset | (SCLKCount == clkscale)), .enable(enable), .count(SCLKCount));

    //when the count hits the scalar, flip SCLK
    always_ff @ (posedge clk or posedge reset) begin
        if (reset | NCS) SCLK <= '0;
        else if (SCLKCount == (clkscale-1)) SCLK <= ~SCLK;
    end

    //data is ready when done is high
    assign dataready = done;

    //the classic
    shiftreg shifter (.clk(SCLK), .reset(reset | state==IDLE), .enable(enable & (state == RW)), .bitin(MISO), .bufout(OUT), .done(done), .bitout(MOSI), .bufin(IN), .pcounter(pcounter), .cdone(cdone));
    //when data is ready, save the output by trapping it in a dreg
    dreg #(8) readdata (.clk(dataready), .enable(1'b1), .reset(reset), .in(IN), .out(read));
    //state machine, when done with one, start doing the other. Goes forever bar enable and reset
    always_comb begin
        //always reset to a known value in comb code
        nextstate = IDLE;
        OUT = '0;
        //state switch method
        //a case is just a switch, you cs know this one
        //change to unique case later? linter hates it for some reason
        case (state)
            IDLE: nextstate = (ready)?RW:IDLE;
            //this isn't good behavior. A proper cycle of the SCLK has 6 normal clock cycles.
            //this takes 5 for the cycle, slightly cutting off the end. This will probably be safe due to scaling inaccuracies, 
            //but is definately something to change in the future.
            //for calc, the low period is (n-1) clk cycles
            RW: nextstate = (cdone&(SCLKCount==clkscale-1))?IDLE:RW;
            default: nextstate = IDLE;
        endcase

        //output selection method
        case (state)
            RW: OUT = {1'b1, address[6:0], writedata};
            IDLE: OUT = '0;
            default: OUT = '0;
        endcase
    end

    //on clock cycle, change state
    //after research, nededge works better! Prob cuz pcounter is a negedge clk anyway
    always_ff @ (negedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end
        else if (enable) begin
            state <= nextstate;
        end
    end
endmodule