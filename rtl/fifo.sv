module fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 16
)(
  input              clk,
  input              rst_n,   // active-low synchronous reset
  input              push,
  input  [WIDTH-1:0] din,
  input              pop,
  output reg [WIDTH-1:0] dout,
  output             full,
  output             empty,
  output reg [31:0]  count   // fixed width so Verilog compilers don't fight
);

  // Verilog-friendly clog2
  function integer clog2;
    input integer value;
    integer i;
    begin
      value = value - 1;
      for (i = 0; value > 0; i = i + 1)
        value = value >> 1;
      clog2 = i;
    end
  endfunction

  localparam ADDR_W = clog2(DEPTH);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [ADDR_W:0]  wr_ptr, rd_ptr; // extra bit for full/empty

  wire wr_en = push && !full;
  wire rd_en = pop  && !empty;

  assign empty = (wr_ptr == rd_ptr);

  assign full  = (wr_ptr[ADDR_W] != rd_ptr[ADDR_W]) &&
                 (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]);

  // write
  always @(posedge clk) begin
    if (wr_en) begin
      mem[wr_ptr[ADDR_W-1:0]] <= din;
    end
  end

  // read (registered output)
  always @(posedge clk) begin
    if (!rst_n) begin
      dout <= {WIDTH{1'b0}};
    end else if (rd_en) begin
      dout <= mem[rd_ptr[ADDR_W-1:0]];
    end
  end

  // pointers + count
  always @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr <= { (ADDR_W+1){1'b0} };
      rd_ptr <= { (ADDR_W+1){1'b0} };
      count  <= 32'd0;
    end else begin
      case ({wr_en, rd_en})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: count <= count;
      endcase

      if (wr_en) wr_ptr <= wr_ptr + 1;
      if (rd_en) rd_ptr <= rd_ptr + 1;
    end
  end

endmodule
