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
        Ret(1 : CVDB_FramePosition(1)) = 0;
        Det = DeterministicSynth(CVDB_Sinusoid_Magn, CVDB_Sinusoid_Freq, ...
                rand(50, 1) * 10, columns(CVDB_Sinusoid_Freq), 256);
        Ret(CVDB_FramePosition(1) : CVDB_FramePosition + length(Det) - 1) = Det;
        
        wavwrite(Ret, 44100, 'a.wav');
end

