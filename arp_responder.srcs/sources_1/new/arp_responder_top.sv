`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Personal Project
// Engineer: Michael Fernandez
// 
// Create Date: 08/06/2021 06:04:05 PM
// Module Name: arp_responder_top
// Description: Top Level of Arp Respondere Module. 
//              Was going for most readable code in this project, could probabaly improve a cycle or two here or there. 
//              
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
import arp_pkg::*;

module arp_responder_top(
    input wire          ARESET,
    input wire [47:0]   MY_MAC,
    input wire [31:0]   MY_IPV4,
    
    input wire          CLK_RX,
    input wire          DATA_VALID_RX,
    input wire [7:0]    DATA_RX,
    
    input wire          CLK_TX,
    output logic        DATA_VALID_TX,
    output logic [7:0]  DATA_TX,
    input wire          DATA_ACK_TX
);

logic rst_rx;
logic rst_tx;
addr_t address_rx;
addr_t address_tx;
logic address_rx_valid;
logic address_tx_available_n;
logic address_tx_available;
logic responce_generator_start;


    reset_sync reset_sync_rx(
        .clk(CLK_RX),
        .reset_i(ARESET),
        .reset_o(rst_rx)
    );
    reset_sync reset_sync_tx(
        .clk(CLK_TX),
        .reset_i(ARESET),
        .reset_o(rst_tx)
    );    
    
    arp_parser arp_parser_inst (
        .clk(CLK_RX),
        .rst(rst_rx),
        .data(DATA_RX),
        .data_valid(DATA_VALID_RX),
        .*
    );
    
    clock_crossing_arp_fifo clock_crossing_arp_fifo_inst (
        .wr_clk(CLK_RX),
        .wr_rst(rst_rx),
        .rd_clk(CLK_TX),
        .rd_rst(rst_tx),
        .din(address_rx),
        .wr_en(address_rx_valid),
        .rd_en(responce_generator_start),
        .dout(address_tx),
        .full(),
        .empty(address_tx_available_n)
    );
    
    always_comb address_tx_available = !address_tx_available_n;
    
    arp_response_generator arp_response_generator_inst(
        .clk(CLK_TX),
        .rst(rst_tx),
        .data_out(DATA_TX),
        .data_out_valid(DATA_VALID_TX),
        .*   
    );
    
    
endmodule
