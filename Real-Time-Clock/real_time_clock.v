module real_time_clock(
    input        CLOCK_50,        // 50 MHz clock
    input        KEY0,            // Reset (active LOW push button)
    output reg [6:0] HEX0,        // Seconds ones
    output reg [6:0] HEX1,        // Seconds tens
    output reg [6:0] HEX2,        // Minutes ones
    output reg [6:0] HEX3,        // Minutes tens
    output reg [6:0] HEX4,        // Hours ones
    output reg [6:0] HEX5         // Hours tens
);

//Reset

    wire rst = ~KEY0;

//50MHz to 1Hz clock

    reg [25:0] counter = 0;
    reg clk_1hz = 0;

    always @(posedge CLOCK_50) begin
        if (rst) begin
            counter <= 0;
            clk_1hz <= 0;
        end
        else begin
            if (counter == 25_000_000 - 1) begin
                counter <= 0;
                clk_1hz <= ~clk_1hz;
            end
            else
                counter <= counter + 1;
        end
    end

//Time register (24 hour format)

    reg [5:0] sec = 0;
    reg [5:0] min = 0;
    reg [4:0] hour = 0;

    always @(posedge clk_1hz or posedge rst) begin
        if (rst) begin
            sec  <= 0;
            min  <= 0;
            hour <= 0;
        end
        else begin
            if (sec == 59) begin
                sec <= 0;
                if (min == 59) begin
                    min <= 0;
                    if (hour == 23)
                        hour <= 0;
                    else
                        hour <= hour + 1;
                end
                else
                    min <= min + 1;
            end
            else
                sec <= sec + 1;
        end
    end

//Split digit

    wire [3:0] sec_ones  = sec % 10;
    wire [3:0] sec_tens  = sec / 10;
    wire [3:0] min_ones  = min % 10;
    wire [3:0] min_tens  = min / 10;
    wire [3:0] hr_ones   = hour % 10;
    wire [3:0] hr_tens   = hour / 10;
	 
//7 Segment Decoder

    function [6:0] seven_seg;
        input [3:0] digit;
        begin
            case(digit)
                4'd0: seven_seg = 7'b1000000;
                4'd1: seven_seg = 7'b1111001;
                4'd2: seven_seg = 7'b0100100;
                4'd3: seven_seg = 7'b0110000;
                4'd4: seven_seg = 7'b0011001;
                4'd5: seven_seg = 7'b0010010;
                4'd6: seven_seg = 7'b0000010;
                4'd7: seven_seg = 7'b1111000;
                4'd8: seven_seg = 7'b0000000;
                4'd9: seven_seg = 7'b0010000;
                default: seven_seg = 7'b1111111;
            endcase
        end
    endfunction

//Outputs

    always @(*) begin
        HEX0 = seven_seg(sec_ones);
        HEX1 = seven_seg(sec_tens);
        HEX2 = seven_seg(min_ones);
        HEX3 = seven_seg(min_tens);
        HEX4 = seven_seg(hr_ones);
        HEX5 = seven_seg(hr_tens);
    end

endmodule
