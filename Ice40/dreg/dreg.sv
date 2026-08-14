module dreg #(parameter bits = 4) (
    input logic [bits-1:0] in, input logic clk, enable, reset,

    output logic [bits-1:0] out
);
    always_ff @ (posedge clk or posedge reset) begin
        if (reset)
            out <= '0;
        else if (enable)
            out <= in;
    end
endmodule