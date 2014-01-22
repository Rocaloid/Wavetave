#  Plugin_F0Marking.m
#    Finds the fundamental frequency by looking for peaks in magnitude
#      spectrum.
#    Stores the fundamental frequency in global variable Plugin_Var_F0
#      (in bin-index form).
#
#  The Algorithm
#    From left(low-freq) to right(high-freq) in the decibel magnitude
#      Spectrum, find the spectral peak which has the biggest difference to
#      the maximum of spectrum on its left.
function Plugin_F0Marking(Spectrum)
        global FFTSize;
        global SampleRate;
        global Environment;
        global Plugin_Var_F0;
        #Sets the minimum F0 to 50Hz.
        F0 = fix(50 * FFTSize / SampleRate + 1);
        #Sets the maximum F0 to 1500Hz.
        UBound = fix(1500 / SampleRate * FFTSize);

        MaxDiff = 0;
        #Any spectral content below -20db will be neglected, to avoid extreme
        #  subtraction results.
        Spectrum = max(Spectrum, - 20);
        for i = 5 : UBound
                #Rules for peak detection:
                #1. Higher than previous bin and next bin.
                #2. 5db higher than bins at 2 indexes away.
                if(Spectrum(i) - Spectrum(i - 1) &&
                   Spectrum(i) > Spectrum(i + 1)
                && Spectrum(i) - Spectrum(i - 2) > 5
                && Spectrum(i) - Spectrum(i + 2) > 5)
                        LeftMax = max(Spectrum(1 : F0));
                        if(Spectrum(i) - LeftMax > MaxDiff)
                                MaxDiff = Spectrum(i) - LeftMax;
                                F0 = i;
                        end
                end
        end
        Plugin_Var_F0 = F0;

        #Labels out when called from the Visualizer.
        if(strcmp(Environment, "Visual"))
                text(F0, Spectrum(F0), cstrcat("x ",
                     mat2str(fix(F0 * SampleRate / FFTSize)), "Hz"));
        end
end

