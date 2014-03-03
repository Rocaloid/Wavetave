#  EpROptimize.m
#    Roughly minimizes differential envelope of an EpR parameter set.

function [Freq, BandWidth, Amp, Estimate, Diff] = ...
    EpROptimize(Envelope, Freq, BandWidth, Amp, N, StepNum, SearchWidth = 1000)
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
        global EpR_UpperBound;
        global EpROptimize_MoveMethod;
        global EpR_LockStat;
        Diff = BiasDiff(Diff);
        for i = 2 : N
                if(EpR_LockStat(i) == 1)
                        #Locked resonance.
                        continue;
                end
                Center = fix(F2B(Freq(i)));
                if(EpROptimize_MoveMethod == 0)
                        #Bilateral summation method.
                        LBin = fix(max(1, F2B(Freq(i) - SearchWidth)));
                        RBin = fix(F2B(Freq(i) + SearchWidth));
                        Left  = sum(Diff(LBin : Center));
                        Right = sum(Diff(Center : RBin));
                        Dir = Right - Left;
                        Freq(i) += Dir / SearchWidth * 500;
                elseif(EpROptimize_MoveMethod == 1)
                        #Gravitation method.
                        A = GetAcceleration(Diff, Freq(i), SearchWidth);
                        Freq(i) += A * 10;
                end
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
                if(Freq(i) < 80)
                        #Lower bound.
                        Freq(i) = 80;
                end
                if(Freq(i) > B2F(EpR_UpperBound))
                        #Upper bound
                        Freq(i) = B2F(EpR_UpperBound);
                end
        end
end

#Gravitation Method.
#  Evaluating the direction and frequency distance to shift a EpR resonance.
#  In the spectrum, assume:
#  * The y-axis represents mass of each frequency bin.
#  * The x-axis represents position of each frequency bin.
#  * The central frequency of a resonance is a point with 1 unit mass.
#  The attraction on resonance (x-axis) is given by:
#          N     m * mi      N      XAmp(i)
#     F = Sum G ------- = G Sum  --------------
#        i = 1   ri ^ 2    i = 1  (i - fc) ^ 2
#  F = ma, a = F
#  Actually the power of denominator does not have to be 2. It's tested that a
#    smaller value such as 0.5 will be better.
function A = GetAcceleration(Diff, Freq, SearchWidth = 500)
        global EpR_UpperBound;
        Center = fix(F2B(Freq));
        LBin = max(1, fix(F2B(Freq - SearchWidth)));
        RBin = min(EpR_UpperBound, fix(F2B(Freq + SearchWidth)));
        Diff(1 : LBin) = 0;
        Diff(RBin : EpR_UpperBound) = 0;
        #Diff > 0: Attract | Diff < 0: Repulse
        F = Diff(1 : EpR_UpperBound) ./ ...
            (abs((1 : EpR_UpperBound) - Center) .^ 0.5);
        F(1 : min(EpR_UpperBound, Center)) *= - 1;
        F(max(1, Center - 3) : min(EpR_UpperBound, Center + 3)) = 0;
        A = sum(F);
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
                if(Amp(i) < Estimate(fix(F2B(Freq(i)))) - 7)
                        Amp(i) = Estimate(fix(F2B(Freq(i)))) - 7;
                end
        end
end

