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
                       (1 : FFTSize / 2)';
        
        #Pre-emphasis as excitation slope.
        Coef(1) = - 0.1;
        Coef(2) = 0;
        Slope = Coef(2) + (1 : length(Spectrum))' * Coef(1);
        Spectrum = Spectrum - Slope;
        Envelpoe = Envelope - Slope;
        
        
end

#Biased differential envelope for Move().
function Diff = BiasDiff(Diff)
        global FFTSize;
        
        DiffNeg = min(0, Diff);
        DiffPos = max(0, Diff);
        
        #Avoid positive rather than negative error.
        DiffNeg = 0.5 * e .^ (0.5 * DiffNeg) - 0.5;
        
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
                Freq(i) += Dir * 15;
                
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
                Dir = Sum;
                Amp(i) += Dir / 5;
                if(Amp(i) < 20 * log10(e ^ Envelope(fix(F2B(Freq(i))))))
                        Amp(i) = 20 * log10(e ^ Envelope(fix(F2B(Freq(i)))));
                end
        end
end

