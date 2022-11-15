module Add1 (
  input a,
  input b,
  input c,
  output p,
  output g,
  output s
);
  assign p = a | b;
  assign g = a & b;
  assign s = a ^ b ^ c;
endmodule

module CLA4 (
  input [3:0] P,
  input [3:0] G,
  input C_in,
  output [4:1] Ci,
  output Pm, Gm
);
  assign Ci[1] = G[0] | P[0] & C_in;
  assign Ci[2] = G[1] | P[1] & G[0] | P[1] & P[0] & C_in;
  assign Ci[3] = G[2] | P[2] & G[1] | P[2] & P[1] & G[0] | P[2] & P[1] & P[0] & C_in;
  assign Ci[4] = G[3] | P[3] & G[2] | P[3] & P[2] & G[1] | P[3] & P[2] & P[1] & G[0] | P[3] & P[2] & P[1] & P[0] & C_in;

  assign Pm = P[0] & P[1] & P[2] & P[3];
  assign Gm = G[3] | P[3] & G[2] | P[3] & P[2] & G[1] | P[3] & P[2] & P[1] & G[0];
endmodule

module Add4 (
  input   [3:0] a,
  input   [3:0] b,
  input       C_in,
  output  [3:0] S,
  output C_out,
  output Pm, Gm
);
  wire [4:0] c;
  wire [3:0] p;
  wire [3:0] g;

  assign c[0] = C_in;
  genvar i;
  generate
    for (i = 0; i <= 3; i = i + 1) begin: Add4
      Add1 ui(a[i], b[i], c[i], p[i], g[i], S[i]);
    end
  endgenerate

  CLA4 cla (
    .P(p),
    .G(g),
    .C_in(C_in),
    .Ci(c[4:1]),
    .Pm(Pm),
    .Gm(Gm)
  );
  assign C_out = c[4];
endmodule

module Add16 (
  input   [15:0] a,
  input   [15:0] b,
  input       C_in,
  output  [15:0] S,
  output      C_out,
  output      Pm, Gm
);  
  wire [4:0] c;
  wire [3:0] P;
  wire [3:0] G;

  assign c[0] = C_in;
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 4) begin: ite
      Add4 ui (
        .a(a[i + 3 : i]),
        .b(b[i + 3 : i]),
        .C_in(c[i / 4]),
        .S(S[i + 3 : i]),
        .Gm(G[i / 4]),
        .Pm(P[i / 4])
      );
    end
  endgenerate

  CLA4 cla(
    .P(P),
    .G(G),
    .C_in(C_in),
    .Ci(c[4:1]),
    .Pm(Pm),
    .Gm(Gm)
  );
  assign C_out = c[4];
endmodule

module Add32 (
  input [31:0] a,
  input [31:0] b,
  output reg [31:0] sum
);
  wire [1:0] P;
  wire [1:0] G;
  wire [31:0] S;
  
  Add16 u1 (
    .a(a[15:0]),
    .b(b[15:0]),
    .C_in(1'b0),
    .S(S[15:0]),
    .Pm(P[0]),
    .Gm(G[0])
  );

  Add16 u2 (
    .a(a[31:16]),
    .b(b[31:16]),
    .C_in(G[0]),
    .S(S[31:16]),
    .Pm(P[1]),
    .Gm(G[1])
  );

  always @(S) begin
    # 1 sum = S;
  end
endmodule
