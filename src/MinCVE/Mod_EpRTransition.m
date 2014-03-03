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

load Data/i1.xepr;
A_VFreq = EpR_Freq;
A_VBwth = EpR_BandWidth;
A_VAmpl = EpR_Amp;
A_VANT1 = EpR_ANT1;
A_VANT2 = EpR_ANT2;

Slope = - 0.1 * (1 : FFTSize / 2);
Slope = DecibelToIFFTLn(Slope);

#Variative EpR
load Data/a1.xepr;
B_VFreq = EpR_Freq;
B_VBwth = EpR_BandWidth;
B_VAmpl = EpR_Amp;
B_VANT1 = EpR_ANT1;
B_VANT2 = EpR_ANT2;

N = 5;

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
                       (1 : FFTSize / 2) - Slope;
        RSpectrum = EnvelopeInterpolate(CVDB_Residual2(iResidual, : ),
                                            FFTSize / 2, 8)(1 : FFTSize / 2);
        
        #Pitch shifting
        XPeak *= 1;
        
        #Variative EpR & Formant parameter mixing
        [A_Freq, A_Bwth, A_Ampl, A_ANT1, A_ANT2] = ...
            EpRIndexer(A_VFreq, A_VBwth, A_VAmpl, A_VANT1, A_VANT2, i);
        [B_Freq, B_Bwth, B_Ampl, B_ANT1, B_ANT2] = ...
            EpRIndexer(B_VFreq, B_VBwth, B_VAmpl, B_VANT1, B_VANT2, ...
                i / RowNum * 4 * rows(B_VFreq));
        
        D_Freq = B_Freq - A_Freq;
        D_Bwth = B_Bwth - A_Bwth;
        D_Ampl = B_Ampl - A_Ampl;
        
        R = i / RowNum;
        Freq = A_Freq + D_Freq * R;
        Bwth = A_Bwth + D_Bwth * R;
        Ampl = A_Ampl + D_Ampl * R;
        ANT1 = ANTTransition(A_ANT1, B_ANT1, R);
        ANT2 = ANTTransition(A_ANT2, B_ANT2, R);
        
        #(Anti)Resonance reconstruction of original envelope.
        OrigEnv = EpR_CumulateResonance(A_Freq, A_Bwth, 
                                        10 .^ (A_Ampl / 20), N);
        OrigResEnv = log(OrigEnv);
        OrigEnv .*= GenANTFilter(OrigEnv, A_ANT1, A_ANT2);
        OrigEnv = log(OrigEnv);

        #(Anti)Resonance reconstruction of new envelope.
        NewEnv = EpR_CumulateResonance(Freq, Bwth, 10 .^ (Ampl / 20), N);
        NewResEnv = log(NewEnv);
        NewEnv .*= GenANTFilter(NewEnv, ANT1, ANT2);
        NewEnv = log(NewEnv);
        
        if(ShowPlot)
        #plot(OrigEnv(1 : 300), 'b');
        #hold on
        #plot(Spectrum(1 : 300), 'b');
        end
        
        #Residual envelope
        HRes = Spectrum - OrigEnv;
        RRes = RSpectrum - OrigResEnv;
        
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
        #HNegativeRes = min(HRes, 0);
        HAbsRes = abs(HRes);
        
        HRes = MapStretch(HRes, Anchor1, Anchor2);
        RRes = MapStretch(RRes, Anchor1, Anchor2);
        
        HRes = min(HAbsRes, HRes);
        HRes = max(- HAbsRes, HRes);
        
        #HRes *= (1 - R);
        
        #Adding resonance envelope
        Spectrum  = HRes + NewEnv;
        RSpectrum = RRes + NewResEnv;
        
        if(ShowPlot)
        plot(Spectrum(1 : 300), 'k'); hold on;
        plot(NewEnv(1 : 300), 'k');
        plot(HRes(1 : 300), 'g');
        
        axis([1, 300, - 5, 5]);
        hold off
        text(0, - 4.5, strcat("Progress: ", mat2str(R * 100), "%"));
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

