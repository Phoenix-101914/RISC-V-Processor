module riscv_core(
    input  wire        clk, reset,
    
    // Instruction Memory Interface
    output wire [31:0] PCF,
    input  wire [31:0] InstrF,
    
    // Data Memory Interface
    output wire        MemWriteM,
    output wire [31:0] ALUResultM, WriteDataM,
    input  wire [31:0] ReadDataM
);

    // Interconnect wires between Control, Datapath, and Hazard
    wire [6:0] op;
    wire [2:0] funct3;
    wire       funct7b5;
    
    // Control signals in Decode
    wire RegWriteD, ResultSrcD, MemWriteD, BranchD, ALUSrcD;
    wire [1:0] ImmSrcD;
    wire [2:0] ALUControlD;
    
    // Hazard signals
    wire StallF, StallD, FlushD, FlushE;
    wire [4:0] Rs1D, Rs2D, RdE, RdM;
    wire RegWriteE, RegWriteM, PCSrcE;
    
    // Extract opcode and funct fields from Decode stage instruction inside Datapath
    // We get this by peering into the datapath, or we can route it out.
    // For cleaner code, we route InstrD out from datapath, or declare it as a wire here.
    wire [31:0] InstrD;
    
    // Instantiate Control Unit
    control_unit cu(
        .op(InstrD[6:0]),
        .funct3(InstrD[14:12]),
        .funct7b5(InstrD[30]),
        .RegWrite(RegWriteD),
        .ResultSrc(ResultSrcD),
        .MemWrite(MemWriteD),
        .Branch(BranchD),
        .ALUSrc(ALUSrcD),
        .ImmSrc(ImmSrcD),
        .ALUControl(ALUControlD)
    );

    // Instantiate Hazard Unit
    hazard_unit hu(
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .RdE(RdE),
        .RdM(RdM),
        .RegWriteE(RegWriteE),
        .RegWriteM(RegWriteM),
        .PCSrcE(PCSrcE),
        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE)
    );

    // Instantiate Datapath
    datapath dp(
        .clk(clk),
        .reset(reset),
        .PCF(PCF),
        .InstrF(InstrF),
        // Control Inputs
        .RegWriteD(RegWriteD),
        .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD),
        .BranchD(BranchD),
        .ALUSrcD(ALUSrcD),
        .ImmSrcD(ImmSrcD),
        .ALUControlD(ALUControlD),
        // Hazard Inputs
        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE),
        // Memory Interface
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .ReadDataM(ReadDataM),
        .MemWriteM(MemWriteM),
        // Hazard Outputs
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .RdE(RdE),
        .RdM(RdM),
        .RegWriteE_out(RegWriteE),
        .RegWriteM_out(RegWriteM),
        .PCSrcE(PCSrcE)
    );
    
    // We need to capture InstrD from the datapath for the control unit
    // Since it's an internal register in datapath, we explicitly assign it here
    // based on the datapath's IF/ID register logic, or we can just route it out.
    // Let's modify the above to assume we tap into it cleanly:
    assign InstrD = dp.InstrD;

endmodule
