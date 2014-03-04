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
        global EpROptimize_MoveMethod;
        global EpR_LockStat;
        EpR_LockStat = zeros(1, 5);
        #0: Bilateral Summation method
        #1: Gravitation method
        EpROptimize_MoveMethod = 0;
        
        Plugin_Load_EpRInitialization();
        
        c = 1;
        
        #Mark the first spectrum.
        global Plugin_Var_F0_Exact;
        global Plugin_Var_F0;
        Position = CVDB_FramePosition(1);
        Spectrum = GenerateSpectrum(Wave(Position - FFTSize / 2 : ...
                       Position + FFTSize /2 - 1));
        #Formant fitting & marking
        Plugin_Var_F0_Exact = CVDB_Sinusoid_Freq(1, 1);
        Plugin_Var_F0 = fix(F2B(Plugin_Var_F0_Exact));
        Plugin_FormantFitting(Spectrum);
        Plugin_FormantMarking_EpR(Spectrum);
        
        EpR_N(c) = Plugin_Var_EpR_N;
        EpR_Freq(c, : ) = Plugin_Var_EpR_Freq;
        EpR_BandWidth(c, : ) = Plugin_Var_EpR_BandWidth;
        EpR_Amp(c, : ) = Plugin_Var_EpR_Amp;
        global EpR_UpperBound;
        EpR_UpperBound = 220;
        #EpR_UpperBound = fix(F2B(Plugin_Var_EpR_Freq(EpR_N(c)) ...
        #               + Plugin_Var_EpR_BandWidth(EpR_N(c))));
        
        #Pre-emphasis slope generation
        Coef = [- 0.1, 0];
        Slope = Coef(2) + (1 : FFTSize / 2) * Coef(1);
        LnSlope = Slope / 20 * log(10);
        
        #For each frame
        for i = HopFactor : HopFactor : length(CVDB_FramePosition)
        
        Progress = 100 * i / length(CVDB_FramePosition);

        c ++;
        
        N = EpR_N(c - 1);
        Freq = EpR_Freq(c - 1, : );
        BandWidth = EpR_BandWidth(c - 1, : );
        Amp = EpR_Amp(c - 1, : );
        
        #Envelope generation
        XPeak = CVDB_Sinusoid_Freq(i, : ) / SampleRate * FFTSize;
        YPeak = CVDB_Sinusoid_Magn(i, : );
        Envelope = PeakInterpolate(XPeak, YPeak, FFTSize, - 20) ...
                       (1 : FFTSize / 2) - log(4 / FFTSize);
        
        #EpR parameter optimization.
        DBEnvelope = 20 / log(10) * Envelope - Slope;
        global Dbg;
        [Freq, BandWidth, Amp, Estimate, Diff] = ...
            EpROptimize(DBEnvelope, Freq, BandWidth, Amp, N, 3);
        
        #Anti-resonance generation.
        [Plugin_Var_EpR_ANT1, Plugin_Var_EpR_ANT2] = ANTFit( ...
            DBEnvelope, Estimate, Freq);
        Estimate = 10 .^ (Estimate / 20) .* GenANTFilter(Estimate, ...
                       Plugin_Var_EpR_ANT1, Plugin_Var_EpR_ANT2);
        Estimate = 20 * log10(Estimate);
        
        #Prepare for manual adjustment.
        Plugin_Var_EpR_Freq = Freq;
        Plugin_Var_EpR_BandWidth = BandWidth;
        Plugin_Var_EpR_Amp = Amp;
        Center = CVDB_FramePosition(i);
        Spectrum = GenerateSpectrum(Wave(Center - FFTSize / 2 : ...
                       Center + FFTSize / 2 - 1));
        Estimate = DecibelToIFFTLn(Estimate);
        Diff = Diff / 20 * log(10);
        
        #Change this line to debug at particular time.
        if(Progress > 0)
                PlotEpR(Envelope, Estimate, Diff, LnSlope, Freq, Amp, N);
        end
        while(1)
                Ret = Prompt(Progress);
                clc;
                if(Ret == 109) #M: Manual Adj
                        Plugin_FormantMarking_EpR(Spectrum);
                        Freq = Plugin_Var_EpR_Freq;
                        BandWidth = Plugin_Var_EpR_BandWidth;
                        Amp = Plugin_Var_EpR_Amp;
                        [Diff, Estimate] = GenEstimateDiff( ...
                            Envelope, Freq, BandWidth, Amp, N);
                        
                        #Anti-resonance reconstruction.
                        [Plugin_Var_EpR_ANT1, Plugin_Var_EpR_ANT2] = ANTFit( ...
                            DBEnvelope, Estimate, Freq);
                        Estimate = 10 .^ (Estimate / 20) .* GenANTFilter( ...
                            Estimate, Plugin_Var_EpR_ANT1, Plugin_Var_EpR_ANT2);
                        Estimate = 20 * log10(Estimate);
                        
                        Estimate = DecibelToIFFTLn(Estimate);
                        Diff = Diff / 20 * log(10);
                        PlotEpR(Envelope, Estimate, Diff, ...
                            LnSlope, Freq, Amp, N);
                elseif(Ret == 108) #L: Lock/Unlock
                        printf("  Which resonance to lock/unlock?\n");
                        fflush(stdout);
                        [x, y, n] = ginput(1);
                        n -= 47; #47: 0
                        if(n < 1 || n > N)
                                printf("  Invalid resonance index.\n");
                                fflush(stdout);
                                break;
                        end
                        EpR_LockStat(n) = !EpR_LockStat(n);
                        printf("  Resonance %d lock stat: %d\n", ...
                            n - 1, EpR_LockStat(n));
                        fflush(stdout);
                else
                        break;
                end
        end
        
        #Dump back from manual adjustment.
        EpR_N(c) = N;
        EpR_Freq(c, : ) = Plugin_Var_EpR_Freq;
        EpR_BandWidth(c, : ) = Plugin_Var_EpR_BandWidth;
        EpR_Amp(c, : ) = Plugin_Var_EpR_Amp;
        EpR_ANT1(c, : ) = Plugin_Var_EpR_ANT1;
        EpR_ANT2(c, : ) = Plugin_Var_EpR_ANT2;

        end
        
        save(strcat("Data/", Name, ".vepr"), ...
            "EpR_N", ...
            "EpR_Freq", ...
            "EpR_BandWidth", ...
            "EpR_Amp", ...
            "EpR_ANT1", ...
            "EpR_ANT2");
end

function PlotEpR(Envelope, Estimate, Diff, LnSlope, Freq, Amp, N)
        global FFTSize;
        plot((Envelope - LnSlope)(1 : 300), "k");
        hold on
        plot((Estimate - log(4 / FFTSize))(1 : 300), "b");
        plot(Diff(1 : 300), "g");
        plot(0 * (1 : 300), "k");
        hold off
        axis([1, 300, - 5, 5]);
        for n = 1 : N
                ResLabel(Freq(n), Amp(n) / 20 * log(10), "F", n, 0.1);
        end
end

function Ret = Prompt(Progress)
        printf("Processing at %d%%\n", Progress);
        printf("  (M) Manual adjustment.\n");
        printf("  (L) Lock/Unlock resonance.\n");
        printf("Press any key else to continue...\n");
        fflush(stdout);
        [x, y, Ret] = ginput(1);
end

