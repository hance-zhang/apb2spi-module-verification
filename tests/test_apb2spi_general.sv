//------------------------------------------------------------------------------
// Copyright (c) 2018 Elsys Eastern Europe
// All rights reserved.
//------------------------------------------------------------------------------
// File name  : test_apb2spi_general.sv
// Developer  : andrijana.ojdanic
// Date       : 
// Description: 
// Notes      : 
//
//------------------------------------------------------------------------------

`ifndef TEST_APB2SPI_GENERAL_SV
`define TEST_APB2SPI_GENERAL_SV

class test_apb2spi_general extends test_apb2spi_base;
  
    // registration macro
    `uvm_component_utils(test_apb2spi_general)
  
    // fields
    data_order_type DORD_TEST; 
    int             DSIZ_TEST; 
    int             SS_sel_TEST = 0;
    int             SPI_TRANS_NUM = 50;
    int             NUM_OF_TRANS_BASIC = 20;
    
    // sequences
    apb2spi_conf_seq        conf_seq;
    apb2spi_read_reg_seq    read_reg_seq;
    apb2spi_write_reg_seq   write_reg_seq; 
    apb2spi_spi_seq         spi_simple_seq;  
     
    // constructor
    extern function new(string name, uvm_component parent);
    
    // run phase
    extern virtual task run_phase(uvm_phase phase);
    
    // configure SPI module without enabling it
    extern virtual task configure(data_order_type _DORD, int _DSIZ, int _SS_sel);
      
    // busy test - parallel writing to Tx buffer and reading from it on SPI side
    extern virtual task busy_test(data_order_type _DORD, int _DSIZ, int _SS_sel, int num_of_trans, int init_tx_data_num);
    
endclass : test_apb2spi_general 

// constructor
function test_apb2spi_general::new(string name, uvm_component parent);
    super.new(name, parent);
    
    // create sequences
    conf_seq                    = apb2spi_conf_seq::type_id::create("conf_seq", this);
    read_reg_seq                = apb2spi_read_reg_seq::type_id::create("read_reg_seq", this);
    write_reg_seq               = apb2spi_write_reg_seq::type_id::create("write_reg_seq", this);
    spi_simple_seq              = apb2spi_spi_seq::type_id::create("spi_simple_seq", this);
   
endfunction : new

// run phase
task test_apb2spi_general::run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // raise objections
    uvm_test_done.raise_objection(this, get_type_name());    
    `uvm_info(get_type_name(), "TEST STARTED", UVM_LOW)
    
    #(500ns);
    rst_interface.rst_n <= 1'b0;
    #(100ns);
    rst_interface.rst_n <= 1'b1;
    
    DORD_TEST   = MSB;
    DSIZ_TEST   = 16;
    SS_sel_TEST = 0;
    
    configure(DORD_TEST, DSIZ_TEST, SS_sel_TEST);
    
    
       
    // drop objections
    uvm_test_done.drop_objection(this, get_type_name());    
    `uvm_info(get_type_name(), "TEST FINISHED", UVM_LOW) 
    
endtask : run_phase

task test_apb2spi_general::configure(data_order_type _DORD, int _DSIZ, int _SS_sel);

    bit DORD;
    bit[4:0] DSIZ;
    bit[7:0] SSEN;
    bit[31:0] SPIxSTAT0_CUR;
    
    //reconfigure(_DORD, _DSIZ, _SS_sel);
    
    case (_DORD)
        MSB : DORD = 1'b0;
        LSB : DORD = 1'b1;
    endcase

    DSIZ = _DSIZ-1;

    case (_SS_sel)
        0: SSEN = 8'b00000001;
        1: SSEN = 8'b00000010;
        2: SSEN = 8'b00000100;
        3: SSEN = 8'b00001000;
        4: SSEN = 8'b00010000;
        5: SSEN = 8'b00100000;
        6: SSEN = 8'b01000000;
        7: SSEN = 8'b10000000;
    endcase    
     
    // initial status check
    if(!read_reg_seq.randomize() with { 
                             paddr        == SPIxSTAT0_ADDR;
          	            }) 
    begin
        `uvm_fatal(get_type_name(), "Failed to randomize.")
    end 
    read_reg_seq.start(apb2spi_env_top.v_sequencer);
    
    
    // start conf sequence, do not enable SPI module
    if(!conf_seq.randomize() with { 
                                    SPIxCTRL1_SSEN  == SSEN;
                                    
                                    SPIxCTRL0_DSIZ  == DSIZ;    
                                    SPIxCTRL0_DORD  == DORD;    
                                    SPIxCTRL0_DIR   == 2'b10; // transmit only
                                    SPIxCTRL0_SPIEN == 1'b0;
  	                         }) 
  	begin
            `uvm_fatal(get_type_name(), "Failed to randomize.")
  	end  
  	    
  	conf_seq.start(apb2spi_env_top.v_sequencer);
    
    
    for(int i = 0; i < 10; i++) begin
    
        // write data to Tx buffer
        if(!write_reg_seq.randomize() with { 
                                       paddr        == SPIxDAT_ADDR;
                                       pstrb        == 4'b1111;
      	                         }) 
      	begin
            `uvm_fatal(get_type_name(), "Failed to randomize.")
      	end 
        write_reg_seq.start(apb2spi_env_top.v_sequencer);
        
        // check status after each writing
        if(!read_reg_seq.randomize() with { 
                             paddr        == SPIxSTAT0_ADDR;
          	            }) 
        begin
            `uvm_fatal(get_type_name(), "Failed to randomize.")
        end 
        read_reg_seq.start(apb2spi_env_top.v_sequencer);
        
    end
     
endtask : configure

/*
task test_apb2spi_general::busy_test(data_order_type _DORD, int _DSIZ, int _SS_sel, int num_of_trans, int init_tx_data_num);
    
    bit DORD;
    bit[4:0] DSIZ;
    bit[7:0] SSEN;
    bit[31:0] SPIxSTAT0_CUR;
    
    reconfigure(_DORD, _DSIZ, _SS_sel);
    
    case (_DORD)
        MSB : DORD = 1'b0;
        LSB : DORD = 1'b1;
    endcase

    DSIZ = _DSIZ-1;

    case (_SS_sel)
        0: SSEN = 8'b00000001;
        1: SSEN = 8'b00000010;
        2: SSEN = 8'b00000100;
        3: SSEN = 8'b00001000;
        4: SSEN = 8'b00010000;
        5: SSEN = 8'b00100000;
        6: SSEN = 8'b01000000;
        7: SSEN = 8'b10000000;
    endcase    
     
    // disable SPI in order to change configuration
    if(!write_reg_seq.randomize() with { 
                                       paddr        == SPIxCTRL0_ADDR;
                                       pstrb        == 4'b1111;
                                       pwdata       == 32'h00000000;
      	                         }) 
    begin
        `uvm_fatal(get_type_name(), "Failed to randomize.")
    end 
    write_reg_seq.start(apb2spi_env_top.v_sequencer);
    
    // start conf sequence, enable SPI module
    if(!conf_seq.randomize() with { 
                                    SPIxCTRL1_SSEN  == SSEN;
                                    
                                    SPIxCTRL0_DSIZ  == DSIZ;    
                                    SPIxCTRL0_DORD  == DORD;    
                                    SPIxCTRL0_DIR   == 2'b10; // transmit only
                                    SPIxCTRL0_SPIEN == 1'b1;
  	                         }) 
  	begin
            `uvm_fatal(get_type_name(), "Failed to randomize.")
  	end  
  	conf_seq.start(apb2spi_env_top.v_sequencer);
    
    // initial status check
    if(!read_reg_seq.randomize() with { 
                             paddr        == SPIxSTAT0_ADDR;
          	            }) 
    begin
        `uvm_fatal(get_type_name(), "Failed to randomize.")
    end 
    read_reg_seq.start(apb2spi_env_top.v_sequencer);
    
     
    if(init_tx_data_num > FDEPTH) init_tx_data_num = FDEPTH;
    
    // write initial data to Tx buffer
    for(int i = 0; i<init_tx_data_num ; i++) begin

        if(!write_reg_seq.randomize() with { 
                                       paddr        == SPIxDAT_ADDR;
                                       pstrb        == 4'b1111;
      	                         }) 
      	begin
            `uvm_fatal(get_type_name(), "Failed to randomize.")
      	end 
        write_reg_seq.start(apb2spi_env_top.v_sequencer);

    end  
      
    fork 
    
        apb_block:  begin
                        
                        flush_moment = $urandom_range(NUM_OF_TRANS_BASIC-1, 1);
                        
                        for(int i=0; i<num_of_trans-init_tx_data_num; i++) begin
                                                 
                            // waiting for tx buffer to have available locations
                            do begin
                               @(spi_trans_started);
                                check_status();
                            end while (apb2spi_env_top.m_scoreboard.SPIxSTAT0_predicted[5] == 1'b0);
                                
                            // write to Tx buffer
                            if(!write_reg_seq.randomize() with {
                                                    trans_delay_kind    == ZERO; 
                                                    paddr               == SPIxDAT_ADDR;
                                                    pstrb               == 4'b1111;
          	                                    }) 
                            begin
                                `uvm_fatal(get_type_name(), "Failed to randomize.")
                            end 
                            write_reg_seq.start(apb2spi_env_top.v_sequencer);
                            
                            // flush at random moment
                             if(i == flush_moment) begin
                                if(!write_reg_seq.randomize() with { 
                                            paddr        == SPIxCTRL0_ADDR;
                                            pstrb        == 4'b1111;
                                            pwdata       == 32'h00040001;
              	                        }) 
                                begin
                                    `uvm_fatal(get_type_name(), "Failed to randomize.")
                                end 
                                write_reg_seq.start(apb2spi_env_top.v_sequencer);
                            end
                                          
                        end // for_end
                        
                        forever begin
                            @(spi_trans_started);
                            check_status();
                        end 
                        
                    end // apb_block_end
                
        spi_block:  begin
                        
                        // read all data from Tx buffer
                        for(int i = 0; i < num_of_trans+10; i++) begin
                        
                            if(!spi_simple_seq.randomize() with { 
                                                    clock_gap   == 3;
                                                    data_size   == _DSIZ;
                                                    data_order  == _DORD;
          	                }) 
              	            begin
                                `uvm_fatal(get_type_name(), "Failed to randomize.")
              	            end
              	                	            
              	            -> spi_trans_started;
                            spi_simple_seq.start(apb2spi_env_top.v_sequencer);
                            
                        end // for end
                        
                    end // spi_block_end
        
    join_any   

    apb2spi_env_top.v_sequencer.stop_sequences();
    disable fork;
   
endtask
*/

`endif // TEST_APB2SPI_GENERAL_SV
