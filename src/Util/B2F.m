#  B2F.m
#    Bin-Index to frequency.

function Ret = B2F(Freq)
        global FFTSize;
        global SampleRate;
        Ret = Freq / FFTSize * SampleRate;
end

