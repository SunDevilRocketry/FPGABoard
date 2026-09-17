//spimaster is kinda misleading, this is more of a spi reader that someone tried to have write too

module spimaster #(parameter clkscale = 4) (
    input logic clk, enable, reset, MISO, ready, input logic [7:0] address, writedata, 

    output logic [7:0] read, output logic dataready, MOSI, SCLK, NCS
);

    //shorthands for address state and readwrite state
    localparam RW = 1'b0, IDLE = 1'b1;

    //out, switches between writing address and data
    logic [7:0] IN;
    logic [15:0] OUT;

    //state machine stuff
    logic state, nextstate;
    logic done;
    logic [3:0] pcounter;

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
    assign dataready = done;

    //the classic
    shiftreg shifter (.clk(clk), .reset(reset), .enable(enable), .bitin(MISO), .bufout(OUT), .done(done), .bitout(MOSI), .bufin(IN), .pcounter(pcounter));
    //when data is ready, save the output by trapping it in a dreg
    dreg #(8) readdata (.clk(dataready), .enable(1'b1), .reset(reset), .in(IN), .out(read));

    //state machine, when done with one, start doing the other. Goes forever bar enable and reset
    always_comb begin
        //always reset to a known value in comb code
        nextstate = RW;
        OUT = '0;
        //state switch method
        //a case is just a switch, you cs know this one
        //change to unique case later? linter hates it for some reason
        case (state)
            RW: nextstate = (dataready)?IDLE:RW;
            IDLE: nextstate = (ready)?RW:IDLE;
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
    //why is this negedge? am I tweaking?
    always_ff @ (negedge clk or posedge reset) begin
        if (reset) begin
            state <= RW;
        end
        else if (enable) begin
            state <= nextstate;
        end
    end
endmodule