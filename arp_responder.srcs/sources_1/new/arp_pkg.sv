`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Personal Project
// Engineer: Michael Fernandez
// 
// Create Date: 08/06/2021 06:32:22 PM
// Module Name: arp_responder_top_tb
// Description: Package containing Statemachine type and various packet structs.   
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

package arp_pkg;

    typedef struct packed {
        logic [47:0] mac_addr;
        logic [31:0] ip_addr;
    } addr_t;
    
    typedef enum {
        IDLE,
        WAIT_FOR_MAC,
        CHECK_IF_BRODCAST,
        WAIT_ETHERTYPE,
        CHECK_ETHERTYPE,
        WAIT_HARDWARE_TYPE,
        CHECK_HARDWARE_TYPE,
        WAIT_PROTOCOL_TYPE,
        CHECK_PROTOCOL_TYPE,
	EXTRACT_HARDWARE_LEN,
	EXTRACT_PROTOCOL_LEN,
	WAIT_OPCODE,
	CHECK_OPCODE,
        PARSING_MAC,
        EXTRACT_MAC,
        PARSING_IP,        
        EXTRACT_IP,
        WAIT_DESTINATION_IP,
        CHECK_DESTINATION_IP,
        NOT_SUPPORTED
    } arp_parser_state_t;   
 
     typedef enum {
        RESPONDER_IDLE,
        START,
        WAIT_FOR_ACK,
        SEND_REMAINING
    } arp_responder_state_t; 
     
    typedef struct packed {
        logic [15:0] hardware_type;
        logic [15:0] protocol_type;
        logic [7:0]  hardware_addr_len;
        logic [7:0]  protocol_addr_len;
        logic [15:0] opcode;
        logic [47:0] source_mac;
        logic [31:0] source_ip;
        logic [47:0] dest_mac;
        logic [31:0] dest_ip;
    } arp_t;   
    
    typedef struct packed {
        logic [47:0] dest_mac;
        logic [47:0] source_mac;
        logic [15:0] ethertype;
        arp_t arp;
    } packet_t;

endpackage
    
