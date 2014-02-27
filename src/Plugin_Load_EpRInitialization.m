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
        
        if(0) #Disabled
        Plugin_Var_EpR_Freq      = [0   , 1200, 1800, 3300, 5000]; #Hz
        Plugin_Var_EpR_BandWidth = [300 , 400 , 300 , 700 , 500 ]; #Hz
        Plugin_Var_EpR_Amp       = [0   , 0.5 , -7  , - 10, - 10]; #DB
        
        #Anti-resonances
        Plugin_Var_EpR_ANT1.Freq      = 1500; #Hz
        Plugin_Var_EpR_ANT1.Amp       = 0;    #DB
        Plugin_Var_EpR_ANT1.BandWidth = 500;  #Hz
        Plugin_Var_EpR_ANT2.Freq      = 2500; #Hz
        Plugin_Var_EpR_ANT2.Amp       = 0;    #DB
        Plugin_Var_EpR_ANT2.BandWidth = 900;  #Hz
        end
        
        Plugin_Var_EpR_Freq = [319.37, 1023.92, 1680.32, 3334.96, 4333.20];
        Plugin_Var_EpR_BandWidth = [250.00, 576.00, 300.00, 281.31, 500.00];
        Plugin_Var_EpR_Amp = [19.241, 26.122, 25.246, 21.564, 18.409];
        Plugin_Var_EpR_ANT1.Freq = 1300;
        Plugin_Var_EpR_ANT2.Freq = 2500;
        Plugin_Var_EpR_ANT1.BandWidth = 500;
        Plugin_Var_EpR_ANT2.BandWidth = 900;
        Plugin_Var_EpR_ANT1.Amp = 0;
        Plugin_Var_EpR_ANT2.Amp = 0;
end

