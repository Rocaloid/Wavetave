function Plugin_VOTMarking(Wave)
	global Length;
	global SampleRate;
	FFTSize = 256;
	PartLength = length(Wave);
	VOTWave = zeros(1, PartLength);
	hold on;
	LMax = 0;

	HoldStart = 0;
	MaxHold = 0;
	MaxStart = 0;
	Holding = 0;
	c = 0;
	for i = 1 : FFTSize : PartLength - FFTSize
		c ++;
		Amp = 20 * log10(abs(fft(Wave(i : i + FFTSize - 1))));
		Max = max(Amp(fix(300 * FFTSize / SampleRate) : fix(1500 * FFTSize / SampleRate)));
		for j = 0 : FFTSize - 1
			VOTWave(i + j) = (LMax * (1 - j / FFTSize) + Max * j / FFTSize) * 0.01;
		end
		LMax = Max;
		MaxEnv(c) = Max;
		if(Holding == 0)
			if(Max > 0)
				Holding = 1;
				HoldStart = c;
			end
		else
			if(c > 2)
				if(Max < 0 || Max < MaxEnv(c - 2) * 0.5 || Max < MaxEnv(c - 1) * 0.6)
					Holding = 0;
#					text(c * FFTSize, VOTWave(c * FFTSize + 1), cstrcat(mat2str(c - HoldStart), " holds."));
				end
			end
			if(c - HoldStart > MaxHold)
				MaxHold = c - HoldStart;
				MaxStart = HoldStart;
			end
		end
	end
	plot(VOTWave);
	text(MaxStart * FFTSize, VOTWave(MaxStart * FFTSize + 1), "x VOT");
	hold off;
end

