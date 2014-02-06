#  GetExactPeak.m
#    Estimate frequency and magnitude of a spectral peak by quadratic
#      interpolating on logarithmic magnitude spectrum.

function [RetFreq, RetAmp] = GetExactPeak(Spectrum, Center)
        global SampleRate;
        global FFTSize;
        a = Spectrum(Center - 1);
        b = Spectrum(Center);
        c = Spectrum(Center + 1);
        a1 = (a + c) / 2 - b;
        a2 = c - b - a1;
        RetBin = - a2 / a1 * 0.5;
        RetFreq = (RetBin + Center - 1) * SampleRate / FFTSize;
        RetAmp = a1 * RetBin ^ 2 + a2 * RetBin + b;
        if(RetAmp > b * 1.2)
                RetAmp = b * 1.2;
        end
        #RetAmp = b;
end

