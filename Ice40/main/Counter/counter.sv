//module counter with inputs clk, reset, enable, and output count
module counter #(
    parameter bits=4
) (
    input logic clk, input logic reset, input logic enable,

    output logic [bits-1:0] count
);

    //localdefs
    localparam [bits-1:0] ZERO = 'b0;
    localparam [bits-1:0] ONE = 'b1;

    //when clk or reset goes HIGH,
    always_ff @ (posedge clk or posedge reset) begin
        //if reset is high, output ZERO
        if (reset)
            count <= ZERO;
        //otherwise, if enable is high, output the old COUNT plus one
        else if (enable)
            count <= count + ONE;
    end
endmodule