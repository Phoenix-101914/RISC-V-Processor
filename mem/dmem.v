module dmem(
    input  wire        clk,
    input  wire        we,       // Write Enable from MEM stage
    input  wire [31:0] a,        // ALU Result acts as the address
    input  wire [31:0] wd,       // Data to write (from rs2)
    output wire [31:0] rd        // Data read from memory
);

    // 64 words of 32-bit memory (256 bytes total)
    // Initialize to zero to prevent 'x' values in simulation
    reg [31:0] RAM[63:0];
    
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            RAM[i] = 32'b0;
        end
    end

    // Asynchronous read: output data immediately based on word-aligned address
    assign rd = RAM[a[31:2]];

    // Synchronous write: update memory on clock edge
    always @(posedge clk) begin
        if (we) begin
            RAM[a[31:2]] <= wd;
        end
    end

endmodule
