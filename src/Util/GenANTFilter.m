#  GenANTFilter.m
#    Generates a multiplicative Anti-resonance filter for improved EpR model.

function Ret = GenANTFilter(OrigEnv, ANT1, ANT2)
        global SampleRate;
        global FFTSize;
        KAmp1 = GetANTLinearAmp(ANT1, OrigEnv);
        KAmp2 = GetANTLinearAmp(ANT2, OrigEnv);
        KANT1 = 1 - KlattFilter(ANT1.Freq, ANT1.BandWidth, KAmp1,
                        SampleRate, FFTSize);
        KANT2 = 1 - KlattFilter(ANT2.Freq, ANT2.BandWidth, KAmp2,
                        SampleRate, FFTSize);
        Ret = KANT1 .* KANT2;
end

