#  SpectrumVisualizer.m
#    Displays waveform and spectrum figures;
#    Interacts with user;
#    Loads and calls plugins.

clear;
addpath("./");

Version = "0.3";

global FFTSize;
global SampleRate;
global Window;
global ViewPos;
global ViewWidth;
global Length;
global PlotLeft;

global SpectrumLowerRange;
global SpectrumUpperRange;
global DBLowerRange;
global DBUpperRange;

#  Global variable for plugins to identify where they are running in.
global Environment;
Environment = "Visual";

function Empty
end

#  Functions in Plugin_Load are called when a new wave file is loaded.
#  Call parameter(s):
#    FunctionName(Wave)
#  Wave: an array of the whole loaded signal.
global Plugin_Load = [
                "Empty"
                "Plugin_Load_PulseMarking"
        ];

#  Functions in Plugin_Wave are called when a waveform redraw takes place.
#  Call parameter(s):
#    FunctionName(Wave)
#  Wave: an array of signal contained in the visible area.
global Plugin_Wave = [
                "Empty"
                "Plugin_PulseMarking"
                "Plugin_VOTMarking"
        ];

#  Functions in Plugin_Spectrum are called when a spectrum redraw takes place.
#  Call parameter(s):
#    FunctionName(Spectrum, Phase, Wave, ExtWave)
#  Spectrum: The decibel magnitude spectrum of a FFTSize-size fourier transform
#    at the center of the visible area.
#  Phase: The phase spectrum of a FFTSize-size fourier transform at the center
#    of the visible area.
#  Wave: an array of signal centered in the visible area. Its length is equal
#    to FFTSize.
#  ExtWave: Extended Wave, which means it's 128 samples longer than Wave. Can
#    be useful in precise fundamental frequency detection.
global Plugin_Spectrum = [
                "Empty"
                "Plugin_F0Marking_ByPhase"
        #       "Plugin_F0Marking"
        #       "Plugin_Freq2Pitch"
        #       "Plugin_HarmonicMarking"
                "Plugin_HarmonicMarking_Naive"
        #       "Plugin_PhaseFigure"
        ];

#  The following variables specify the feature of the spectrum figure.
FFTSize = 2048;
SpectrumLowerRange = 0;
SpectrumUpperRange = 15000;
DBLowerRange = - 70;
DBUpperRange = 40;
WindowFunc = @hanning;

#  Keycodes
Button_Click = 1;
Button_Exit = - 1;
Button_W = 119;
Button_A = 97;
Button_S = 115;
Button_D = 100;
Button_O = 111;

#  Draws the time domain signal in the range of visible area.
function UpdateView(Wave)
        global ViewPos;
        global ViewWidth;
        global Length;
        global PlotLeft;
        global Plugin_Wave;
        Left = ViewPos - ViewWidth;
        Right = ViewPos + ViewWidth;
        if(Left < 1)
                Left = 1;
        end
        if(Right > Length)
                Right = Length;
        end
        PlotLeft = fix(Left);
        plot(Wave(PlotLeft : fix(Right)));
        axis([0, Right - PlotLeft, - 0.3, 0.3]);
        text(ViewPos - PlotLeft, Wave(fix(ViewPos)), "x");

        #Evaluates Plugin_Wave plugins.
        for i = 1 : length(Plugin_Wave(:, 1))
                eval(cstrcat(Plugin_Wave(i, :),
                     "(Wave(PlotLeft : fix(Right)));"));
        end
end

#  Calulates the decibel magnitude and phase spectrum from time domain signals.
function [Ret, RetPhase] = GenerateSpectrum(Wave)
        global FFTSize;
        global Window;
        X = fft(fftshift(Wave .* Window));
        Ret = abs(X)(1 : FFTSize / 2);
        Ret = log10(Ret + 0.000001) * 20;
        RetPhase = arg(X);
end

#  Returns the spectrum and waveform in the range of FFT area.
function [Ret, RetPhase, RetWave, ExtWave] = UpdateSpectrum(Wave)
        global ViewPos;
        global ViewWidth;
        global Length;
        global FFTSize;
        Left = ViewPos - FFTSize / 2;
        Right = ViewPos + FFTSize / 2;
        if(Left < 0)
                Left = 0;
        end
        if(Right > Length)
                Right = Length;
        end
        RetWave = Wave(Left : Right - 1);
        ExtWave = Wave(Left : Right - 1 + 128);
        [Ret, RetPhase] = GenerateSpectrum(RetWave);
