`timescale 1ns/1ps

module tb_single_cycle_cpu;

    //========================================================
    // TESTBENCH SIGNALS
    //========================================================

    reg clk;
    reg reset;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] alu_result;


    //========================================================
    // DUT - DEVICE UNDER TEST
    //========================================================

    single_cycle_cpu DUT (

        .clk(clk),
        .reset(reset),

        .pc_out(pc),
        .instruction_out(instruction),
        .alu_result_out(alu_result)

    );


    //========================================================
    // CLOCK GENERATION
    // 10 ns clock period
    //========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    //========================================================
    // RESET
    //========================================================

    initial begin

        reset = 1'b1;

        // Keep processor in reset
        #12;

        reset = 1'b0;

    end


    //========================================================
    // SIMULATION TIME
    //========================================================

    initial begin

        #250;

        $stop;

    end


    //========================================================
    // MONITOR
    //========================================================

    initial begin

        $monitor(
            "TIME=%0t | RESET=%b | PC=%h | INSTRUCTION=%h | ALU_RESULT=%h",
            $time,
            reset,
            pc,
            instruction,
            alu_result
        );

    end


    //========================================================
    // DISPLAY REGISTER VALUES
    //========================================================

    initial begin

        #20;

        $display("---------------------------------------------");
        $display("      RISC-V SINGLE CYCLE PROCESSOR");
        $display("---------------------------------------------");

        $display("Initial x1 = %0d",
                 DUT.RF.registers[1]);

        $display("Initial x2 = %0d",
                 DUT.RF.registers[2]);

        #100;

        $display("---------------------------------------------");
        $display("Register Values");
        $display("---------------------------------------------");

        $display("x3  = %0d",
                 DUT.RF.registers[3]);

        $display("x4  = %0d",
                 DUT.RF.registers[4]);

        $display("x5  = %0d",
                 DUT.RF.registers[5]);

        $display("x6  = %0d",
                 DUT.RF.registers[6]);

        $display("x7  = %0d",
                 DUT.RF.registers[7]);

        $display("x8  = %0d",
                 DUT.RF.registers[8]);

        $display("x9  = %0d",
                 DUT.RF.registers[9]);

        $display("x10 = %0d",
                 DUT.RF.registers[10]);

        $display("x11 = %0d",
                 DUT.RF.registers[11]);

        $display("x12 = %0d",
                 DUT.RF.registers[12]);

        $display("x13 = %0d",
                 DUT.RF.registers[13]);

        $display("x14 = %0d",
                 DUT.RF.registers[14]);

        $display("x15 = %h",
                 DUT.RF.registers[15]);

        $display("x16 = %h",
                 DUT.RF.registers[16]);

        $display("---------------------------------------------");

    end

endmodule
