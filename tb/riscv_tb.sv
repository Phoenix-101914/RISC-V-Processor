`timescale 1ns/1ps

module riscv_tb;

    // Clock and Reset
    logic clk;
    logic reset;
    
    // Core memory interface signals
    logic [31:0] PCF, InstrF;
    logic MemWriteM;
    logic [31:0] ALUResultM, WriteDataM, ReadDataM;

    // Instantiate Top-Level RISC-V Core
    riscv_core dut (
        .clk(clk),
        .reset(reset),
        .PCF(PCF),
        .InstrF(InstrF),
        .MemWriteM(MemWriteM),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .ReadDataM(ReadDataM)
    );

    // Instantiate Instruction Memory (ROM)
    imem imem_inst (
        .a(PCF),
        .rd(InstrF)
    );

    // Instantiate Data Memory (RAM)
    dmem dmem_inst (
        .clk(clk),
        .we(MemWriteM),
        .a(ALUResultM),
        .wd(WriteDataM),
        .rd(ReadDataM)
    );

    // Clock Generation: 10ns period (100 MHz)
    always #5 clk = ~clk;

    // Simulation Sequence
    initial begin
        // Setup waveform dumping for GTKWave
        $dumpfile("waves.vcd");
        $dumpvars(0, riscv_tb);
        
        // Initialize clock and apply reset
        clk = 0;
        reset = 1;
        
        // Hold reset for a few cycles, then release
        #15 reset = 0;

        // Failsafe timeout to prevent infinite loops
        #2000;
        $display("Simulation timed out.");
        $finish;
    end

    // Monitor Memory Writes for Self-Checking
    always @(negedge clk) begin
        if (MemWriteM) begin
            $display("Time: %0t | MemWrite: Addr = %h, Data = %0d (0x%h)", 
                     $time, ALUResultM, WriteDataM, WriteDataM);
            
            // Example termination condition: 
            // If the program writes the value 34 (0x22) to address 104 (0x68), the test passes.
            if (ALUResultM == 32'h00000068 && WriteDataM == 32'h00000022) begin
                $display("Test Passed! Expected value successfully written to memory.");
                $finish;
            end
        end
    end

endmodule
