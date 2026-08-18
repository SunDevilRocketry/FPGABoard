module shiftreg(
    input logic clk, reset, enable, bitin, input logic [7:0] bufout,

    output logic done, bitout, output logic [7:0] bufin
);

    logic [2:0] count;
    logic [7:0] sampleout;
    logic benable;
    //the dreg is to ensure after the reset, the first clock cycle does not start at 0, but rather 1
    //Look at count wire with *apio sim  shiftreg/shiftreg_tb.sv* for more info
    counter #(3) timer (.clk(clk), .reset(reset), .enable(benable), .count(count));
    dreg #(1) buffer (.clk(clk), .reset(reset), .enable(enable), .in(enable), .out(benable));
    assign done = count == 3'd7;
    
    //on the rising clock edge, we sample the input
    always_ff @ (posedge reset or posedge clk) begin
        if (reset) begin
            bufin <= '0;
        end
        else if (enable) begin
            bufin <= {bufin[6:0], bitin};
        end
    end

    //on the falling clock edge, we set our outputs to be sampled
    always_ff @ (posedge reset or negedge clk or negedge done) begin
        if (reset | done) begin
            sampleout = bufout;
        end
        else if (enable) begin
            sampleout <= {sampleout[6:0], '0};
            bitout <= sampleout[7];
        end
    end
endmodule