#  EpRFit.m
#    Semi-automatic fitting tool for EpR Voice Model & CVDB.

#  Not finished yet.

function EpRFit(Name)
        global FFTSize;
        global HopSize;
        global Window;
        global SampleRate;
        global Environment;
        
        global SpectrumLowerRange;
        global SpectrumUpperRange;
        global DBLowerRange;
        global DBUpperRange;
        
        global CVDB_Residual;
        global CVDB_Sinusoid_Magn;
        global CVDB_Sinusoid_Freq;
        global CVDB_Wave;
        
        addpath("../");
        addpath("../Oct");
        addpath("../Util");
        
        Environment = "Procedure";
        FFTSize = 2048;
        Window = hanning(FFTSize);
        
        SpectrumLowerRange = 0;
        SpectrumUpperRange = 6000;
        DBLowerRange = - 70;
        DBUpperRange = 40;

        #Load and align.
        load(strcat("Data/", Name, ".cvdb"));
        CVDBUnwrap;
        [Wave, SampleRate] = wavread(CVDB_SourceLink);
        Length = length(Wave);
        Wave = Wave(CVDB_SourceOffset : Length);
        Length = length(Wave);
        
        #Hop
        HopFactor = 4;
        HopSize = (CVDB_FramePosition(2) - CVDB_FramePosition(1)) * HopFactor;

        #Initialize global EpR parameters.
        global Plugin_Var_EpR_N;
        global Plugin_Var_EpR_Freq;
        global Plugin_Var_EpR_BandWidth;
        global Plugin_Var_EpR_Amp;
        global Plugin_Var_EpR_ANT1;
        global Plugin_Var_EpR_ANT2;
        Plugin_Var_EpR_N = 5;
        Plugin_Var_EpR_Freq = [319.37, 1023.92, 1680.32, 3334.96, 4333.20];
        Plugin_Var_EpR_BandWidth = [250.00, 576.00, 300.00, 281.31, 500.00];
        Plugin_Var_EpR_Amp = [19.241, 26.122, 25.246, 21.564, 18.409];
        Plugin_Var_EpR_ANT1.Freq = 1300;
        Plugin_Var_EpR_ANT2.Freq = 2500;
        Plugin_Var_EpR_ANT1.BandWidth = 500;
        Plugin_Var_EpR_ANT2.BandWidth = 900;
        Plugin_Var_EpR_ANT1.Amp = 0;
        Plugin_Var_EpR_ANT2.Amp = 0;
        c = 1;
        
        #Marking the first spectrum.
        Position = CVDB_FramePosition(1);
        Spectrum = GenerateSpectrum(Wave(Position - FFTSize / 2 : ...
                       Position + FFTSize /2 - 1));
        Plugin_FormantMarking_EpR(Spectrum);
        
        EpR_N(c) = Plugin_Var_EpR_N;
        EpR_Freq(c, : ) = Plugin_Var_EpR_Freq;
        EpR_BandWidth(c, : ) = Plugin_Var_EpR_BandWidth;
        EpR_Amp(c, : ) = Plugin_Var_EpR_Amp;
        global EpR_UpperBound;
        EpR_UpperBound = fix(F2B(Plugin_Var_EpR_Freq(EpR_N(c)) ...
                       + Plugin_Var_EpR_BandWidth(EpR_N(c))));
        
        #Pre-emphasis slope generation
        Coef = [- 0.1, 0];
        Slope = Coef(2) + (1 : FFTSize / 2) * Coef(1);
        Slope = DecibelToIFFTLn(Slope);
        
        #For each frame
        for i = HopFactor : HopFactor : length(CVDB_FramePosition)
        
        printf("%d%%\n", 100 * i / length(CVDB_FramePosition));

        c ++;
        
        N = EpR_N(c - 1);
        Freq = EpR_Freq(c - 1, : );
        BandWidth = EpR_BandWidth(c - 1, : );
        Amp = EpR_Amp(c - 1, : );
        
        #Envelope generation
        XPeak = CVDB_Sinusoid_Freq(i, : ) / SampleRate * FFTSize;
        YPeak = CVDB_Sinusoid_Magn(i, : );
        Envelope = PeakInterpolate(XPeak, YPeak, FFTSize, - 20) ...
                       (1 : FFTSize / 2) - Slope;
        
        DBEnvelope = 20 * log10(e) * Envelope;
        [Freq, BandWidth, Amp, Estimate, Diff] = ...
            EpROptimize(DBEnvelope, Freq, BandWidth, Amp, N, 5);
        Estimate = Estimate / 20 / log10(e);
        Diff = Diff / 20 / log10(e);
        
        #Iterative approximation.
        #for step = 1 : 5
        #        [Diff, Estimate] = GenEstimateDiff(Envelope, Freq, BandWidth,
        #                               Amp, N);
        #        Freq = Move(Diff, Freq, BandWidth, Amp, N);
        #        Amp  = Scale(Diff, Envelope, Freq, BandWidth, Amp, N);
        #end
        
        Plugin_Var_EpR_Freq = Freq;
        Plugin_Var_EpR_BandWidth = BandWidth;
        Plugin_Var_EpR_Amp = Amp;
        
        Center = CVDB_FramePosition(i);
        Spectrum = GenerateSpectrum(Wave(Center - FFTSize / 2 : ...
                       Center + FFTSize / 2 - 1));
        Plugin_FormantMarking_EpR(Spectrum);
        
        if(1)
        plot(Envelope, "r");
        hold on
        plot(Estimate, "b");
        plot(Diff, "g");
        plot(0 * (1 : 300), "k");
        hold off
        axis([1, 300, - 5, 5]);
        pause
        end

        EpR_N(c) = N;
        EpR_Freq(c, : ) = Plugin_Var_EpR_Freq;
        EpR_BandWidth(c, : ) = Plugin_Var_EpR_BandWidth;
        EpR_Amp(c, : ) = Plugin_Var_EpR_Amp;

        end
        
        save(strcat("Data/", Name, ".vepr"), ...
            "EpR_N", ...
            "EpR_Freq", ...
            "EpR_BandWidth", ...
            "EpR_Amp");
end

#Generates Estimate and Differential Spectrum.
function [Diff, Estimate] = GenEstimateDiff(Envelope, Freq, BandWidth, Amp, N)
        global FFTSize;
        global SampleRate;
        global EpR_UpperBound;
        
        Estimate = EpR_CumulateResonance(Freq, BandWidth, 10 .^ (Amp / 20), N);
        Estimate = log(Estimate);
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

