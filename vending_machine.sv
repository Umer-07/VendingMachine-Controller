// =============================================================================
// Vending Machine Controller — Parameterized Price
// =============================================================================
// Description : FSM-based vending machine controller. Accepts nickel, dime,
//               and quarter coin inputs for a configurable product price.
//               Tracks inserted amount, dispenses when enough is inserted,
//               and returns correct change.
//
// Parameters  : PRICE      — product price in cents (default 30)
//               MAX_CHANGE  — max returnable change in cents (default 45)
//
// Inputs      : clk        — system clock (posedge triggered)
//               reset      — synchronous active-high reset
//               coin[1:0]  — coin input encoding
//                            2'b00 = no coin
//                            2'b01 = nickel  (5¢)
//                            2'b10 = dime    (10¢)
//                            2'b11 = quarter (25¢)
//               refund     — active-high refund request
//
// Outputs     : dispense   — 1 when product should be dispensed (1 cycle pulse)
//               change     — cents of change to return (valid when dispense=1
//                            or refund_out=1)
//               refund_out — 1 when refund is being issued (1 cycle pulse)
//               amount     — current inserted total (for display / debug)
//
// Notes       : Amount is tracked in multiples of 5 cents (GCD of all coins).
//               State is encoded as the current amount (0..PRICE-5 in steps of 5).
//               Any overpayment is returned as change immediately.
// =============================================================================

module vending_machine #(
    parameter int PRICE      = 30,   // product price in cents
    parameter int MAX_CHANGE = 45    // worst case: PRICE-5 inserted + quarter
) (
    input  logic        clk,
    input  logic        reset,
    input  logic [1:0]  coin,        // 00=none, 01=nickel, 10=dime, 11=quarter
    input  logic        refund,      // request refund of current amount

    output logic        dispense,    // pulse: product dispensed
    output logic [5:0]  change,      // cents of change (0–45)
    output logic        refund_out,  // pulse: refund issued
    output logic [5:0]  amount       // current total inserted (for display)
);

    // -------------------------------------------------------------------------
    // Internal state: current accumulated amount (in cents, multiples of 5)
    // -------------------------------------------------------------------------
    // We use a plain integer register rather than named enum states so that
    // PRICE can be any multiple of 5 set at elaboration time.
    // -------------------------------------------------------------------------
    localparam int STATE_BITS = 6;   // enough for 0..60 cents

    logic [STATE_BITS-1:0] state, next_state;

    // -------------------------------------------------------------------------
    // Coin value decoder (combinational)
    // -------------------------------------------------------------------------
    logic [4:0] coin_val;
    always_comb begin
        unique case (coin)
            2'b00: coin_val = 5'd0;
            2'b01: coin_val = 5'd5;
            2'b10: coin_val = 5'd10;
            2'b11: coin_val = 5'd25;
        endcase
    end

    // -------------------------------------------------------------------------
    // Next-state + output logic (combinational)
    // -------------------------------------------------------------------------
    logic [STATE_BITS-1:0] tentative;

    always_comb begin
        // Defaults
        next_state  = state;
        dispense    = 1'b0;
        change      = 6'd0;
        refund_out  = 1'b0;
        tentative   = state + {1'b0, coin_val};

        if (refund) begin
            // ---- REFUND path ----
            refund_out = 1'b1;
            change     = state;        // return everything inserted
            next_state = '0;           // go back to S0

        end else if (coin != 2'b00) begin
            // ---- COIN INSERTED path ----
            if (tentative >= STATE_BITS'(PRICE)) begin
                // Enough money — dispense and give change
                dispense   = 1'b1;
                change     = 6'(tentative - STATE_BITS'(PRICE));
                next_state = '0;       // back to S0 after dispense
            end else begin
                // Not enough yet — accumulate
                next_state = tentative;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Sequential state register (synchronous reset)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (reset)
            state <= '0;
        else
            state <= next_state;
    end

    // -------------------------------------------------------------------------
    // Amount output (registered for clean readback)
    // -------------------------------------------------------------------------
    assign amount = state;

endmodule