#  ANTTransition.m
#    Anti-resonance structure transition.

function Ret = ANTTransition(ANT1, ANT2, Ratio)
        Ret.Freq      = ANT1.Freq + (ANT2.Freq - ANT1.Freq) * Ratio;
        Ret.BandWidth = ANT1.BandWidth + ...
            (ANT2.BandWidth - ANT1.BandWidth) * Ratio;
        Ret.Amp       = ANT1.Amp + (ANT2.Amp - ANT1.Amp) * Ratio;
end

