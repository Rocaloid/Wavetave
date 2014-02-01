#  Plugin_VOTMarking.m
#    Finds and marks the Voice Onset Time of the signals in visible area.
#
#  The Algorithm
#    256-point FFTs are taken through the observe window at a HopSize of 256
#      samples.
#    Take the maximum of low frequency area of decibel magnitude spectrum, we
#      find that in voiced parts the maximum almost always exceed 0db.
#    The longest stroke which keeps the maximum above 0db will be identified as
#      the voiced part of the vocal signal. The start of the stroke is then
#      identified as VOT.

function Plugin_VOTMarking(Wave)
        global Length;
        global SampleRate;
        global Environment;
        global Plugin_Var_VOT;
        #Initialization; notice FFTSize is not working as a global variable.
        FFTSize = 256;
        PartLength = length(Wave);
        VOTWave = zeros(1, PartLength);
        MaxEnv = zeros(1, PartLength);
        LMax = 0;
        if(strcmp(Environment, "Visual"))
                hold on;
        endif

        HoldStart = 0;
        MaxHold = 0;
        MaxStart = 0;
        Holding = 0;
        c = 0;
        #Scan through the wave
        for i = 1 : FFTSize : PartLength - FFTSize
                c ++;
                #Generate decibel magnitude spectrums and find the maximum.
                Amp = 20 * log10(abs(fft(Wave(i : i + FFTSize - 1))));
                Max = max(Amp(fix(300 * FFTSize / SampleRate) : ...
                              fix(1500 * FFTSize / SampleRate)));
                #Connect the dots in Visual mode.
                if(strcmp(Environment, "Visual"))
                        for j = 0 : FFTSize - 1
                                VOTWave(i + j) = (LMax * (1 - j / FFTSize) ...
                                               + Max * j / FFTSize) * 0.01;
                        end
                end
                LMax = Max;
                MaxEnv(c) = Max;
                #If no stroke exist currently
                if(Holding == 0)
                        if(Max > 0)
                                #Start a stroke if exceeds the threshold.
                                Holding = 1;
                                HoldStart = c;
                        end
                else
                        #Avoid shaking trend line that causes false detection.
                        if(c > 2)
                                if(Max < 0 ||
                                   Max < MaxEnv(c - 2) * 0.5 ||
                                   Max < MaxEnv(c - 1) * 0.6)
                                        Holding = 0;
                                end
                        end
                        #Mark the longest stroke as the voiced part.
                        if(c - HoldStart > MaxHold)
                                MaxHold = c - HoldStart;
                                MaxStart = HoldStart;
                                #Mark the long enough stroke as the voiced part.
                                if(c - HoldStart > 8)
                                        break;
                                end
                        end
                end
        end
        Plugin_Var_VOT = MaxStart * FFTSize;
        #Plot the trend line and labels out VOT.
        if(strcmp(Environment, "Visual"))
                plot(VOTWave);
                text(MaxStart * FFTSize, VOTWave(MaxStart * FFTSize + 1),
                     "x VOT");
                hold off;
        end
end

