`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Personal Project
// Engineer: Michael Fernandez
// 
// Create Date: 08/07/2021 06:44:01 PM
// Module Name: arp_parser
// Description: Parses Arp msg. Checks that Msg type is supported. Extracts information needed for Arp response.  
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
import arp_pkg::*;

module arp_parser(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    input wire [31:0] MY_IPV4,
    
    output addr_t address_rx,
    output logic address_rx_valid
);
arp_parser_state_t state, next_state;
addr_t address_internal;
   
logic [47:0] data_current;
logic [47:0] data_previous;
logic [15:0] ether_type;
logic [15:0] hardware_type;
logic [15:0] protocol_type;
logic [15:0] opcode;
logic [7:0] hardware_length;
logic [7:0] protocol_length;

logic [15:0] counter;
logic broadcast_ready;
logic ethertype_ready;
logic hardware_type_ready;
logic protocol_type_ready;
logic opcode_ready;
logic mac_ready;
logic ip_ready; 
logic dest_ip_ready; 

    always_comb data_current = {data_previous, data};
    
    always_ff @(posedge clk)
        data_previous <= data_current;
    
    //Will Contain Data one cycle after ready pulse
    always_comb address_internal.mac_addr = data_previous;
    always_comb address_internal.ip_addr = data_previous[31:0];
    always_comb ether_type = data_previous[15:0];    
    always_comb hardware_type = data_previous[15:0];
    always_comb protocol_type = data_previous[15:0];
    always_comb opcode = data_previous[15:0];
    
    always_ff @(posedge clk)
        if(rst)
            state <= IDLE;
        else
            state <= next_state;

    //State Machine sets up counters and pulses to let other state machine know when relivant part of packet has been parsed.  
    always_ff @(posedge clk)
        unique case(next_state)
        IDLE: begin
            counter             <= 6;
            broadcast_ready     <= 0;
            ethertype_ready     <= 0;
            hardware_type_ready <= 0;
            protocol_type_ready <= 0;   
            mac_ready           <= 0;
            ip_ready            <= 0;
            dest_ip_ready       <= 0;
        end
        WAIT_FOR_MAC: begin
            counter <= counter - 1;
            if(counter-2 == 0)
                broadcast_ready <= 1; 
        end
        CHECK_IF_BRODCAST:
            counter <= 8;
        WAIT_ETHERTYPE: begin
            counter <= counter - 1;
            if(counter-2 == 0)
                ethertype_ready <= 1;
        end
        CHECK_ETHERTYPE:
            counter <= 2;
        WAIT_HARDWARE_TYPE: begin
            counter <= counter - 1;
            if(counter-2 == 0)
                hardware_type_ready <= 1;
        end
        CHECK_HARDWARE_TYPE:
            counter <= 2;
        WAIT_PROTOCOL_TYPE: begin
            counter <= counter - 1;
            if(counter-2 == 0)
                protocol_type_ready <= 1;
        end
        CHECK_PROTOCOL_TYPE:
            counter <= 0;
        EXTRACT_HARDWARE_LEN:
            hardware_length <= data_current[7:0];
        EXTRACT_PROTOCOL_LEN: begin
            protocol_length <= data_current[7:0];
            counter <= 2;
        end
        WAIT_OPCODE: begin
            counter <= counter - 1;
            if(counter-2 == 0)
                opcode_ready <= 1;
        end     
        CHECK_OPCODE :
            counter <= hardware_length;     
        PARSING_MAC:begin
            counter <= counter - 1;
            if(counter-2 == 0)
                mac_ready <= 1;
        end
        EXTRACT_MAC:
            counter <= protocol_length;
        PARSING_IP: begin
            counter <= counter - 1;
            if(counter-2 == 0)
                ip_ready <= 1;
        end        
        EXTRACT_IP:
            counter <= hardware_length + protocol_length;
        WAIT_DESTINATION_IP: begin
            counter <= counter - 1;
            if(counter-2 == 0)
                dest_ip_ready <= 1;
        end  
        CHECK_DESTINATION_IP: 
            counter <= 0;
        NOT_SUPPORTED:
            counter <= 0;
    endcase    
    
    //Decision Making state machine. Checks to make sure Msg is supported and moves state machine when relivant part of msg is parsed and ready.        
    always_comb
        unique case(state)
            IDLE:                   next_state = data_valid ?                                   WAIT_FOR_MAC : IDLE;
            WAIT_FOR_MAC:           next_state = broadcast_ready ?                              CHECK_IF_BRODCAST : WAIT_FOR_MAC;
            CHECK_IF_BRODCAST:      next_state = address_internal.mac_addr == 'hFFFFFFFFFFFF ?  WAIT_ETHERTYPE : NOT_SUPPORTED;               
            WAIT_ETHERTYPE:         next_state = ethertype_ready ?                              CHECK_ETHERTYPE : WAIT_ETHERTYPE;
            CHECK_ETHERTYPE:        next_state = ether_type == 'h0806 ?                         WAIT_HARDWARE_TYPE : NOT_SUPPORTED;
            WAIT_HARDWARE_TYPE:     next_state = hardware_type_ready ?                          CHECK_HARDWARE_TYPE : WAIT_HARDWARE_TYPE;
            CHECK_HARDWARE_TYPE:    next_state = hardware_type == 'h0001 ?                      WAIT_PROTOCOL_TYPE : NOT_SUPPORTED;           
            WAIT_PROTOCOL_TYPE:     next_state = protocol_type_ready ?                          CHECK_PROTOCOL_TYPE : WAIT_PROTOCOL_TYPE;
            CHECK_PROTOCOL_TYPE:    next_state = protocol_type == 'h0800 ?                      EXTRACT_HARDWARE_LEN : NOT_SUPPORTED;    
            EXTRACT_HARDWARE_LEN:   next_state =                                                EXTRACT_PROTOCOL_LEN;
            EXTRACT_PROTOCOL_LEN:   next_state =                                                WAIT_OPCODE;
            WAIT_OPCODE:            next_state = opcode_ready ?                                 CHECK_OPCODE : WAIT_OPCODE;
            CHECK_OPCODE:           next_state = opcode == 'h0001 ?                             PARSING_MAC : NOT_SUPPORTED;
            PARSING_MAC:            next_state = mac_ready ?                                    EXTRACT_MAC : PARSING_MAC;
            EXTRACT_MAC:            next_state =                                                PARSING_IP;
            PARSING_IP:             next_state = ip_ready?                                      EXTRACT_IP : PARSING_IP;
            EXTRACT_IP:             next_state =                                                WAIT_DESTINATION_IP;
            WAIT_DESTINATION_IP:    next_state = dest_ip_ready?                                 CHECK_DESTINATION_IP : WAIT_DESTINATION_IP;   
            CHECK_DESTINATION_IP:   next_state =                                                IDLE;   
            NOT_SUPPORTED:          next_state = data_valid ?                                   NOT_SUPPORTED : IDLE;
        endcase    

    //Need to save Sender's Mac and IP for responce msg
    always_ff @(posedge clk)
        if(rst)
            address_rx <= 0;
        else if (state == EXTRACT_MAC)
            address_rx.mac_addr <= address_internal.mac_addr;
        else if (state == EXTRACT_IP)
            address_rx.ip_addr <= address_internal.ip_addr;

    //Got All the way to the end now just verify you are IP the sender is looking for
    always_ff @(posedge clk)
        if(state == CHECK_DESTINATION_IP)
            address_rx_valid <= address_internal.ip_addr == MY_IPV4; 
        else
            address_rx_valid <= 0;


endmodule