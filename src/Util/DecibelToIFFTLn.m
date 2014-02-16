#  DecibelToIFFTLn.m
#    From Decibel to Ln at corresponding time domain sinusoidal magnitude.
#    (for hanning window)

function Ret = DecibelToIFFTLn(DB)
        global FFTSize;
        Ret = DB / 20 * log(10) + log(4 / FFTSize);
end

