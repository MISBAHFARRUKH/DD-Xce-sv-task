module tb_router;

    // Testbench signals
    logic clk;
    logic rst;
    logic dst_ready;
    logic src_valid;
    logic src_ready;
    logic [1:0] dst_addr;
    logic [1:0] p_type;  // Renamed from 'type' to 'p_type'
    logic [7:0] payload;
    logic eop;

    // Signals for noc_router
    logic [12:0] src_data;
    logic [7:0] buffer00;
    logic [7:0] buffer01;
    logic [7:0] buffer10;
    logic [7:0] buffer11;
    logic dst_valid;

    // Instantiate packet_generator
    packet_generator uut_gen (
        .clk(clk),
        .rst(rst),
        .dst_ready(dst_ready),
        .src_valid(src_valid),
        .src_ready(src_ready),
        .dst_addr(dst_addr),
        .p_type(p_type),
        .payload(payload),
        .eop(eop)
    );

    // Instantiate noc_router
    noc_router #(
        .DataWidth(13)
    ) uut_router (
        .clk(clk),
        .rst(rst),
        .src_valid(src_valid),
        .src_data(src_data),
        .buffer00(buffer00),
        .buffer01(buffer01),
        .buffer10(buffer10),
        .buffer11(buffer11),
        .dst_valid(dst_valid),
        .dst_ready(dst_ready)
    );


    always begin
        #10 clk = ~clk; 
    end


    task monitor;
        $display("Time: %0t, src_valid: %b, src_ready: %b, dst_ready: %b, dst_valid: %b, dst_addr: %b, p_type: %b, payload: %h, eop: %b",
                 $time, src_valid, src_ready, dst_ready, dst_valid, dst_addr, p_type, payload, eop);
        $display("Buffer00: %h, Buffer01: %h, Buffer10: %h, Buffer11: %h", buffer00, buffer01, buffer10, buffer11);
    endtask

    
    task driver(
        input logic [1:0] addr,
        input logic [1:0] packet_type,   
        input logic [7:0] data,
        input logic end_of_packet
    );

        begin
            dst_addr = addr;
            p_type = packet_type;
            payload = data;
            eop = end_of_packet;
        end
    endtask

    initial begin
        clk = 0;
        rst = 0;
        dst_ready = 0;


        rst = 1;
        #10;
        rst = 0;
    
        dst_ready = 1;


        driver(2'b00, 2'b01, 8'hAB, 1'b1);
        #10;
        driver(2'b01, 2'b10, 8'hCD, 1'b0);
        #10;

        monitor();
        #10;

        $finish;
    end

endmodule
