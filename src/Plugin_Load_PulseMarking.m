function Plugin_Load_PulseMarking(Wave)
	global Environment;
	global Plugin_Var_VOT;
	global Plugin_Var_Pulses;
	global Plugin_Var_F0;
	global FFTSize;
	global SampleRate;
	global Window;

	Plugin_Var_Pulses = zeros(1, 1000);
	Environment_ = Environment;
	Environment = "Procedure";

	Plugin_VOTMarking(Wave);
	Length = length(Wave);

	CurrentPos = Plugin_Var_VOT;
	Part = Wave(CurrentPos - FFTSize / 2 + 2048 : CurrentPos + FFTSize / 2 - 1 + 2048);
	X = fft(Part .* Window);
	Plugin_F0Marking(20 * log10(abs(X)));
	Period = fix(FFTSize / Plugin_Var_F0);

	c = 1;
	_Pos = CurrentPos;
	[Y, CurrentPos] = max(Wave(CurrentPos - fix(Period / 2) : CurrentPos + fix(Period / 2)) - 1);
	CurrentPos += _Pos - fix(Period / 2);
	while (CurrentPos < Length - FFTSize)
		Part = Wave(CurrentPos - FFTSize / 2 : CurrentPos + FFTSize / 2 - 1);
		X = fft(Part .* Window);
		Plugin_F0Marking(20 * log10(abs(X)));
		Period_ = fix(FFTSize / Plugin_Var_F0);
		if(abs(Period_ - Period) < 5)
			Period = Period_;
		end
		EstimatedPos = CurrentPos + Period;

		Part = Wave(EstimatedPos - fix(Period / 2) : EstimatedPos + fix(Period / 2));
		[Y, ConvergePos] = max(abs(Part));
		ConvergePos += EstimatedPos - fix(Period / 2);
		
		CurrentPos = fix(ConvergePos * 0.7 + EstimatedPos * 0.3);
		Plugin_Var_Pulses(c) = CurrentPos;
		c ++;
	end

	Plugin_Var_Pulses = Plugin_Var_Pulses(1 : c - 1);

	Environment = Environment_;
end

