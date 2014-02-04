/*  SinusoidalFrameSynth.cc
    Synthesizes sinusoids in an analysis frame.
*/

#include <octave/oct.h>
#include <math.h>

//Ret = SinusoidalFrameSynth(FreqBuffer, MagnBuffer, WinSize);
DEFUN_DLD (SinusoidalFrameSynth, args, nargout, "")
{
    NDArray FreqBuffer = args(0).array_value();
    NDArray MagnBuffer = args(1).array_value();
    int WinSize = args(2).int_value();
    int PeakNum = FreqBuffer.length();

    int i, j;
    NDArray Wave;
    Wave.resize1(WinSize);
    for(j = 0; j < WinSize; j ++)
        Wave(j) = 0;
    for(i = 0; i < PeakNum; i ++)
        for(j = 0; j < WinSize; j ++)
            Wave(j) += pow(M_E, MagnBuffer(i)) * cos(2.0 * M_PI / 44100.0
                                               * j * FreqBuffer(i));
    return octave_value(Wave);
}

