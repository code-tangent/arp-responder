`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Personal Project
// Engineer: Michael Fernandez
// 
// Create Date: 08/07/2021 04:25:01 PM
// Module Name: reset_sync
// Description: Takes async reset and makes sync. Extends couple cycles to be safe. 
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module reset_sync(
    input wire clk,
    input wire reset_i,
    output logic reset_o
);

    logic sync0 = 1;
    logic sync1 = 1;
    logic sync2 = 1;
    
    always_ff @(posedge clk or posedge reset_i)
        if(reset_i) begin
            sync0 <= 1;
            sync1 <= 1;
            sync2 <= 1;
        end
        else begin
            sync0 <= 0;
            sync1 <= sync0;
            sync2 <= sync1;
        end
        
    always_comb reset_o = sync2;
    
endmodule
