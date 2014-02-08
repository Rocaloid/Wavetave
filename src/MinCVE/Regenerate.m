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
        
        Ret = PSOLASynthesis(PSOLAMatrix, PSOLAWinHalf, CVDB_Pulses);
        wavwrite(Ret, 44100, 'a.wav');
end

