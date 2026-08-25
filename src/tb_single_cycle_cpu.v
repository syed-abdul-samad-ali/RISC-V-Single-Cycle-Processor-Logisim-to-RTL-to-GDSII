module tb_single_cycle_cpu;

    reg clk;
    reg reset;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] alu_result;


    //========================================================
    // DUT
    //========================================================

    single_cycle_cpu DUT (

        .clk(clk),

        .reset(reset),

        .pc_out(pc),

        .instruction_out(instruction),

        .alu_result_out(alu_result)

    );


    //========================================================
    // CLOCK
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

        #12;

        reset = 1'b0;

        #250;

        $stop;

    end


    //========================================================
    // MONITOR
    //========================================================

    initial begin

        $monitor(
            "TIME=%0t | PC=%h | INSTR=%h | ALU=%h | x3=%h | x4=%h | x15=%h | x16=%h",
            $time,
            pc,
            instruction,
            alu_result,
            DUT.RF.registers[3],
            DUT.RF.registers[4],
            DUT.RF.registers[15],
            DUT.RF.registers[16]
        );

    end

endmodule
