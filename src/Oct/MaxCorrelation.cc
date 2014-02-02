/*  MaxCorrelation.cc
    Finds the equivalent position in next or previous period.
*/

#include <octave/oct.h>
#include <stdio.h>

//C++ implemention of octave function corr.
double Correlation(NDArray* W1, NDArray* W2, int Offset1, int Offset2, int Length)
{
    double Sum = 0;
    int i;
    for(i = 0; i < Length - 3; i += 4)
    {
        Sum += W1[0](Offset1 + i + 0) * W2[0](Offset2 + i + 0);
        Sum += W1[0](Offset1 + i + 1) * W2[0](Offset2 + i + 1);
        Sum += W1[0](Offset1 + i + 2) * W2[0](Offset2 + i + 2);
        Sum += W1[0](Offset1 + i + 3) * W2[0](Offset2 + i + 3);
    }
    for(; i < Length; i ++)
        Sum += W1[0](Offset1 + i) * W2[0](Offset2 + i);
    return Sum;
}

//Ret = MaxCorrelation(Wave, Position, Period, Offset, Range);
DEFUN_DLD (MaxCorrelation, args, nargout, "")
{
    NDArray Wave = args(0).array_value();
    int Position = args(1).int_value();
    int Period = args(2).int_value();
    double Offset = args(3).double_value();
    double Range = args(4).double_value();
    
    int i;
    double MaxCorr;
    int MaxPos;
    int LBound, HBound;
    LBound = Position + (int)((Offset - Range) * Period);
    HBound = Position + (int)((Offset + Range) * Period);
    
    MaxCorr = - 999;
    MaxPos = 0;
    for(i = LBound; i < HBound; i ++)
    {
        double CorrVal = Correlation(& Wave, & Wave,
                                     Position - Period, i - Period,
                                     2 * Period);
        if(CorrVal > MaxCorr)
        {
            MaxCorr = CorrVal;
            MaxPos = i;
        }
    }
    
    return octave_value(MaxPos);
}

