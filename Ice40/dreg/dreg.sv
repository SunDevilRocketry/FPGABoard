//Module Dreg with parameter bits, inputs in, clk, enable, reset, and output out
module dreg #(parameter bits = 4) (
    input logic [bits-1:0] in, input logic clk, enable, reset,

    output logic [bits-1:0] out
);
    //when clk or reset goes HIGH,
    always_ff @ (posedge clk or posedge reset) begin
        //if reset is high, out becomes 0
        if (reset)
            out <= '0;
        //if reset is not high and enable is, output the input value
        else if (enable)
            out <= in;
    end
endmodule