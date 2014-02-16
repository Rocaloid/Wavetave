#  Mod_EpRTransition.m
#    Formant transition based on EpR Voice Model.
#
#  Reference
#    Bonada, Jordi, et al. "Singing voice synthesis combining excitation plus
#    resonance and sinusoidal plus residual models." Proceedings of
#    International Computer Music Conference. 2001.

CVDB_Pulses2 = CVDB_Pulses;
for i = 2 : length(CVDB_Pulses)
        #Skip consonant part
        if(CVDB_Pulses2(i) < CVDB_VOTIndex - 2)
                continue;
        end
        #Pulse Contraction / Expansion
        CVDB_Pulses(i) = CVDB_Pulses(i - 1) + fix(...
                             (CVDB_Pulses2(i) - CVDB_Pulses2(i - 1)) / 1);
end

#Loading
load i_noslope.epr;
A_Freq = Freq;
A_BandWidth = BandWidth;
A_Amp = Amp;

load a_noslope.epr;
B_Freq = Freq;
B_BandWidth = BandWidth;
B_Amp = Amp;

D_Freq = B_Freq - A_Freq;
D_BandWidth = B_BandWidth - A_BandWidth;
D_Amp = B_Amp - A_Amp;

Slope = ExpDecay(DecibelToIFFTLn(25),
                 DecibelToIFFTLn(90),
                 - 1, FFTSize / 2);
OrigEnv = EpR_CumulateResonance(A_Freq, A_BandWidth, 10 .^ (A_Amp / 20), N);
OrigEnv = log(OrigEnv) + log(4 / FFTSize);

RowNum = rows(CVDB_Sinusoid_Magn);

#Create copy
CVDB_Residual2 = CVDB_Residual;

for i = 1 : RowNum
        iResidual = fix(i / 2 + 1);
        #Avoid overflow.
        if(iResidual > rows(CVDB_Residual))
                iResidual = rows(CVDB_Residual);
        end

        #Envelope generation
        XPeak = CVDB_Sinusoid_Freq(i, : ) / SampleRate * FFTSize;
        YPeak = CVDB_Sinusoid_Magn(i, : );
        Spectrum = PeakInterpolate(XPeak, YPeak, FFTSize, - 20) ...
                       (1 : FFTSize / 2);
        RSpectrum = EnvelopeInterpolate(CVDB_Residual2(iResidual, : ),
                                            FFTSize / 2, 8)(1 : FFTSize / 2);

        #Pitch shifting
        #XPeak *= 1;

        #Formant parameter mixing
        R = i / RowNum;
        Freq = A_Freq + D_Freq * R;
        BandWidth = A_BandWidth + D_BandWidth * R;
        Amp = A_Amp + D_Amp * R;

        #Generate new envelope
        NewEnv = EpR_CumulateResonance(Freq, BandWidth, 10 .^ (Amp / 20), N);
        NewEnv = log(NewEnv) + log(4 / FFTSize);

        #plot(OrigEnv(1 : 300));
        #hold on
        #plot(RSpectrum);
        #axis([1, 300, - 13, 5]);
        #hold off
        #sleep(0.1);

        #Residual envelope
        Spectrum = Spectrum - OrigEnv;
        RSpectrum = RSpectrum - OrigEnv;

        #Adding resonance envelope
        Spectrum += NewEnv;
        RSpectrum += NewEnv;
        
        #Envelope maintaining
        for j = 1 : length(YPeak)
                if(XPeak(j) < 5)
                        break;
                end
                YPeak(j) = Spectrum(max(fix(XPeak(j)), 1));
        end

        #Dump back
        CVDB_Sinusoid_Freq(i, : ) = XPeak / FFTSize * SampleRate;
        CVDB_Sinusoid_Magn(i, : ) = YPeak;
        CVDB_Residual(iResidual, : ) = SpectralEnvelope(RSpectrum, 8);
end

