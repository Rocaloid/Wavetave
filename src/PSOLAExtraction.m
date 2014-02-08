#  PSOLAExtraction.m
#    Extracts windowed waves from the original voice wave.
#    Returns in matrix form.

function [PSOLAMatrix, PSOLAWinHalf] = PSOLAExtraction(Wave, Pulses)
        Length = length(Wave);
        for i = 1 : length(Pulses)
                if(i == 1)
                        #First pulse
                        WinSize = (Pulses(i + 1) - Pulses(i)) * 2;
                elseif(i == length(Pulses))
                        #Last pulse
                        WinSize = (Pulses(i) - Pulses(i - 1)) * 2;
                else
                        WinSize = Pulses(i + 1) - Pulses(i - 1);
                end
                WinHalf = fix(WinSize / 2);
                
                #If pulse exceeds wave
                if(Pulses(i) + WinHalf > Length)
                        break;
                end
                #Extract and window.
                PSOLAMatrix(i, 1 : WinHalf * 2) = ...
                    Wave(Pulses(i) - WinHalf : Pulses(i) + WinHalf - 1) ...
                    .* hanning(WinHalf * 2);
                PSOLAWinHalf(i) = WinHalf;
        end
end

