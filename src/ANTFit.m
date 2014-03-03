#  ANTFit.m
#    Generates ANT parameters from a basic EpR model.

function [ANT1, ANT2] = ANTFit(Envelope, Estimate, Freq)
        F1Bin = max(1, fix(F2B(Freq(2))))
        F2Bin = max(1, fix(F2B(Freq(3))))
        F3Bin = max(1, fix(F2B(Freq(4))))
        
        #Find the lowest point between F1 & F2, F2 & F3.
        #Notice: the interval may not always be concave.
        #[Amp1, Bin1] = min(Envelope(F1Bin : F2Bin))
        #[Amp2, Bin2] = min(Envelope(F2Bin : F3Bin))
        #Bin1 += F1Bin;
        #Bin2 += F2Bin;
        
        #Mid point
        Bin1 = fix((F2Bin + F1Bin) / 2);
        Bin2 = fix((F3Bin + F2Bin) / 2);
        ANT1.Freq = B2F(Bin1);
        ANT2.Freq = B2F(Bin2);
        
        #Difference in amplitude.
        ANT1.Amp = Estimate(Bin1) - Envelope(Bin1);
        ANT2.Amp = Estimate(Bin2) - Envelope(Bin2);
        
        #BandWidth is determined by minimal interval between Anti-resonances
        #  and Resonances.
        ANT1.BandWidth = min(ANT1.Freq - Freq(2), Freq(3) - ANT1.Freq) * 0.7;
        ANT2.BandWidth = min(ANT2.Freq - Freq(3), Freq(4) - ANT2.Freq) * 0.7;
        ANT1.BandWidth = max(100, ANT1.BandWidth);
        ANT2.BandWidth = max(100, ANT2.BandWidth);
end

