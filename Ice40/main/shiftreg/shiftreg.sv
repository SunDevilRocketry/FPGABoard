module shiftreg(
    input logic clk, reset, enable, bitin, input logic [15:0] bufout,

    output logic done, bitout, output logic [7:0] bufin, output logic [3:0] pcounter
);

    logic [7:0] sampleout;
    logic benable;
    //the dreg is to ensure after the reset, the first clock cycle does not start at 0, but rather 1
    //Look at count wire with *apio sim  shiftreg/shiftreg_tb.sv* for more info
    counter_neg #(4) timer (.clk(clk), .reset(reset), .enable(benable), .count(pcounter));
    dreg_neg #(1) buffer (.clk(clk), .reset(reset), .enable(enable), .in(enable), .out(benable));
    
    //if reset or clk goes high,
    always_ff @ (posedge reset or posedge clk) begin
        //if reset is high, we make inbuf 0
        if (reset) begin
            bufin <= '0;
            done <= '0;
        end
        //otherwise, we take the first 7 bits of bufin and add bitin
        else if (enable & (pcounter >= 7)) begin
            bufin <= {bufin[6:0], bitin};
            if (pcounter==4'd15) done <= 1;
        end
    end

    //when reset goes high or clk goes LOW,
    assign bitout = bufout[4'd15-pcounter];

endmodule


//Comments:
/*
If we have a clock, would just having the blocks be bufout[count] be more efficient? A shiftreg may be better for bitin, but
might be a lot for the bitout, especially with 3 seperate if statements. Worth simming later, but a good point for now.
*/