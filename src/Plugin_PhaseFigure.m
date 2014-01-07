function Plugin_PhaseFigure(Spectrum, Phase, Wave)
	global FFTSize;
	global SampleRate;

	global SpectrumLowerRange;
	global SpectrumUpperRange;

	figure(3);
	plot(Phase);
	title("Phase");
	axis([FFTSize / SampleRate * SpectrumLowerRange, FFTSize / SampleRate * SpectrumUpperRange, - pi, pi]);
	figure(1);
end

