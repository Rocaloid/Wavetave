#  EpRIndexer.m
#    Linearly interpolates EpR parameter matrix for Variative EpR.

function [Freq, BandWidth, Amp, ANT1, ANT2] = ...
    EpRIndexer(M_Freq, M_BandWidth, M_Amp, M_ANT1, M_ANT2, iFrame)
        Vi = iFrame / 4 + 1;
        if(Vi > rows(M_Freq) - 2)
                Vi = rows(M_Freq) - 2;
        end
        Vi1 = fix(Vi);
        Vi2 = fix(Vi) + 1;
        V = mod(Vi, 1);
        U = 1 - V;
        Freq      = M_Freq(Vi1, : ) * U + M_Freq(Vi2, : ) * V;
        BandWidth = M_BandWidth(Vi1, : ) * U ...
                  + M_BandWidth(Vi2, : ) * V;
        Amp       = M_Amp(Vi1, : ) * U + M_Amp(Vi2, : ) * V;
        ANT1 = ANTTransition(M_ANT1(Vi1 + 1), M_ANT1(Vi2 + 1), V);
        ANT2 = ANTTransition(M_ANT2(Vi1 + 1), M_ANT2(Vi2 + 1), V);
end

