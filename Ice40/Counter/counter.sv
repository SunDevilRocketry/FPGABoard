module counter #(
    parameter bits=4
) (
    input logic clk, input logic reset, input logic enable,

    output logic [bits-1:0] count
);

    localparam [bits-1:0] ZERO = 'b0;
    localparam [bits-1:0] ONE = 'b1;

    always_ff @ (posedge clk or posedge reset) begin
        if (reset)
            count <= ZERO;
        else if (enable)
            count <= count + ONE;
    end
endmodule