module test_tb;
    
    reg [7:0] WRITEDATA;
    reg [2:0] WRITEREG, READREG1, READREG2;
    reg CLK, RESET, WRITEENABLE; 
    wire [7:0] REGOUT1, REGOUT2;
    wire [31:0] PC;
    reg [7:0] MEMORY[0:1023];
    wire [31:0] INS_MEMORY;
    
    cpu mycpu(RESET,CLK,PC,INS_MEMORY); //give Instruction to the cpu module depend on the pc
    assign #2 INS_MEMORY={MEMORY[PC+3],MEMORY[PC+2],MEMORY[PC+1],MEMORY[PC]}; //get the instruction from memory
    
       
    initial
    begin
        CLK = 1'b1; //give the instructions as a array
        {MEMORY[3],MEMORY[2],MEMORY[1],MEMORY[0]}=32'b00000110000000100000000000000000;
        {MEMORY[7],MEMORY[6],MEMORY[5],MEMORY[4]}=32'b00000000000000010000000011110111;
        {MEMORY[11],MEMORY[10],MEMORY[9],MEMORY[8]}=32'b00000000000000110000000011110000;
        {MEMORY[15],MEMORY[14],MEMORY[13],MEMORY[12]}=32'b00000000000000010000000000000101;
        {MEMORY[19],MEMORY[18],MEMORY[17],MEMORY[16]}=32'b00000000000000110000000000000101;
        {MEMORY[23],MEMORY[22],MEMORY[21],MEMORY[20]}=32'b00000111111111100000000100000011;
        {MEMORY[27],MEMORY[26],MEMORY[25],MEMORY[24]}=32'b00000010000000100000000100000011;
        {MEMORY[31],MEMORY[30],MEMORY[29],MEMORY[28]}=32'b00000011000000010000000100000001;
        {MEMORY[35],MEMORY[34],MEMORY[33],MEMORY[32]}=32'b00000010000000100000000100000011;
        {MEMORY[39],MEMORY[38],MEMORY[37],MEMORY[36]}=32'b00000101000001010000010000000010;
        {MEMORY[43],MEMORY[42],MEMORY[41],MEMORY[40]}=32'b00000011000000010000000100000001;
        {MEMORY[47],MEMORY[46],MEMORY[45],MEMORY[44]}=32'b00000100000001010000010000000001;
        
        
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, test_tb);
        
        // assign values with time to input signals to see output 
        RESET = 1'b0;
        #1 RESET= 1'b1;
        #1 RESET= 1'b0;
        
        

        
        #180
        $finish;
    end
    
    // clock signal generation
    always
        #5 CLK = ~CLK;
        

endmodule




















module cpu(RESET,CLK,PC,INS_FROM_MEMORY);

input RESET,CLK;
input [31:0] INS_FROM_MEMORY;

output reg [31:0] PC;

wire [31:0]OUTPUT_PC;


control_unit my_control_unit(RESET,CLK,PC,INS_FROM_MEMORY,OUTPUT_PC);


always @(RESET) begin //set the pc value depend on the RESET to start the programme
    PC=-4;
end

always @(posedge CLK) begin //update the pc value depend on the positive clock edge
   
        #1 PC=OUTPUT_PC; //update the pc
end  
endmodule





















module control_unit(RESET,CLK,PC,INSTRUCTION,OUTPUT_PC);

input RESET,CLK;
input [31:0] INSTRUCTION,PC;

output [31:0] OUTPUT_PC;


wire [2:0] WRITEREG, READREG1, READREG2;
wire [3:0] OPCODE;
wire [7:0] REGOUT1, REGOUT2,ALURESULT;
wire ZERO,beq_signal;
wire [31:0] IMMIDIATE,OUTPUT_ADDED_PC,OUT_MUX3,PC_INCREMENT;

reg [7:0] DATA2;
reg [2:0] ALUOP;
reg MUX1,MUX2,WRITEENABLE,MUX3,MUX4;

assign   PC_INCREMENT=PC+4; //increment the pc value by 4
assign   WRITEREG=INSTRUCTION[18:16]; //decode the instruction and get Writereg
assign   READREG1=INSTRUCTION[10:8];  //decode the instruction and get readreg1
assign   READREG2=INSTRUCTION[2:0];   //decode the instruction and get readreg2
assign  #1 OPCODE=INSTRUCTION[27:24];   //decode the instruction and get opcode

