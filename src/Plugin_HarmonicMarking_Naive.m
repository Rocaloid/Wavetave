#  Plugin_HarmonicMarking_Naive.m
#    The simplified version of Plugin_HarmonicMarking, which doesn't do
#      fundamental frequency correction as marking harmonic peaks. Instead
#      it uses F0 generated by Plugin_F0Marking_ByPhase to achieve a much
#      higher accuracy.
#  Depends on Plugin_F0Marking_ByPhase.

function Plugin_HarmonicMarking_Naive(Spectrum, Phase, Wave)
        global FFTSize;
        global SampleRate;
        global Plugin_Var_F0;
        global Plugin_Var_F0_Exact;
        global SpectrumUpperRange;
        SpectrumUpperBin = SpectrumUpperRange * FFTSize / SampleRate;

        #If the data is valid
        if(Plugin_Var_F0_Exact > 50)
                for i = 2 : fix(SpectrumUpperBin / Plugin_Var_F0)
                        PinX = Plugin_Var_F0_Exact * FFTSize / SampleRate * i;
                        PinY = max(Spectrum(fix(PinX) - 3 : fix(PinX) + 3));
                        text(PinX, PinY + 5, strcat("H", mat2str(i - 1)));
                        text(PinX, PinY, cstrcat("x ",
                             mat2str(fix(PinX * SampleRate / FFTSize)), "Hz"));
                end
        endif
end
