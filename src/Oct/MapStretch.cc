/*  MapStretch.cc
      Maps and stretches an array to another array by specified anchor points.
      The first anchor point should be 1;
      The last should be the length of Arr.
*/

#include <octave/oct.h>
#include <math.h>

//Ret = MapStretch(Arr, SrcPoints, DstPoints);
DEFUN_DLD (MapStretch, args, nargout, "")
{
    NDArray Arr = args(0).array_value();
    NDArray SrcPoints = args(1).array_value();
    NDArray DstPoints = args(2).array_value();
    int NPoints = SrcPoints.length();
    int ArrSize = Arr.length();
    
    NDArray Ret;
    Ret.resize1(ArrSize);
    
    int i;
    double j;
    double SrcL, SrcH, DstL, DstH;
    double SrcDist, DstDist;
    for(i = 0; i < NPoints; i ++)
    {
        if(SrcPoints(i) < 1          ) SrcPoints(i) = 1;
        if(SrcPoints(i) > ArrSize - 1) SrcPoints(i) = ArrSize - 1;
        if(DstPoints(i) < 1          ) DstPoints(i) = 1;
        if(DstPoints(i) > ArrSize - 1) DstPoints(i) = ArrSize - 1;
    }
    for(i = 0; i < NPoints - 1; i ++)
    {
        SrcL = SrcPoints(i + 0) - 1;
        SrcH = SrcPoints(i + 1) - 1;
        DstL = DstPoints(i + 0) - 1;
        DstH = DstPoints(i + 1) - 1;
        SrcDist = SrcH - SrcL;
        DstDist = DstH - DstL;
        for(j = DstL; j <= DstH; j ++)
        {
            //Map & Stretch
            int DstIndex = (int)j;
            double DstRatio = ((double)DstIndex - DstL) / DstDist;
            double SrcPos   = SrcL + SrcDist * DstRatio;
            double SrcRatio = fmod(SrcPos, 1.0f);
            int SrcIndex = (int)SrcPos;
            
            //Linear interpolation
            Ret(DstIndex) = Arr(SrcIndex) * (1.0f - SrcRatio)
                          + Arr(SrcIndex + 1) * SrcRatio;
        }
    }
    Ret(ArrSize - 1) = Arr(ArrSize - 1);
    
    return octave_value(Ret);
}

