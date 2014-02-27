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
        ANT1.Freq      = 1500; #Hz
        ANT1.Amp       = 0;    #DB
        ANT1.BandWidth = 350;  #Hz
        ANT2.Freq      = 2500; #Hz
        ANT2.Amp       = 0;    #DB
        ANT2.BandWidth = 350;  #Hz
end

