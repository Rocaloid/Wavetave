# ResLabel.m
#   Label the frequency of each resonances.

function ResLabel(Freq, Amp, Type, Num, Dist = 2)
        global SampleRate;
        global FFTSize;
        
        text(Freq / SampleRate * FFTSize, Amp,
            cstrcat("X ", mat2str(fix(Freq)), "Hz"));
        text(Freq / SampleRate * FFTSize, Amp + Dist,
            cstrcat(Type, mat2str(Num - 1)));
end
