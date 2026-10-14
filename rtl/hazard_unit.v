module hazard_unit(
    input  wire [4:0] Rs1D, Rs2D,
    input  wire [4:0] RdE, RdM,
    input  wire       RegWriteE, RegWriteM,
    input  wire       PCSrcE,
    output wire       StallF, StallD, FlushD, FlushE
);

    // Data Hazards (No Forwarding): 
    // Stall if a source register in ID matches a destination register in EX or MEM
    wire data_hazard_E = RegWriteE & (RdE != 0) & ((Rs1D == RdE) | (Rs2D == RdE));
    wire data_hazard_M = RegWriteM & (RdM != 0) & ((Rs1D == RdM) | (Rs2D == RdM));
    
    wire stall_condition = data_hazard_E | data_hazard_M;

    // Stall Fetch and Decode stages
    assign StallF = stall_condition;
    assign StallD = stall_condition;
    
    // Control Hazards: Flush Decode if a branch is taken.
    assign FlushD = PCSrcE;
    
    // Flush Execute stage to insert a bubble if stalling or branching
    assign FlushE = stall_condition | PCSrcE;

endmodule
