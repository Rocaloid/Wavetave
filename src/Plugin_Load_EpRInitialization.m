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
        
        #Resonances
        Plugin_Var_EpR_Freq      = [319.37, 1023.9, 1680.3, 3334.9, 4333.2];#Hz
        Plugin_Var_EpR_BandWidth = [250.00, 576.00, 300.00, 281.31, 500.00];#Hz
        Plugin_Var_EpR_Amp       = [19.241, 26.122, 25.246, 21.564, 18.409];#dB
        
        #Anti-resonances
        Plugin_Var_EpR_ANT1.Freq = 1300;
        Plugin_Var_EpR_ANT2.Freq = 2500;
        Plugin_Var_EpR_ANT1.BandWidth = 500;
        Plugin_Var_EpR_ANT2.BandWidth = 900;
        Plugin_Var_EpR_ANT1.Amp = 0;
        Plugin_Var_EpR_ANT2.Amp = 0;
        
        #Resonance templates
        global Plugin_Var_EpR_TemplateNum;
        global Plugin_Var_EpR_FreqTemplates;
        global Plugin_Var_EpR_BandWidthTemplates;
        global Plugin_Var_EpR_AmpTemplates;
        Plugin_Var_EpR_TemplateNum = 6;
        
        #Type 1 : a
        Plugin_Var_EpR_FreqTemplates(1, : ) = ...
                [150.00, 1011.1, 1645.0, 3323.7, 3993.0];#Hz
        Plugin_Var_EpR_BandWidthTemplates(1, : ) = ...
                [300.00, 480.00, 208.33, 405.09, 347.22];#Hz
        Plugin_Var_EpR_AmpTemplates(1, : ) = ...
                [15.000, 28.956, 27.261, 11.864, 11.572];#dB
        
        #Type 2 : o-
        Plugin_Var_EpR_FreqTemplates(2, : ) = ...
                [150.00, 1035.2, 1762.2, 3347.8, 4262.6];#Hz
        Plugin_Var_EpR_BandWidthTemplates(2, : ) = ...
                [300.00, 576.00, 300.00, 405.09, 600.00];#Hz
        Plugin_Var_EpR_AmpTemplates(2, : ) = ...
                [15.000, 28.693, 4.1806, 16.422, 10.432];#dB
        
        #Type 3 : e
        Plugin_Var_EpR_FreqTemplates(3, : ) = ...
                [150.00, 706.15, 1340.0, 3464.9, 4156.6];#Hz
        Plugin_Var_EpR_BandWidthTemplates(3, : ) = ...
                [300.00, 480.00, 300.00, 700.00, 347.22];#Hz
        Plugin_Var_EpR_AmpTemplates(3, : ) = ...
                [15.000, 23.843, 16.714, 15.282, 13.003];#dB
        
        #Type 4 : e-
        Plugin_Var_EpR_FreqTemplates(4, : ) = ...
                [150.00, 682.07, 2338.3, 3217.7, 4545.0];#Hz
        Plugin_Var_EpR_BandWidthTemplates(4, : ) = ...
                [300.00, 400.00, 432.00, 486.11, 416.66];#Hz
        Plugin_Var_EpR_AmpTemplates(4, : ) = ...
                [15.000, 30.387, 18.146, 17.269, 23.551];#dB
        
        #Type 5 : i
        Plugin_Var_EpR_FreqTemplates(5, : ) = ...
                [150.00, 377.14, 2890.4, 3253.1, 3957.6];#Hz
        Plugin_Var_EpR_BandWidthTemplates(5, : ) = ...
                [250.00, 333.33, 208.33, 234.42, 289.35];#Hz
        Plugin_Var_EpR_AmpTemplates(5, : ) = ...
                [15.000, 27.553, 14.435, 14.990, 14.991];#dB
        
        #Type 6 : o
        Plugin_Var_EpR_FreqTemplates(6, : ) = ...
                [150.00, 694.91, 1092.9, 3417.8, 4132.5];#Hz
        Plugin_Var_EpR_BandWidthTemplates(6, : ) = ...
                [300.00, 333.33, 360.00, 486.11, 347.21];#Hz
        Plugin_Var_EpR_AmpTemplates(6, : ) = ...
                [21.564, 31.819, 20.132, 4.6337, 8.1046];#dB
end

