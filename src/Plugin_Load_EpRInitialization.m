#  Plugin_Load_EpR_Initialization.m
#    Setting up initial EpR parameters.

function Plugin_Load_EpRInitialization()
        global Plugin_Var_EpR_N;
        global Plugin_Var_EpR_Freq;
        global Plugin_Var_EpR_BandWidth;
        global Plugin_Var_EpR_Amp;
        Plugin_Var_EpR_N = 5;
        Plugin_Var_EpR_Freq      = [0   , 1200, 1800, 3300, 5000]; #Hz
        Plugin_Var_EpR_BandWidth = [300 , 400 , 300 , 700 , 500 ]; #Hz
        Plugin_Var_EpR_Amp       = [0   , 0.5 , -7  , - 10, - 10]; #DB
end

