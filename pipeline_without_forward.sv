
//Pipeline without forward structure edited by Gowthami Budideti
module pipeline_without_forward(output bit done);


//Arithmetic instructions
parameter  add=6'd0, addi=6'd1, sub=6'd2, subi=6'd3, mul =6'd4, muli=6'd5;


//Logical instructions
parameter  orr=6'd6, orri=6'd7, andr=6'd8, andi=6'd9, xorr=6'd10, xori=6'd11;


//Memory instructions
parameter  ldr=6'd12, str=6'd13;


//Control flow instructions
parameter  bz=6'd14, beq=6'd15, jump=6'd16, halt_i=6'd17;

bit signed [31:0] reg_file[32];
bit signed [7:0]mem[4096];
bit signed [31:0]program_counter ;
int fd;
int count;
int count_cycles;
int stall_raw;
int total_instr_count;
bit branch_taken;
int branch_count ;
int hit;
int stall_one;
int stall_two;
bit temp;

struct {

  bit [31:0]Ir;
  bit [5:0]opcode;
  bit [4:0]src1;
  bit [4:0]src2;
  bit [4:0]dest;
  bit signed[31:0]rs;
  bit signed[31:0]rt;
  bit signed[31:0]rd;
  bit signed[16:0]imm;
  bit signed[31:0]result;
  bit [31:0]ld_value ;
  bit [31:0]st_value;
  bit signed[31:0]load_data;
  bit signed[31:0]pc_value;
  int signed source_reg1;
  int signed source_reg2;
  int signed dest_reg;
  bit signed [31:0]branch_target; } 

instruction_line[5];
bit [3:0] pipeline_stage[5];
int i=0;
int decode_stall;
bit decode_wait;
bit fetch_wait;
int total_stall;
bit halt=0;


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
  #60;
  $fclose(fd);

end : file_block


bit clock=0;

always 
begin

#10 clock=~clock;

end

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
                         instruction_line[i].Ir ={mem[program_counter ], mem[program_counter +1], mem[program_counter +2], mem[program_counter +3] }  ;
                         instruction_line[i].pc_value     = program_counter ;
                         program_counter =program_counter +4;
                         break;
                       end
           end
    end
 end
end

always@(posedge clock)

 begin

if(done==0 )

