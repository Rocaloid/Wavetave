function Plugin_HarmonicMarking(Spectrum, Phase, Wave)
	global FFTSize;
	global SampleRate;
	global Plugin_Var_F0;
	global SpectrumUpperRange;
	SpectrumUpperBin = SpectrumUpperRange * FFTSize / SampleRate;
	Width = fix(Plugin_Var_F0 / 4);
	for i = 2 : fix(SpectrumUpperBin / Plugin_Var_F0)
		ThisBin = fix(i * Plugin_Var_F0);
		[MaxY, MaxX] = max(Spectrum(ThisBin - Width : ThisBin + Width));
		MaxX += ThisBin - Width - 1;
		text(MaxX, MaxY + 5, strcat("H", mat2str(i - 1)));
		text(MaxX, MaxY, cstrcat("x ", mat2str(fix(MaxX * SampleRate / FFTSize)), "Hz"));
		if(i < 6)
			Plugin_Var_F0 = MaxX / i;
		end
	end
end
