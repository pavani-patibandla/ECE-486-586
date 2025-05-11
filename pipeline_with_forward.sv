//Pipeline with Forward System Verilog implementation//

module pipeline_with_forward(output bit done);
parameter  add=6'd0, addi=6'd1, sub=6'd2, subi=6'd3, mul =6'd4, muli=6'd5;
parameter  orr=6'd6, orri=6'd7, andr=6'd8, andi=6'd9, xorr=6'd10, xori=6'd11;
parameter  ldr=6'd12, str=6'd13;
parameter  bz=6'd14, beq=6'd15, jump=6'd16, halt=6'd17;
bit signed [31:0]reg_file[32];
bit signed [31:0]reg_updated[32];
bit signed [7:0]mem[4096];
bit signed [31:0]program_counter;
int fd;
int count;
int count_cycles;
int stall_raw;
int total_instr_count;
bit branch_taken;
int branch_count ;
int hit;
struct             {
  bit [31:0]Ir;
  bit [5:0]opcode;
  bit [4:0]src1;
  bit [4:0]src2;
  bit [4:0]dest;
  bit signed [31:0]rs;
  bit signed [31:0]rt;
  bit signed [31:0]rd;
  bit signed [16:0]imm;
  bit signed [31:0]result;
  bit [31:0]ld_value;
  bit [31:0]st_value;
  bit signed [31:0]load_data;
  bit signed [31:0]pc_value;
  int signed source_reg1;
  int signed source_reg2;
  int signed dest_reg;
  bit signed [31:0]branch_target; } instruction_line[5];
bit [3:0] pipeline_stage[5];
int i=0;
int decode_stall;
bit fetch_wait;

// Memory  //

 initial begin : file_block

        fd = $fopen ("./trace.txt", "r");
  
  if(fd ==0)
    disable file_block;
  
  while (!($feof(fd))) begin
    $fscanf(fd, "%32h",{mem[i], mem[i+1], mem[i+2], mem[i+3]});
     i=i+4;
   begin

  end
    end
  #25;
  $finish();

  $fclose(fd);

end : file_block

// Clock Generation //

bit clock=0;

always 
begin

#10 clock=~clock;

end

// Instrunction Fetch //

always@(posedge clock)

 begin
if(done==0)
begin
 if(fetch_wait==0) 
   begin
   for(int i=0; i<5; i++)

          begin

            if(pipeline_stage[i]==0 )

                       begin		         
                         pipeline_stage[i] <=1;
                         instruction_line[i].Ir ={mem[program_counter], mem[program_counter+1], mem[program_counter+2], mem[program_counter+3] }  ;
                         instruction_line[i].pc_value     = program_counter;
                         program_counter=program_counter+4;
                         break;
                       end
           end
    end
 end
end

// Instruction Decode //

always@(posedge clock)

 begin
