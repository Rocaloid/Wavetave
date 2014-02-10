/*  FFTReflect.cc
    Restore the symmetric structure of real fourier transform.
*/

#include <octave/oct.h>

DEFUN_DLD (FFTReflect, args, nargout, "")
{
    ComplexNDArray Wave = args(0).complex_array_value();
    int FFTSize = args(1).int_value();

    int i;
    ComplexNDArray Ret;
    Ret.resize1(FFTSize);
    for(i = 0; i < FFTSize / 2 + 1; i ++)
        Ret(i) = Wave(i);
    for(i = 0; i < FFTSize / 2 - 1; i ++)
        Ret(i + FFTSize / 2 + 1) = conj(Wave(FFTSize / 2 - i - 1));

    return octave_value(Ret);
}

