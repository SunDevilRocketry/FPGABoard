module spimaster (
    input logic  clk, enable, reset, MISO, input logic [7:0] address, writedata,

    output logic [7:0] read, output logic dataready, MOSI
);

    //shorthands for address state and readwrite state
    localparam ADDR = 1'b0, RW = 1'b1;

    //out, switches between writing address and data
    logic [7:0] OUT, IN;
    //state machine stuff
    logic state, nextstate, done;

    //based on the state change the data were outputting
    assign OUT = (state)?(writedata):(address);
    //data is ready when done is high and state is 1, so RW
    //basically when done in the RW state SOMETHING is finished
    //readwrite agnostic code may or may not kill me later on 
    assign dataready = done & state;

    //the classic
    shiftreg shifter (.clk(clk), .reset(reset), .enable(enable), .bitin(MISO), .bufout(OUT), .done(done), .bitout(MOSI), .bufin(IN));
    //when data is ready, save the output by trapping it in a dreg
    dreg #(8) readdata (.clk(clk), .enable(dataready), .reset(reset), .in(IN), .out(read));

    //state machine, when done with one, start doing the other. Goes forever bar enable and reset
    always_comb begin
        nextstate = ADDR;
        case (state)
            ADDR: nextstate = (done)?RW:ADDR;
            RW: nextstate = (done)?ADDR:RW;
        endcase
    end

    //on clock cycle, change state
    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            state <= ADDR;
        end
        else if (enable) begin
            state <= nextstate;
        end
    end
endmodule