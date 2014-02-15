/*  KlattFilter.cc
    Generates filter spectrum of a Klatt Formant Filter.
    Length of returned spectrum is FFTSize / 2.
    
    Reference
        Bonada, Jordi, et al. "Singing voice synthesis combining excitation 
        plus resonance and sinusoidal plus residual models." Proceedings of
        International Computer Music Conference. 2001.
*/

#include <octave/oct.h>
#include <math.h>
#include <complex.h>

//Ret = KlattFilter(F, BandWidth, Amp, SampleRate, FFTSize);
DEFUN_DLD (KlattFilter, args, nargout, "")
{
    double F = args(0).double_value();
    double BandWidth = args(1).double_value();
    double Amp = args(2).double_value();
    int SampleRate = args(3).int_value();
    int FFTSize = args(4).int_value();
    
    NDArray Ret;
    Ret.resize1(FFTSize / 2);
    
    //IIR filter coefficents.
    double C = - exp(2.0f * M_PI * BandWidth / SampleRate);
    double B = - 2.0f * exp(M_PI * BandWidth / SampleRate);
    double A = 1.0f - B - C;
    
    //z = e ^ jpi = cos(pi) + isin(pi) = - 1
    //1 / H(e ^ jpi)
    double AmpFactor = (1.0f + B - C) / A * Amp;
    
    //Z-Transform
    int i;
    for(i = 0; i < FFTSize / 2; i ++)
    {
        double complex z;
        double f;
        f = (double)i / FFTSize * SampleRate;
        //z = e ^ (j2pi(0.5 + (f - F) / fs))
        z = cexp(I * 2 * M_PI * (0.5f + (f - F) / SampleRate));
        
        //abs(H(z))
        //H(z) = A / (1 - Bz^-1 - Cz^-2)
        Ret(i) = cabs(A / (1.0f - B / z - C / z / z)) * AmpFactor;
    }
    
    return octave_value(Ret);
}

