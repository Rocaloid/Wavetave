/*  PeakInterpolate.cc
    Linearly interpolates sets of x and y coordinates to generate an array.
*/

#include <octave/oct.h>
#include <math.h>

//Ret = PeakInterpolate(XPeak, YPeak, Length, Zero);
DEFUN_DLD (PeakInterpolate, args, nargout, "")
{
    NDArray XPeak = args(0).array_value();
    NDArray YPeak = args(1).array_value();
    int Length = args(2).int_value();
    int PeakNum = XPeak.length();
    double Zero = args(3).double_value();
    
    NDArray Ret;
    Ret.resize1(Length);
    
    int i, j;
    //Clear
    for(i = 0; i < Length; i ++)
        Ret(i) = 0;

    int LIndex, HIndex;
    double LHeight, HHeight;
    for(i = - 1; i < PeakNum - 1; i ++)
    {
        if(i == - 1)
        {
            //First line
            LIndex = 0;
            LHeight = YPeak(0);
        }else
        {
            LIndex = XPeak(i);
            LHeight = YPeak(i);
        }
        
        HIndex = XPeak(i + 1);
        HHeight = YPeak(i + 1);
        
        //Irregular arrangement, breaks.
        if(HIndex <= LIndex)
                break;
        
        //Linear interpolate.
        for(j = LIndex; j < HIndex; j ++)
        {
            double Ratio = ((double)(j - LIndex)) / (HIndex - LIndex);
            Ret(j) = LHeight * (1.0 - Ratio) + HHeight * Ratio;
        }
    }
    
    //Fill up.
    double Last = Zero;
    for(; j < Length; j ++)
        Ret(j) = Last;
    
    return octave_value(Ret);
}

