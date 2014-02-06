/*  SpectralEnvelope.cc
    Extracts maximum heights from a magnitude spectrum.
    Returns an NDArray of spectral heights.
*/

#include <octave/oct.h>
#include <math.h>

double MaxInterval(NDArray* Src, int LowIndex, int HighIndex, int UBound)
{
    double Max = - 999;
    int i;
    if(HighIndex > UBound)
        HighIndex = UBound;
    for(i = LowIndex; i <= HighIndex; i ++)
        if(Src[0](i) > Max)
            Max = Src[0](i);
    return Max;
}

//Ret = SpectralEnvelope(Spectrum, Interval);
DEFUN_DLD (SpectralEnvelope, args, nargout, "")
{
    NDArray Spectrum = args(0).array_value();
    int Interval = args(1).int_value();
    int FFTSize = Spectrum.length();
    
    int MaxNum = FFTSize / Interval;
    int HalfInterval = Interval / 2;
    NDArray Ret;
    Ret.resize1(MaxNum);
    
    int i;
    for(i = 0; i < MaxNum; i ++)
    {
        Ret(i) = MaxInterval(& Spectrum,
                             i * Interval + HalfInterval,
                             (i + 1) * Interval + HalfInterval, FFTSize - 1);
    }

    return octave_value(Ret);
}

