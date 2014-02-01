#  Plugin_Load_PulseMarking_Stable.m
#    Marks the estimated glottal pulses of voice signal in the visible area by
#      finding maximum and minimum, then using autocorrelation to locate
#      similar pulses across periods.
#    Plugin_Load_PulseMarking_Stable is optimized for maximum stability and is
#      more robust than Plugin_Load_PulseMarking and Plugin_PulseMarking_Naive.
#    Suitable for PSOLA.
#    The result is stored in global variable Plugin_Var_Pulses.
#  Depends on Plugin_VOTMarking, Plugin_F0Marking, STFTAnalysis and
#    STFTSynthesis.

function Plugin_Load_PulseMarking_Stable(Wave)
        global Environment;
        global Plugin_Var_VOT;
        global Plugin_Var_Pulses;
        global Plugin_Var_F0;
        global FFTSize;
        global SampleRate;
        global Window;

        addpath('Oct');
        
        #Disable plotting.
        Plugin_Var_Pulses = zeros(1, 1000);
        Environment_ = Environment;
        Environment = "Procedure";

        #Get Voice Onset Time.
        Plugin_VOTMarking(Wave);
        Length = length(Wave);
        
        #Find determining harmonic index.
        WavePart = Wave(Plugin_Var_VOT + 2048 : ...
                   Plugin_Var_VOT + 2047 + FFTSize) .* Window;
        Amp = 20 * log10(abs(fft(WavePart)));
        MaxAmp = max(Amp);
        #Search from right to left.
        for i = 1 : FFTSize / 2
                if(Amp(FFTSize / 2 - i) > MaxAmp - 10)
                        break;
                end
        end
        i = FFTSize / 2 - i;
        Plugin_F0Marking(Amp);
        LPF = fix(i / Plugin_Var_F0 + 1) * Plugin_Var_F0;
        
        #Low pass the wave to make it smooth and more suitable for analysis.
        Frames = STFTAnalysis(Wave, Window, FFTSize, 256);
        Frames(:, LPF : FFTSize / 2) = 0;
        LWave = STFTSynthesis(Frames, Window, FFTSize, 256);
        
        #Initial peak finding
        

        #Magn = abs(Wave);
        #Wind(1 : 100, 1) = 1;

        #Initial Peak
        #Period = MarkPeriodAt(Wave, Plugin_Var_VOT + 2048);
        #[Y, InitX] = MaxCenteredAt(Magn, Plugin_Var_VOT + 2048, Period);
        #if(Wave(InitX) > 0)
        #        Magn = Wave + 1;
        #else
        #        Magn = - Wave + 1;
        #end
        #CurrentPos = InitX;
        #InitPeriod = Period;
        #X = InitX;

        c = 1;
        #Backward
        #while(CurrentPos > Plugin_Var_VOT)
                #Remeausre
                #Period_ = MarkPeriodAt(Wave, CurrentPos);
        #        Period_ = CurrentPos - X;
        #        if(abs(Period - Period_) < 50)
        #                Period = Period_;
        #        end
                #Find previous peak
        #        [Y, X] = MaxCenteredAt_Window(Magn, Wind, CurrentPos - Period);
        #        CurrentPos = X;
        #        Plugin_Var_Pulses(c) = X;
        #        c ++;
        #end

        #Plugin_Var_Pulses(c) = InitX;
        #c ++;
        #Forward
        #CurrentPos = InitX;
        #Period = InitPeriod;
        #while(CurrentPos < Length - FFTSize * 2)
                #Remeausre
                #Period_ = MarkPeriodAt(Wave, CurrentPos);
        #        Period_ = X - CurrentPos;
        #        if(abs(Period - Period_) < 50)
        #                Period = Period_;
        #        end
                #Find previous peak
        #        [Y, X] = MaxCenteredAt_Window(Magn, Wind, CurrentPos + Period);
        #        CurrentPos = X;
        #        Plugin_Var_Pulses(c) = X;
        #        c ++;
        #end

        Plugin_Var_Pulses = Plugin_Var_Pulses(1 : c - 1);

        Environment = Environment_;
end

function Ret = MarkPeriodAt(Wave, Center)
        global FFTSize;
        global SampleRate;
        global Window;
        global Plugin_Var_F0;
        Part = Wave(Center - FFTSize / 2 : ...
                    Center + FFTSize / 2 - 1);
        X = fft(Part .* Window);
        Plugin_F0Marking(20 * log10(abs(X)));
        Ret = fix(FFTSize / Plugin_Var_F0);
end

function [Y, X] = MaxCenteredAt(Wave, Center, Width)
        [Y, X] = max(Wave(Center - Width : Center + Width));
        X += Center - Width;
end

function [Y, X] = MaxCenteredAt_Window(Wave, Window, Center)
        Width = fix(length(Window) / 2);
        [Y, X] = max(Wave(Center - Width : Center + Width - 1) .* Window);
        X += Center - Width;
end

