#  Normalize.m
#    Scale the NDArray to [0, 1]

function Ret = Normalize(Wave)
        W_Max = max(Wave);
        W_Min = min(Wave);
        Ret= (Wave - W_Min) / (W_Max - W_Min);
end