end

#  Draws the ticks in the spectrum plot.
function UpdatePlotTick(SpectrumLowerRange, SpectrumUpperRange, DBLowerRange)
        global FFTSize;
        global SampleRate;
        SpectrumWidth = SpectrumUpperRange - SpectrumLowerRange;
        BinWidth = SpectrumWidth / SampleRate * FFTSize;
        FixTo10 = fix(BinWidth / 60 + 1) * 5;
        Range = [FFTSize / SampleRate * SpectrumLowerRange : FixTo10 : ...
                 FFTSize / SampleRate * SpectrumUpperRange];
        set(gca, 'xtick', Range);
        for i = Range
                text(i - 1, DBLowerRange + 5,
                     strcat(mat2str(fix(i / FFTSize * SampleRate)), "Hz"));
        end
end

#  Initialization
OrigWave = zeros(10000, 1);
SampleRate = 44100;
Length = length(OrigWave);
Window = WindowFunc(FFTSize);
ViewPos = fix(Length / 2);
ViewWidth = ViewPos;
WaveToOpen = "";

clf;
figure(1);
plot(OrigWave);
UpdateView(OrigWave);

printf(cstrcat("Spectrum Visualizer ", Version, "\n"));
printf("W - Scale in,     S - Scale out.\n");
printf("A - Move to left, D - Move to right.\n");
printf("O - Open wave file.\n");
fflush(stdout);

while(1)
        [Spectrum, Phase, Wave, ExtWave] = UpdateSpectrum(OrigWave);
        figure(2);
        LBound = fix(FFTSize / SampleRate * SpectrumLowerRange);
        UBound = fix(FFTSize / SampleRate * SpectrumUpperRange);
        plot(Spectrum(1 : UBound));
        title(cstrcat("Spectrum, FFTSize: ", mat2str(FFTSize)));
        axis([LBound, UBound, DBLowerRange, DBUpperRange]);
        UpdatePlotTick(SpectrumLowerRange, SpectrumUpperRange, DBLowerRange);

        #Evaluates Plugin_Spectrum plugins.
        for i = 1 : length(Plugin_Spectrum(:, 1))
                eval(cstrcat(Plugin_Spectrum(i, :),
                     "(Spectrum, Phase, Wave, ExtWave);"));
        end

        figure(1);
        UpdateView(OrigWave);
        title(cstrcat("Waveform at ", mat2str(ViewPos / SampleRate), " sec."));
        [X, Y, Button] = ginput(1);
        X += PlotLeft;

        if(Button == Button_Click)
                ViewPos = fix(X); #Move to mouse pos
        elseif(Button == Button_W)
                ViewWidth *= 0.5; #Scale in
        elseif(Button == Button_S)
                ViewWidth /= 0.5; #Scale out
        elseif(Button == Button_A)
                ViewPos -= ViewWidth * 0.2; #Left
        elseif(Button == Button_D)
                ViewPos += ViewWidth * 0.2; #Right
        elseif(Button == Button_O)
                #Open
                WaveToOpen = input("Wave to open(enclosed by quotes): ");
                [OrigWave, SampleRate] = wavread(WaveToOpen);
                Length = length(OrigWave);
                Window = hanning(FFTSize);
                ViewPos = fix(Length / 2);
                ViewWidth = ViewPos;

                #Evaluates Plugin_Load plugins.
                for i = 1 : length(Plugin_Load(:, 1))
                        eval(cstrcat(Plugin_Load(i, :), "(OrigWave);"));
                end
        elseif(Button == Button_Exit)
                break; #Exit
        end
        ViewPos = fix(ViewPos);

        #Keep the visible area in the wave.
        if(ViewPos < 1)
                ViewPos = 1;
        elseif(ViewPos > Length - FFTSize)
                ViewPos = Length - FFTSize;
        end
        fflush(stdout);
end

close(1);
close(2);

