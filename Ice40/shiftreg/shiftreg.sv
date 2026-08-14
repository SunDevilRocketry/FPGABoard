module shiftreg(
    input logic clk, reset, enable, bitin, input logic [7:0] bufout,

    output logic done, bitout, output logic [7:0] bufin
);

    logic [2:0] count;
    //the positive timer is used to update bitout count on the pos clock edge, so its ready to be adjusted when neg clock edge
    //the negative timer is used for the counter for bitin, so the count is ready when clockedge goes high to sample. 
    counter #(3) timer (.clk(clk), .reset(reset), .enable(enable), .count(count));
    assign done = count == 3'd7;
    
    //on the rising clock edge, we sample the input
    always_ff @ (posedge reset or posedge clk) begin
        if (reset) begin
            bufin <= '0;
        end
        else if (enable) begin
            bufin[3'd7-count] <= bitin;
        end
    end

    //on the falling clock edge, we set our outputs to be sampled
    always_ff @ (posedge reset or negedge clk) begin
        if (reset) begin
            bitout <= bufout[3'd7-count];
        end
        else if (enable) begin
            bitout <= bufout[3'd7-count];
        end
    end
endmodule