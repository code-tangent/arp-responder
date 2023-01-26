`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Personal Project
// Engineer: Michael Fernandez
// 
// Create Date: 08/07/2021 06:44:59 PM
// Module Name: arp_response_generator
// Description: Takes parsed mac and ip and sends responce msg using my_mac and my_ipv4.   
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
import arp_pkg::*;

module arp_response_generator(
	input wire clk,
	input wire rst,
	input wire address_tx_available,
	input addr_t address_tx,

	input wire [47:0]   MY_MAC,
	input wire [31:0]   MY_IPV4,
	input wire DATA_ACK_TX,

	output logic responce_generator_start,
	output logic [7:0] data_out,
	output logic data_out_valid
);
    
packet_t packet = 0;
logic [15:0] byte_counter = 0;
arp_responder_state_t state, next_state;   


    always_ff @(posedge clk)
        if(rst) begin
            packet <= 0;
            responce_generator_start <= 0;
        end
        else if(address_tx_available && !data_out_valid) begin
            packet.dest_mac                 <= address_tx.mac_addr;
            packet.source_mac               <= MY_MAC;
            packet.ethertype                <= 'h0806; //ARP
            packet.arp.hardware_type        <= 'h0001; //ethernet
            packet.arp.protocol_type        <= 'h0800; //IP
            packet.arp.hardware_addr_len    <= 'h06;
            packet.arp.protocol_addr_len    <= 'h04;
            packet.arp.opcode               <= 'h0002; //reply
            packet.arp.source_mac           <= MY_MAC;
            packet.arp.source_ip            <= MY_IPV4;
            packet.arp.dest_mac             <= address_tx.mac_addr;
            packet.arp.dest_ip              <= address_tx.ip_addr;
            responce_generator_start         <= 1;
        end
        else
            responce_generator_start         <= 0;

    always_ff @(posedge clk)
        if(rst)
            state <= RESPONDER_IDLE;
        else
            state <= next_state;
           
    always_comb
        unique case(state)  
            RESPONDER_IDLE: next_state = address_tx_available && !data_out_valid ?  START : RESPONDER_IDLE;
            START:          next_state = DATA_ACK_TX ?                              SEND_REMAINING : START;
            SEND_REMAINING: next_state = byte_counter == 1 ?                        RESPONDER_IDLE : SEND_REMAINING;
        endcase
        
    always_ff @(posedge clk)
        unique case(next_state)
        RESPONDER_IDLE: begin
            data_out_valid <= 0;
            byte_counter   <= 0;
        end  
        START: begin
            data_out_valid <= 1;
            byte_counter   <= 42;
        end
        SEND_REMAINING: begin
            data_out_valid <= 1;
            byte_counter <= byte_counter - 1;  
        end
        endcase
            
    always_comb data_out = packet >> (byte_counter * 8-8);

endmodule
