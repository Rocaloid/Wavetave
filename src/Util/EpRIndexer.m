#  EpRIndexer.m
#    Linearly interpolates EpR parameter matrix for Variative EpR.

function [Freq, BandWidth, Amp] = ...
    EpRIndexer(M_Freq, M_BandWidth, M_Amp, iFrame)
        Vi = iFrame / 4 + 1;
        if(Vi > rows(M_Freq) - 1)
                Vi = rows(M_Freq) - 1;
        end
        Vi1 = fix(Vi);
        Vi2 = fix(Vi) + 1;
        V = mod(Vi, 1);
        U = 1 - V;
        Freq      = M_Freq(Vi1, : ) * U + M_Freq(Vi2, : ) * V;
        BandWidth = M_BandWidth(Vi1, : ) * U ...
                  + M_BandWidth(Vi2, : ) * V;
        Amp       = M_Amp(Vi1, : ) * U + M_Amp(Vi2, : ) * V;
end

