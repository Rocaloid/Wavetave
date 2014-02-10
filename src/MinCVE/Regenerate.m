#  Regenerate.m
#    Regenerates wave from CVDB.
#    Depends on various Plugins and Octs.

#  Not finished yet.

function Ret = Regenerate(Path)
        addpath("../");
        addpath("../Oct");
        addpath("../Util");
        
        global CVDB_Residual;
        global CVDB_Sinusoid_Magn;
        global CVDB_Sinusoid_Freq;
        global CVDB_Wave;
        
        global FFTSize;
        global Window;
        FFTSize = 2048;
        Window = hanning(FFTSize);
        
        load(Path);
        CVDBUnwrap;
        
        [PSOLAMatrix, PSOLAWinHalf] = PSOLAExtraction(CVDB_Wave, CVDB_Pulses);
        
        #Modifications to CVDB can be done here
        #----------------------------------------------------------------------
        
        CVDB_Pulses2 = CVDB_Pulses;
        for i = 2 : length(CVDB_Pulses)
                CVDB_Pulses(i) = CVDB_Pulses(i - 1) + fix(...
                                 (CVDB_Pulses2(i) - CVDB_Pulses2(i - 1)) ...
                                 + (sin(i * 0.07) * 5) - 50);
        end
        
        #----------------------------------------------------------------------
        
        #Ret = PSOLASynthesis(PSOLAMatrix, PSOLAWinHalf, CVDB_Pulses);
        CVDB_Sinusoid_Magn = exp(CVDB_Sinusoid_Magn);
        
        #Deterministic
        Ret(1 : CVDB_FramePosition(1)) = 0;
        Det = DeterministicSynth(CVDB_Sinusoid_Magn, CVDB_Sinusoid_Freq, ...
                rand(50, 1) * 0, columns(CVDB_Sinusoid_Freq), 256);
        Ret(CVDB_FramePosition(1) : CVDB_FramePosition + length(Det) - 1) ...
                 = Det;
        
        #Stochastic
        Sto = zeros(1, length(Ret));
        for i = 1 : rows(CVDB_Residual) * 2 - 1
                X = GenResidual(CVDB_Residual(fix(i / 2 + 1), : ), 8, FFTSize)';
                Residual = real(ifft(X)) .* Window;
                Center = CVDB_FramePosition(i);
                Sto(Center - FFTSize / 2 : Center + FFTSize / 2 - 1) += Residual';
        end
        
        wavwrite(Ret, 44100, 'sinusoidal.wav');
        wavwrite(Sto, 44100, 'residual.wav');
        wavwrite(Sto + Ret, 44100, 'plus.wav');
end