if(done==0)
begin
#0;
   for(int i=0; i<5; i++)

          begin
            if(pipeline_stage[i]==4'd1)
           
                       begin
                          decode_stage(i) ;                            
                          decode_stall = check_decode_stall(i);
                          if(decode_stall==1)
                            begin
                          stall_raw=stall_raw+1;
                           fetch_wait <=1;
                            @(posedge clock);
                            fetch_wait<=0;
                           decode_stage(i) ; 
                             end
                          pipeline_stage[i]<=2;                         
                       break;
		       end
           end
 end
end
task decode_stage(int i);

     instruction_line[i].opcode = instruction_line[i].Ir[31:26];

                       
                         if ( (instruction_line[i].opcode==add) || (instruction_line[i].opcode==sub) ||   (instruction_line[i].opcode==mul) || (instruction_line[i].opcode==orr) ||(instruction_line[i].opcode==andr) ||(instruction_line[i].opcode==xorr))
                         
                                    begin       
                                      instruction_line[i].src1     = instruction_line[i].Ir[25:21];
                                      instruction_line[i].src2     = instruction_line[i].Ir[20:16];
                                      instruction_line[i].dest     = instruction_line[i].Ir[15:11];
                                      instruction_line[i].source_reg1 = instruction_line[i].Ir[25:21];
                                      instruction_line[i].source_reg2     = instruction_line[i].Ir[20:16];
                                      instruction_line[i].dest_reg     = instruction_line[i].Ir[15:11];
                                      instruction_line[i].rs         = $signed(reg_file[instruction_line[i].Ir[25:21]]);
                                      instruction_line[i].rt         = $signed(reg_file[instruction_line[i].Ir[20:16]]);
                                      instruction_line[i].rd         = $signed(reg_file[instruction_line[i].Ir[15:11]]);
                                    end
                                                        	                          
                         else if ((instruction_line[i].opcode==addi) ||(instruction_line[i].opcode==subi) ||(instruction_line[i].opcode==muli) ||(instruction_line[i].opcode==orri) ||(instruction_line[i].opcode==andi) ||(instruction_line[i].opcode==xori) || (instruction_line[i].opcode==ldr) || (instruction_line[i].opcode==str))
                         
                                    begin                                     
                                      instruction_line[i].imm        = $signed(instruction_line[i].Ir[15:0]);
                                      instruction_line[i].src1     = instruction_line[i].Ir[25:21];
                                      instruction_line[i].src2     = instruction_line[i].Ir[20:16];
                                      instruction_line[i].source_reg1 = instruction_line[i].Ir[25:21];
                                      instruction_line[i].dest_reg     = instruction_line[i].Ir[20:16];
                                      instruction_line[i].source_reg2  = 32'hffff;
                                      instruction_line[i].rs         = $signed(reg_file[instruction_line[i].Ir[25:21]]);
                                      instruction_line[i].rt         = $signed(reg_file[instruction_line[i].Ir[20:16]]);
                                    end
                         
                         else if ((instruction_line[i].opcode== bz))
                          
                                     begin
                                       instruction_line[i].src1     = instruction_line[i].Ir[25:21];
                                       instruction_line[i].branch_target     = $signed(instruction_line[i].Ir[15:0]);
                                       instruction_line[i].rs         = $signed(reg_file[instruction_line[i].Ir[25:21]]);
                                       instruction_line[i].source_reg1 = instruction_line[i].Ir[25:21];
                                       instruction_line[i].dest_reg    = 32'hffff;
                                       instruction_line[i].source_reg2  = 32'hffff;
                                     end
                         
                         else if ((instruction_line[i].opcode== beq))
                          
                                     begin
                                      instruction_line[i].src1     = instruction_line[i].Ir[25:21];
                                      instruction_line[i].src2     = instruction_line[i].Ir[20:16];
                                      instruction_line[i].branch_target     = $signed(instruction_line[i].Ir[15:0]);	                  
                                      instruction_line[i].source_reg1 = instruction_line[i].Ir[25:21];
                                      instruction_line[i].source_reg2= instruction_line[i].Ir[20:16];
                                      instruction_line[i].dest_reg  = 32'hffff;           
                                      instruction_line[i].rs         = $signed(reg_file[instruction_line[i].Ir[25:21]]);
                                      instruction_line[i].rt         = $signed(reg_file[instruction_line[i].Ir[20:16]]);
                                    end
                         
                         else if ((instruction_line[i].opcode== jump))
                          
                                     begin
                                     instruction_line[i].src1     = instruction_line[i].Ir[25:21];                          
                                     instruction_line[i].rs         = $signed(reg_file[instruction_line[i].Ir[25:21]]);
                                     instruction_line[i].source_reg1 = instruction_line[i].Ir[25:21];
                                     instruction_line[i].dest_reg    = 32'hffff;
                                     instruction_line[i].source_reg2  = 32'hffff;
                                     end
                           else
                                   begin
                                      instruction_line[i].rd         = 0;
                                      instruction_line[i].rs         = 0;
                                      instruction_line[i].rt         = 0;
                                      instruction_line[i].dest     = 0;
                                      instruction_line[i].src1     = 0;
                                      instruction_line[i].src2     = 0;
                                      instruction_line[i].source_reg1 =  32'hffff;
                                      instruction_line[i].dest_reg    = 32'hffff;
                                      instruction_line[i].source_reg2  = 32'hffff;
				   end
endtask

 function int check_decode_stall(int add );

  for(int i=0; i<5; i++)
  
    begin
               if( ( ( instruction_line[add].source_reg1== instruction_line[i].dest_reg) || ( instruction_line[add].source_reg2== instruction_line[i].dest_reg) )    &&  ( instruction_line[i].dest_reg != 32'hffff )  && pipeline_stage[i]==4'd2 && branch_taken==0 &&  instruction_line[i].opcode == 6'd12  ) 

                           begin    hit=1;  break  ;    end                       
    end
          
  if(hit==1) begin hit=0;  return 1; end else  return 0 ;
            
  endfunction

// Instruction Execute //

always@(posedge clock)

  begin
if(done==0)
begin
       for(i=0; i<5; i++)

          begin
            
            if(pipeline_stage[i]==4'd2)

                       begin

                          instruction_line[i].rs=$signed(reg_updated[instruction_line[i].src1]);
                          instruction_line[i].rt=$signed(reg_updated[instruction_line[i].src2]);
                          instruction_line[i].rd=$signed(reg_updated[instruction_line[i].dest]);                                                 
                          pipeline_stage[i]<=3;
                           
                     if(branch_taken ==0 )
                       begin   
                         case(instruction_line[i].opcode)
                           
                           add :  begin  ADD(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result ); 
                                           reg_updated[instruction_line[i].dest] =  $signed(instruction_line[i].result) ;               end
                           
                           addi:  begin  ADDI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                           reg_updated[instruction_line[i].src2] =  $signed(instruction_line[i].result) ;               end
                           
                           sub:    begin  SUB(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                                           reg_updated[instruction_line[i].dest] =  $signed(instruction_line[i].result) ;               end
                                                      
                           subi:   begin SUBI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                           reg_updated[instruction_line[i].src2] =  $signed(instruction_line[i].result) ;               end
                           	                            
                           mul:    begin  MUL(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                                           reg_updated[instruction_line[i].dest] =  $signed(instruction_line[i].result) ;               end
                           
                           muli:   begin MULI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                           reg_updated[instruction_line[i].src2] =  $signed(instruction_line[i].result) ;               end
                                                     
                           orr:    begin   OR(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                                           reg_updated[instruction_line[i].dest] =  $signed(instruction_line[i].result) ;               end
                                   
                           orri:    begin ORI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                           reg_updated[instruction_line[i].src2] =  $signed(instruction_line[i].result );               end
                                                      
                           andr:    begin  AND(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                                           reg_updated[instruction_line[i].dest] =  $signed(instruction_line[i].result) ;               end
                           	                           
                           andi:   begin ANDI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                           reg_updated[instruction_line[i].src2] =  $signed(instruction_line[i].result );               end
                                                      
                           xorr:    begin  XOR(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                                           reg_updated[instruction_line[i].dest] =  $signed(instruction_line[i].result) ;               end
                                                      
                           xori:   begin XORI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                           reg_updated[instruction_line[i].src2] =  $signed(instruction_line[i].result) ;               end
                                                      
                           ldr :   instruction_line[i].ld_value=instruction_line[i].rs+instruction_line[i].imm;
                                                      
                           str:   instruction_line[i].st_value= instruction_line[i].rs+instruction_line[i].imm;
                                                      
                           bz:      begin
                                       if(instruction_line[i].rs==0)  begin   
                                       program_counter<= (instruction_line[i].branch_target*4 )+instruction_line[i].pc_value;  branch_taken<=1; branch_count= branch_count +1;  end
                           	     end
                           
                           beq:    begin
                                       if(instruction_line[i].rs==instruction_line[i].rt)
                                      begin  program_counter<= (instruction_line[i].branch_target*4) +instruction_line[i].pc_value ; branch_taken<=1; branch_count= branch_count +1; end
                           	     end
                           
                           jump:     begin
                                       program_counter<=instruction_line[i].rs;
                                       branch_taken<=1; branch_count= branch_count +1;
                           	    end                           
                           endcase
                        end

                      else
           
                         begin
                           
                           instruction_line[i].opcode=6'd22; 
                           count=count+1;
                         
                           if(count>1)
                           begin
                              count=0;
                              branch_taken<=0;              
                            end
                        end
                           
                           break;
               end                                       
        end               
  end
end

// Instruction Memory Stage //

always@(posedge clock)

  begin
if(done==0)
begin
      for(i=0; i<5; i++)
          begin

            if(pipeline_stage[i]==4'd3)

                       begin

                         pipeline_stage[i]<=4;

                        case(instruction_line[i].opcode)
                                                                              
                           ldr : begin
                           
                             instruction_line[i].load_data= {mem[instruction_line[i].ld_value],mem[instruction_line[i].ld_value+1], mem[instruction_line[i].ld_value+2], mem[instruction_line[i].ld_value+3]};
                                reg_updated[ instruction_line[i].src2] = $signed(instruction_line[i].load_data);
                           	   end
                           
                           str: begin
                             {mem[instruction_line[i].st_value],mem[instruction_line[i].st_value+1], mem[instruction_line[i].st_value+2], mem[instruction_line[i].st_value+3]}=instruction_line[i].rt;
                           
                           	   end
                        
                           endcase
                           
                           break;
                      
                       end
         end
  end
end

// Instruction Write Back Stage //

always@(posedge clock)

  begin
if(done==0)
begin
      for(i=0; i<5; i++)

          begin

            if(pipeline_stage[i]==4'd4)

                       begin
                         if(instruction_line[i].opcode <= 6'd18)
                         total_instr_count =total_instr_count+1;  
      
                         pipeline_stage[i]<=0;
                         
                         case(instruction_line[i].opcode) 
                           
                           add :    reg_file[instruction_line[i].dest] = instruction_line[i].result;
                                                        
                           addi:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                                                     
                           sub:     reg_file[instruction_line[i].dest] = instruction_line[i].result;                 
                           
                           subi:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                           	                                
                           mul:     reg_file[instruction_line[i].dest] = instruction_line[i].result;                                                
                           
                           muli:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                                                      
                           orr:      reg_file[instruction_line[i].dest] = instruction_line[i].result;
                           	                            
                           orri:    reg_file[instruction_line[i].src2] = instruction_line[i].result;
                                                      
                           andr:     reg_file[instruction_line[i].dest] = instruction_line[i].result;
                           	                            
                           andi:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                           	                                
                           xorr:     reg_file[instruction_line[i].dest] = instruction_line[i].result;
                                                      
                           xori:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                           	                              
                           ldr :   reg_file[instruction_line[i].src2] = instruction_line[i].load_data;
                                                                               
                           halt:    done<=1;
                                                     	               
                           endcase
                           
                           break;                       
                       end
         end
  end

end

// End of Stages //

always@(posedge clock)
begin  
if(done==0)
 count_cycles=count_cycles+1; 
 end

// Arithmetic Stage //

function void ADD (input  bit signed [31:0]a , input bit signed [31:0]b , output bit signed [31:0]c ) ;   c=a+b;  endfunction
function void ADDI (input bit signed [31:0]a , input bit signed [15:0]b , output bit signed [31:0]c ) ;  c=a+b;  endfunction
function void SUB (input  bit signed [31:0]a , input bit signed [31:0]b , output bit signed [31:0]c ) ;   c=a-b;  endfunction
function void SUBI (input bit signed [31:0]a , input bit signed [15:0]b , output bit signed [31:0]c ) ;  c=a-b;  endfunction
function void MUL (input  bit signed [31:0]a , input bit signed [31:0]b , output bit signed [31:0]c ) ;  c=a*b;   endfunction
function void MULI(input  bit signed [31:0]a , input bit signed [15:0]b , output bit signed [31:0]c ) ; c=a*b;  endfunction
function void OR (input   bit  [31:0]a , input bit  [31:0]b , output bit  [31:0]c ) ;   c=a|b;  endfunction
function void ORI (input  bit  [31:0]a , input bit  [15:0]b , output bit  [31:0]c ) ;  c=a|b;  endfunction
function void AND (input  bit  [31:0]a , input bit  [31:0]b , output bit  [31:0]c ) ;  c=a&b;  endfunction
function void ANDI (input bit  [31:0]a , input bit  [15:0]b , output bit  [31:0]c ) ; c=a&b;  endfunction
function void XOR (input  bit  [31:0]a , input bit  [31:0]b , output bit  [31:0]c ) ; c=a^b;  endfunction
function void XORI (input bit  [31:0]a , input bit  [15:0]b , output bit  [31:0]c ) ; c=a^b;  endfunction

endmodule


