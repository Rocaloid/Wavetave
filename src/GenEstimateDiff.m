#  GenEstimateDiff.m
#    Generates Estimated and Differential Spectrum.

function [Diff, Estimate] = GenEstimateDiff(Envelope, Freq, BandWidth, Amp, N)
        global FFTSize;
        global SampleRate;
        global EpR_UpperBound;
        
        Estimate = EpR_CumulateResonance(Freq, BandWidth, 10 .^ (Amp / 20), N);
        Estimate = 20 * log10(Estimate);
        Diff = Envelope - Estimate;
        
        #Cutoff high-frequency content.
        Diff(EpR_UpperBound : FFTSize / 2) = 0;
        #Cutoff low-frequency content.
        Diff(1 : fix(Freq(1) / SampleRate * FFTSize / 2)) = 0;
end

