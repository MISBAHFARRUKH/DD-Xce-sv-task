module packet_generator (
    input logic clk,
    input logic rst,
    input logic dst_ready,
    output logic src_valid,    // Declared as output instead of logic
    output logic src_ready,
    output logic [1:0] dst_addr, 
    output logic [1:0] p_type, 
    output logic [7:0] payload,
    output logic eop 
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        SEND = 2'b01,
        WAIT = 2'b10
    } STATES;

    STATES state, next_state;
    logic [3:0] counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            src_valid <= 0;
            src_ready <= 1;
            dst_addr <= 0;
            p_type <= 0;
            payload <= 0;
            eop <= 0;
        end else begin
            state <= next_state;
            
            if (state == SEND && dst_ready) begin
                src_valid <= 1;
                dst_addr <= $random % 4;  
                p_type <= $random % 4;  
                payload <= $random; 
                eop <= ($random % 2); 
            end else begin
                src_valid <= 0;
            end
        end
    end

    always_comb begin
        case (state)
            IDLE: begin
                next_state = SEND;
            end
            SEND: begin
                if (dst_ready && src_valid) begin
                    next_state = (eop) ? WAIT : SEND;
                end else begin
                    next_state = SEND;
                end
            end
            WAIT: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule
