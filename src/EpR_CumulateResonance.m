#  EpR_CumulateResonance.m
#    Generates and accumulates resonances in linear scale for an EpR Model.
#
#  Reference
#    Bonada, Jordi, et al. "Singing voice synthesis combining excitation 
#    plus resonance and sinusoidal plus residual models." Proceedings of
#    International Computer Music Conference. 2001.

#  Freq(Hz), BandWidth(Hz), Amp(Linear), N(Integer)
function Ret = EpR_CumulateResonance(Freq, BandWidth, Amp, N)
        global SampleRate;
        global FFTSize;
        Ret = zeros(1, FFTSize / 2);
        for i = 1 : N
                Ret += KlattFilter(Freq(i), BandWidth(i), Amp(i),
                                   SampleRate, FFTSize);
        end
end

# My improved KlattFilter.
function Ret = DecayFilter(Freq, BandWidth, Amp, Decay, SampleRate, FFTSize)
        Ret = KlattFilter(Freq, BandWidth, Amp, SampleRate, FFTSize);
        Center = fix(Freq / SampleRate * FFTSize) + 1;
        Ret = log(Ret);
        Ret(1 : Center) -= (Center - (1 : Center)) / 50 * Decay;
        Ret(Center : FFTSize / 2) -= ((Center : FFTSize / 2) - Center) ...
                                   / 50 * Decay;
        Ret = e .^ Ret;
end

