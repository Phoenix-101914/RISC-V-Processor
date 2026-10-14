module datapath(
    input  wire        clk, reset,
    // Fetch
    output wire [31:0] PCF,
    input  wire [31:0] InstrF,
    // Control unit inputs (Decode)
    input  wire        RegWriteD, ResultSrcD, MemWriteD, BranchD, ALUSrcD,
    input  wire [1:0]  ImmSrcD,
    input  wire [2:0]  ALUControlD,
    // Hazard unit inputs
    input  wire        StallF, StallD, FlushD, FlushE,
    // Memory
    output wire [31:0] ALUResultM, WriteDataM,
    input  wire [31:0] ReadDataM,
    output wire        MemWriteM,
    // Hazard unit outputs
    output wire [4:0]  Rs1D, Rs2D, RdE, RdM,
    output wire        RegWriteE_out, RegWriteM_out, PCSrcE
);

    // --- Fetch Stage ---
    reg  [31:0] PCReg;
    wire [31:0] PCNext, PCPlus4F;
    wire [31:0] PCTargetE;
    
    always @(posedge clk or posedge reset) begin
        if (reset) PCReg <= 32'b0;
        else if (!StallF) PCReg <= PCNext;
    end
    
    assign PCF = PCReg;
    assign PCPlus4F = PCF + 32'd4;
    assign PCNext = PCSrcE ? PCTargetE : PCPlus4F;

    // --- IF/ID Register ---
    reg [31:0] InstrD, PCD, PCPlus4D;
    always @(posedge clk or posedge reset) begin
        if (reset || FlushD) begin
            InstrD <= 32'b0; PCD <= 32'b0; PCPlus4D <= 32'b0;
        end else if (!StallD) begin
            InstrD <= InstrF; PCD <= PCF; PCPlus4D <= PCPlus4F;
        end
    end

    // --- Decode Stage ---
    wire [31:0] RD1D, RD2D, ImmExtD;
    wire [4:0]  RdD = InstrD[11:7];
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    
    wire [31:0] ResultW;
    wire [4:0]  RdW;
    wire        RegWriteW;

    regfile rf (.clk(clk), .we3(RegWriteW), .a1(Rs1D), .a2(Rs2D), 
                .a3(RdW), .wd3(ResultW), .rd1(RD1D), .rd2(RD2D));
                
    // Immediate Extension
    assign ImmExtD = (ImmSrcD == 2'b00) ? {{20{InstrD[31]}}, InstrD[31:20]} :                      // I-Type
                     (ImmSrcD == 2'b01) ? {{20{InstrD[31]}}, InstrD[31:25], InstrD[11:7]} :        // S-Type
                     (ImmSrcD == 2'b10) ? {{20{InstrD[31]}}, InstrD[7], InstrD[30:25], InstrD[11:8], 1'b0} : // B-Type
                     32'b0;

    // --- ID/EX Register ---
    reg [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
    reg        RegWriteE, ResultSrcE, MemWriteE, BranchE, ALUSrcE;
    reg [2:0]  ALUControlE;
    
    always @(posedge clk or posedge reset) begin
        if (reset || FlushE) begin
            RegWriteE <= 0; ResultSrcE <= 0; MemWriteE <= 0; BranchE <= 0; ALUSrcE <= 0; ALUControlE <= 0;
            RD1E <= 0; RD2E <= 0; ImmExtE <= 0; PCE <= 0; RdE <= 0; PCPlus4E <= 0;
        end else begin
            RegWriteE <= RegWriteD; ResultSrcE <= ResultSrcD; MemWriteE <= MemWriteD; 
            BranchE <= BranchD; ALUSrcE <= ALUSrcD; ALUControlE <= ALUControlD;
            RD1E <= RD1D; RD2E <= RD2D; ImmExtE <= ImmExtD; PCE <= PCD; 
            RdE <= RdD; PCPlus4E <= PCPlus4D;
        end
    end
    
    assign RegWriteE_out = RegWriteE;

    // --- Execute Stage ---
    wire [31:0] SrcAE = RD1E;
    wire [31:0] SrcBE = ALUSrcE ? ImmExtE : RD2E;
    wire [31:0] ALUResultE;
    wire        ZeroE;

    alu alu_inst (.a(SrcAE), .b(SrcBE), .alucontrol(ALUControlE), .result(ALUResultE), .zero(ZeroE));
    
    assign PCTargetE = PCE + ImmExtE;
    assign PCSrcE = BranchE & ZeroE;

    // --- EX/MEM Register ---
    reg [31:0] ALUResultM_reg, WriteDataM_reg;
    reg        RegWriteM_reg, ResultSrcM, MemWriteM_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWriteM_reg <= 0; ResultSrcM <= 0; MemWriteM_reg <= 0;
            ALUResultM_reg <= 0; WriteDataM_reg <= 0; RdM <= 0;
        end else begin
            RegWriteM_reg <= RegWriteE; ResultSrcM <= ResultSrcE; MemWriteM_reg <= MemWriteE;
            ALUResultM_reg <= ALUResultE; WriteDataM_reg <= RD2E; RdM <= RdE;
        end
    end

    assign ALUResultM = ALUResultM_reg;
    assign WriteDataM = WriteDataM_reg;
    assign MemWriteM = MemWriteM_reg;
    assign RegWriteM_out = RegWriteM_reg;

    // --- MEM/WB Register ---
    reg [31:0] ALUResultW, ReadDataW;
    reg        RegWriteW_reg, ResultSrcW;
    reg [4:0]  RdW_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWriteW_reg <= 0; ResultSrcW <= 0;
            ALUResultW <= 0; ReadDataW <= 0; RdW_reg <= 0;
        end else begin
            RegWriteW_reg <= RegWriteM_reg; ResultSrcW <= ResultSrcM;
            ALUResultW <= ALUResultM; ReadDataW <= ReadDataM; RdW_reg <= RdM;
        end
    end
    
    assign RegWriteW = RegWriteW_reg;
    assign RdW = RdW_reg;

    // --- Writeback Stage ---
    assign ResultW = ResultSrcW ? ReadDataW : ALUResultW;

endmodule
