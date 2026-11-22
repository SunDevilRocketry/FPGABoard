//counts to maxval, resets
module count_up_to 
#(
	parameter N=16
) 
(
	input [N-1:0] maxval, input clk, rst,
	
	output logic [N-1:0] count
);
logic [N-1:0] ncount; 
assign ncount = (count < maxval - 1'b1) ? count + 1'b1 : '0;
always_ff @(posedge clk or posedge rst)
	if(rst)
		count <= '0;
	else
		count <= ncount;	
endmodule