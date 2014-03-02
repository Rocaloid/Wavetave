#  EpROptimize.m
#    Roughly minimizes differential envelope of an EpR parameter set.

function [Freq, BandWidth, Amp, Estimate, Diff] = ...
    EpROptimize(Envelope, Freq, BandWidth, Amp, N, StepNum)
        SearchWidth = 500;
        #Iterative approximation.
        for Step = 1 : StepNum
                [Diff, Estimate] = GenEstimateDiff(Envelope, Freq, ...
                                        BandWidth, Amp, N);
                [Freq, Amp] = Move(Diff, Freq, BandWidth, Amp, N, SearchWidth);
                Amp  = Scale(Diff, Envelope, Estimate, Freq, BandWidth, Amp, N);
                SearchWidth *= 0.8;
        end
end

#Biased differential envelope for Move().
function Diff = BiasDiff(Diff)
        global FFTSize;
        
        DiffNeg = min(0, Diff);
        DiffPos = max(0, Diff);
        
        #Avoid positive rather than negative error.
        DiffNeg = 3 * e .^ (0.15 * DiffNeg) - 3;
        
        Diff = DiffPos + DiffNeg;
end

#Horizontal adjustment.
function [Freq, Amp] = Move(Diff, Freq, BandWidth, Amp, N, SearchWidth = 500)
        global Dbg;
        Diff = BiasDiff(Diff);
        for i = 2 : N
                Center = fix(F2B(Freq(i)));
                #LBin = fix(max(1, F2B(Freq(i) - BandWidth(i) * 1.5)));
                #RBin = fix(F2B(Freq(i) + BandWidth(i) * 1.5));
                LBin = fix(max(1, F2B(Freq(i) - SearchWidth)));
                RBin = fix(F2B(Freq(i) + SearchWidth));
                Left  = sum(Diff(LBin : Center));
                Right = sum(Diff(Center : RBin));
                Dir = Right - Left;
                Freq(i) += Dir / SearchWidth * 500;
                if(Dbg)
                        printf("N: %d, Dir; %f\n", i - 1, Dir);
                end
                
                #Freq(i) should be in the range of [Freq(i - 1), Freq(i + 1)].
                if(i < N)
                        Mid = (Freq(i + 1) + Freq(i - 1)) / 2;
                        if(Freq(i) > Freq(i + 1))
                                Freq(i) = max(Freq(i + 1) - 10, Mid);
                        end
                        if(Freq(i) < Freq(i - 1))
                                Freq(i) = min(Freq(i - 1) + 10, Mid);
                        end
                else
                        if(Freq(i) < Freq(i - 1))
                                Freq(i) = Freq(i - 1) + 10;
                        end
                end
        end
end

#Vertical adjustment.
function Amp = Scale(Diff, Envelope, Estimate, Freq, BandWidth, Amp, N)
        for i = 1 : N
                LBin = fix(max(1, F2B(Freq(i) - BandWidth(i))));
                RBin = fix(F2B(Freq(i) + BandWidth(i)));
                Sum = sum(Diff(LBin : RBin));
                Dir = Sum;
                Amp(i) += Dir / 60;
                
                #Peaks should not be submerged under either Envelope or 
                #  Estimated Envelope - 10dB.
                if(Amp(i) < Envelope(fix(F2B(Freq(i)))))
                        Amp(i) = Envelope(fix(F2B(Freq(i))));
                end
                if(Amp(i) < Estimate(fix(F2B(Freq(i)))) - 10)
                        Amp(i) = Estimate(fix(F2B(Freq(i))) - 10);
                end
        end
end

