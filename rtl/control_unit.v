module control_unit(
    input  wire [6:0] op,
    input  wire [2:0] funct3,
    input  wire       funct7b5,
    output reg        RegWrite, ResultSrc, MemWrite, Branch, ALUSrc,
    output reg  [1:0] ImmSrc,
    output reg  [2:0] ALUControl
);

    reg [1:0] ALUOp;

    // Main Decoder
    always @(*) begin
        case(op)
            7'b0000011: begin // lw
                RegWrite = 1; ImmSrc = 2'b00; ALUSrc = 1; MemWrite = 0; 
                ResultSrc = 1; Branch = 0; ALUOp = 2'b00;
            end
            7'b0100011: begin // sw
                RegWrite = 0; ImmSrc = 2'b01; ALUSrc = 1; MemWrite = 1; 
                ResultSrc = 0; Branch = 0; ALUOp = 2'b00;
            end
            7'b0110011: begin // R-type
                RegWrite = 1; ImmSrc = 2'bx;  ALUSrc = 0; MemWrite = 0; 
                ResultSrc = 0; Branch = 0; ALUOp = 2'b10;
            end
            7'b1100011: begin // beq
                RegWrite = 0; ImmSrc = 2'b10; ALUSrc = 0; MemWrite = 0; 
                ResultSrc = 0; Branch = 1; ALUOp = 2'b01;
            end
            7'b0010011: begin // I-type ALU (addi)
                RegWrite = 1; ImmSrc = 2'b00; ALUSrc = 1; MemWrite = 0; 
                ResultSrc = 0; Branch = 0; ALUOp = 2'b10;
            end
            default: begin
                RegWrite = 0; ImmSrc = 2'b00; ALUSrc = 0; MemWrite = 0; 
                ResultSrc = 0; Branch = 0; ALUOp = 2'b00;
            end
        endcase
    end

    // ALU Decoder
    always @(*) begin
        case(ALUOp)
            2'b00: ALUControl = 3'b000; // addition (lw, sw)
            2'b01: ALUControl = 3'b001; // subtraction (beq)
            2'b10: begin // R-type or I-type ALU
                case(funct3)
                    3'b000: ALUControl = (op == 7'b0110011 && funct7b5) ? 3'b001 : 3'b000; // sub/add
                    3'b010: ALUControl = 3'b101; // slt
                    3'b110: ALUControl = 3'b011; // or
                    3'b111: ALUControl = 3'b010; // and
                    default: ALUControl = 3'b000;
                endcase
            end
            default: ALUControl = 3'b000;
        endcase
    end

endmodule
