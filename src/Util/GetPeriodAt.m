#  GetPeriodAt.m
#    Period approximation.
#  Depends on Plugin_F0Marking.

function Ret = GetPeriodAt(Wave, Center)
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

