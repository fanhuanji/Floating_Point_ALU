module Add_Sub(
	input [31:0] InA,InB, 
	input Operation,				  
	output [31:0] Out              
	);

	wire Oper;
	wire En;
	wire SignOut;

	wire [31:0] TempA,TempB;
	wire [23:0] MemA,MemB;
	wire [7:0] ExpDiff;


	wire [23:0] MemOp;
	wire [7:0] ExpOp;

	wire [24:0] MemAdd;
	wire [30:0] FullAdd;

	wire [23:0] PreMemSub;
	wire [24:0] MemSub;
	wire [30:0] FullSub;
	wire [24:0] MemDiff; 
	wire [7:0] ExpSub;

	assign {En,TempA,TempB} = (InA[30:0] < InB[30:0]) ? {1'b1,InB,InA} : {1'b0,InA,InB};

	assign Exception = (&TempA[30:23]) | (&TempB[30:23]);
	assign SignOut = Operation ? En ? !TempA[31] : TempA[31] : TempA[31] ;
	assign Oper = Operation ? TempA[31] ^ TempB[31] : ~(TempA[31] ^ TempB[31]);

	assign MemA = (|TempA[30:23]) ? {1'b1,TempA[22:0]} : {1'b0,TempA[22:0]};
	assign MemB = (|TempB[30:23]) ? {1'b1,TempB[22:0]} : {1'b0,TempB[22:0]};

	assign ExpDiff = TempA[30:23] - TempB[30:23];
	assign MemOp = MemB >> ExpDiff;
	assign ExpOp = TempB[30:23] + ExpDiff; 
	assign perform = (TempA[30:23] == ExpOp);

	assign MemAdd = (perform & Oper) ? (MemA + MemOp) : 25'd0; 
	assign FullAdd[22:0] = MemAdd[24] ? MemAdd[23:1] : MemAdd[22:0];
	assign FullAdd[30:23] = MemAdd[24] ? (1'b1 + TempA[30:23]) : TempA[30:23];

	assign PreMemSub = (perform & !Oper) ? ~(MemOp) + 24'd1 : 24'd0 ; 
	assign MemSub = perform ? (MemA + PreMemSub) : 25'd0;
	PriorityEncoder pe(MemSub,TempA[30:23],MemDiff,ExpSub);
	assign FullSub[30:23] = ExpSub;
	assign FullSub[22:0] = MemDiff[22:0];

	assign Out = Exception ? 32'b0 : ((!Oper) ? {SignOut,FullSub} : {SignOut,FullAdd});

endmodule