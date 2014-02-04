#  Plugin_Load_PulseMarking_Stable.m
#    Marks the estimated glottal pulses of voice signal in the visible area by
#      finding maximum and minimum, then using autocorrelation to locate
#      similar pulses across periods.
#    Plugin_Load_PulseMarking_Stable is optimized for maximum stability and is
#      more robust than Plugin_Load_PulseMarking and Plugin_PulseMarking_Naive.
#    Suitable for PSOLA.
#    The result is stored in global variable Plugin_Var_Pulses.
#  Depends on Plugin_VOTMarking, Plugin_F0Marking, STFTAnalysis, STFTSynthesis
#    and MaxCorrelation.

function Plugin_Load_PulseMarking_Stable(Wave, AnalysisCenter = 0, ReferenceLength = 0)
        global Environment;
        global Plugin_Var_VOT;
        global Plugin_Var_Pulses;
        global Plugin_Var_F0;
        global FFTSize;
        global SampleRate;
        global Window;
        
        #Disable plotting.
        Plugin_Var_Pulses = zeros(1, 1000);
        Environment_ = Environment;
        Environment = "Procedure";

        #Get Voice Onset Time.
        Plugin_VOTMarking(Wave);
        Length = length(Wave);
        if(AnalysisCenter == 0)
                AnalysisCenter = fix(Length / 2);
        end
        if(ReferenceLength == 0)
                ReferenceLength = Length;
        end
        
        #Find determining harmonic index.
        WavePart = Wave(Plugin_Var_VOT + AnalysisCenter : ...
                   Plugin_Var_VOT + AnalysisCenter - 1 + FFTSize) .* Window;
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
        
        #Determine whether the most prominent peak is concave or convex.
        CConcave = 0;
        CConvex  = 0;
        for i = Plugin_Var_VOT + 1024 : FFTSize : min(Length - FFTSize,
                Plugin_Var_VOT + ReferenceLength)
                [Y, X] = PeakCenteredAt(Wave, i, ...
                                        fix(FFTSize / Plugin_Var_F0) * 2);
                if(Y > 0)
                        CConvex ++;
                else
                        CConcave ++;
                end
        end
        #Flip the waves if most peaks are concave.
        if(CConcave > CConvex)
                LWave = - LWave;
                Wave  = - Wave;
        end
        #Initial peak finding
        [Y, InitX] = MaxCenteredAt(Wave, AnalysisCenter, ...
                                   fix(FFTSize / Plugin_Var_F0) * 2);
        #Find the corresponding peak in low passed wave.
        [Y, InitX] = MaxCenteredAt(LWave, InitX, 15);
        
        c = 1;
        X = InitX;
        CurrentPos = InitX;
        Period_ = fix(FFTSize / Plugin_Var_F0);
        Period  = fix(FFTSize / Plugin_Var_F0);
        InitPeriod = Period;

        #Backward
        while(CurrentPos > Plugin_Var_VOT)
                if(abs(Period - Period_) < 20)
                        Period = Period_;
                end
                
                #Autocorrelation
                MaxPos = MaxCorrelation(LWave, CurrentPos, Period, - 1.0, 0.5);
                
                #Peak Correction
                [Y, MaxPos] = MaxCenteredAt(LWave, MaxPos, 10);
                Period_ = CurrentPos - MaxPos;
                CurrentPos = MaxPos;
                Plugin_Var_Pulses(c) = CurrentPos;
                c ++;
        end

        Plugin_Var_Pulses(c) = InitX;
        c ++;
        #Forward
        CurrentPos = InitX;
        Period = InitPeriod;
        while(CurrentPos < Length - FFTSize * 2)
                if(abs(Period - Period_) < 20)
                        Period = Period_;
                end
                
                #Autocorrelation
                MaxPos = MaxCorrelation(LWave, CurrentPos, Period, + 1.0, 0.5);
                
                #Peak Correction
                [Y, MaxPos] = MaxCenteredAt(LWave, MaxPos, 10);
                Period_ = MaxPos - CurrentPos;
                CurrentPos = MaxPos;
                Plugin_Var_Pulses(c) = CurrentPos;
                c ++;
        end

        Plugin_Var_Pulses = Plugin_Var_Pulses(1 : c - 1);

        Environment = Environment_;
end

function [Y, X] = PeakCenteredAt(Wave, Center, Width)
        [POSY, POSX] = max(Wave(Center - Width : Center + Width));
        [NEGY, NEGX] = min(Wave(Center - Width : Center + Width));
        if(POSY > - NEGY)
                Y = POSY;
                X = POSX;
        else
                Y = NEGY;
                X = NEGX;
        end
        X += Center - Width;
end

function [Y, X] = MaxCenteredAt(Wave, Center, Width)
        [Y, X] = max(Wave(Center - Width : Center + Width));
        X += Center - Width;
end

