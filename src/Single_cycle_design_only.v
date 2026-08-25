`timescale 1ns/1ps

//============================================================
// RISC-V RV32I SINGLE-CYCLE PROCESSOR
//
// Instruction Formats:
// R   : ADD SUB AND OR XOR SLT
// I   : ADDI ANDI ORI XORI LW
// S   : SW
// SB  : BEQ BNE
// U   : LUI AUIPC
// UJ  : JAL
//============================================================


//============================================================
// ALU
//============================================================
module alu (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_control,
    output reg [31:0] result,
    output zero
);

    always @(*) begin
        case (alu_control)

            4'b0000: result = a + b;                    // ADD
            4'b0001: result = a - b;                    // SUB
            4'b0010: result = a & b;                    // AND
            4'b0011: result = a | b;                    // OR
            4'b0100: result = a ^ b;                    // XOR
            4'b0101: result = ($signed(a) < $signed(b))
                              ? 32'd1 : 32'd0;           // SLT

            default: result = 32'd0;

        endcase
    end

    assign zero = (result == 32'd0);

endmodule


//============================================================
// REGISTER FILE
// 32 registers x 32 bits
// x0 is always zero
//============================================================
module register_file (
    input clk,
    input reset,

    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,

    input [31:0] write_data,
    input reg_write,

    output [31:0] read_data1,
    output [31:0] read_data2
);

    reg [31:0] registers [0:31];

    integer i;

    assign read_data1 =
        (rs1 == 5'd0) ? 32'd0 : registers[rs1];

    assign read_data2 =
        (rs2 == 5'd0) ? 32'd0 : registers[rs2];

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;

            // Initial values for testing
            registers[1] <= 32'd10;
            registers[2] <= 32'd5;

        end

        else begin

            if (reg_write && (rd != 5'd0))
                registers[rd] <= write_data;

            registers[0] <= 32'd0;

        end

    end

endmodule


//============================================================
// CONTROL UNIT
//============================================================
module control_unit (
    input [6:0] opcode,

    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,

    output reg alu_src,
    output reg branch,
    output reg branch_ne,

    output reg jump,

    output reg lui,
    output reg auipc,

    output reg [1:0] alu_op
);

    always @(*) begin

        // Default values
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;

        alu_src   = 1'b0;

        branch    = 1'b0;
        branch_ne = 1'b0;

        jump      = 1'b0;

        lui       = 1'b0;
        auipc     = 1'b0;

        alu_op    = 2'b00;


        case (opcode)

            //================================================
            // R-TYPE
            // opcode = 0110011
            //================================================
            7'b0110011: begin

                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;

            end


            //================================================
            // I-TYPE ALU
            // opcode = 0010011
            //================================================
            7'b0010011: begin

                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;

            end


            //================================================
            // LW
            // opcode = 0000011
            //================================================
            7'b0000011: begin

                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;

                alu_src = 1'b1;
                alu_op  = 2'b00;

            end


            //================================================
            // S-TYPE / SW
            // opcode = 0100011
            //================================================
            7'b0100011: begin

                mem_write = 1'b1;

                alu_src = 1'b1;
                alu_op  = 2'b00;

            end


            //================================================
            // SB-TYPE / BEQ
            // opcode = 1100011
            //================================================
            7'b1100011: begin

                branch = 1'b1;

                alu_src = 1'b0;
                alu_op  = 2'b01;

                // BNE uses funct3 = 001
                branch_ne = 1'b0;

            end


            //================================================
            // U-TYPE / LUI
            // opcode = 0110111
            //================================================
            7'b0110111: begin

                reg_write = 1'b1;
                lui       = 1'b1;

            end


            //================================================
            // U-TYPE / AUIPC
            // opcode = 0010111
            //================================================
            7'b0010111: begin

                reg_write = 1'b1;
                auipc     = 1'b1;

            end


            //================================================
            // UJ-TYPE / JAL
            // opcode = 1101111
            //================================================
            7'b1101111: begin

                reg_write = 1'b1;
                jump      = 1'b1;

            end


            default: begin

                reg_write = 1'b0;

            end

        endcase

    end

endmodule


//============================================================
// ALU CONTROL
//============================================================
module alu_control (
    input [1:0] alu_op,
    input [2:0] funct3,
    input funct7_bit,

    output reg [3:0] alu_control_signal
);

    always @(*) begin

        case (alu_op)

            //================================================
            // ADD
            // Used by LW / SW
            //================================================
            2'b00: begin

                alu_control_signal = 4'b0000;

            end


            //================================================
            // SUB
            // Used by branches
            //================================================
            2'b01: begin

                alu_control_signal = 4'b0001;

            end


            //================================================
            // R-TYPE
            //================================================
            2'b10: begin

                case (funct3)

                    3'b000: begin

                        if (funct7_bit)
                            alu_control_signal = 4'b0001; // SUB

                        else
                            alu_control_signal = 4'b0000; // ADD

                    end

                    3'b111:
                        alu_control_signal = 4'b0010; // AND

                    3'b110:
                        alu_control_signal = 4'b0011; // OR

                    3'b100:
                        alu_control_signal = 4'b0100; // XOR

                    3'b010:
                        alu_control_signal = 4'b0101; // SLT

                    default:
                        alu_control_signal = 4'b0000;

                endcase

            end


            //================================================
            // I-TYPE
            //================================================
            2'b11: begin

                case (funct3)

                    3'b000:
                        alu_control_signal = 4'b0000; // ADDI

                    3'b111:
                        alu_control_signal = 4'b0010; // ANDI

                    3'b110:
                        alu_control_signal = 4'b0011; // ORI

                    3'b100:
                        alu_control_signal = 4'b0100; // XORI

                    default:
                        alu_control_signal = 4'b0000;

                endcase

            end

            default:
                alu_control_signal = 4'b0000;

        endcase

    end

endmodule


//============================================================
// IMMEDIATE GENERATOR
//
// Generates immediate for:
// I
// S
// SB
// U
// UJ
//============================================================
module immediate_generator (
    input [31:0] instruction,

    output reg [31:0] immediate
);

    wire [6:0] opcode;

    assign opcode = instruction[6:0];

    always @(*) begin

        case (opcode)

            //================================================
            // I-TYPE
            //================================================
            7'b0010011,
            7'b0000011: begin

                immediate =
                    {{20{instruction[31]}},
                     instruction[31:20]};

            end


            //================================================
            // S-TYPE
            //================================================
            7'b0100011: begin

                immediate =
                    {{20{instruction[31]}},
                     instruction[31:25],
                     instruction[11:7]};

            end


            //================================================
            // SB-TYPE
            //================================================
            7'b1100011: begin

                immediate =
                    {{19{instruction[31]}},
                     instruction[31],
                     instruction[7],
                     instruction[30:25],
                     instruction[11:8],
                     1'b0};

            end


            //================================================
            // U-TYPE
            // LUI / AUIPC
            //================================================
            7'b0110111,
            7'b0010111: begin

                immediate = {
                    instruction[31:12],
                    12'b0
                };

            end


            //================================================
            // UJ-TYPE
            // JAL
            //================================================
            7'b1101111: begin

                immediate =
                    {{11{instruction[31]}},
                     instruction[31],
                     instruction[19:12],
                     instruction[20],
                     instruction[30:21],
                     1'b0};

            end


            default:
                immediate = 32'd0;

        endcase

    end

endmodule


//============================================================
// INSTRUCTION MEMORY
//============================================================
module instruction_memory (
    input [31:0] address,

    output [31:0] instruction
);

    reg [31:0] memory [0:255];

    assign instruction = memory[address[9:2]];


    initial begin

        //====================================================
        // R-TYPE
        //====================================================

        // ADD x3, x1, x2
        // x3 = 10 + 5 = 15
        memory[0] = 32'h002081B3;

        // SUB x4, x3, x2
        // x4 = 15 - 5 = 10
        memory[1] = 32'h40218233;

        // AND x5, x3, x4
        memory[2] = 32'h0041F2B3;

        // OR x6, x3, x4
        memory[3] = 32'h0041E333;

        // XOR x7, x3, x4
        memory[4] = 32'h0041C3B3;

        // SLT x8, x4, x3
        // x8 = 1
        memory[5] = 32'h00322433;


        //====================================================
        // I-TYPE
        //====================================================

        // ADDI x9, x8, 10
        memory[6] = 32'h00A40493;

        // ANDI x10, x9, 15
        memory[7] = 32'h00F4F513;

        // ORI x11, x10, 16
        memory[8] = 32'h01056593;

        // XORI x12, x11, 5
        memory[9] = 32'h0055C613;


        //====================================================
        // S-TYPE
        //====================================================

        // SW x12, 0(x0)
        memory[10] = 32'h00C02023;


        //====================================================
        // I-TYPE LOAD
        //====================================================

        // LW x13, 0(x0)
        memory[11] = 32'h00002683;


        //====================================================
        // SB-TYPE
        //====================================================

        // BEQ x12, x13, +8
        memory[12] = 32'h00D60463;

        // This instruction is skipped if BEQ is taken
        // ADDI x14, x0, 100
        memory[13] = 32'h06400713;


        //====================================================
        // U-TYPE
        //====================================================

        // LUI x15, 0x12345
        // x15 = 0x12345000
        memory[14] = 32'h123457B7;

        // AUIPC x16, 0x1
        // x16 = PC + 0x1000
        memory[15] = 32'h00001817;


        //====================================================
        // UJ-TYPE
        //====================================================

        // JAL x0, +8
        memory[16] = 32'h0080006F;

        // Skipped by JAL
        // ADDI x17, x0, 200
        memory[17] = 32'h0C800893;

        // NOP
        memory[18] = 32'h00000013;

    end

endmodule


//============================================================
// DATA MEMORY
//============================================================
module data_memory (
    input clk,

    input mem_read,
    input mem_write,

    input [31:0] address,
    input [31:0] write_data,

    output [31:0] read_data
);

    reg [31:0] memory [0:255];

    assign read_data =
        mem_read ? memory[address[9:2]] : 32'd0;


    always @(posedge clk) begin

        if (mem_write)
            memory[address[9:2]] <= write_data;

    end

endmodule


//============================================================
// TOP LEVEL SINGLE-CYCLE CPU
//============================================================
module single_cycle_cpu (

    input clk,
    input reset,

    output [31:0] pc_out,
    output [31:0] instruction_out,
    output [31:0] alu_result_out

);

    //========================================================
    // PROGRAM COUNTER
    //========================================================

    reg [31:0] pc;

    wire [31:0] next_pc;

    assign pc_out = pc;


    //========================================================
    // INSTRUCTION MEMORY
    //========================================================

    wire [31:0] instruction;

    assign instruction_out = instruction;


    instruction_memory IMEM (

        .address(pc),
        .instruction(instruction)

    );


    //========================================================
    // INSTRUCTION FIELDS
    //========================================================

    wire [6:0] opcode;

    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;

    wire [2:0] funct3;

    wire funct7_bit;


    assign opcode = instruction[6:0];

    assign rd = instruction[11:7];

    assign funct3 = instruction[14:12];

    assign rs1 = instruction[19:15];

    assign rs2 = instruction[24:20];

    assign funct7_bit = instruction[30];


    //========================================================
    // CONTROL UNIT
    //========================================================

    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;

    wire alu_src;

    wire branch;
    wire branch_ne;

    wire jump;

    wire lui;
    wire auipc;

    wire [1:0] alu_op;


    control_unit CU (

        .opcode(opcode),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),

        .alu_src(alu_src),

        .branch(branch),
        .branch_ne(branch_ne),

        .jump(jump),

        .lui(lui),
        .auipc(auipc),

        .alu_op(alu_op)

    );


    //========================================================
    // REGISTER FILE
    //========================================================

    wire [31:0] reg_data1;
    wire [31:0] reg_data2;

    wire [31:0] write_back_data;


    register_file RF (

        .clk(clk),
        .reset(reset),

        .rs1(rs1),
        .rs2(rs2),

        .rd(rd),

        .write_data(write_back_data),

        .reg_write(reg_write),

        .read_data1(reg_data1),
        .read_data2(reg_data2)

    );


    //========================================================
    // IMMEDIATE GENERATOR
    //========================================================

    wire [31:0] immediate;


    immediate_generator IG (

        .instruction(instruction),

        .immediate(immediate)

    );


    //========================================================
    // ALU CONTROL
    //========================================================

    wire [3:0] alu_control_signal;


    alu_control AC (

        .alu_op(alu_op),

        .funct3(funct3),

        .funct7_bit(funct7_bit),

        .alu_control_signal(alu_control_signal)

    );


    //========================================================
    // ALU INPUT B MUX
    //========================================================

    wire [31:0] alu_input_b;


    assign alu_input_b =
        alu_src ? immediate : reg_data2;


    //========================================================
    // ALU
    //========================================================

    wire [31:0] alu_result;

    wire alu_zero;


    assign alu_result_out = alu_result;


    alu ALU (

        .a(reg_data1),

        .b(alu_input_b),

        .alu_control(alu_control_signal),

        .result(alu_result),

        .zero(alu_zero)

    );


    //========================================================
    // DATA MEMORY
    //========================================================

    wire [31:0] memory_data;


    data_memory DMEM (

        .clk(clk),

        .mem_read(mem_read),

        .mem_write(mem_write),

        .address(alu_result),

        .write_data(reg_data2),

        .read_data(memory_data)

    );


    //========================================================
    // U-TYPE RESULT
    //========================================================

    wire [31:0] lui_result;

    wire [31:0] auipc_result;


    assign lui_result = immediate;

    assign auipc_result = pc + immediate;


    //========================================================
    // WRITE-BACK MUX
    //========================================================

    assign write_back_data =

        jump  ? (pc + 32'd4) :

        lui   ? lui_result :

        auipc ? auipc_result :

        mem_to_reg ? memory_data :

        alu_result;


    //========================================================
    // BRANCH TARGET
    //========================================================

    wire [31:0] branch_target;


    assign branch_target = pc + immediate;


    //========================================================
    // JUMP TARGET
    //========================================================

    wire [31:0] jump_target;


    assign jump_target = pc + immediate;


    //========================================================
    // BRANCH CONDITION
    //========================================================

    wire take_branch;


    assign take_branch =

        branch &&

        (
            (funct3 == 3'b000 && alu_zero) ||        // BEQ
            (funct3 == 3'b001 && !alu_zero)          // BNE
        );


    //========================================================
    // NEXT PC
    //========================================================

    assign next_pc =

        jump ? jump_target :

        take_branch ? branch_target :

        pc + 32'd4;


    //========================================================
    // PROGRAM COUNTER REGISTER
    //========================================================

    always @(posedge clk or posedge reset) begin

        if (reset)
            pc <= 32'd0;

        else
            pc <= next_pc;

    end

endmodule


//============================================================
// TESTBENCH
//============================================================
