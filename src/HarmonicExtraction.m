clear;
addpath("./");

Version = "0.21";

global FFTSize;
global SampleRate;
global Window;
global ViewPos;
global ViewWidth;
global Length;
global PlotLeft;

global Environment;
Environment = "Procedure";

FFTSize = 2048;
WindowFunc = @hanning;

[OrigWave, SampleRate] = wavread(input("Wave: "));
Length = length(OrigWave);
Window = WindowFunc(FFTSize);
ViewPos = fix(Length / 2);
ViewWidth = ViewPos;

Plugin_VOTMarking(OrigWave);
