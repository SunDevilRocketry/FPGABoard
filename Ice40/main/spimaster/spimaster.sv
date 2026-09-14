module spimaster (
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

    //lower NCS when were not in idle
    //Due to timing requirements, a delay on actual operation may need to take place to ensure NCS setup time
    assign NCS = (state == IDLE)?(1'b1):(1'b0);

    //for now SCLK output is just the normal clock, Ill fix this when the hardware stops working
    assign SCLK = clk;

    //data is ready when done is high and state is RW
    //basically when done in the RW state SOMETHING is finished
    //readwrite agnostic code may or may not kill me later on 
    assign dataready = done & (state == RW);

    //the classic
    shiftreg shifter (.clk(clk), .reset(reset), .enable(enable), .bitin(MISO), .bufout(OUT), .done(done), .bitout(MOSI), .bufin(IN));
    //when data is ready, save the output by trapping it in a dreg
    dreg #(8) readdata (.clk(dataready), .enable(1'b1), .reset(reset), .in(IN), .out(read));

    //state machine, when done with one, start doing the other. Goes forever bar enable and reset
    always_comb begin
        //always reset to a known value in comb code
        nextstate = ADDR;
        OUT = '0;
        //state switch method
        //a case is just a switch, you cs know this one
        //a unique case means only check for these values, no other value is possible
        // ^ = tell the compiler "trust me bro"
        //allows for more optimization! 
        unique case (state)
            ADDR: nextstate = (done)?RW:ADDR;
            RW: nextstate = (done)?IDLE:RW;
            IDLE: nextstate = enable?ADDR:IDLE;
        endcase

        //output selection method
        unique case (state)
            ADDR: OUT = address;
            RW: OUT = writedata;
            IDLE: OUT = '0;
        endcase
    end

    //on clock cycle, change state
    always_ff @ (negedge clk or posedge reset) begin
        if (reset) begin
            state <= ADDR;
        end
        else if (enable) begin
            state <= nextstate;
        end
    end
endmodule