#  GenCVDB.m
#    DataBase content generator.
#  Depends on various Plugins.
#
#    Not finished yet.

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
        Length = length(OrigWave);

        #Find VOT first.
        Plugin_VOTMarking(OrigWave);
        
        #Find pulses for PSOLA manipulation.
        global Plugin_Var_Pulses;
        Plugin_Load_PulseMarking_Stable(OrigWave, Plugin_Var_VOT + 2048, FFTSize * 5);
        #Sort by increasing trend.
        Plugin_Var_Pulses = sort(Plugin_Var_Pulses);
        
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
        for i = Plugin_Var_VOT : HopSize : Length - FFTSize * 2
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
                        CVDB_Sinusoid_Magn(c, j) = log(...
                                10 ^ (Plugin_Var_Harmonics_Magn(j) / 20) ...
                                   / FFTSize * 4);
                        CVDB_Sinusoid_Freq(c, j) = ...
                                Plugin_Var_Harmonics_Freq(j);
                end
                
                #Spectral subtraction.
                Resynth = SinusoidalFrameSynth(CVDB_Sinusoid_Freq(c, : ), ...
                                               CVDB_Sinusoid_Magn(c, : ), ...
                                               FFTSize)';
                X2 = abs(fft(fftshift(Resynth .* Window)));
                plot(log(abs(X)));
	        axis([1, 400, - 6, 4]);
                sleep(1);
                plot(log(max(0, abs(X)-X2)));
	        axis([1, 400, - 6, 4]);
                sleep(1);
                
                c ++;
        end
        
        #Save.
        CVDB_Wave = OrigWave;
        CVDB_Length = Length;
        CVDB_VOT = Plugin_Var_VOT;
        CVDB_Pulses = Plugin_Var_Pulses;
        save(cstrcat(Name, ".cvdb"), "-float-binary", "-z", ...
                #"CVDB_Wave", ...
                "CVDB_Length", ...
                "CVDB_VOT", ...
                "CVDB_FramePosition", ...
                "CVDB_PitchCurve", ...
                "CVDB_Sinusoid_Freq", ...
                "CVDB_Sinusoid_Magn", ...
                "CVDB_Pulses")
end

