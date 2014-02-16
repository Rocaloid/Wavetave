#  Mod_ParabolaTransition.m
#    Formant transition based on piecewise parabola spectral envelpe fitting.

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
load i.fmt;
A_PeakX = PeakX;
A_PeakY = PeakY;
A_ValleyX = ValleyX;
A_ValleyY = ValleyY;

load a.fmt;
B_PeakX = PeakX;
B_PeakY = PeakY;
B_ValleyX = ValleyX;
B_ValleyY = ValleyY;

D_PeakX = B_PeakX - A_PeakX;
D_PeakY = B_PeakY - A_PeakY;
D_ValleyX = B_ValleyX - A_ValleyX;
D_ValleyY = B_ValleyY - A_ValleyY;

OrigEnv = ParabolaInterpolate(A_PeakX, A_PeakY, A_ValleyX, A_ValleyY,
                                N, 300, - 12, FFTSize / 2);

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
        Spectrum = PeakInterpolate(XPeak, YPeak, FFTSize, - 20);
        RSpectrum = EnvelopeInterpolate(CVDB_Residual2(iResidual, : ),
                                                FFTSize / 2, 8);

        #Pitch shifting
        #XPeak *= 1;
                
        #Formant parameter mixing
        R = i / RowNum;
        PeakX = A_PeakX + D_PeakX * R;
        PeakY = A_PeakY + D_PeakY * R;
        ValleyX = A_ValleyX + D_ValleyX * R;
        ValleyY = A_ValleyY + D_ValleyY * R;

        #Generate new envelope
        NewEnv = ParabolaInterpolate(PeakX, PeakY, ValleyX, ValleyY,
                                        N, 300, - 12, FFTSize / 2);

        #Differential envelope
        Spectrum = Spectrum(1 : FFTSize / 2) - OrigEnv / 20 * log(10);
        RSpectrum = RSpectrum(1 : FFTSize / 2) - OrigEnv / 20 * log(10) * 0.3;
                
        #Additive parabola envelope
        Spectrum += NewEnv / 20 * log(10);
        RSpectrum += NewEnv / 20 * log(10) * 0.3;

        #plot(RSpectrum(1 : 300));
        #axis([1, 300, - 10, 5]);
        #sleep(0.1);

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

