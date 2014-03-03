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

load Data/e1_preemph.epr;
A_Freq = Freq;
A_BandWidth = BandWidth;
A_Amp = Amp;

A_ANT1.Freq = (A_Freq(1) + A_Freq(2)) / 2;
A_ANT2.Freq = (A_Freq(2) + A_Freq(3)) / 2;
A_ANT1.Amp = 0;
A_ANT2.Amp = 0;
A_ANT1.BandWidth = 0;
A_ANT2.BandWidth = 0;
#A_ANT1 = ANT1;
#A_ANT2 = ANT2;
#A_ANT1.Amp = ANT1.Amp / 20 * log(10);
#A_ANT2.Amp = ANT2.Amp / 20 * log(10);

load Data/_en0_preemph.epr;
B_Freq = Freq;
B_BandWidth = BandWidth;
B_Amp = Amp;
B_ANT1 = ANT1;
B_ANT2 = ANT2;
#B_ANT1.Freq = (B_Freq(1) + B_Freq(2)) / 2;
#B_ANT2.Freq = (B_Freq(2) + B_Freq(3)) / 2;
#B_ANT1.Amp = 0;
#B_ANT2.Amp = 0;
#B_ANT1.BandWidth = 0;
#B_ANT2.BandWidth = 0;
B_ANT1.Amp = B_ANT1.Amp / 20 * log(10);
B_ANT2.Amp = B_ANT2.Amp / 20 * log(10);

Slope = Coef(2) + (1 : FFTSize / 2) * Coef(1);
Slope = DecibelToIFFTLn(Slope);

#Variative EpR
load Data/e1.vepr;

#OrigEnv = EpR_CumulateResonance(A_Freq, A_BandWidth, 10 .^ (A_Amp / 20), N);
#OrigEnv = log(OrigEnv);

RowNum = rows(CVDB_Sinusoid_Magn);

#Create copy
CVDB_Residual2 = CVDB_Residual;

for i = 1 : RowNum
        iResidual = fix(i / 2 + 1);
        #Avoid overflow.
        if(iResidual > rows(CVDB_Residual))
                iResidual = rows(CVDB_Residual);
        end
        
        #Variative EpR
        [A_Freq, A_BandWidth, A_Amp] = ...
            EpRIndexer(EpR_Freq, EpR_BandWidth, EpR_Amp, i);
        
        D_Freq = B_Freq - A_Freq;
        D_BandWidth = B_BandWidth - A_BandWidth;
        D_Amp = B_Amp - A_Amp;
        
        OrigEnv = EpR_CumulateResonance(A_Freq, A_BandWidth, 
                                        10 .^ (A_Amp / 20), N);
        
        #Anti-resonance reconstruction.
        ANT1 = A_ANT1;
        ANT2 = A_ANT2;
        OrigEnv .*= GenANTFilter(OrigEnv, ANT1, ANT2);
        OrigEnv = log(OrigEnv);

        #Envelope generation
        XPeak = CVDB_Sinusoid_Freq(i, : ) / SampleRate * FFTSize;
        YPeak = CVDB_Sinusoid_Magn(i, : );
        Spectrum = PeakInterpolate(XPeak, YPeak, FFTSize, - 20) ...
                       (1 : FFTSize / 2) - Slope;
        RSpectrum = EnvelopeInterpolate(CVDB_Residual2(iResidual, : ),
                                            FFTSize / 2, 8)(1 : FFTSize / 2);

        #Pitch shifting
        XPeak *= 1;

        #Formant parameter mixing
        R = i / RowNum;
        Freq = A_Freq + D_Freq * R;
        BandWidth = A_BandWidth + D_BandWidth * R;
        Amp = A_Amp + D_Amp * R;
        ANT1 = ANTTransition(A_ANT1, B_ANT1, R);
        ANT2 = ANTTransition(A_ANT2, B_ANT2, R);

        #Generate new envelope
        NewEnv = EpR_CumulateResonance(Freq, BandWidth, 10 .^ (Amp / 20), N);
        
        #Anti-resonance reconstruction.
        NewEnv .*= GenANTFilter(NewEnv, ANT1, ANT2);
        NewEnv = log(NewEnv);
        
        if(0)
        plot(OrigEnv(1 : 300), 'b');
        hold on
        plot(Spectrum(1 : 300), 'b');
        end
        
        #Residual envelope
        HRes = Spectrum - OrigEnv;
        RRes = RSpectrum - OrigEnv;
        
        #Compress & Stretch Residual envelope
        Anchor1 = [1, A_Freq, A_Freq(N) + 300, SampleRate / 2];
        Anchor2 = [1, Freq  , Freq(N) + 300  , SampleRate / 2];
        Anchor1 *= FFTSize / SampleRate;
        Anchor2 *= FFTSize / SampleRate;
        
        #Error gain limitation.
        #HDif = NewEnv - OrigEnv;
        #HPositiveRes = max(HRes, 0);
        #HDif = max(0, min(HDif, HPositiveRes));
        #HRes -= HDif;
        
        HRes = MapStretch(HRes, Anchor1, Anchor2);
        RRes = MapStretch(RRes, Anchor1, Anchor2);
        
        #HRes *= (1 - R);
        
        #Adding resonance envelope
        Spectrum  = HRes + NewEnv;
        RSpectrum = RRes + NewEnv;
        
        if(0)
        plot(Spectrum(1 : 300), 'k');
        plot(NewEnv(1 : 300), 'k');
        plot(HRes(1 : 300), 'g');
        
        axis([1, 300, - 5, 5]);
        hold off
        sleep(0.1);
        end
        
        Spectrum += Slope;
        
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