and(beq_signal,MUX4,ZERO);//make and operation between zero signal and MUx4 to check whether equal the two registers of beq
adder myadder(IMMIDIATE,PC_INCREMENT,OUTPUT_ADDED_PC); //extended imidiate value in distination field is being added to pc
signExtention mysignExtention(INSTRUCTION[23:16],IMMIDIATE);//pass the imidate value in distination field to sign extension
reg_file File(ALURESULT, REGOUT1, REGOUT2, WRITEREG, READREG1, READREG2, WRITEENABLE, CLK, RESET); //reg file control 
alu mainalu(REGOUT1, DATA2, ALURESULT, ALUOP,ZERO); //alu control
mux_2_to_1 mymux3(OUTPUT_ADDED_PC,PC_INCREMENT,MUX3,OUT_MUX3);//check wheather jump or not when jump immidiate added is taken
mux_2_to_1 mymux4(OUTPUT_ADDED_PC,OUT_MUX3,beq_signal,OUTPUT_PC);//check wheather beq and output ZERO,or not 



always @(RESET) //when reset zero make write enable to zero for avoiding written garbage to register
begin
  WRITEENABLE=1'b0 ; 
end

always @(OPCODE)  //depend on the opcode generate the control signals 
begin
   case(OPCODE)
        4'b0010 :begin       //add
                WRITEENABLE=1'b1; //write enable signal
                MUX1=1'b1; //mux1 signal
                MUX2=1'b0; //mux2 signal
                MUX3=1'b0;
                MUX4=1'b0;
                ALUOP=3'b001; //aluop code
                end      
        4'b0011 :begin     //sub
                WRITEENABLE=1'b1;
                MUX1=1'b0;
                MUX2=1'b0;
                MUX3=1'b0;
                MUX4=1'b0;
                ALUOP=3'b001;
                end          
        4'b0101 :begin     //or
                WRITEENABLE=1'b1;
                MUX1=1'b1;
                MUX2=1'b0;
                MUX3=1'b0;
                MUX4=1'b0;
                ALUOP=3'b011;
                end               
        4'b0100 :begin    //and
                WRITEENABLE=1'b1;
                MUX1=1'b1;
                MUX2=1'b0;
                MUX3=1'b0;
                MUX4=1'b0;
                ALUOP=3'b010;
                end               
        4'b0001 :begin      //mov
                WRITEENABLE=1'b1;
                MUX1=1'b1;
                MUX2=1'b0;
                MUX3=1'b0;
                MUX4=1'b0;
                ALUOP=3'b000;
                end              
        4'b0000 :begin     //lodi
                WRITEENABLE=1'b1;
                MUX1=1'b0;
                MUX2=1'b1;
                MUX3=1'b0;
                MUX4=1'b0;
                ALUOP=3'b000;
                end
        4'b0110 :begin     //J instruction
                WRITEENABLE=1'b0;
                MUX1=1'b0;
                MUX2=1'b1;
                MUX3=1'b1;
                MUX4=1'b0;
                ALUOP=3'b000;
                end       

        4'b0111 :begin     //beq instruction
                WRITEENABLE=1'b0;
                MUX1=1'b0;
                MUX2=1'b0;
                MUX3=1'b0;
                MUX4=1'b1;
                ALUOP=3'b001;
                end                      
              
    endcase
   
end


