module cpu (
    input clk, 
    input reset,
    output reg [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe,
    output [32*32-1:0] registers  // EXTRA PORT
);
    //reg [31:0] iaddr;
    reg [31:0] daddrq;
    reg [31:0] daddrd;
    
    //reg [31:0] drdata;
    reg [3:0]  dweq;
    reg [3:0]  dwed;
    reg signed [31:0] reg_val1,reg_val2;
    reg [31:0] alu_result;
    reg [31:0] reg1 ,reg2;
    parameter IMMED = 7'b0010011 , ALU = 7'b0110011 , LOAD = 7'b0000011 ,STR = 7'b0100011, LUI = 7'b0110111, AUIPC = 7'b0010111 , BRANCH = 7'b1100011 , JAL = 7'b1101111 , JALR = 7'b1100111 ;
    reg [31:0] datard;
    reg [31:0] rf[0:31];

    reg [31:0] regwdatad;
     reg [31:0] regwdataq;

    assign registers = {rf[31], rf[30], rf[29], rf[28], rf[27], rf[26], rf[25], rf[24], rf[23], rf[22], rf[21], rf[20], rf[19], rf[18], rf[17], rf[16], rf[15], rf[14], rf[13], rf[12], rf[11], rf[10], rf[9], rf[8], rf[7], rf[6], rf[5], rf[4], rf[3], rf[2], rf[1], rf[0]}; 


    // reg [31:0] daddr;
    // reg [3:0] dwe;
    // reg [31:0] dwdata;
    reg [31:0] dwdatad;
    reg [31:0] dwdataq;
    reg [4:0] destd;
    reg [4:0] destq;
    reg [31:0] offsetq;
     reg [31:0] offsetd;
    //reg [31:0] flagq;
    reg [31:0] flagd;
    
    integer i = 0;

    
  initial
  begin
    iaddr = 'd0;
    for(i = 0; i<32; i = i+1) begin
            rf[i] = 'd0;
  end

  end

  assign dwe = dweq;
    assign daddr[31:0]= daddrq[31:0];
  assign dwdata = dwdataq;
  

    always @(posedge clk) begin
        if(destd[4:0]!= 5'd0 ) 
        begin
            rf[destd[4:0]] <= regwdatad[31:0];
        end
        if (reset) begin
            iaddr <= 0;
            daddrq <= 0;
            dweq<= 0;
            offsetq <= 0;
            regwdataq <= 0;
            dwdataq <= 0;
        end 
          else begin 

            daddrq <= daddrd;
            dweq<= dwed;
            offsetq <= offsetd;
            regwdataq <= regwdatad;
            destq <= destd;
            dwdataq <= dwdatad;
            //flagq <= flagd;
              //$display("R1=%d ",rf[1],"R2=%d ", rf[2], "R3=%d ", rf[3],"R4=%d ", rf[4]);
              
            

            if(idata[6:0] == JAL) begin
                iaddr <= iaddr + offsetd;
            end
            else if(idata[6:0] == JALR) begin
                iaddr <= offsetd & 32'hfffffffe;
            end

            else if(idata[6:0] == BRANCH) begin     
                if (flagd == 'd1) begin 
                    iaddr <= iaddr + offsetd;
                    end      
                else 
                begin 
                    iaddr <= iaddr + 4;
                    end                     
            end  

            else begin
                 iaddr <= iaddr + 4;
            end
    

            

       $display("inst = %d",iaddr,"    R14=%d ", rf[14],"R1=%d ",rf[1],"R2=%d ",rf[2],"R10=%d ",rf[10],"R15=%d ",rf[15],"R31=%d ",rf[31]);
            //iaddr <= iaddr + 4;
        end

        
        //$display(" rd%d = %d || regwdata = %d",idata[11:7],rf[idata[11:7]],regwdata);
      

    end
    
    always @(*) begin

    dwdatad[31:0] = dwdataq;  
    dwed[3:0] = dweq[3:0];
    reg_val1 = 'd0;
    reg1 ='d0;
    reg2 ='d0;
    reg_val2 = 'd0;
  
    alu_result = 'd0;
    //regwdata = rf[idata[11:7]];
    //offset = 'd0;
    offsetd = offsetq;
    destd = destq;
    regwdatad = regwdataq;
    daddrd = daddrq;
    //flagd = flagq;
    
    reg_val1 = rf[idata[19:15]];
    reg_val2 = rf[idata[24:20]];
    reg1 = rf[idata[19:15]];
    reg2 = rf[idata[24:20]];
        
    case(idata[6:0]) 
    
    IMMED: 
    begin //immed = 0010011
    
    if(idata[14:12]== 3'b000) //ADDI
     begin
     //regfile r1(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
     alu_result[31:0] = {{20{idata[31]}},idata[31:20]} + reg_val1;
     //drdata[31:0] = alu_result[31:0];
     
    end
    
    else if( idata[14:12]== 3'b010) //slti
    begin
     //regfile r2(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
     if(reg_val1 < idata[31:20]) alu_result = 1;
     else alu_result = 0; 
    end
    
    else if( idata[14:12]== 3'b011) //sltiu
    begin
      //regfile r3(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
    // unsigned case of slti
    // if regval and idata are negative , invert them
     reg1[31:0] = reg_val1[31:0];
     reg2[31:0] = idata[31:20];
     if(reg1 < reg2) alu_result= 1;
     else alu_result = 0; 
    
    
    
    end
    
    else if( idata[14:12]== 3'b100) //xori
    begin
      //regfile r4(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
     alu_result[31:0] = {{20{idata[31]}},idata[31:20]} ^ reg_val1;
     //drdata[31:0] = alu_result[31:0];
    
    end

    else if( idata[14:12]== 3'b110) 
    begin   //ORI
      //regfile r5(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
      alu_result[31:0] = reg_val1 | {{20{idata[31]}},idata[31:20]};
      //drdata[31:0] = alu_result[31:0];  
    
      
    end

    else if( idata[14:12]== 3'b111) 
    begin   //ANDI
      //regfile r6(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
      alu_result[31:0] = reg_val1 & {{20{idata[31]}},idata[31:20]};
      //drdata[31:0] = alu_result[31:0];  
    
      
    end

    else if( idata[14:12]== 3'b001) 
    begin   //SLLI
      //regfile r7(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
      alu_result[31:0] = reg_val1 << idata[24:20];
      //drdata[31:0] = alu_result[31:0];  
    
      
    end

    else if( idata[14:12]== 3'b101) 
    begin   //SRLI and SRAI
    //regfile r8(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
      if(idata[31:25] == 7'b0100000) 
     begin
       alu_result[31:0] = reg_val1 >>> idata[24:20];
     end
     
     else alu_result[31:0] = reg_val1 >> idata[24:20];
     
     //drdata[31:0] = alu_result[31:0];
    
      
    end

    regwdatad[31:0] = alu_result[31:0];
    destd[4:0] = idata[11:7];
    
    end
    


    ALU : begin // alu = 0110011 
    //regfile r9(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
    if(idata[14:12]== 3'b000) //ADD
    begin
     
     if(idata[31:25] == 7'b0100000) 
     begin
       alu_result[31:0] = reg_val1 - reg_val2;
     end
     
     else  if(idata[31:25] == 7'b0000000) 
     begin
      alu_result[31:0] = reg_val1 + reg_val2;
     end
     
     //drdata[31:0] = alu_result[31:0];
     
    end

    else if( idata[14:12]== 3'b001) 
    begin   //SLL
      alu_result[31:0] = reg_val1 << reg_val2[5:0];
      //drdata[31:0] = alu_result[31:0];  
    
      
    end

    else if( idata[14:12]== 3'b010) 
    begin   //SLT
      if(reg_val1 < reg_val2) alu_result = 1;
     else alu_result= 0;  
    
      
    end

    else if( idata[14:12]== 3'b011) 
    begin   //SLTU
      if(reg_val1[31]==1'b1) reg1[31:0] = reg_val1[31:0];
     if(reg_val2<0) reg2[31:0] = reg_val2[31:20];
     if(reg1 < reg2) alu_result = 1;
     else alu_result = 0; 
    
      
    end
    
    else if( idata[14:12]== 3'b100) 
    begin   //XOR
      alu_result[31:0] = reg_val1 ^ reg_val2;
      //drdata[31:0] = alu_result[31:0];  
    
      
    end

    else if( idata[14:12]== 3'b101) 
    begin   //SRL and SRA
      if(idata[31:25] == 7'b0100000) 
     begin
       alu_result[31:0] = reg_val1 >>> reg_val2[5:0];
     end
     
     else alu_result[31:0] = reg_val1 >> reg_val2[5:0];
     
     //drdata[31:0] = alu_result[31:0];
    
      
    end

    else if( idata[14:12]== 3'b110) 
    begin   //OR
      alu_result[31:0] = reg_val1 | reg_val2;
      //drdata[31:0] = alu_result[31:0];  
    
      
    end

    else if( idata[14:12]== 3'b111) 
    begin   //AND
      alu_result[31:0] = reg_val1 & reg_val2;
      //drdata[31:0] = alu_result[31:0];  
    end

    regwdatad[31:0] = alu_result[31:0];
    destd[4:0] = idata[11:7];

    end



    LOAD : begin // 00000113
     
     
    //regfile r10(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);

      if(idata[14:12]== 3'b010) //LW
    begin
     
     daddrd[31:0] = reg_val1[31:0] + {{20{idata[31]}},idata[31:20]} ; //sign extend idata if not working
     //dmem d9(clk,daddr,dwdatad,dwe,drdata);
     regwdatad[31:0] = drdata[31:0];
    end

    else if(idata[14:12]== 3'b001) //LH
    begin     
     daddrd[31:0] = reg_val1[31:0] + {{20{idata[31]}},idata[31:20]} ; //sign extend idata if not working
     //dmem d8(clk,daddr,dwdatad,dwe,datard);
     regwdatad[31:0] = {{16{drdata[15]}},drdata[15:0]} ; 
    end

    else if(idata[14:12]== 3'b000) //LB
    begin     
     daddrd[31:0] = reg_val1[31:0] + {{20{idata[31]}},idata[31:20]} ; //sign extend idata if not working
     //dmem d7(clk,daddr,dwdatad,dwe,datard);
     regwdatad[31:0] = {{24{drdata[7]}},drdata[7:0]} ; 
    end

    else if(idata[14:12]== 3'b100) //LBU
    begin
     
     daddrd[31:0] = reg_val1[31:0] + {{20{idata[31]}},idata[31:20]} ; //sign extend idata if not working
    // dmem d6(clk,daddr,dwdatad,dwe,datard);
     regwdatad[31:0] = {{24{1'b0}},drdata[7:0]} ; 
    end

    else if(idata[14:12]== 3'b101) //LHU
    begin
     
     daddrd[31:0] = reg_val1[31:0] + {{20{idata[31]}},idata[31:20]} ; //sign extend idata if not working
     //dmem d5(clk,daddr,dwdatad,dwe,datard);
     regwdatad[31:0] = {{16{1'b0}},drdata[15:0]} ; 
    end

   //egwdata[31:0] = drdata[31:0];
   destd[4:0] = idata[11:7];


    end 


    STR : begin
        regwdatad = 0;
           destd[4:0] = 0;
      //regfile r11(clk ,idata[19:15],idata[24:20],idata[11:7],regwdata[31:0],we,reg_val1,reg_val2);
      if(idata[14:12]== 3'b000) //SB
    begin
     
     daddrd[31:0] = reg_val1[31:0] + {{20{idata[31]}},idata[31:25], idata[11:7]} ; //sign extend idata if not working
      case(daddrd[1:0])
      2'b00 : begin
        dwed[3:0] = 4'b0001;
      end

      2'b01 : begin
        dwed[3:0] = 4'b0010;
      end

      2'b10 : begin
        dwed[3:0] = 4'b0100;
      end

      2'b11 : begin
        dwed[3:0] = 4'b100;
      end
      endcase
     dwdatad[31:0] = reg_val2[7:0] ; 
     
     //dmem d4(clk,daddr,dwdatad,dwe,drdata);
    end

    else if(idata[14:12]== 3'b001) //SH
    begin
     
     daddrd[31:0] = reg_val1[31:0] + {{20{idata[31]}},idata[31:25], idata[11:7]} ; //sign extend idata if not working

     case(daddrd[0])
      1'b0 : begin
        dwed[3:0] = 4'b0011;
      end

      1'b1 : begin
        dwed[3:0] = 4'b1100;
      end
     endcase

     dwdatad[31:0] = reg_val2[15:0] ; 
     //dmem d3(clk,daddr,dwdatad,dwe,drdata);
     
    end
    
    else if(idata[14:12]== 3'b010) //SW
    begin
     
     daddrd[31:0] = reg_val1[31:0] + {{20{idata[31]}},idata[31:25], idata[11:7]} ; //sign extend idata if not working

     dwed[3:0] = 4'b1111;
     //dmemwdata[31:0] = reg_val2[31:0] ;
     dwdatad[31:0] = reg_val2[31:0] ; 
     //dmem d2(clk,daddr,dwdatad,dwe,drdata);
     
    end

    end


    LUI : begin
        alu_result[31:0] = idata[31:12];
        regwdatad= alu_result<<12;
        destd[4:0] = idata[11:7];
    end



    AUIPC : begin

        alu_result[31:0] = iaddr[31:0] + {idata[31:12] , {12{1'b0}}};
        regwdatad = alu_result;
           destd[4:0] = idata[11:7];

    end



    JAL : begin

        regwdatad = iaddr + 4;
        offsetd = {{12{idata[31]}},idata[19:12],idata[20],idata[30:21],1'b0};
           destd[4:0] = idata[11:7];
    end



    JALR : begin
         
        regwdatad = iaddr + 4; 
        offsetd= {{20{idata[31]}},idata[31:20]} + reg_val1;
           destd[4:0] = idata[11:7];
    end



    BRANCH : begin
        regwdatad = 0;
           destd[4:0] = 0;


        if(idata[14:12]== 3'b000) begin //BEQ
         offsetd = {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
         if(reg_val1 == reg_val2)
         begin
            flagd = 'd1;
         end
         else
         begin
            flagd = 'd0;
         end
        end

        else if(idata[14:12]== 3'b001) begin //BNE
         offsetd = {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
         if(reg_val1 != reg_val2)
         begin
            flagd = 'd1;
         end
         else
         begin
            flagd = 'd0;
         end
        end

        else if(idata[14:12]== 3'b100) begin //BLT
         offsetd = {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
         if($signed(reg_val1) < $signed(reg_val2))
         begin
            flagd = 'd1;
         end
         else
         begin
            flagd = 'd0;
         end
        end

        else if(idata[14:12]== 3'b101) begin //Bge
         offsetd = {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
         if($signed(reg_val1) >= $signed(reg_val2))
         begin
            flagd = 'd1;
         end
         else
         begin
            flagd = 'd0;
         end
        end

        else if(idata[14:12]== 3'b110) begin //BLTU
         offsetd = {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
         if(reg1 < reg2)
         begin
            flagd = 'd1;
         end
         else
         begin
            flagd = 'd0;
         end
        end

        else if(idata[14:12]== 3'b111) begin //BGEU
         offsetd = {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
         if(reg1 >= reg2)
         begin
            flagd = 'd1;
         end
         else
         begin
            flagd = 'd0;
         end
        end

    
              
    end




    default : 
    begin
      regwdatad = 'd0;
      destd = 'd0;
    end

    endcase
    end
    

endmodule



    




