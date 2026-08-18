module counter #(
    parameter bits=4
) (
    input logic clk, input logic reset, input logic enable,

    output logic [bits-1:0] count
);

    //localdefs
    localparam [bits-1:0] ZERO = 'b0;
    localparam [bits-1:0] ONE = 'b1;

    //on the rising clock edge, increment by one
    //otherwise reset
    //this depends on overflowing to create a constant 0-7 loop
    always_ff @ (posedge clk or posedge reset) begin
        if (reset)
            count <= ZERO;
        else if (enable)
            count <= count + ONE;
    end
endmodule