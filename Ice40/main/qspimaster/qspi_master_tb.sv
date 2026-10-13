// ======================================================================================= // 
// testbench for qspi_master
// 
// ======================================================================================= // 

`timescale 1ns/1ps
module qspi_master_tb;
    localparam logic [1:0] OP_TX = 2'b00;
    localparam logic [1:0] OP_RX = 2'b01;
    localparam logic [1:0] OP_DUMMY = 2'b10;

    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    logic [7:0] clk_div = 0;
    logic late_sample = 0;
    logic cmd_valid = 0, cmd_last = 0;
    logic [7:0] cmd_data = 0;
    logic [1:0] cmd_width = 0, cmd_op = 0;
    logic cmd_ready, rx_valid, busy, sclk, cs_n;
    logic [7:0] rx_data;
    logic [3:0] io_o, io_oe;
    logic [3:0] io_i;

    // instantiate the qspi_master module
    qspi_master qspi_master_inst (
        .clk(clk), .rst_n(rst_n), .clk_div(clk_div), .late_sample(late_sample),
        .cmd_valid(cmd_valid), .cmd_ready(cmd_ready), .cmd_data(cmd_data),
        .cmd_width(cmd_width), .cmd_op(cmd_op), .cmd_last(cmd_last),
        .rx_valid(rx_valid), .rx_data(rx_data), .busy(busy),
        .sclk(sclk), .cs_n(cs_n), .io_o(io_o), .io_oe(io_oe), .io_i(io_i)
    );

    // i need a moment to think about this 
    