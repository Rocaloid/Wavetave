#  Plugin_Load_PulseMarking_Naive.m
#    Marks the estimated glottal pulses of voice signal in the visible area by
#      finding maximum and minimum within certain range.
#    The result is stored in global variable Plugin_Var_Pulses.
#  Depends on Plugin_VOTMarking, Plugin_F0Marking and Util/GetPeriodAt.m.

function Plugin_Load_PulseMarking_Naive(Wave)
        global Environment;
        global Plugin_Var_VOT;
        global Plugin_Var_Pulses;
        global Plugin_Var_F0;
        global FFTSize;
        global SampleRate;
        global Window;
        
        addpath("Util");

        #Disable plotting.
        Plugin_Var_Pulses = zeros(1, 1000);
        Environment_ = Environment;
        Environment = "Procedure";

        #Get Voice Onset Time.
        Plugin_VOTMarking(Wave);
        Length = length(Wave);

        Magn = abs(Wave);
        Wind(1 : 100, 1) = 1;

        #Initial Peak
        Period = GetPeriodAt(Wave, Plugin_Var_VOT + 2048);
        [Y, InitX] = MaxCenteredAt(Magn, Plugin_Var_VOT + 2048, Period);
        if(Wave(InitX) > 0)
                Magn = Wave + 1;
        else
                Magn = - Wave + 1;
        end
        CurrentPos = InitX;
        InitPeriod = Period;
        X = InitX;

        c = 1;
        #Backward
        while(CurrentPos > Plugin_Var_VOT)
                #Remeausre
                #Period_ = MarkPeriodAt(Wave, CurrentPos);
                Period_ = CurrentPos - X;
                if(abs(Period - Period_) < 50)
                        Period = Period_;
                end
                #Find previous peak
                [Y, X] = MaxCenteredAt_Window(Magn, Wind, CurrentPos - Period);
                CurrentPos = X;
                Plugin_Var_Pulses(c) = X;
                c ++;
        end

        Plugin_Var_Pulses(c) = InitX;
        c ++;
        #Forward
        CurrentPos = InitX;
        Period = InitPeriod;
        while(CurrentPos < Length - FFTSize * 2)
                #Remeausre
                #Period_ = MarkPeriodAt(Wave, CurrentPos);
                Period_ = X - CurrentPos;
                if(abs(Period - Period_) < 50)
                        Period = Period_;
                end
                #Find previous peak
                [Y, X] = MaxCenteredAt_Window(Magn, Wind, CurrentPos + Period);
                CurrentPos = X;
                Plugin_Var_Pulses(c) = X;
                c ++;
        end

        Plugin_Var_Pulses = Plugin_Var_Pulses(1 : c - 1);

        Environment = Environment_;
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

