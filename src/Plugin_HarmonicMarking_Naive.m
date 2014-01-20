function Plugin_HarmonicMarking_Naive(Spectrum, Phase, Wave)
	global FFTSize;
	global SampleRate;
	global Plugin_Var_F0;
	global Plugin_Var_F0_Exact;
	global SpectrumUpperRange;
	SpectrumUpperBin = SpectrumUpperRange * FFTSize / SampleRate;

	if(Plugin_Var_F0_Exact > 1)
	for i = 2 : fix(SpectrumUpperBin / Plugin_Var_F0)
		PinX = Plugin_Var_F0_Exact * FFTSize / SampleRate * i;
		PinY = max(Spectrum(fix(PinX) - 3 : fix(PinX) + 3));
		text(PinX, PinY + 5, strcat("H", mat2str(i - 1)));
		text(PinX, PinY, cstrcat("x ", mat2str(fix(PinX * SampleRate / FFTSize)), "Hz"));
	end
	endif
end

