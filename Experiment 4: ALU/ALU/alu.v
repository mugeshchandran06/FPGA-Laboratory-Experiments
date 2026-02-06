module ALU (
    input  wire        clk_50MHz,   // 50 MHz FPGA clock
    input  wire        reset,
    input  wire [2:0]  A,            // 3-bit input A
    input  wire [2:0]  B,            // 3-bit input B
    input  wire [2:0]  ALU_Sel,
    output reg  [7:0]  ALU_Out,
    output reg         CarryOut
);

    // ================= CLOCK DIVIDER (50 MHz → 1 Hz) =================
    reg [25:0] clk_count;
    reg        clk_1Hz;

    always @(posedge clk_50MHz or posedge reset) begin
        if (reset) begin
            clk_count <= 26'd0;
            clk_1Hz   <= 1'b0;
        end else if (clk_count == 26'd24_999_999) begin
            clk_count <= 26'd0;
            clk_1Hz   <= ~clk_1Hz;
        end else begin
            clk_count <= clk_count + 1;
        end
    end

    // ================= ZERO EXTENSION =================
    wire [7:0] A_ext = {5'b00000, A};
    wire [7:0] B_ext = {5'b00000, B};

    // ================= COUNTER & LFSR =================
    reg [7:0] counter;
    reg [7:0] lfsr;
    wire      feedback;

    // LFSR polynomial: x^8 + x^6 + x^5 + x^4 + 1
    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

    always @(posedge clk_1Hz or posedge reset) begin
        if (reset) begin
            counter <= 8'b00000000;
            lfsr    <= 8'b00000001;   // non-zero seed
        end else begin
            case (ALU_Sel)
                3'b110: counter <= counter + 1;
                3'b111: lfsr    <= {lfsr[6:0], feedback};
                default: begin
                    counter <= counter;
                    lfsr    <= lfsr;
                end
            endcase
        end
    end

    // ================= COMBINATIONAL ALU =================
    always @(*) begin
        CarryOut = 1'b0;

        case (ALU_Sel)
            3'b000: {CarryOut, ALU_Out} = A_ext + B_ext; // ADD
            3'b001: {CarryOut, ALU_Out} = A_ext - B_ext; // SUB
            3'b010: ALU_Out = A_ext & B_ext;             // AND
            3'b011: ALU_Out = A_ext | B_ext;             // OR
            3'b100: ALU_Out = A_ext ^ B_ext;             // XOR
            3'b101: ALU_Out = ~A_ext;                    // NOT A
            3'b110: ALU_Out = counter;                   // Counter
            3'b111: ALU_Out = lfsr;                      // LFSR
            default: ALU_Out = 8'b0;
        endcase
    end

endmodule
