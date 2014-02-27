#  Plugin_FormantFitting.m
#    Automatic formant detection and fitting based on EpR Voice Model.
#
#  Some of the codes come from MinCVE/EpRFit.m and Plugin_FormantMarking_EpR.
#
#  Depends on KlattFilter, Plugin_F0Marking_ByPhase and
#    Plugin_HarmonicMarking_Naive.
#
#  Not finished yet.

function Plugin_FormantFitting(Spectrum)
        global FFTSize;
        global SampleRate;
        global Environment;

        #Shared parameters.
        global Plugin_Var_EpR_N;
        global Plugin_Var_EpR_Freq;
        global Plugin_Var_EpR_BandWidth;
        global Plugin_Var_EpR_Amp;
        global Plugin_Var_EpR_ANT1;
        global Plugin_Var_EpR_ANT2;
        
        global Plugin_Var_F0;
        
        #Invalid analysis frame.
        if(Plugin_Var_F0 < 5)
                return;
        end
        
        #Initialization
        N = Plugin_Var_EpR_N;
        Freq = Plugin_Var_EpR_Freq;
        BandWidth = Plugin_Var_EpR_BandWidth;
        Amp = Plugin_Var_EpR_Amp;
        ANT1 = Plugin_Var_EpR_ANT1;
        ANT2 = Plugin_Var_EpR_ANT2;
        
        _Environment = Environment;
        Environment = "Procedure";
        Plugin_HarmonicMarking_Naive(Spectrum);
        Environment = _Environment;
        
        #Envelope generation
        global Plugin_Var_Harmonics_Freq;
        global Plugin_Var_Harmonics_Magn;
        XPeak = Plugin_Var_Harmonics_Freq;
        YPeak = Plugin_Var_Harmonics_Magn;
        fflush(stdout);
        Envelope = PeakInterpolate(XPeak, YPeak, FFTSize, - 20) ...
                       (1 : FFTSize / 2);
        
        #Pre-emphasis as excitation slope.
        Coef(1) = - 0.1;
        Coef(2) = 0;
        Slope = Coef(2) + (1 : length(Spectrum)) * Coef(1);
        Spectrum = Spectrum' - Slope;
        Envelope = Envelope - Slope;
        
        hold on
        #Iterative approximation.
        for step = 1 : 5
                [Diff, Estimate] = GenEstimateDiff(Envelope, Freq, BandWidth,
                                       Amp, N);
                Freq = Move(Diff, Freq, BandWidth, Amp, N);
                Amp  = Scale(Diff, Envelope, Freq, BandWidth, Amp, N);
        end
        plot(Estimate + Slope, 'r');
        plot(Diff, 'g');
        pause
        hold off
end

#Generates Estimate and Differential Spectrum.
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
        Diff(1 : fix(Freq(1) / SampleRate * FFTSize)) = 0;
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
function Freq = Move(Diff, Freq, BandWidth, Amp, N)
        Diff = BiasDiff(Diff);
        for i = 2 : N
                Center = fix(F2B(Freq(i)));
                LBin = fix(max(1, F2B(Freq(i) - BandWidth(i))));
                RBin = fix(F2B(Freq(i) + BandWidth(i)));
                Left  = sum(Diff(LBin : Center));
                Right = sum(Diff(Center : RBin));
                Dir = Right - Left;
                Freq(i) += Dir * 3;
                
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
function Amp = Scale(Diff, Envelope, Freq, BandWidth, Amp, N)
        for i = 2 : N
                LBin = fix(max(1, F2B(Freq(i) - BandWidth(i))));
                RBin = fix(F2B(Freq(i) + BandWidth(i)));
                Sum = sum(Diff(LBin : RBin));
                Dir = Sum
                Amp(i) += Dir / 60;
                if(Amp(i) < Envelope(fix(F2B(Freq(i)))))
                        Amp(i) = Envelope(fix(F2B(Freq(i))));
                end
        end
end

