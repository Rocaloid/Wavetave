/*  STFTAnalysis.cc
    Generate complex frames based on Short Time Fourier Transform.
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

//[CFrames, WinFactor] = STFTAnalysis(Wave, Window, FFTSize, HopSize);
DEFUN_DLD (STFTAnalysis, args, nargout, "")
{
    NDArray Wave = args(0).array_value();
    NDArray Window = args(1).array_value();
    int FFTSize = args(2).int_value();
    int HopSize = args(3).int_value();
    int WaveSize = Wave.length();
    int WinSize = Window.length();
    
    //The maximum number of analysis frames that Wave can hold.
    int WinNum = WaveSize / HopSize - WinSize / HopSize;
    
    //Complex Frames returned by this function.
    //CFrames(TimeIndex, BinIndex);
    ComplexNDArray CFrames(dim_vector(WinNum, FFTSize));
	//Buffer for windowed wave;
	NDArray WinBuffer;
	WinBuffer.resize1(WinSize);
	//Buffer for untransformed wave;
	NDArray PreBuffer;
	PreBuffer.resize1(FFTSize);
	//Buffer for transformed wave;
	ComplexNDArray FFTBuffer;
	FFTBuffer.resize1(FFTSize);
	
	int i, j;
	for(i = 0; i <= WinNum; i ++)
	{
	    int Base = i * HopSize;
	    
	    //Window & Copy
	    for(j = 0; j < WinSize; j ++)
	        WinBuffer(j) = Wave(Base + j) * Window(j);
        Zeropad(& PreBuffer, & WinBuffer, WinSize, FFTSize);
        
        //Do fft
        FFTBuffer = PreBuffer.fourier();
        
        //Store
        for(j = 0; j < FFTSize; j ++)
            CFrames(i, j) = FFTBuffer(j);
	}

    return octave_value(CFrames);
}

