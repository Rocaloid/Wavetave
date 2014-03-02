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
        
        global Plugin_Var_EpR_FreqTemplates;
        global Plugin_Var_EpR_BandWidthTemplates;
        global Plugin_Var_EpR_AmpTemplates;
        global Plugin_Var_EpR_TemplateNum;
        
        global Plugin_Var_F0;
        
        #Invalid analysis frame.
        if(Plugin_Var_F0 < 5)
                return;
        end
        
        #Initialization
        global EpR_UpperBound;
        N = Plugin_Var_EpR_N;
        Freq = Plugin_Var_EpR_Freq;
        BandWidth = Plugin_Var_EpR_BandWidth;
        Amp = Plugin_Var_EpR_Amp;
        ANT1 = Plugin_Var_EpR_ANT1;
        ANT2 = Plugin_Var_EpR_ANT2;
        EpR_UpperBound = fix(5000 / SampleRate * FFTSize);
        
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
        
        #Find the best-fitting EpR parameter set.
        for i = 1 : Plugin_Var_EpR_TemplateNum
                Freq = Plugin_Var_EpR_FreqTemplates(i, : );
                BandWidth = Plugin_Var_EpR_BandWidthTemplates(i, : );
                Amp = Plugin_Var_EpR_AmpTemplates(i, : );
                
                [Freq, BandWidth, Amp, Estimate, Diff] = ...
                    EpROptimize(Envelope, Freq, BandWidth, Amp, N, 3);
                
                #Neglect very negative error: EpR always produces a "loose"
                #  envelope.
                Error = sum(abs(max(0, Diff)));
                
                #Resonances obviously higher than spectral envelope are invalid.
                Error += CheckHigh(Envelope, Freq, BandWidth, Amp, N) * 10;
                
                #Low-frequency formants are expected to be better fitted.
                LError = sum(abs(Diff(1 : fix(Freq(2) ...
                             * FFTSize / SampleRate))));
                
                TemplateOptFreq(i, : ) = Freq;
                TemplateOptBandWidth(i, : ) = BandWidth;
                TemplateOptAmp(i, : ) = Amp;
                TemplateOptErr(i) = Error;
                TemplateOptLErr(i) = LError;
        end
        
        #Find the parameter set with smallest error.
        TemplateOptErr
        [Sorted, Match] = sort(TemplateOptErr, "ascend");
        
        #Do second sort in a range of 100 Diff error.
        LErr = 0;
        TopErr = TemplateOptErr(Match(1));
        for i = 1 : 3
                if(TemplateOptErr(Match(i)) > TopErr + 100)
                        break;
                else
                        LErr(i) = TemplateOptLErr(Match(i));
                end
        end
        [LSorted, LMatch] = sort(LErr, "ascend");
        
        #Best
        i = Match(LMatch(1));
        Freq = TemplateOptFreq(i, : );
        BandWidth = TemplateOptBandWidth(i, : );
        Amp = TemplateOptAmp(i, : );
        
        #Further optimize
        [Freq, BandWidth, Amp, Estimate, Diff] = ...
            EpROptimize(Envelope, Freq, BandWidth, Amp, N, 3);
        
        #Labeling & plotting
        [Diff, Estimate] = GenEstimateDiff(Envelope, Freq, BandWidth, Amp, N);
        for i = 1 : N
                ResLabel(Freq(i), Amp(i) + Slope(fix(Freq(i) * FFTSize / ...
                    SampleRate)), "F", i);
        end
        if(strcmp(Environment, "Visual"))
        hold on
        plot(Estimate + Slope, 'r');
        plot(Diff, 'g');
        hold off
        end
        
        Plugin_Var_EpR_Freq = Freq;
        Plugin_Var_EpR_BandWidth = BandWidth;
        Plugin_Var_EpR_Amp = Amp;
end

function ResLabel(Freq, Amp, Type, Num)
        global SampleRate;
        global FFTSize;
        
        text(Freq / SampleRate * FFTSize, Amp,
            cstrcat("X ", mat2str(fix(Freq)), "Hz"));
        text(Freq / SampleRate * FFTSize, Amp + 2,
            cstrcat(Type, mat2str(Num - 1)));
end

#Check if any formant is obviously higher than spectral envelope.
function Ret = CheckHigh(Envelope, Freq, BandWidth, Amp, N)
        global FFTSize;
        global SampleRate;
        Ret = 0;
        for i = 2 : N
                Bin = fix(Freq(i) * FFTSize / SampleRate);
                if(Amp(i) - Envelope(Bin) > 5)
                        Ret += Amp(i) - Envelope(Bin);
                end
        end
end

