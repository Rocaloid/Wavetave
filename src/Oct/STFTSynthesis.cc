/*  STFTSynthesis.cc
    Synthesis waveform from complex matrix generated from STFTAnalysis.
*/
#include <octave/oct.h>
#include <octave/CNDArray.h>
#include <stdio.h>

//Fill the blank with zero and do fftshift.
void Zeropad(NDArray* Dest, NDArray* Src, int WinSize, int FFTSize)
{
    int i;
    //First half
    for(i = 0; i < WinSize / 2; i ++)
        Dest[0](i) = Src[0](WinSize / 2 + i);
    //Fill up the blank
    for(; i < FFTSize - WinSize / 2; i ++)
        Dest[0](i) = 0;
    //Last half
    for(i = 0; i < WinSize / 2; i ++)
        Dest[0](FFTSize - WinSize / 2 + i) = Src[0](i);
}

//Complete the symmetrical complex spectrum.
void Reflect(ComplexNDArray* Dest, int N)
{
    int k;
    int j = N / 2;
    for(k = 1; k < j; k ++)
        Dest[0](N - k) = conj(Dest[0](k));
}

//Evaluate the magnitude of a window.
double GetWindowFactor(NDArray* Src, int HopSize)
{
    int WinSize = Src -> length();
    int i;
    double Amp = 0;
    for(i = 0; i < WinSize / HopSize; i ++)
        Amp += Src[0](i * HopSize);
    return Amp;
}

//Wave = STFTSynthesis(CFrames, Window, FFTSize, HopSize);
DEFUN_DLD (STFTSynthesis, args, nargout, "")
{
    ComplexNDArray CFrames = args(0).complex_array_value();
    NDArray Window = args(1).array_value();
    int FFTSize = args(2).int_value();
    int HopSize = args(3).int_value();
    int WinSize = Window.length();
    int WinNum = CFrames.rows();
    
    double WinFactor = 1.0f / GetWindowFactor(& Window, HopSize);
    
    //Wave signal returned by this function.
    NDArray Wave;
    Wave.resize1(WinNum * HopSize + WinSize);
    //Buffer for uniffted wave;
    ComplexNDArray PreBuffer;
    PreBuffer.resize1(FFTSize);
    //Buffer for iffted wave;
    NDArray FFTBuffer;
    FFTBuffer.resize1(FFTSize);
    //Buffer for unpadded wave;
    NDArray WinBuffer;
    WinBuffer.resize1(FFTSize);
    
    int i, j;
    
    //Initialize Wave
    for(i = 0; i < WinNum * HopSize; i ++)
        Wave(i) = 0;
    
    for(i = 0; i < WinNum; i ++)
    {
        int Base = i * HopSize;
    
        //Copy & Complete
        for(j = 0; j < FFTSize; j ++)
            PreBuffer(j) = CFrames(i, j);
        Reflect(& PreBuffer, FFTSize);
        
        FFTBuffer = real(PreBuffer.ifourier());
        
        //Inversed fftshift
        Zeropad(& WinBuffer, & FFTBuffer, WinSize, FFTSize);
        
        //Add onto the wave
        for(j = 0; j < WinSize; j ++)
            Wave(Base + j) += WinBuffer(FFTSize / 2 - WinSize / 2 + j)
                            * WinFactor;
    }
    
    return octave_value(Wave);
}

