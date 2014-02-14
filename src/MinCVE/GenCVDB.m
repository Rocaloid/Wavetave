#  GenCVDB.m
#    DataBase content generator.
#  Depends on various Plugins and Octs.

function Ret = GenCVDB(Path, Name)
        addpath("../");
        addpath("../Oct");
        addpath("../Util");

        global FFTSize;
        global SampleRate;
        global Window;
        global Environment;
        global OrigWave;
        global Length;

        global Plugin_Var_VOT;

        HopSize = 256;
        FFTSize = 2048;
        Environment = "Procedure";
        WindowFunc = @hanning;
        
        Window = WindowFunc(FFTSize);
        [OrigWave, SampleRate] = wavread(Path);
        
        #Cut off unvoiced part.
        global Plugin_Var_Unvoiced;
        Plugin_UnvoicedDetection(OrigWave);
        Plugin_Var_Unvoiced = Plugin_Var_Unvoiced - HopSize;
        OrigWave = OrigWave(Plugin_Var_Unvoiced : length(OrigWave));
        Length = length(OrigWave);

        #Find VOT.
        Plugin_VOTMarking(OrigWave);
        
        #Find pulses for PSOLA manipulation.
        global Plugin_Var_Pulses;
        Plugin_Load_PulseMarking_Stable(OrigWave, Plugin_Var_VOT + 2048,
                                        FFTSize * 5);
        #Sort by increasing trend.
        Plugin_Var_Pulses = sort(Plugin_Var_Pulses);
        #Extending pulses backward.
        l = Plugin_Var_Pulses(2) - Plugin_Var_Pulses(1);
        p = Plugin_Var_Pulses(1) - l;
        c = 0;
        FrontPulses = 0;
        while p > HopSize
                c ++;
                FrontPulses(c) = p;
                p -= l;
        end
        Plugin_Var_Pulses = cat(2, flipdim(FrontPulses), Plugin_Var_Pulses);
        
        #Find standard F0.
        c = 1;
        for i = Plugin_Var_VOT + 2048 : FFTSize : Length - FFTSize * 2
                F0Trials(c) = GetF0At(OrigWave, i);
                #Neglect irregular detections.
                if(F0Trials(c) > 70)
                        c ++;
                end
        end
        #Median
        F0Trials = sort(F0Trials);
        StandardF0 = F0Trials(fix(length(F0Trials) / 2));
        F0LowRange = StandardF0 - SampleRate / FFTSize * 2;
        F0HighRange = StandardF0 + SampleRate / FFTSize * 2;
        
        c = 1;
        global Plugin_Var_F0_Exact;
        global Plugin_Var_F0;
        global SpectrumUpperRange;
        SpectrumUpperRange = 10000;
        global Plugin_Var_Harmonics_Freq;
        global Plugin_Var_Harmonics_Magn;
        
        F0 = StandardF0;
        #SMS Analysis
        for i = Plugin_Var_VOT + HopSize * 5 : HopSize : Length - FFTSize * 2
                CVDB_FramePosition(c) = i;
                
                #Cut & Window
                Wide = OrigWave(i - FFTSize / 2 : ...
                                i + FFTSize / 2 + 99);
                Selection = Wide(1 : FFTSize) .* Window;
                
                #Transform
                X = fft(fftshift(Selection));
                Amp = 20 * log10(abs(X));
                Arg = arg(X);
                
                #Ensure F0 is accurate.
                Plugin_F0Marking_ByPhase(Amp, Arg, Selection, Wide);
                if(Plugin_Var_F0_Exact > F0LowRange &&
                   Plugin_Var_F0_Exact < F0HighRange)
                        F0 = Plugin_Var_F0_Exact;
                end
                CVDB_PitchCurve(c) = F0;
                
                #Mark harmonics.
                Plugin_Var_F0_Exact = F0;
                Plugin_HarmonicMarking_Naive(Amp, Arg, Selection);
                for j = 1 : length(Plugin_Var_Harmonics_Magn)
                        #Decibel to logarithmic sinusoidal magnitude.
                        [Freq, Magn] = GetExactPeak(Amp, ...
                                       Plugin_Var_Harmonics_Freq(j));
                        CVDB_Sinusoid_Magn(c, j) = log(...
                                10 ^ (Magn / 20) ...
                                   / FFTSize * 4);
                        CVDB_Sinusoid_Freq(c, j) = Freq;
                end
                
                #Store residual every 2 hops for data compression.
                if(mod(c, 2) == 0)
                
                #Spectral subtraction.
                Resynth = SinusoidalFrameSynth(CVDB_Sinusoid_Freq(c, : ), ...
                                               CVDB_Sinusoid_Magn(c, : ), ...
                                               FFTSize)';
                ResynthX = abs(fft(fftshift(Resynth .* Window)));
                ResidualX = log(max(0, abs(X) - ResynthX));
                
                #Extract residual max heights.
                CVDB_Residual(c / 2, : ) = SpectralEnvelope( ...
                                               ResidualX(1 : FFTSize / 2), 8);
                Regenerate = EnvelopeInterpolate(CVDB_Residual(c / 2, : ),
                                                 FFTSize / 2, 8);
                
                if(0) #Plot Switch
                plot(log(abs(X)), "color", "red", "linewidth", 2);
	        hold on
                #plot(log(ResynthX), "color", "blue");
                plot(max(- 6, log(ResynthX)), ...
                              "color", "green", "linewidth", 2);
                #plot(CVDB_Residual(c, : ));
                plot(Regenerate - 0.3);
	        axis([1, 600, - 6, 4]);
	        hold off
                sleep(1);
                end
                
                fflush(stdout);
                
                end
                
                c ++;
        end
        
        CVDB_Residual = int8(12 * CVDB_Residual + 60);
        CVDB_Sinusoid_Magn = int16(1000 * CVDB_Sinusoid_Magn);
        CVDB_Sinusoid_Freq = uint16(6 * CVDB_Sinusoid_Freq);
        CVDB_Wave = int16(OrigWave(1 : Plugin_Var_VOT + FFTSize * 2) * 32767);
        
        CVDB_Length = Length;
        CVDB_VOT = Plugin_Var_VOT;
        CVDB_Pulses = Plugin_Var_Pulses;
        CVDB_VOTIndex = length(FrontPulses);
        
        #Pre-Compression disabled.
        
        #First compression
        #CVDB_Sinusoid_Magn_Diff = Difference2D(CVDB_Sinusoid_Magn);
        #CVDB_Sinusoid_Freq_Diff = Difference2D(CVDB_Sinusoid_Freq);
        #CVDB_Residual_Diff = Difference2D(CVDB_Residual);
        #CVDB_Wave_Diff = Difference1D(CVDB_Wave);
        #CVDB_Pulses_Diff = Difference1D(CVDB_Pulses);
        #CVDB_FramePosition_Diff = Difference1D(CVDB_FramePosition);
        
        #Double compression
        #CVDB_Wave_Diff = Difference1D(CVDB_Wave_Diff);
        #CVDB_Sinusoid_Magn_Diff = Difference2D(CVDB_Sinusoid_Magn_Diff);
        #CVDB_Sinusoid_Freq_Diff = Difference2D(CVDB_Sinusoid_Freq_Diff);
        #CVDB_Pulses_Diff = Difference1D(CVDB_Pulses_Diff);
        
        #Save.
        save(cstrcat(Name, ".cvdb"), "-float-binary", #"-z", ...
                "CVDB_Length", ...
                "CVDB_VOT", ...
                "CVDB_VOTIndex", ...
                "CVDB_FramePosition", ...
                "CVDB_Wave", ...
                "CVDB_Sinusoid_Freq", ...
                "CVDB_Sinusoid_Magn", ...
                "CVDB_Residual", ...
                "CVDB_Pulses")
end

function Ret = Difference1D(Array)
        Ret(1) = Array(1);
        for i = 2 : length(Array)
                Ret(i) = Array(i) - Array(i - 1);
        end
end

function Ret = Difference2D(Array)
        Ret(1, : ) = Array(1, : );
        for i = 2 : length(Array(: , 1))
                Ret(i, : ) = Array(i, : ) - Array(i - 1, : );
        end
end

