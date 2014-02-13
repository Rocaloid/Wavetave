#  Plugin_Load_PulseMarking.m
#    Marks the estimated glottal pulses of voice signal in the visible area.
#    The result is stored in global variable Plugin_Var_Pulses.
#  Depends on Plugin_VOTMarking and Plugin_F0Marking.
#
#  The Algorithm
#    This function is an improved version of praat's pulse marking algorithm,
#      which simply finds the maximum and minimum sample within each period.
#        static double findExtremum_3 (...)
#    When a change of position of the maximum sample takes place, praat
#      neglects the change to ensure its period intervals to be coherent. Our
#      algorithm performs a transition on the relative pulse position across
#      several periods.
#    This only yields a rough approximation of glottal pulses, and may contain
#      a few error pulses. We're going to use this for turbulent noise
#      reconstruction in Rocaloid's new synthesis engine, which does not
#      require very accurate pulse marking. However, if you are looking for
#      glottal pulse extraction techniques for algorithms such as PSOLA, please
#      refer to praat's method(Plugin_Load_PulseMarking_Stable).

function Plugin_Load_PulseMarking(Wave)
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

        #Start from the VOT, get the initial fundamental frequency.
        CurrentPos = Plugin_Var_VOT;
        Part = Wave(CurrentPos - FFTSize / 2 + 2048 : ...
                    CurrentPos + FFTSize / 2 - 1 + 2048);
        X = fft(Part .* Window);
        Plugin_F0Marking(20 * log10(abs(X)));
        Period = fix(FFTSize / Plugin_Var_F0);

        c = 1;
        #The initial position is the local maximum at VOT.
        _Pos = CurrentPos;
        [Y, CurrentPos] = max(Wave(CurrentPos - fix(Period / 2) : CurrentPos + fix(Period / 2)) - 1);
        CurrentPos += _Pos - fix(Period / 2);
        while (CurrentPos < Length - FFTSize)
                #Estimate the next position.
                Part = Wave(CurrentPos - FFTSize / 2 : CurrentPos + FFTSize / 2 - 1);
                X = fft(Part .* Window);
                Plugin_F0Marking(20 * log10(abs(X)));
                Period_ = fix(FFTSize / Plugin_Var_F0);
                if(abs(Period_ - Period) < 5)
                        Period = Period_;
                end
                EstimatedPos = CurrentPos + Period;

                #Find local maximum near the estimated position within a period's range.
                Part = Wave(EstimatedPos - fix(Period / 2) : EstimatedPos + fix(Period / 2));
                [Y, ConvergePos] = max(abs(Part));
                ConvergePos += EstimatedPos - fix(Period / 2);

                #Converge to the maximum.
                CurrentPos = fix(ConvergePos * 0.7 + EstimatedPos * 0.3);
                Plugin_Var_Pulses(c) = CurrentPos;
                c ++;
        end

        Plugin_Var_Pulses = Plugin_Var_Pulses(1 : c - 1);

        Environment = Environment_;
end

