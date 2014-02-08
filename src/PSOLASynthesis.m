#  PSOLASynthesis.m
#    Generates wave from PSOLA matrix returned by PSOLAExtraction.m

function Ret = PSOLASynthesis(PSOLAMatrix, PSOLAWinHalf, Pulses)
        #Initialization
        Ret = zeros(Pulses(length(Pulses)) + 1000, 1);
        
        for i = 1 : length(PSOLAWinHalf)
                WinHalf = PSOLAWinHalf(i);
                Center = Pulses(i);
                Ret(Center - WinHalf : Center + WinHalf - 1) += ...
                        PSOLAMatrix(i, 1 : WinHalf * 2)';
        end
end

