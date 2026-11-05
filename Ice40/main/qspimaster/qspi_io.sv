// qspi_io.sv - generic tri-state pad wrapper for qspi_master
// use this module in the top level 
module qspi_io (
  input logic [3:0] io_o,
  input logic [3:0] io_oe,
  output logic [3:0] io_i,
  inout wire [3:0] io_pad
);
  genvar g;
  generate
    for (g = 0; g < 4; g++) begin : g_pad
      assign io_pad[g] = io_oe[g] ? io_o[g] : 1'bz;
    end
  endgenerate
  assign io_i = io_pad;
endmodule
