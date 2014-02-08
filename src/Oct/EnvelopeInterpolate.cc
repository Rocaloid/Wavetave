/*  EnvelopeInterpolate.cc
    Generates envelope from an array of heights and a given interval.
    Returns an NDArray of envelope.
*/

#include <octave/oct.h>
#include <math.h>

//Ret = EnvelopeInterpolate(Points, Size, Interval);
DEFUN_DLD (EnvelopeInterpolate, args, nargout, "")
{
    NDArray Points = args(0).array_value();
    int Size = args(1).int_value();
    int Interval = args(2).int_value();
    
    int MaxNum = Points.length();
    NDArray Ret;
    Ret.resize1(Size);
    
    int i, j;
    //Clear
    for(i = 0; i < Size; i ++)
        Ret(i) = 0;

    int LIndex, HIndex;
    double LHeight, HHeight;
    for(i = - 1; i < MaxNum - 1; i ++)
    {
        if(i == - 1)
        {
            //First line
            LIndex = 0;
            LHeight = Points(0);
        }else
        {
            LIndex = (i + 1) * Interval;
            LHeight = Points(i);
        }
        
        HIndex = LIndex + Interval;
        HHeight = Points(i + 1);
        
        //Interpolate
        for(j = LIndex; j < HIndex; j ++)
        {
            double Ratio = (double)(j - LIndex) / Interval;
            Ret(j) = LHeight * (1.0 - Ratio) + HHeight * Ratio;
        }
    }
    
    return octave_value(Ret);
}