always @(MUX2 or MUX1 or REGOUT2 or INSTRUCTION) //depend on mux1,mux2 give the operand2{DATA2} to the alu
begin
    if(MUX2==1'b1) begin
            DATA2=INSTRUCTION[7:0];
            
        end
    else if (MUX1==1'b1) begin
        DATA2=REGOUT2;
    end else begin
        DATA2=~REGOUT2+1;
    end
end


endmodule















module reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);
	input [2:0] INADDRESS, OUT1ADDRESS,OUT2ADDRESS; //declare inputs
	input [7:0] IN; //declare input In
	input WRITE,CLK,RESET;
	output  [7:0] OUT1,OUT2; //declare outputs
    reg [7:0] register[0:7]; //register file with 8 registers
	integer i; //declare two integers
    integer j;

   

    always @(OUT1ADDRESS or OUT2ADDRESS) //define always block for select OUT1,OUT2 registers
    begin                                //depend on the OUT1ADDRESS and OUT2ADDRESS
        case(OUT1ADDRESS) //select integer i on OUT1ADDRESS
                3'b000 :i=0;
                3'b001 :i=1;
                3'b010 :i=2;
                3'b011 :i=3;
                3'b100 :i=4;
                3'b101 :i=5;
                3'b110 :i=6;
                3'b111 :i=7;
                
        endcase
                
        case(OUT2ADDRESS)  //select integer i on OUT2ADDRESS
                3'b000 :j=0;
                3'b001 :j=1;
                3'b010 :j=2;
                3'b011 :j=3;
                3'b100 :j=4;
                3'b101 :j=5;
                3'b110 :j=6;
                3'b111 :j=7;
                
        endcase

    end


	always @(posedge CLK or  RESET) //define always block for write and reset the register 
	begin                           //on the clock edge and reset level
        if(RESET==1'b1) //if reset is 1 then every register become zero 
            #2  //delay for reset the register file
            begin
            register[0]=8'b00000000;
            register[1]=8'b00000000;
            register[2]=8'b00000000;
            register[3]=8'b00000000;
            register[4]=8'b00000000;
            register[5]=8'b00000000;
            register[6]=8'b00000000;
            register[7]=8'b00000000;
            end
        else if(WRITE==1'b1) //if write is enable regiter is writting depend on INADDRESS
            #2               //on the clock edge,#2 for give delay for writting
            begin
                case(INADDRESS) //write register on INADDRESS
                    3'b000 :register[0]=IN;
                    3'b001 :register[1]=IN;
                    3'b010 :register[2]=IN;
                    3'b011 :register[3]=IN;
                    3'b100 :register[4]=IN;
                    3'b101 :register[5]=IN;
                    3'b110 :register[6]=IN;
                    3'b111 :register[7]=IN;
                
                endcase
            end

        
	end
    assign #2 OUT1=register[i];  //Set OUT1 asynchronsly 
    assign #2 OUT2=register[j];  //Set OUT2 asynchronsly ,OUT1,OUT2 are changing when  assign value is changing
	
endmodule




















module  alu(DATA1, DATA2, RESULT, SELECT,ZERO); //module deleration
	input [7:0] DATA1,DATA2;  //define input  two 8 bit buses for oprands
	input [2:0] SELECT; //define input 3 bit buse for alu op selector
	
    output reg [7:0] RESULT; //define 8 bit out bus as a reg type
    output ZERO;

    wire wire1,wire2,wire3;

    or(wire1,RESULT[0],RESULT[1],RESULT[2]);
    or(wire2,RESULT[3],RESULT[4],RESULT[5]);
    or(wire3,RESULT[5],RESULT[6]);
    nor(ZERO,wire1,wire2,wire3);

always @(DATA1 or DATA2 or SELECT)  //declare always block wich sensitive for DATA1,DATA2,SELECT
	begin
		#1
		case (SELECT) //case block for handle the selector 
			3'b000 : RESULT=DATA2;  //FORWARD instruction output
					
			3'b001 : #1 RESULT=DATA1+DATA2; //ADD instruction output
                        
			3'b010 :RESULT=DATA1&DATA2; // bitwise and for AND instruction output
					
			3'b011 :RESULT=DATA1|DATA2; // bitwise or for OR instruction output
					 
					
			default:RESULT = 8'bxxxxxxxx; //for handle unused selectors and output in unnown
					  
					
		endcase 
	end 
endmodule





module signExtention(
    Immidiate,ExtendedImmidiate
);

integer i;

input [7:0] Immidiate;
output reg [31:0] ExtendedImmidiate;


always @(Immidiate) begin
    ExtendedImmidiate[1:0]=2'b00;
    ExtendedImmidiate[9:2]=Immidiate;
    for (i =10; i < 32; i = i + 1) begin
      ExtendedImmidiate[i]=Immidiate[7];
    end
end

endmodule // signExtention for extend the word imidiate to bit address




module adder( //adder for add pc and immidiate
    IMMIDIATE,PC,PC_OUT
);
input [31:0] IMMIDIATE,PC;
output reg [31:0] PC_OUT;

always @(IMMIDIATE or PC) begin
    #2 PC_OUT=PC+IMMIDIATE;
end

endmodule // adder




module mux_2_to_1( //mux for get 32 bit two inputs and output on select
    IN1,IN2,sel,out
);

input [31:0] IN1,IN2;
input sel;
output reg [31:0] out;

always @(sel,IN1,IN2) begin
    if (sel==1'b1) out =IN1;
    else out =IN2;
end

endmodule // 2X1_Mux