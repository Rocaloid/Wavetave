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

#Source
load(strcat("Data/", Path, ".xepr"));
A_VFreq = EpR_Freq;
A_VBwth = EpR_BandWidth;
A_VAmpl = EpR_Amp;
A_VANT1 = EpR_ANT1;
A_VANT2 = EpR_ANT2;

#Target
load(strcat("Data/", Path2, ".xepr"));
B_VFreq = EpR_Freq;
B_VBwth = EpR_BandWidth;
B_VAmpl = EpR_Amp;
B_VANT1 = EpR_ANT1;
B_VANT2 = EpR_ANT2;

N = EpR_N;

Slope = - 0.1 * (1 : FFTSize / 2);
Slope = DecibelToIFFTLn(Slope);

RowNum = rows(CVDB_Sinusoid_Magn);
RowNum_2 = rows(CVDB_Sinusoid_Magn_2);

#Create copy
CVDB_Residual2 = CVDB_Residual;

for i = 1 : RowNum
        #Dest index.
        i_2 = ceil(i / RowNum * RowNum_2);
        
        iResidual = fix(i / 2 + 1);
        #Avoid overflow.
        if(iResidual > rows(CVDB_Residual))
                iResidual = rows(CVDB_Residual);
        end
        iResidual_2 = fix(i_2 / 2 + 1);
        #Avoid overflow.
        if(iResidual_2 > rows(CVDB_Residual_2))
                iResidual_2 = rows(CVDB_Residual_2);
        end
        
        #Source Envelope generation
        XPeak = CVDB_Sinusoid_Freq(i, : ) / SampleRate * FFTSize;
        YPeak = CVDB_Sinusoid_Magn(i, : );
        Spectrum = PeakInterpolate(XPeak, YPeak, FFTSize, - 20) ...
                       (1 : FFTSize / 2) - Slope;
        RSpectrum = EnvelopeInterpolate(CVDB_Residual2(iResidual, : ),
                        FFTSize / 2, 8)(1 : FFTSize / 2);
        #Dest Envelope generation
        XPeak_2 = CVDB_Sinusoid_Freq_2(i_2, : ) / SampleRate * FFTSize;
        YPeak_2 = CVDB_Sinusoid_Magn_2(i_2, : );
        Spectrum_2 = PeakInterpolate(XPeak_2, YPeak_2, FFTSize, - 20) ...
                       (1 : FFTSize / 2) - Slope;
        RSpectrum_2 = EnvelopeInterpolate(CVDB_Residual_2(iResidual_2, : ),
                          FFTSize / 2, 8)(1 : FFTSize / 2);
        
        #Pitch shifting
        XPeak *= 1;
        XPeak_2 *= 1;
        
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
        OrigEnv .*= GenANTFilter(OrigEnv, A_ANT1, A_ANT2);
        OrigEnv = log(OrigEnv);
        #(Anti)Resonance reconstruction of dest envelope.
        OrigEnv_2 = EpR_CumulateResonance(B_Freq, B_Bwth, 
                                        10 .^ (B_Ampl / 20), N);
        OrigEnv_2 .*= GenANTFilter(OrigEnv_2, B_ANT1, B_ANT2);
        OrigEnv_2 = log(OrigEnv_2);

        #(Anti)Resonance reconstruction of new envelope.
        NewEnv = EpR_CumulateResonance(Freq, Bwth, 10 .^ (Ampl / 20), N);
        NewEnv .*= GenANTFilter(NewEnv, ANT1, ANT2);
        NewEnv = log(NewEnv);
        
        if(ShowPlot)
        plot(OrigEnv(1 : 300), 'b');
        hold on
        plot(Spectrum(1 : 300), 'b');
        end
        
        #Residual envelope
        HRes = Spectrum - OrigEnv;
        RRes = RSpectrum - OrigEnv;
        HRes_2 = Spectrum_2 - OrigEnv_2;
        RRes_2 = RSpectrum_2 - OrigEnv_2;
        
        #Compress & Stretch Residual envelope
        Anchor1 = [1, A_Freq, A_Freq(N) + 300, SampleRate / 2];
        Anchor2 = [1, Freq  , Freq(N) + 300  , SampleRate / 2];
        Anchor1 *= FFTSize / SampleRate;
        Anchor2 *= FFTSize / SampleRate;
        Anchor1_2 = [1, B_Freq, B_Freq(N) + 300, SampleRate / 2];
        Anchor1_2 *= FFTSize / SampleRate;
        
        HAbsRes = abs(HRes);
        HAbsRes_2 = abs(HRes_2);
        HRes = MapStretch(HRes, Anchor1, Anchor2);
        RRes = MapStretch(RRes, Anchor1, Anchor2);
        HRes_2 = MapStretch(HRes_2, Anchor1_2, Anchor2);
        RRes_2 = MapStretch(RRes_2, Anchor1_2, Anchor2);
        HRes = min(HAbsRes, HRes);
        HRes = max(- HAbsRes, HRes);
        HRes_2 = min(HAbsRes_2, HRes_2);
        HRes_2 = max(- HAbsRes_2, HRes_2);
                
        #Adding resonance envelope
        Spectrum  = HRes + NewEnv;
        RSpectrum = RRes + NewEnv;
        Spectrum_2  = HRes_2 + NewEnv;
        RSpectrum_2 = RRes_2 + NewEnv;
        
        if(ShowPlot)
        plot(Spectrum(1 : 300), 'k'); #hold on;
        plot(NewEnv(1 : 300), 'k');
        plot(HRes(1 : 300), 'g');
        
        axis([1, 300, - 5, 5]);
        hold off
        text(0, - 4.5, strcat("Progress: ", mat2str(R * 100), "%"));
        sleep(0.1);
        end
        
        Spectrum += Slope;
        Spectrum_2 += Slope;
        Spectrum = Spectrum + (Spectrum_2 - Spectrum) * R;
        RSpectrum = RSpectrum + (RSpectrum_2 - RSpectrum) * R;
        
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

