#  DecibelToIFFTLn.m
#    From Decibel to Ln at corresponding time domain sinusoidal magnitude.
#    (for hanning window)
#  x = e ^ ln(x)
#  20 * log10(x) = 20 * ln(x) / ln(10)
#  20 * log10(x) = 20 * ln(e ^ lnx) / ln(10)
#  dB = lnx / ln(10) * 20
#  lnx = dB / 20 * ln(10)

function Ret = DecibelToIFFTLn(DB)
        global FFTSize;
        Ret = DB / 20 * log(10) + log(4 / FFTSize);
end

