#  Plugin_Load_EpR_Initialization.m
#    Setting up initial EpR parameters.

function Plugin_Load_EpRInitialization()
        global Plugin_Var_EpR_N;
        global Plugin_Var_EpR_Freq;
        global Plugin_Var_EpR_BandWidth;
        global Plugin_Var_EpR_Amp;
        global Plugin_Var_EpR_ANT1;
        global Plugin_Var_EpR_ANT2;
        Plugin_Var_EpR_N = 5;
        Plugin_Var_EpR_Freq      = [0   , 1200, 1800, 3300, 5000]; #Hz
        Plugin_Var_EpR_BandWidth = [300 , 400 , 300 , 700 , 500 ]; #Hz
        Plugin_Var_EpR_Amp       = [0   , 0.5 , -7  , - 10, - 10]; #DB
        
        #Anti-resonances
        Plugin_Var_EpR_ANT1.Freq      = 1500; #Hz
        Plugin_Var_EpR_ANT1.Amp       = 7;    #DB
        Plugin_Var_EpR_ANT1.BandWidth = 600;  #Hz
        Plugin_Var_EpR_ANT2.Freq      = 2500; #Hz
        Plugin_Var_EpR_ANT2.Amp       = 10;   #DB
        Plugin_Var_EpR_ANT2.BandWidth = 1200; #Hz
end

