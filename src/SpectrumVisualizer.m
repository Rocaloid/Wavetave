#! /usr/bin/env octave

#{
    Title: SpectrumVisualizer
        Displays waveform and spectrum figures;
        Interacts with user;
        Loads and calls plugins.
#}

clear;
addpath("./");
addpath("./Oct");
addpath("./Util");

Version = "0.32";

#{
    Section: Globals
    
    Variable: FFTSize
    
        Number of FFT points.
    
        (Int Scalar)
#}
global FFTSize;

#{
    Variable: SampleRate
    
        Sample rate(Hertz) of wave being loaded and processed.
    
        (Int Scalar)
#}
global SampleRate;

#{
    Variable: Window
        
        The analysis window used throughout Wavetave.
    
        (1 Dimensional Real Array)
#}
global Window;

#{
    Variable: ViewPos
        
        The central position(in sample) of view window in the wave.
    
        (Int Scalar)
#}
global ViewPos;

#{
    Variable: ViewWidth
        
        The width(in sample) of view window.
    
        (Int Scalar)
#}
global ViewWidth;

#{
    Variable: Length
        
        The number of samples in the wave being analyzed.
    
        (Int Scalar)
#}
global Length;

#{
    Variable: PlotLeft
        
        The left boundary(in sample) of the view window in the wave being
        analyzed.
    
        (Int Scalar)
#}
global PlotLeft;

#{
    Variable: SpectrumLowerRange
        
        The left boundary(Hertz) of the spectrum.
    
        (Int Scalar)
#}
global SpectrumLowerRange;

#{
    Variable: SpectrumUpperRange
        
        The Right boundary(Hertz) of the spectrum.
    
        (Int Scalar)
#}
global SpectrumUpperRange;

#{
    Variable: DBLowerRange
        
        The lower boundary(dB) of the spectrum.
    
        (Real Scalar)
#}
global DBLowerRange;

#{
    Variable: DBUpperRange
        
        The upper boundary(dB) of the spectrum.
    
        (Real Scalar)
#}
global DBUpperRange;

#{
    Variable: Environment
        
        Global variable for plugins to identify where they are running in.
    
        (String)
#}
global Environment;
Environment = "Visual";

function Empty
end

#{
    Variable: Plugin_Load
        
        Functions in Plugin_Load are called when a new wave file is loaded.
        
        (Char Matrix)
        
        Containing Function:
        
            FunctionName(Wave)
        
        Call parameter(s):
        
            Wave - an array of the whole loaded signal.
            (Real 1 Dimensional Array)
#}
global Plugin_Load = [
                "Empty"
                "Plugin_Load_EpRInitialization"
        #       "Plugin_Load_PulseMarking"
        #       "Plugin_Load_PulseMarking_Stable"
        #       "Plugin_Load_PulseMarking_Naive"
        ];

#{
    Variable: Plugin_Wave
        
        Functions in Plugin_Wave are called when a waveform redraw takes place.
        
        (Char Matrix)
        
        Containing Function:
        
            FunctionName(Wave)
        
        Call parameter(s):
        
            Wave - an array of signal contained in the visible area.
            (Real 1 Dimensional Array)
#}
global Plugin_Wave = [
                "Empty"
        #       "Plugin_UnvoicedDetection"
        #       "Plugin_PulseMarking"
        #       "Plugin_VOTMarking"
        ];

#{
    Variable: Plugin_Spectrum
        
        Functions in Plugin_Spectrum are called when a spectrum redraw takes
        place.
        
        (Char Matrix)
        
        Containing Function:
        
            FunctionName(Spectrum, Phase, Wave, ExtWave)
        
        Call parameter(s):
        
            Spectrum: The decibel magnitude spectrum of a FFTSize-size fourier 
            transform at the center of the visible area.
            (Real 1 Dimensional Array)
            
            Phase: The phase spectrum gained by a FFT at the center of the
            visible area. (Real 1 Dimensional Array)
            
            Wave: an array of signal centered in the visible area. Its length
            is equal to FFTSize. (Real 1 Dimensional Array)
            
            ExtWave: Extended Wave, which means it's 128 samples longer than
            Wave. Can be useful in precise fundamental frequency detection.
            (Real 1 Dimensional Array)
#}
global Plugin_Spectrum = [
                "Empty"
                "Plugin_F0Marking"
                "Plugin_F0Marking_ByPhase"
                "Plugin_FormantFitting"
        #       "Plugin_Freq2Pitch"
        #       "Plugin_HarmonicMarking"
        #       "Plugin_HarmonicMarking_Naive"
        #       "Plugin_PhaseFigure"
        ];

#  The following variables specify the feature of the spectrum figure.
FFTSize = 2048;
SpectrumLowerRange = 0;
SpectrumUpperRange = 6000;
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
Button_M = 109;
Button_P = 112;
Button_E = 101;

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
        axis([0, Right - PlotLeft, - 0.35, 0.35]);
        text(ViewPos - PlotLeft, Wave(fix(ViewPos)), "x");

        #Evaluates Plugin_Wave plugins.
        for i = 1 : length(Plugin_Wave(:, 1))
                eval(cstrcat(Plugin_Wave(i, :),
                     "(Wave(PlotLeft : fix(Right)));"));
        end
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

printf(cstrcat("Spectrum Visualizer ", Version, "\n"));
printf("W - Scale in,     S - Scale out.\n");
printf("A - Move to left, D - Move to right.\n");
printf("O - Open wave file.\n");
fflush(stdout);

while(1)
        [Spectrum, Phase, Wave, ExtWave] = UpdateSpectrum(OrigWave);
        figure(2);
        hold off;
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
        elseif(Button == Button_M)
                printf("Formant Modeling Method:\n");
                printf("     (P) Piecewise Parabola\n");
                printf("     (E) EpR\n");
                fflush(stdout);
                [X, Y, Button] = ginput(1);
                if(Button == Button_P)
                        Plugin_FormantMarking_Parabola();
                elseif(Button == Button_E)
                        Plugin_FormantMarking_EpR(Spectrum);
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

