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

--Documentation Statement: 
--C3C Culp helped me by explainging the function of the MUX in the top basys file to enhance my understanding
--of how the component works and its purpose within the lab. He also helped me with my controller fsm by explaing how it was going to
-- be modeled after the stoplight fsm due to how it is an FSM that needed f_Q and f_Q_next. He also helped with 
--debugging the controlller fsm. C3C Leong helped me by explaing how the flags in the CPU operate to help 
--better my understanding when drawing the schematic for the ALU.
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
-- TODO
port(
        clk   : in std_logic;
        btnU  : in std_logic;
        btnC  : in std_logic;
        sw    : in std_logic_vector (7 downto 0);
        
--        sw_2  : in std_logic_vector (3 downto 0);
        
        --outputs
        
        led   : out std_logic_vector (15 downto 0);
        seg   : out std_logic_vector  (6 downto 0);
        an    : out std_logic_vector (3 downto 0) 
        
);
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
component MUX_4_1 is
    port( i_A      : in STD_LOGIC_VECTOR (7 downto 0);
          i_result : in STD_LOGIC_VECTOR (7 downto 0);
          i_B      : in STD_LOGIC_VECTOR (7 downto 0);
          i_cycle  : in std_logic_vector (3 downto 0);
          o_out    : out std_logic_vector(7 downto 0)
    );
end component MUX_4_1;	
	
--seven segment decoder
component sevenSegDecoder is
    port(   i_D : in std_logic_vector (3 downto 0);
            o_S : out std_logic_vector (6 downto 0)      
    );
end component sevenSegDecoder;

signal w_S : std_logic_vector ( 6 downto 0);
  
  --clock divider
component clock_divider is
    generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles											   -- Effectively, you divide the clk double this 									   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	   port ( 	i_clk    : in std_logic;
			    i_reset  : in std_logic;		   -- asynchronous
			    o_clk    : out std_logic		   -- divided (slow) clock
	           );
end component clock_divider;

signal w_clk_TDM4 : std_logic;

  
--controller fsm
component controller_fsm is
    port( i_reset : in std_logic;  --btnU
          i_adv   : in std_logic; --btnC
          o_cycle : out std_logic_vector(3 downto 0);
          i_clk   : in std_logic
          );
end component controller_fsm;

signal w_reset : std_logic;
signal w_adv   : std_logic;
signal w_cycle : std_logic_vector(3 downto 0);
signal w_clk   : std_logic;

--regA
component regA is
    port( i_L    : in std_logic_vector(3 downto 0);
          i_regA : in std_logic_vector(7 downto 0);
          o_regA : out std_logic_vector(7 downto 0);
          i_btn  : in std_logic);
end component regA;
          
signal w_regAin  : std_logic_vector(7 downto 0);
signal w_regAout : std_logic_vector(7 downto 0);

--regB
component regB is
    port( i_L    : in std_logic_vector(3 downto 0);
          i_regB : in std_logic_vector(7 downto 0);         
          o_regB : out std_logic_vector(7 downto 0));
end component regB;

signal w_regBin : std_logic_vector(7 downto 0);
signal w_regBout : std_logic_vector(7 downto 0);

--twoscomp

component twoscomp_decimal is
    port(
            i_binary: in std_logic_vector(7 downto 0);
            o_negative: out std_logic_vector (3 downto 0);
            o_hundreds: out std_logic_vector(3 downto 0);
            o_tens: out std_logic_vector(3 downto 0);
            o_ones: out std_logic_vector(3 downto 0)
    );
end component twoscomp_decimal;
--signal w_bin : std_logic_vector(7 downto 0);
signal w_negative : std_logic_vector (3 downto 0);
signal w_hund : std_logic_vector(3 downto 0);
signal w_tens : std_logic_vector(3 downto 0);
signal w_ones : std_logic_vector (3 downto 0);

---ALU

component ALU is
    port( i_A      : in STD_LOGIC_VECTOR (7 downto 0);
         i_op     : in STD_LOGIC_VECTOR (2 downto 0);
         i_B      : in STD_LOGIC_VECTOR ( 7 downto 0);
         o_flags  : out STD_LOGIC_VECTOR (2 downto 0);
         o_result : out STD_LOGIC_VECTOR( 7 downto 0);
         o_Cout   : out std_logic
    );
end component ALU;
signal w_result : std_logic_vector(7 downto 0);
signal w_out    : std_logic_vector(7 downto 0);


--TDM4
component TDM4 is
  generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
    );
end component TDM4;

signal w_data, w_sel : std_logic_vector(3 downto 0);
signal w_negative_sign : std_logic_vector(3 downto 0);
--signal w_sel : std_logic_vector(3 downto 0);


begin

--led(12 downto 4) <= "000000000";
led(12 downto 5) <= w_regAout;
led(3 downto 0) <= w_cycle;
w_clk <= clk;

	-- PORT MAPS ----------------------------------------
controller_fsm_inst: controller_fsm
    port map( i_reset => btnU,
              i_adv   => btnC,
              o_cycle => w_cycle,
              i_clk   => w_clk
    );
 ---------------------------------------------------------------------------
--unsure of how to connect the w_cycle to i_clk to both registars
regA_inst: regA
    port map( i_regA => sw(7 downto 0),
              o_regA => w_regAout,
              i_L => w_cycle,
              i_btn => btnC
    );
 
 regB_inst: regB
        port map( i_regB => sw(7 downto 0),
                  o_regB => w_regBout,
                  i_L => w_cycle
        );   
------------------------------------------------------------------------------
--Unsure about the switch connection    
ALU_inst: ALU
    port map( i_A  => w_regAout,
              i_B  => w_regBout,
              i_op => sw(2 downto 0),
              o_result => w_result,
              o_flags => led(15 downto 13)
    );
    
--------------------------------------------------------------------------------      
	
twoscomp_decimal_inst: twoscomp_decimal
    port map( i_binary   => w_out,
              o_negative => w_negative,
              o_hundreds => w_hund,
              o_tens     => w_tens,
              o_ones     => w_ones  
    );
    
-- w_negative_sign <= x"A" when (w_negative = "1111") else x"F";
    
TDM4_inst: TDM4
    port map( i_reset => btnU,
              i_clk => w_clk_TDM4,
              i_D3=> w_negative, --w_negative
              i_D2 => w_hund,
              i_D1 => w_tens,
              i_D0 => w_ones,
              o_data => w_data,
              o_sel => w_sel
    );

clock_divider_inst: clock_divider
    generic map (k_DIV => 10000)
    port map(o_clk => w_clk_TDM4,
             i_clk => w_clk,
             i_reset => btnU
    );
    
sevenSegDecoder_inst: sevenSegDecoder
    port map( i_D => w_data,
              o_S => seg
    );
    

    
MUX_4_1_inst: MUX_4_1
    port map( i_A      => w_regAout, 
              i_B      => w_regBout,
              i_result => w_result,
              i_cycle  => w_cycle,
              o_out    => w_out
    );
	

	
	-- CONCURRENT STATEMENTS ----------------------------
	an <= x"F" when w_cycle = "0000" else w_sel;
    
	
	
end top_basys3_arch;
