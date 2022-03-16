module \$_ALDFF_PN_ (D, C, L, AD, Q);
input D, C, L, AD;
output reg Q;

wire RN, SN;

\$_OR_ R_NAND ( .Y(RN), .A(L), .B(AD) );

\$_NAND_ S_NAND ( .Y(SN), .A(L), .B(AD) );

\$_DFFSR_PNN_ SRFF (.C(C), 
    .S(SN), 
    .R(RN), 
    .D(D), 
    .Q(Q)
);

endmodule
