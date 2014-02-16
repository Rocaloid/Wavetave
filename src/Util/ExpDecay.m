#  ExpDecay.m
#    Generates exponential decay spectrum.

function Ret = ExpDecay(Gain, Depth, Slope, Size)
        Ret = Gain + Depth * (exp(Slope * (1 : Size) / Size) - 1);
end

