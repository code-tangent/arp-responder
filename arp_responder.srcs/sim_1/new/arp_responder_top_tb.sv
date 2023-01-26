`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Personal Project
// Engineer: Michael Fernandez
// 
// Create Date: 08/09/2021 11:44:53 PM
// Module Name: arp_responder_top_tb
// Description: Sim top level. Generates clocks resets and inputs. Checks outputs.   
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
import arp_pkg::*;

module arp_responder_top_tb();

    localparam CLK_FREQ = 161.131e6;
    localparam CLK_HALF_PERIOD = 1/real'(CLK_FREQ)*1000e6/2;
    localparam DRIVE_DLY = 1;
    
    logic           ARESET;
    logic  [47:0]   MY_MAC;
    logic  [31:0]   MY_IPV4; 
    logic           CLK_RX;
    logic           DATA_VALID_RX;
    logic  [7:0]    DATA_RX;
    logic           CLK_TX;
    logic           DATA_VALID_TX;
    logic  [7:0]    DATA_TX;
    logic           DATA_ACK_TX;
     
    logic [$clog2(42):0] counter_rx; 
    logic [$clog2(42):0] counter_tx;    
    logic [$clog2(255):0] counter_send;    
    logic [$clog2(255):0] counter_recieve;    
   
    packet_t msg;
    packet_t msg_bad;
    packet_t responce_msg;
    packet_t responce_msg_golden; 
    //gen clocks
    always begin
        #CLK_HALF_PERIOD CLK_RX = 1;
        #CLK_HALF_PERIOD CLK_RX = 0;
    end
    always_comb CLK_TX = !CLK_RX;
    
     default clocking clock @(posedge CLK_RX);
        default input #1step output #DRIVE_DLY;
        output negedge ARESET;
    endclocking  
    
    arp_responder_top dut(
        .*
    );


    always_ff @ (posedge CLK_RX)
        if(ARESET) begin
            //Copied from PDF
            msg = 'hFFFFFFFFFFFF000142005f6808060001080006040001000142005f68c0a80101000000000000c0a80102;
            //Golden copied directly from Timing Diagram, output should match this if correct.
            responce_msg_golden = 'h000142005f6800022301020308060001080006040002000223010203c0a80102000142005f68c0a80101;
            msg_bad = 'h01FFFFFFFFFF000142005f6808060001080006040001000142005f68c0a80101000000000000c0a80102;
        end          

    task send_arp(
        input packet_t msg_local,
        input logic [$clog2(255):0] number_of_arps_to_send   
    );
        for (counter_send = number_of_arps_to_send; counter_send>0; counter_send = counter_send -1)begin
            DATA_VALID_RX =1;
            for (counter_rx = ($bits(packet_t)/8); counter_rx>0; counter_rx = counter_rx -1)
                begin
                    DATA_RX = msg_local>>(counter_rx*8-8); ##1;
                end
            DATA_VALID_RX =0;
            DATA_RX = 0;
            ##1;
        end
    endtask;
    
    task recieve_responce_arp(
        input logic [$clog2(255):0] number_of_arps_to_recieve
    );
        for (counter_recieve = number_of_arps_to_recieve; counter_recieve>0; counter_recieve = counter_recieve -1)begin
            wait(DATA_VALID_TX);
            @(posedge CLK_TX);
            DATA_ACK_TX = 1;
            for (counter_tx = ($bits(packet_t)/8); counter_tx>0; counter_tx = counter_tx -1) begin
                @(posedge CLK_TX);
                responce_msg = {responce_msg, DATA_TX};             
                 DATA_ACK_TX = 0;
            end
            assert(responce_msg == responce_msg_golden);
        end
    endtask;
    
    initial begin
        MY_MAC = 'h000223010203; //from PDF
        MY_IPV4 = 'hc0a80102; //from PDF
        ARESET = 0;
        DATA_VALID_RX = 0;
        DATA_RX = 0;
        DATA_ACK_TX = 0;
        
        //Toggle Reset
        ##2 ARESET = 1;
        ##2 ARESET = 0;
        ##20;
        
        $display("\n **** Start Test\n");
        //Send 255 Msgs as a stress test to see if fifo overflows or design bottlenecks
            $display("      Sending 255 Arps");
            fork begin
                send_arp(msg, 255);
            end
            begin
                recieve_responce_arp(255);
    
            end
            join
                //Send a bad msg and see if state machine handles properly
                $display("      Sending Non-Broadcast Mac");
                send_arp(msg_bad, 1);
                assert($past(dut.arp_parser_inst.state,1) == NOT_SUPPORTED);
                
                //Send a good msg to make sure state machine not stuck in bad state
                $display("      Sending Final Arp");
                send_arp(msg, 1);
                recieve_responce_arp(1);
        $display(" **** Test's Sucessful if no assertions fired");
        $display(" **** End Test\n");
        $finish;
    end

endmodule
