module tb_fifo;

  localparam WIDTH = 8;
  localparam DEPTH = 16;

  reg clk, rst_n;
  reg push, pop;
  reg [WIDTH-1:0] din;

  wire [WIDTH-1:0] dout;
  wire full, empty;
  wire [31:0] count;

  fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n), .push(push), .din(din),
    .pop(pop), .dout(dout), .full(full), .empty(empty), .count(count)
  );

  // Reference model: circular buffer
  reg [WIDTH-1:0] ref_mem [0:DEPTH-1];
  integer ref_wr, ref_rd;
  integer ref_count;

  // Temps
  integer i;
  integer wr_ok, rd_ok;
  reg [WIDTH-1:0] exp;

  // clock
  initial clk = 0;
  always #5 clk = ~clk;

  // waves
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_fifo);
  end

  task do_reset;
    begin
      push = 0; pop = 0; din = 0;
      rst_n = 0;

      // reset reference model too
      ref_wr = 0; ref_rd = 0; ref_count = 0;

      repeat (3) @(posedge clk);
      rst_n = 1;
      @(posedge clk);
    end
  endtask

  task drive_push;
    input [WIDTH-1:0] v;
    begin
      @(negedge clk);
      push = 1; din = v; pop = 0;
      @(negedge clk);
      push = 0;
    end
  endtask

  task drive_pop;
    begin
      @(negedge clk);
      pop = 1; push = 0;
      @(negedge clk);
      pop = 0;
    end
  endtask

  task drive_push_pop;
    input [WIDTH-1:0] v;
    begin
      @(negedge clk);
      push = 1; din = v;
      pop  = 1;
      @(negedge clk);
      push = 0; pop = 0;
    end
  endtask

  // Scoreboard/checker
  always @(posedge clk) begin
    if (!rst_n) begin
      // keep reference in a known state during reset
      ref_wr <= 0;
      ref_rd <= 0;
      ref_count <= 0;
    end else begin
      // IMPORTANT: decide acceptance using DUT flags at posedge (no negedge sampling)
      wr_ok = (push && !full);
      rd_ok = (pop  && !empty);

      // If pop accepted, compare expected data
      if (rd_ok) begin
        exp = ref_mem[ref_rd];
        #1;
        if (dout !== exp) begin
          $fatal(1, "DATA MISMATCH: got=%0h exp=%0h", dout, exp);
        end

        // advance rd
        if (ref_rd == DEPTH-1) ref_rd = 0;
        else ref_rd = ref_rd + 1;

        ref_count = ref_count - 1;
      end

      // If push accepted, update ref model
      if (wr_ok) begin
        ref_mem[ref_wr] = din;

        // advance wr
        if (ref_wr == DEPTH-1) ref_wr = 0;
        else ref_wr = ref_wr + 1;

        ref_count = ref_count + 1;
      end

      // Give DUT combinational flags a tiny moment to update after NBA pointer updates
      #1;

      if (empty !== (ref_count == 0)) begin
        $fatal(1, "EMPTY mismatch: dut=%0b ref=%0b ref_count=%0d",
               empty, (ref_count==0), ref_count);
      end

      if (full !== (ref_count == DEPTH)) begin
        $fatal(1, "FULL mismatch: dut=%0b ref=%0b ref_count=%0d",
               full, (ref_count==DEPTH), ref_count);
      end
    end
  end

  initial begin
    $display("TB start");
    do_reset();

    // Fill to full
    for (i = 0; i < DEPTH; i = i + 1) begin
      drive_push(i[WIDTH-1:0]);
    end
    if (!full) $fatal(1, "Expected full after filling");

    // Overflow attempt (ignored)
    drive_push(8'hAA);
    if (!full) $fatal(1, "Expected still full after overflow attempt");

    // Drain to empty
    for (i = 0; i < DEPTH; i = i + 1) begin
      drive_pop();
    end
    if (!empty) $fatal(1, "Expected empty after draining");

    // Underflow attempt (ignored)
    drive_pop();
    if (!empty) $fatal(1, "Expected still empty after underflow attempt");

    // Wraparound stress
    for (i = 0; i < DEPTH*2; i = i + 1) begin
      drive_push(i[WIDTH-1:0]);
      if (i % 2 == 0) drive_pop();
    end
    while (!empty) drive_pop();

    // Simultaneous push+pop
    drive_push(8'h11);
    drive_push(8'h22);
    drive_push(8'h33);
    for (i = 0; i < 5; i = i + 1) begin
      drive_push_pop($random);
    end
    while (!empty) drive_pop();

    $display("ALL TESTS PASSED ✅");
    $finish;
  end

endmodule
