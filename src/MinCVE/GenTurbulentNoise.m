#  GenTurbulentNoise.m
#    Create Turbulent Noise based on analysis on deterministic component.

function Sto = GenTurbulentNoise(Deterministic, Stochastic, VOT)
        global Plugin_Var_VOT;
        global Plugin_Var_F0;
        global Plugin_Var_Pulses;
        Plugin_Var_VOT = VOT;
        Plugin_Load_PulseMarking(Deterministic');
        Sto = Stochastic * 0.4;
        NoiseWindow = 3 * hanning(120)' + 1;
        
        for i = Plugin_Var_Pulses
                Sto(i - 60 : i + 59) .*= NoiseWindow;
        end
end

