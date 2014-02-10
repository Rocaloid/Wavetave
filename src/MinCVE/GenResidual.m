#  GenResidual.m
#    Generates residual spectrum from residual peak envelope.
#  Depends on Oct/FFTReflect.

function Ret = GenResidual(PeakEnvelope, Interval, FFTSize)
        Envelope = EnvelopeInterpolate(PeakEnvelope, FFTSize / 2, Interval);
        
        #Unlog
        Envelope = exp(Envelope);
        
        #Random Spectrum
        Amp = rand(1, FFTSize / 2) .* Envelope;
        Phi = rand(1, FFTSize / 2) * pi * 2 - pi;
        
        Spectrum = Amp .* exp(complex(0, Phi));
        Ret = FFTReflect(Spectrum, FFTSize);
end