begin
#0;
   for(int i=0; i<5; i++)

          begin
            if(pipeline_stage[i]==4'd1)
           
                       begin
                          decode_stage(i) ;                            
                          decode_stall = check_decode_stall(i);
                          if(decode_stall==2 && halt==0)
                           stall_two=stall_two+1;
                          if(decode_stall==1 && halt==0)
                           stall_one=stall_one+1;
                          decode_wait =0; 
                          if(decode_stall!=0 && halt==0 )
                            begin
                          stall_raw=stall_raw+1;
                          repeat(decode_stall)
                           begin
                           decode_wait<=1; 
                           fetch_wait <=1;
                            @(posedge clock);
                            fetch_wait<=0;
                           end
                           decode_stage(i) ; 
                          decode_wait<=0;
                             end
                          pipeline_stage[i]<=2;                         
                       break;

		       end
           end

 end
end

task decode_stage(int i);

     instruction_line[i].opcode = instruction_line[i].Ir[31:26];

                       
                         if ( (instruction_line[i].opcode==add) || (instruction_line[i].opcode==sub) ||   (instruction_line[i].opcode==mul ) || (instruction_line[i].opcode==orr) ||(instruction_line[i].opcode==andr) ||(instruction_line[i].opcode==xorr))
                         
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
                                                        	                          
                         else if ((instruction_line[i].opcode==addi) ||(instruction_line[i].opcode==subi) ||(instruction_line[i].opcode==muli) ||(instruction_line[i].opcode==orri) ||(instruction_line[i].opcode==andi) ||(instruction_line[i].opcode==xori) || (instruction_line[i].opcode==ldr) || (instruction_line[i].opcode==str) )
                         
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
                                      instruction_line[i].rs         =$signed( reg_file[instruction_line[i].Ir[25:21]]);
                                      instruction_line[i].rt         = $signed(reg_file[instruction_line[i].Ir[20:16]]);
                                    end
                         
                         else if ((instruction_line[i].opcode== jump ))
                          
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

  hit=0;

  for(int i=0; i<5; i++)
  
    begin
        if( ( ( instruction_line[add].source_reg1== instruction_line[i].dest_reg) || ( instruction_line[add].source_reg2== instruction_line[i].dest_reg) )    &&  ( instruction_line[i].dest_reg != 32'hffff )  && pipeline_stage[i]==4'd2 && branch_taken==0 && temp==0 ) 

                           begin   hit=1;  break  ;    end                       
    end
          
  for(int i=0; i<5; i++)  

      begin
                                                                   
                                 
            if ( ( ( instruction_line[add].source_reg1== instruction_line[i].dest_reg) || ( instruction_line[add].source_reg2== instruction_line[i].dest_reg) )   &&  ( instruction_line[i].dest_reg != 32'hffff )  && pipeline_stage[i]==4'd3 && hit !=1 &&  branch_taken==0 && temp==0) 
                         begin
                              hit=2;
                              break;
                         end    
      end

          if(hit==0) begin  return 0; end
           else if (hit==1) return 2;
           else if (hit ==2) return 1 ;

  endfunction





always@(posedge clock)

  begin
if(done==0)
begin
       for(i=0; i<5; i++)

          begin
            

            if(pipeline_stage[i]==4'd2)

                       begin

                         pipeline_stage[i]<=3;
                           
                     if(branch_taken ==0 )
                       begin   
                         case(instruction_line[i].opcode)
                           
                           add :    ADD(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                           
                           addi:   ADDI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                           
                           sub:     SUB(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                                                      
                           subi:   SUBI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                           	                            
                           mul :     MUL(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                           
                           muli:   MULI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                                     
                           orr:      OR(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                                   
                           orri:    ORI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                                      
                           andr:     AND(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                           	                           
                           andi:   ANDI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                                      
                           xorr:     XOR(instruction_line[i].rs, instruction_line[i].rt, instruction_line[i].result );
                                                      
                           xori:   XORI(instruction_line[i].rs, instruction_line[i].imm , instruction_line[i].result );
                                                      
                           ldr :   instruction_line[i].ld_value =instruction_line[i].rs+instruction_line[i].imm;
                                                      
                           str:   instruction_line[i].st_value= instruction_line[i].rs+instruction_line[i].imm;
                                                      
                           bz:      begin
                             if(instruction_line[i].rs==0)  begin    
                               program_counter <= (instruction_line[i].branch_target*4 )+instruction_line[i].pc_value;  branch_taken<=1;temp=1; branch_count= branch_count +1;  end
                           	     end
                           
                           beq:    begin
                                       if(instruction_line[i].rs==instruction_line[i].rt)
                                      begin  program_counter <= (instruction_line[i].branch_target*4) +instruction_line[i].pc_value ; branch_taken<=1;temp=1; branch_count= branch_count +1; end
                           	     end
                           
                           jump:     begin
                                       program_counter <=instruction_line[i].rs;
                                       branch_taken<=1;temp=1; branch_count= branch_count +1;
                           	    end  
                            halt_i: halt=1;                         
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
                              temp=0;             
                            end
                        end
                           
                           break;
               end                                       
        end               
  end
end

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
                           
                             instruction_line[i].load_data= {mem[instruction_line[i].ld_value ],mem[instruction_line[i].ld_value +1], mem[instruction_line[i].ld_value +2], mem[instruction_line[i].ld_value +3]};
                           
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
                           
                           add :   begin  reg_file[instruction_line[i].dest] = instruction_line[i].result;  end
                                                        
                           addi: begin   reg_file[instruction_line[i].src2] = instruction_line[i].result; end
                                                     
                           sub:     reg_file[instruction_line[i].dest] = instruction_line[i].result;                 
                           
                           subi:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                           	                                
                           mul :     reg_file[instruction_line[i].dest] = instruction_line[i].result;                                                
                           
                           muli:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                                                      
                           orr:      reg_file[instruction_line[i].dest] = instruction_line[i].result;
                           	                            
                           orri:    reg_file[instruction_line[i].src2] = instruction_line[i].result;
                                                      
                           andr:     reg_file[instruction_line[i].dest] = instruction_line[i].result;
                           	                            
                           andi:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                           	                                
                           xorr:     reg_file[instruction_line[i].dest] = instruction_line[i].result;
                                                      
                           xori:   reg_file[instruction_line[i].src2] = instruction_line[i].result;
                           	                              
                           ldr :   reg_file[instruction_line[i].src2] = instruction_line[i].load_data;
                                                                               
                           halt_i:    begin done<=1;  end
                                                     	               
                           endcase
                           
                           break;                       
                       end
         end
  end
end



always@(posedge clock)

begin
if(done==0)
count_cycles=count_cycles+1;

if(decode_wait && halt==0)
total_stall=total_stall+1;

end



function void ADD (input bit signed [31:0]a , input bit signed [31:0]b , output bit signed [31:0]c ) ; c=a+b ;    endfunction

function void ADDI (input bit signed [31:0]a , input  bit signed  [15:0]b , output  bit signed  [31:0]c ) ; c=a+b;  endfunction

function void SUB (input bit signed [31:0]a , input bit signed [31:0]b , output bit signed  [31:0]c ) ;   c=a-b;  endfunction

function void SUBI (input bit signed [31:0]a , input bit signed [15:0]b , output bit signed [31:0]c ) ;  c=a-b;  endfunction

function void MUL (input bit signed [31:0]a , input bit signed [31:0]b , output bit signed [31:0]c ) ;  c=a*b;   endfunction

function void MULI (input bit signed [31:0]a , input bit signed [15:0]b , output bit signed [31:0]c ) ; c=a*b;  endfunction

function void OR (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ;   c=a|b;  endfunction

function void ORI (input bit [31:0]a , input bit [15:0]b , output bit [31:0]c ) ;  c=a|b;  endfunction

function void AND (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ;  c=a&b;  endfunction

function void ANDI (input bit [31:0]a , input bit [15:0]b , output bit [31:0]c ) ; c=a&b;  endfunction

function void XOR (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ; c=a^b;  endfunction

function void XORI (input bit [31:0]a , input bit [15:0]b , output bit [31:0]c ) ; c=a^b;  endfunction

endmodule



