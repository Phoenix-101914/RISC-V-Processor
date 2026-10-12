module imem(
    input  wire [31:0] a,
    output wire [31:0] rd
);

    // 64 words of 32-bit memory (256 bytes total)
    // Increase the size [63:0] if your programs are larger
    reg [31:0] RAM[63:0]; 

    initial begin
        // Initialize memory with the test program
        $readmemh("../tb/test_prog.hex", RAM);
    end

    // Asynchronous read, ignoring byte offsets
    assign rd = RAM[a[31:2]];

endmodule
