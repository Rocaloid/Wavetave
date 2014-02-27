#  GetANTLinearAmp.m
#    Calculate linear amplitude of an Anti-resonance, to be used as Klatt
#      Filter amplitude and multipled with resonance spectrum.
function KAmp = GetANTLinearAmp(ANT, Restrum)
        global SampleRate;
        global FFTSize;

        #Center of Anti-resonances
        ANTPos = fix(ANT.Freq / SampleRate * FFTSize);
        #Original spectral amplitude
        RAmp  = Restrum(ANTPos);
        #New linear amplitude
        Magn = 10 ^ ((20 * log10(RAmp) - ANT.Amp) / 20);
        #Klatt Filter linear amplitude
        KAmp  = 1 - Magn / RAmp;
end

