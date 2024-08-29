module noc_router #(
    parameter DataWidth = 13        // Data Width = 2-bit address + 2-bit packet type + 8-bit payload + 1-bit eop
)(
    input logic clk,
    input logic rst,

    input logic src_valid,
    input logic [DataWidth-1:0] src_data,

    output logic [7:0] buffer00,
    output logic [7:0] buffer01,
    output logic [7:0] buffer10,
    output logic [7:0] buffer11,

    output logic dst_valid,
    input logic dst_ready
);

    logic [DataWidth-1:0] fifo_buffer [3:0];
    logic [3:0] fifo_write, fifo_read;
    logic [1:0] packet_type;
    logic [1:0] dst_addr;
    logic [7:0] packet_payload;
    logic fifo_full, fifo_empty;

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        WRITE = 2'b01,
        READ = 2'b10
    } FIFO_STATE;

    FIFO_STATE fifo_state, next_fifo_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_write <= 0;
            fifo_read <= 0;
            fifo_state <= IDLE;
        end else begin
            fifo_state <= next_fifo_state;

            if (fifo_state == WRITE) begin
                fifo_buffer[fifo_write] <= src_data;
                fifo_write <= fifo_write + 1;
            end
            if (fifo_state == READ) begin
                fifo_read <= fifo_read + 1;
            end
        end
    end

    always_comb begin
        case (fifo_state)
            IDLE: begin
                if (src_valid && !fifo_full) begin
                    next_fifo_state = WRITE;
                end else if (!fifo_empty && dst_ready) begin
                    next_fifo_state = READ;
                end else begin
                    next_fifo_state = IDLE;
                end
            end
            WRITE: begin
                if (!src_valid || fifo_full) begin
                    next_fifo_state = IDLE;
                end else begin
                    next_fifo_state = WRITE;
                end
            end
            READ: begin
                if (!dst_ready || fifo_empty) begin
                    next_fifo_state = IDLE;
                end else begin
                    next_fifo_state = READ;
                end
            end
            default: next_fifo_state = IDLE;
        endcase
    end

    assign fifo_full = (fifo_write == fifo_read - 1); // Flags for FIFO 
    assign fifo_empty = (fifo_write == fifo_read);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            dst_addr <= 0;
            packet_type <= 0;
            packet_payload <= 0;
        end else if (fifo_state == READ) begin
            dst_addr <= fifo_buffer[fifo_read][12:11];
            packet_type <= fifo_buffer[fifo_read][10:9];
            packet_payload <= fifo_buffer[fifo_read][8:1];
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer00 <= 0;
            buffer01 <= 0;
            buffer10 <= 0;
            buffer11 <= 0;
        end else if (fifo_state == READ && packet_type != 2'b11) begin // FIFO will not store payload for the reserved packet type
            case (dst_addr)
                2'b00: buffer00 <= packet_payload;
                2'b01: buffer01 <= packet_payload;
                2'b10: buffer10 <= packet_payload;
                2'b11: buffer11 <= packet_payload;
            endcase
        end
    end

    assign dst_valid = (fifo_state == READ);

endmodule
