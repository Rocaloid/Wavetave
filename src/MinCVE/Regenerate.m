#  Regenerate.m
#    Regenerates wave from CVDB.
#    Depends on various Plugins and Octs.

function Ret = Regenerate(Path)
        addpath("../");
        addpath("../Oct");
        addpath("../Util");
        
        global CVDB_Residual;
        global CVDB_Sinusoid_Magn;
        global CVDB_Sinusoid_Freq;
        global CVDB_Wave;
        
        global FFTSize;
        global SampleRate;
        global Window;
        global Environment;
        SampleRate = 44100;
        FFTSize = 2048;
        Window = hanning(FFTSize);
        Environment = "Procedure";
        
        load(strcat(Path, ".cvdb"));
        CVDBUnwrap;
        
        [PSOLAMatrix, PSOLAWinHalf] = PSOLAExtraction(CVDB_Wave, CVDB_Pulses);
        
        #Modifications to CVDB can be done here
        #----------------------------------------------------------------------
        
        CVDB_Pulses2 = CVDB_Pulses;
        for i = 2 : length(CVDB_Pulses)
                #Skip consonant part
                if(CVDB_Pulses2(i) < CVDB_VOTIndex - 2)
                        continue;
                end
                #Pulse Contraction / Expansion
                CVDB_Pulses(i) = CVDB_Pulses(i - 1) + fix(...
                                 (CVDB_Pulses2(i) - CVDB_Pulses2(i - 1)) ...
                                 / 1);
        end
        
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
                RSpectrum = EnvelopeInterpolate(CVDB_Residual(iResidual, : ),
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
                RSpectrum = RSpectrum(1 : FFTSize / 2) ...
                                - OrigEnv / 20 * log(10) * 0.3;
                
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
                CVDB_Residual(iResidual, : ) = SpectralEnvelope( ...
                                                   RSpectrum, 8);
        end
        
        #----------------------------------------------------------------------
        
        #Transition Region
        T = PSOLASynthesis(PSOLAMatrix, PSOLAWinHalf, CVDB_Pulses);
        
        #Approximate F0
        Center = fix(length(PSOLAWinHalf) * 0.2 + CVDB_VOTIndex * 0.8);
        CenterPos = CVDB_Pulses(Center);
        Period = CVDB_Pulses(Center) - CVDB_Pulses(Center - 1);
        ApprBin = fix(FFTSize / Period);
        
        #Window
        Wide = T(CenterPos - FFTSize / 2 : CenterPos + FFTSize / 2 + 99);
        Selection = Wide(1 : FFTSize);
        Selection = Selection .* Window;
        
        #Transform
        X = fft(fftshift(Selection));
        Amp = 20 * log10(abs(X));
        Arg = arg(X);
        
        #Bin F0
        global Plugin_Var_F0;
        [Y, Plugin_Var_F0] = max(Amp(ApprBin - 2 : ApprBin + 2));
        Plugin_Var_F0 += ApprBin - 3;
        
        #Exact F0
        global Plugin_Var_F0_Exact;
        Plugin_F0Marking_ByPhase(Amp, Arg, Selection, Wide, 0);
        
        #Sinusoidal Extraction
        global SpectrumUpperRange;
        SpectrumUpperRange = 10000;
        global Plugin_Var_Harmonics_Freq;
        global Plugin_Var_Harmonics_Magn;
        InitialPhase = zeros(50, 1);
        
        Plugin_HarmonicMarking_Naive(Amp, Arg, Selection);
        HNum = length(Plugin_Var_Harmonics_Freq);
        SNum = columns(CVDB_Sinusoid_Magn);
        for j = HNum + 1 : SNum
                CVDB_Sinusoid_Magn(1, j) = - 20;
                CVDB_Sinusoid_Magn(2, j) = - 20;
                CVDB_Sinusoid_Magn(3, j) = - 20;
        end
        for j = 1 : HNum
                #Decibel to logarithmic sinusoidal magnitude.
                [Freq, Magn] = GetExactPeak(Amp, ...
                                Plugin_Var_Harmonics_Freq(j));
                CVDB_Sinusoid_Magn(1, j) = log(...
                        10 ^ (Magn / 20) ...
                           / FFTSize * 4);
                CVDB_Sinusoid_Freq(1, j) = Freq;
                
                #Transition
                CVDB_Sinusoid_Magn(2, j) = CVDB_Sinusoid_Magn(1, j);
                CVDB_Sinusoid_Freq(2, j) = CVDB_Sinusoid_Freq(1, j);
                CVDB_Sinusoid_Magn(3, j) = (CVDB_Sinusoid_Magn(2, j) + ...
                                            CVDB_Sinusoid_Magn(4, j)) / 2;
                CVDB_Sinusoid_Freq(3, j) = (CVDB_Sinusoid_Freq(2, j) + ...
                                            CVDB_Sinusoid_Freq(4, j)) / 2;
                #Initial phase for deterministic synthesis.
                InitialPhase(j) = Arg(Plugin_Var_Harmonics_Freq(j));
        end
        
        #Unwrap
        CVDB_Sinusoid_Magn = exp(CVDB_Sinusoid_Magn);
        
        #Deterministic
        Ret(1 : CenterPos) = 0;
        Det = DeterministicSynth(CVDB_Sinusoid_Magn, CVDB_Sinusoid_Freq, ...
                InitialPhase, fix(columns(CVDB_Sinusoid_Freq) * 2 / 3), 256);
        Ret(CenterPos : CenterPos + length(Det) - 1) ...
                 = Det;
        
        #Stochastic
        Offset = CenterPos - CVDB_FramePosition(1);
        Sto = zeros(1, length(Ret));
        for i = 1 : rows(CVDB_Residual) * 2 - 1
                X = GenResidual(CVDB_Residual(fix(i / 2 + 1), : ),
                        8, FFTSize)';
                Residual = real(ifft(X)) .* Window;
                Center = CVDB_FramePosition(i) + Offset;
                Sto(Center - FFTSize / 2 : Center + FFTSize / 2 - 1) += ...
                        Residual';
        end
        
        #Turbulent Noise reconstruction.
        Sto = GenTurbulentNoise(Ret, Sto, CVDB_Pulses(CVDB_VOTIndex));
        Sto *= 0.6;
        
        #Fade Out
        T(CenterPos : CenterPos + 255) .*= 1 - (1 : 256)' / 256;
        Ret(CenterPos : CenterPos + 255) .*=  (1 : 256) / 256;
        Ret(1 : CenterPos + 255) += T(1 : CenterPos + 255)';
        
        wavwrite(T, 44100, 'PSOLA.wav');
        wavwrite(Ret, 44100, 'sinusoidal.wav');
        wavwrite(Sto, 44100, 'residual.wav');
        wavwrite(Sto + Ret, 44100, strcat(Path, ".wav"));
end

