# RISC-V 5-Stage Pipelined CPU (RV32I)

This repository contains the RTL design and verification environment for a 32-bit, 5-stage pipelined RISC-V processor implementing a subset of the RV32I Instruction Set Architecture (ISA). The core is written in Verilog, with testbenches developed in SystemVerilog.

## Architecture Overview

The processor datapath is partitioned into the classic 5-stage RISC pipeline:
1. **Instruction Fetch (IF):** Fetches the next instruction from Instruction Memory and updates the Program Counter (PC).
2. **Instruction Decode (ID):** Decodes the instruction, reads operands from the Register File, and generates control signals.
3. **Execute (EX):** Performs arithmetic/logical operations using the ALU and calculates branch targets.
4. **Memory (MEM):** Handles data reads and writes to the Data Memory.
5. **Write-Back (WB):** Writes ALU results or loaded memory data back to the Register File.

### Hazard Management
To maintain structural simplicity and accuracy, this pipeline handles hazards **without data forwarding**:
* **Data Hazards (Load-Use):** Resolved via pipeline stalling. The Hazard Unit detects if a load instruction in the Execute stage has a destination register matching a source register in the Decode stage, inserting a bubble (stall) to allow the load to complete.
* **Control Hazards (Branches):** Resolved via flushing. When a branch is taken in the Execute stage, the instructions already fetched into the IF and ID stages are flushed from the pipeline registers to prevent incorrect execution.

## Repository Structure

```text
riscv-5stage-pipeline/
├── README.md               # Project overview and instructions
├── docs/                   # Pipeline diagrams and ISA documentation
├── rtl/                    # Synthesizable Verilog design files
│   ├── alu.v               # Arithmetic Logic Unit
│   ├── control_unit.v      # Main decoder and ALU decoder
│   ├── hazard_unit.v       # Stall and flush logic
│   ├── regfile.v           # 32x32 Register File
│   ├── datapath.v          # Datapath and pipeline registers
│   └── riscv_core.v        # Top-level CPU wrapper
├── mem/                    # Memory models
│   ├── imem.v              # Instruction Memory
│   └── dmem.v              # Data Memory
├── tb/                     # Verification
│   ├── riscv_tb.sv         # SystemVerilog testbench
│   └── test_prog.hex       # Machine code hex file for simulation
└── scripts/                # Build and simulation scripts
    └── Makefile
