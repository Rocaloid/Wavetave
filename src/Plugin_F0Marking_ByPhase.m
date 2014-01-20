function Plugin_F0Marking_ByPhase(Spectrum, Phase, Wave, ExtWave)
	global FFTSize;
	global Window;
	global SampleRate;
	global Environment;
	global Plugin_Var_F0;
	global Plugin_Var_F0_Exact;

	HopSize = 1;

	Environment_ = Environment;
	Environment = "Procedure";
	Plugin_F0Marking(Spectrum, Phase, Wave);
	if(Plugin_Var_F0 > 1)
	ThisPhase = Phase(Plugin_Var_F0);
	X = fft(fftshift(ExtWave(HopSize + 1 : HopSize + FFTSize) .* Window));
	NextArg = arg(X);
	NextPhase = NextArg(Plugin_Var_F0);
	if(NextPhase < ThisPhase)
		NextPhase += 2 * pi;
	endif
	Delta = NextPhase - ThisPhase;
	Plugin_Var_F0_Exact = Delta / 2 / pi * SampleRate / HopSize;
	if(strcmp(Environment_, "Visual"))
		text(Plugin_Var_F0, Spectrum(Plugin_Var_F0), cstrcat("x ", mat2str(Plugin_Var_F0_Exact), "Hz"));
	endif
	endif
	Environment = Environment_;
end

