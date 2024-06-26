--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
--|
--| ALU OPCODES:
--|
--|     ADD     000
--|
--|
--|
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity ALU is
-- TODO
    Port(
        i_A      : in STD_LOGIC_VECTOR (7 downto 0);
        i_op     : in STD_LOGIC_VECTOR (2 downto 0);
        i_B      : in STD_LOGIC_VECTOR (7 downto 0);
        o_flags  : out STD_LOGIC_VECTOR (2 downto 0);
        o_result : out STD_LOGIC_VECTOR( 7 downto 0);
        o_Cout   : out std_logic
    );
    
end ALU;

architecture behavioral of ALU is 

	-- declare components and signals
        
         
         signal w_and_bits    : std_logic_vector(7 downto 0);
         signal w_or_bits     : std_logic_vector(7 downto 0);
         signal w_result      : std_logic_vector(7 downto 0);
         signal w_shift_right : std_logic_vector(7 downto 0);
         signal w_shift_left  : std_logic_vector(7 downto 0);
         signal w_and_or_bits : std_logic_vector(7 downto 0);
         signal w_add         : std_logic_vector(8 downto 0);
         signal w_AS          : std_logic_vector(7 downto 0);
         signal w_neg         : std_logic_vector(7 downto 0);
         signal w_carry       : std_logic;
         signal w_zero        : std_logic;
         signal w_sign        : std_logic;

        
begin
	-- PORT MAPS ----------------------------------------
--      w_add_sub     <= std_logic_vector((unsigned('0' & i_A) + unsigned('0' & i_B))) when i_op(0)= '0'
--                    else std_logic_vector((unsigned('0' & i_A) - unsigned('0' & i_B)));
                    
      w_neg <= STD_LOGIC_VECTOR(NOT(unsigned(i_B)) + unsigned(i_op)) when i_op(0) = '1' else --poisitive or negative B
                    STD_LOGIC_VECTOR(unsigned(i_B)) when i_op(0) = '0';
                                     
      w_add <= std_logic_vector(unsigned('0' & i_A) + unsigned(w_neg));
    
    
    
	w_and_bits <= i_A and i_B;
	
	w_or_bits <= i_A or i_B;
	
	w_and_or_bits <= w_and_bits when i_op(0)='0' else
	                   w_or_bits;
	
	w_shift_right <= std_logic_vector(shift_right(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
	
	w_shift_left <= std_logic_vector(shift_left(unsigned(i_A), to_integer(unsigned(i_B(2 downto 0)))));
	
	
	w_result <= w_add(7 downto 0) when i_op(2 downto 1) = "00" else
	            w_and_or_bits when i_op(2 downto 1) = "01" else  --And = 010  or = 011
	            w_shift_right when i_op(2 downto 1) = "10" else
	            w_shift_left  when i_op(2 downto 1) = "11";
	            
	      
	o_result <= w_result;
	w_carry <= w_add(8);
	w_zero <= '1' when w_result = "00000000" else '0';
	w_sign <= '1' when w_result(7) = '1' else '0';
	o_flags(0) <= w_carry;
	o_flags(2) <= w_result(7);
	o_flags(1) <= '1' when w_result = "00000000" else '0';
	            
	            
      
	
end behavioral;
