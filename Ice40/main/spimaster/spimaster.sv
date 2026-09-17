//spimaster is kinda misleading, this is more of a spi reader that someone tried to have write too

module spimaster #(parameter clkscale = 4) (
    input logic  clk, enable, reset, MISO, input logic [7:0] address, writedata,

    output logic [7:0] read, output logic dataready, MOSI, SCLK, NCS
);

    //shorthands for address state and readwrite state
    localparam ADDR = 2'd0, RW = 2'd1, IDLE = 2'd2;

    //out, switches between writing address and data
    logic [7:0] OUT, IN;

    //state machine stuff
    logic [1:0] state, nextstate;
    logic done;
    logic [2:0] pcounter;

    //lower NCS when were not in idle
    //Due to timing requirements, a delay on actual operation may need to take place to ensure NCS setup time
    //currently, 
    assign NCS = (state == IDLE)?(1'b1):(1'b0);

    //using the clk scale parameter, generate a signal that scales down the sclk by that amount
    //$clog2 returns log2(x), so in the default case where clkscale = 4, returns 2
    logic [$clog2(clkscale)-1:0] SCLKCount;
    counter #($clog2(clkscale)) SCLKOut (.clk(clk), .reset(reset), .enable(enable), .count(SCLKCount));
    assign SCLK = (SCLKCount == '1);

    //data is ready when done is high and state is RW
    //basically when done in the RW state SOMETHING is finished
    //readwrite agnostic code may or may not kill me later on 
    assign dataready = done & (state == IDLE);

    //the classic
    shiftreg shifter (.clk(clk), .reset(reset), .enable(enable), .bitin(MISO), .bufout(OUT), .done(done), .bitout(MOSI), .bufin(IN), .pcounter(pcounter));
    //when data is ready, save the output by trapping it in a dreg
    dreg #(8) readdata (.clk(dataready), .enable(1'b1), .reset(reset), .in(IN), .out(read));

    //state machine, when done with one, start doing the other. Goes forever bar enable and reset
    always_comb begin
        //always reset to a known value in comb code
        nextstate = ADDR;
        OUT = '0;
        //state switch method
        //a case is just a switch, you cs know this one
        //change to unique case later? linter hates it for some reason
        case (state)
            ADDR: nextstate = (pcounter==3'd6)?RW:ADDR;
            RW: nextstate = (pcounter==3'd6)?IDLE:RW;
            IDLE: nextstate = (enable&&NCS)?ADDR:IDLE;
            default: nextstate = ADDR;
        endcase

        //output selection method
        case (state)
            ADDR: OUT = address;
            RW: OUT = writedata;
            IDLE: OUT = '0;
            default: OUT = address;
        endcase
    end

    //on clock cycle, change state
    //why is this negedge? am I tweaking?
    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            state <= ADDR;
        end
        else if (enable) begin
            state <= nextstate;
        end
    end
endmodule