#  GenerateSpectrum.m
#    Calulates the decibel magnitude and phase spectrum from time domain
#    signals.

function [Ret, RetPhase] = GenerateSpectrum(Wave)
        global FFTSize;
        global Window;
        X = fft(fftshift(Wave .* Window));
        Ret = abs(X)(1 : FFTSize / 2);
        Ret = log10(Ret + 0.000001) * 20;
        RetPhase = arg(X);
end

