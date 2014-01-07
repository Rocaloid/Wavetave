clear;

Version = "0.2";

global FFTSize;
global Window;
global ViewPos;
global ViewWidth;
global Length;
global PlotLeft;

FFTSize = 2048;
SpectrumLowerRange = 0;
SpectrumUpperRange = 5500;
DBLowerRange = - 70;
DBUpperRange = 40;
WindowFunc = @hanning;

Button_Click = 1;
Button_Exit = - 1;
Button_W = 119;
Button_A = 97;
Button_S = 115;
Button_D = 100;
Button_O = 111;
WaveToOpen = "";

function UpdateView(Wave)
	global ViewPos;
	global ViewWidth;
	global Length;
	global PlotLeft;
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
end

function Ret = GenerateSpectrum(Wave)
	global FFTSize;
	global Window;
	Ret = abs(fft(Wave .* Window))(1 : FFTSize / 2);
	Ret = log10(Ret + 0.000001) * 20;
end

function Ret = UpdateSpectrum(Wave)
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
	Ret = GenerateSpectrum(Wave(Left : Right - 1));
end

function UpdatePlotTick(SampleRate, SpectrumLowerRange, SpectrumUpperRange, DBLowerRange)
	global FFTSize;
	SpectrumWidth = SpectrumUpperRange - SpectrumLowerRange;
	BinWidth = SpectrumWidth / SampleRate * FFTSize;
	FixTo10 = fix(BinWidth / 60 + 1) * 5;
	Range = [FFTSize / SampleRate * SpectrumLowerRange : FixTo10 : FFTSize / SampleRate * SpectrumUpperRange];
	set(gca, 'xtick', Range);
	for i = Range
		text(i - 1, DBLowerRange + 5, strcat(mat2str(fix(i / FFTSize * SampleRate)), "Hz"));
	end
end

OrigWave = zeros(10000, 1);
SampleRate = 44100;
Length = length(OrigWave);
Window = WindowFunc(FFTSize);
ViewPos = fix(Length / 2);
ViewWidth = ViewPos;

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
	Spectrum = UpdateSpectrum(OrigWave);
	figure(2);
	plot(Spectrum);
	title(cstrcat("Spectrum, FFTSize: ", mat2str(FFTSize)));
	axis([FFTSize / SampleRate * SpectrumLowerRange, FFTSize / SampleRate * SpectrumUpperRange, DBLowerRange, DBUpperRange]);
	UpdatePlotTick(SampleRate, SpectrumLowerRange, SpectrumUpperRange, DBLowerRange);
	figure(1);
	UpdateView(OrigWave);
	title(cstrcat("Waveform at ", mat2str(ViewPos / SampleRate), " sec."));
	[X, Y, Button] = ginput(1);
	X += PlotLeft;

	if(Button == Button_Click)
		ViewPos = fix(X);
	elseif(Button == Button_W)
		ViewWidth *= 0.8;
	elseif(Button == Button_S)
		ViewWidth /= 0.8;
	elseif(Button == Button_A)
		ViewPos -= ViewWidth * 0.2;
	elseif(Button == Button_D)
		ViewPos += ViewWidth * 0.2;
	elseif(Button == Button_O)
		#Open
		WaveToOpen = input("Wave to open(enclosed by quotes): ");
		[OrigWave, SampleRate] = wavread(WaveToOpen);
		Length = length(OrigWave);
		Window = hanning(FFTSize);
		ViewPos = fix(Length / 2);
		ViewWidth = ViewPos; 
	elseif(Button == Button_Exit)
		break;
	end
	ViewPos = fix(ViewPos);

	if(ViewPos < 1)
		ViewPos = 1;
	elseif(ViewPos > Length - FFTSize)
		ViewPos = Length - FFTSize;
	end
	fflush(stdout);
end

close(1);
close(2);

