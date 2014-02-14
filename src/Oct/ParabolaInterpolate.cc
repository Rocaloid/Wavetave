/*  ParabolaInterpolate.cc
    Generates envelope from peaks and valleys of piecewise parabola functions.
    Returns an NDArray.
*/

#include <octave/oct.h>
#include <math.h>

typedef struct
{
    double a0;
    double a1;
    double a2;
} Quadratic;

//Get quadratic coefficients from three control points.
Quadratic GenQuadratic(double x0, double y0,
                       double x1, double y1,
                       double x2, double y2)
{
    Quadratic Ret;
	double o = x0 * x0 - x1 * x1;
	double p = x1 * x1 - x2 * x2;
	double m = x0 - x1;
	double n = x1 - x2;
	double u = y0 - y1;
	double v = y1 - y2;

	Ret.a0 = (v * m - n * u) / (m * p - n * o);
	Ret.a1 = (u - Ret.a0 * o) / m;
	Ret.a2 = y0 - Ret.a1 * x0 - Ret.a0 * (x0 * x0);
	
	return Ret;
}

void ParabolaToNDArray(NDArray* Dest, double P0X, double P0Y,
                                      double VX, double VY,
                                      double P1X, double P1Y)
{
    int i;
    if(P0X < 0)
        P0X = 0;
    Quadratic Track = GenQuadratic(P0X, P0Y, VX, VY, P1X, P1Y);
    
    for(i = (int)P0X; i <= (int)P1X; i ++)
        Dest[0](i) = Track.a0 * (i * i) + Track.a1 * i + Track.a2;
}

//Ret = ParabolaInterpolate(PeakX, PeakY, ValleyX, ValleyY,
//                          N, FillX, FillY, FFTSize);
DEFUN_DLD (ParabolaInterpolate, args, nargout, "")
{
    NDArray PeakX = args(0).array_value();
    NDArray PeakY = args(1).array_value();
    NDArray ValleyX = args(2).array_value();
    NDArray ValleyY = args(3).array_value();
    int N = args(4).int_value();
    double FillX = args(5).int_value();
    double FillY = args(6).double_value();
    int FFTSize = args(7).int_value(); 
    
    NDArray Ret;
    Ret.resize1(FFTSize);
    
    int i;
    //Complete parabola part.
    for(i = 0; i < N; i ++)
    {
        ParabolaToNDArray(& Ret, PeakX(i), PeakY(i),
                                 ValleyX(i), ValleyY(i),
                                 PeakX(i + 1), PeakY(i + 1));
    }
    
    //Complete the envelope.
    int LastX = (int)PeakX(i);
    double LastY = PeakY(i);
    double XRange = FillX - LastX;
    double YRange = FillY - LastY;
    double Factor = YRange / XRange;
    for(i = LastX; i < FillX; i ++)
        Ret(i) = LastY + ((double)i - LastX) * Factor;
    for(; i < FFTSize; i ++)
        Ret(i) = FillY;
    
    return octave_value(Ret);
}

