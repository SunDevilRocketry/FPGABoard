module shiftreg(
    input logic clk, reset, enable, bitin, input logic [7:0] bufout,

    output logic done, bitout, output logic [7:0] bufin, output logic [2:0] pcounter
);

    logic [7:0] sampleout;
    logic benable;
    logic [2:0] check;
    assign check = 3'd7-pcounter;
    //the dreg is to ensure after the reset, the first clock cycle does not start at 0, but rather 1
    //Look at count wire with *apio sim  shiftreg/shiftreg_tb.sv* for more info
    counter_neg #(3) timer (.clk(clk), .reset(reset), .enable(benable), .count(pcounter));
    dreg_neg #(1) buffer (.clk(clk), .reset(reset), .enable(enable), .in(enable), .out(benable));
    assign done = pcounter == 3'd7;
    
    //if reset or clk goes high,
    always_ff @ (posedge reset or posedge clk) begin
        //if reset is high, we make inbuf 0
        if (reset) begin
            bufin <= '0;
        end
        //otherwise, we take the first 7 bits of bufin and add bitin
        else if (enable) begin
            bufin <= {bufin[6:0], bitin};
        end
    end

    //when reset goes high or clk goes LOW,
    always_ff @ (posedge reset or negedge clk) begin
        //if reset is high, get a new out buffer
        if (reset) begin
            sampleout <= bufout;
        end
        //otherwise if enable is high,
        else if (enable) begin
            //if done is high, get a new sample and bit out from the bufout
            bitout = bufout[check];
        end
    end
endmodule


//Comments:
/*
If we have a clock, would just having the blocks be bufout[count] be more efficient? A shiftreg may be better for bitin, but
might be a lot for the bitout, especially with 3 seperate if statements. Worth simming later, but a good point for now.
*/