// =============================================================================
// Vending Machine Controller — Testbench
// =============================================================================
// Description : Comprehensive self-checking testbench for vending_machine.sv.
//               Tests multiple product prices, all coin combinations, change
//               return, refund logic, reset during transaction, and edge cases.
//
// How to run  :
//   iverilog   : Not supported (SystemVerilog tasks/types needed — use VCS/Xcelium/ModelSim)
//   VCS        : vcs -sverilog rtl/vending_machine.sv tb/vending_machine_tb.sv -o simv && ./simv
//   Xcelium    : xrun rtl/vending_machine.sv tb/vending_machine_tb.sv
//   ModelSim   : vlog rtl/vending_machine.sv tb/vending_machine_tb.sv && vsim -c vending_machine_tb -do "run -all; quit"
//   Vivado sim : Add both files to sim set, set vending_machine_tb as top
//
// Waveform    : The $dumpfile / $dumpvars calls generate vending_machine.vcd
//               Open in GTKWave: gtkwave vending_machine.vcd
// =============================================================================

`timescale 1ns/1ps

module vending_machine_tb;

    // -------------------------------------------------------------------------
    // Clock and DUT signals
    // -------------------------------------------------------------------------
    localparam int CLK_PERIOD = 10;  // 10 ns → 100 MHz

    logic        clk;
    logic        reset;
    logic [1:0]  coin;
    logic        refund;
    logic        dispense;
    logic [5:0]  change;
    logic        refund_out;
    logic [5:0]  amount;

    // -------------------------------------------------------------------------
    // DUT instantiation (default price = 30¢ for most tests)
    // -------------------------------------------------------------------------
    vending_machine #(.PRICE(30)) dut (
        .clk        (clk),
        .reset      (reset),
        .coin       (coin),
        .refund     (refund),
        .dispense   (dispense),
        .change     (change),
        .refund_out (refund_out),
        .amount     (amount)
    );

    // -------------------------------------------------------------------------
    // A second DUT with PRICE=25 for parameterization test
    // -------------------------------------------------------------------------
    logic        dispense_25;
    logic [5:0]  change_25;
    logic        refund_out_25;
    logic [5:0]  amount_25;

    vending_machine #(.PRICE(25)) dut25 (
        .clk        (clk),
        .reset      (reset),
        .coin       (coin),
        .refund     (refund),
        .dispense   (dispense_25),
        .change     (change_25),
        .refund_out (refund_out_25),
        .amount     (amount_25)
    );

    // -------------------------------------------------------------------------
    // Clock generation
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Test counters
    // -------------------------------------------------------------------------
    int pass_count = 0;
    int fail_count = 0;

    // -------------------------------------------------------------------------
    // Task: apply one coin for one clock cycle, then idle
    // -------------------------------------------------------------------------
    task automatic insert_coin(input logic [1:0] c);
        @(negedge clk);
        coin = c;
        @(posedge clk); #1;  // sample outputs after posedge
        @(negedge clk);
        coin = 2'b00;        // deassert coin
    endtask

    // -------------------------------------------------------------------------
    // Task: check expected outputs one cycle after coin applied
    // -------------------------------------------------------------------------
    task automatic check(
        input string  test_name,
        input logic   exp_dispense,
        input logic [5:0] exp_change,
        input logic   exp_refund_out
    );
        if (dispense    !== exp_dispense  ||
            change      !== exp_change    ||
            refund_out  !== exp_refund_out)
        begin
            $display("FAIL [%s] | dispense=%0b(exp %0b) change=%0d(exp %0d) refund_out=%0b(exp %0b)",
                     test_name, dispense, exp_dispense, change, exp_change, refund_out, exp_refund_out);
            fail_count++;
        end else begin
            $display("PASS [%s] | dispense=%0b change=%0d¢ refund_out=%0b amount=%0d¢",
                     test_name, dispense, change, refund_out, amount);
            pass_count++;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: assert synchronous reset
    // -------------------------------------------------------------------------
    task automatic do_reset();
        @(negedge clk);
        reset = 1;
        coin  = 2'b00;
        refund = 0;
        @(posedge clk); #1;
        @(negedge clk);
        reset = 0;
    endtask

    // -------------------------------------------------------------------------
    // Coin encodings (local params for readability)
    // -------------------------------------------------------------------------
    localparam logic [1:0] NO_COIN  = 2'b00;
    localparam logic [1:0] NICKEL   = 2'b01;
    localparam logic [1:0] DIME     = 2'b10;
    localparam logic [1:0] QUARTER  = 2'b11;

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    initial begin
        // Waveform dump
        $dumpfile("vending_machine.vcd");
        $dumpvars(0, vending_machine_tb);

        $display("=============================================================");
        $display("  Vending Machine Controller — Testbench  (PRICE = 30¢)");
        $display("=============================================================");

        // Initial conditions
        reset  = 1;
        coin   = NO_COIN;
        refund = 0;
        repeat(3) @(posedge clk); #1;
        do_reset();

        // -----------------------------------------------------------------
        // TEST 1: 10¢ + 10¢ + 10¢ = 30¢ — dispense, no change
        // -----------------------------------------------------------------
        $display("\n--- Test 1: 10+10+10 = dispense, no change ---");
        insert_coin(DIME);   check("T1a no-dispense", 0, 0, 0);
        insert_coin(DIME);   check("T1b no-dispense", 0, 0, 0);
        insert_coin(DIME);   check("T1c dispense",    1, 0, 0);
        @(posedge clk); #1;  // let state reset propagate
        check("T1d idle after dispense", 0, 0, 0);

        // -----------------------------------------------------------------
        // TEST 2: 25¢ + 5¢ = 30¢ — dispense, no change
        // -----------------------------------------------------------------
        $display("\n--- Test 2: 25+5 = dispense, no change ---");
        do_reset();
        insert_coin(QUARTER); check("T2a S25", 0, 0, 0);
        insert_coin(NICKEL);  check("T2b dispense", 1, 0, 0);

        // -----------------------------------------------------------------
        // TEST 3: 25¢ + 10¢ = 35¢ — dispense, 5¢ change
        // -----------------------------------------------------------------
        $display("\n--- Test 3: 25+10 = dispense, 5¢ change ---");
        do_reset();
        insert_coin(QUARTER); check("T3a S25", 0, 0, 0);
        insert_coin(DIME);    check("T3b dispense+change", 1, 6'd5, 0);

        // -----------------------------------------------------------------
        // TEST 4: 25¢ + 25¢ = 50¢ — dispense, 20¢ change
        // -----------------------------------------------------------------
        $display("\n--- Test 4: 25+25 = dispense, 20¢ change ---");
        do_reset();
        insert_coin(QUARTER); check("T4a S25", 0, 0, 0);
        insert_coin(QUARTER); check("T4b dispense+20¢", 1, 6'd20, 0);

        // -----------------------------------------------------------------
        // TEST 5: 5¢ × 6 = 30¢ — dispense, no change
        // -----------------------------------------------------------------
        $display("\n--- Test 5: nickel x6 = dispense, no change ---");
        do_reset();
        insert_coin(NICKEL); check("T5a S5",  0, 0, 0);
        insert_coin(NICKEL); check("T5b S10", 0, 0, 0);
        insert_coin(NICKEL); check("T5c S15", 0, 0, 0);
        insert_coin(NICKEL); check("T5d S20", 0, 0, 0);
        insert_coin(NICKEL); check("T5e S25", 0, 0, 0);
        insert_coin(NICKEL); check("T5f dispense", 1, 0, 0);

        // -----------------------------------------------------------------
        // TEST 6: No coin — no dispense (idle check)
        // -----------------------------------------------------------------
        $display("\n--- Test 6: no coin → no dispense ---");
        do_reset();
        @(posedge clk); #1;
        check("T6a idle no dispense", 0, 0, 0);
        @(posedge clk); #1;
        check("T6b idle no dispense", 0, 0, 0);

        // -----------------------------------------------------------------
        // TEST 7: Reset in the middle of a transaction
        // -----------------------------------------------------------------
        $display("\n--- Test 7: reset mid-transaction ---");
        do_reset();
        insert_coin(DIME);   check("T7a dime", 0, 0, 0);
        insert_coin(DIME);   check("T7b 2nd dime", 0, 0, 0);
        do_reset();          // reset before reaching price
        @(posedge clk); #1;
        check("T7c after reset — no dispense", 0, 0, 0);
        if (amount !== 0) begin
            $display("FAIL [T7d] amount should be 0 after reset, got %0d", amount);
            fail_count++;
        end else begin
            $display("PASS [T7d] amount correctly 0 after reset");
            pass_count++;
        end

        // -----------------------------------------------------------------
        // TEST 8: Refund mid-transaction
        // -----------------------------------------------------------------
        $display("\n--- Test 8: refund mid-transaction ---");
        do_reset();
        insert_coin(DIME);   check("T8a dime", 0, 0, 0);
        insert_coin(NICKEL); check("T8b nickel (15¢)", 0, 0, 0);
        // Issue refund
        @(negedge clk);
        refund = 1;
        @(posedge clk); #1;
        if (refund_out !== 1 || change !== 6'd15) begin
            $display("FAIL [T8c] refund: refund_out=%0b change=%0d (exp refund_out=1 change=15)", refund_out, change);
            fail_count++;
        end else begin
            $display("PASS [T8c] refund issued: refund_out=1 change=15¢");
            pass_count++;
        end
        @(negedge clk);
        refund = 0;
        @(posedge clk); #1;
        check("T8d after refund — idle", 0, 0, 0);

        // -----------------------------------------------------------------
        // TEST 9: Single quarter overpay on low price
        //         PRICE=25 DUT — quarter alone should dispense
        // -----------------------------------------------------------------
        $display("\n--- Test 9: PRICE=25 DUT — single quarter = dispense, no change ---");
        do_reset();
        insert_coin(QUARTER);
        if (dispense_25 !== 1 || change_25 !== 0) begin
            $display("FAIL [T9] PRICE=25: dispense_25=%0b change_25=%0d (exp 1, 0)", dispense_25, change_25);
            fail_count++;
        end else begin
            $display("PASS [T9] PRICE=25: dispense on single quarter, no change");
            pass_count++;
        end

        // -----------------------------------------------------------------
        // TEST 10: PRICE=25 DUT — dime+quarter=35¢, dispense, 10¢ change
        // -----------------------------------------------------------------
        $display("\n--- Test 10: PRICE=25 DUT — dime+quarter = 35¢, 10¢ change ---");
        do_reset();
        insert_coin(DIME);
        insert_coin(QUARTER);
        if (dispense_25 !== 1 || change_25 !== 6'd10) begin
            $display("FAIL [T10] PRICE=25: dispense_25=%0b change_25=%0d (exp 1, 10)", dispense_25, change_25);
            fail_count++;
        end else begin
            $display("PASS [T10] PRICE=25: dispense + 10¢ change");
            pass_count++;
        end

        // -----------------------------------------------------------------
        // TEST 11: Rapid coin sequence — state accumulates correctly
        // -----------------------------------------------------------------
        $display("\n--- Test 11: rapid coin sequence 5+5+10+10 = 30¢ ---");
        do_reset();
        insert_coin(NICKEL); check("T11a S5",  0, 0, 0);
        insert_coin(NICKEL); check("T11b S10", 0, 0, 0);
        insert_coin(DIME);   check("T11c S20", 0, 0, 0);
        insert_coin(DIME);   check("T11d dispense", 1, 0, 0);

        // -----------------------------------------------------------------
        // TEST 12: Simultaneous refund + coin (refund takes priority in DUT)
        // -----------------------------------------------------------------
        $display("\n--- Test 12: refund takes priority over coin ---");
        do_reset();
        insert_coin(DIME);   check("T12a S10", 0, 0, 0);
        @(negedge clk);
        coin   = NICKEL;
        refund = 1;
        @(posedge clk); #1;
        if (refund_out !== 1) begin
            $display("FAIL [T12b] refund should take priority: refund_out=%0b", refund_out);
            fail_count++;
        end else begin
            $display("PASS [T12b] refund takes priority over coin");
            pass_count++;
        end
        coin   = NO_COIN;
        refund = 0;

        // -----------------------------------------------------------------
        // Summary
        // -----------------------------------------------------------------
        $display("\n=============================================================");
        $display("  RESULTS: %0d passed, %0d failed  (total %0d)",
                 pass_count, fail_count, pass_count + fail_count);
        $display("=============================================================\n");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED — review output above");

        $finish;
    end

    // -------------------------------------------------------------------------
    // Timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        #100000;
        $display("TIMEOUT — simulation exceeded limit");
        $finish;
    end

endmodule