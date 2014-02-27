#  F2B.m
#    Frequency to Bin-Index.

function Ret = F2B(Freq)
        global FFTSize;
        global SampleRate;
        Ret = Freq * FFTSize / SampleRate;
end
