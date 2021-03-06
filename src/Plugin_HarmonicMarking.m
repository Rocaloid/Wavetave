#{
    Title: Plugin_HarmonicMarking
    
    Finds the positions of harmonic peaks within the visible spectrum area and
    marks them out.
    
    Algorithm:
    (start code)
    For the first few harmonics, it looks for peaks around the integer
      multiples of fundamental frequency.
    For higher harmonics, it looks for peaks as correcting the fundamental
      frequency simutaneously.
    (end)
    
    Function: Plugin_HarmonicMarking
    
    Parameters:
    
        Spectrum - The decibel-magnitude spectrum to be analyzed.
        (1 Dimensional Real Array)
        
        Phase - The corresponding phase spectrum.
        (1 Dimensional Real Array)
        
        Wave - The corresponding time-domain singal.
        (1 Dimensional Real Array)

    Input Global Variables:
        
        <FFTSize>
        
        <SampleRate>
        
        <SpectrumUpperRange>
    
        <Plugin_Var_F0>

    Output Global Variables:
    
        <Plugin_Var_F0>
    
    Dependency:
    
        Plugin_F0Marking
#}
function Plugin_HarmonicMarking(Spectrum, Phase, Wave)
        global FFTSize;
        global SampleRate;
        global Plugin_Var_F0;
        global SpectrumUpperRange;
        SpectrumUpperBin = SpectrumUpperRange * FFTSize / SampleRate;

	#If data is valid
	if(Plugin_Var_F0 > 5)
	        #The searching range
        	Width = fix(Plugin_Var_F0 / 4);
        	for i = 2 : fix(SpectrumUpperBin / Plugin_Var_F0)
        	        #Approximated harmonic frequency
        	        ThisBin = fix(i * Plugin_Var_F0);
        	        [MaxY, MaxX] = max(Spectrum(ThisBin - Width : ThisBin + Width));
        	        MaxX += ThisBin - Width - 1;
        	        text(MaxX, MaxY + 5, strcat("H", mat2str(i - 1)));
        	        text(MaxX, MaxY, cstrcat("x ", mat2str(fix(MaxX * SampleRate / FFTSize)), "Hz"));
        	        #Fundamental frequency correction
        	        if(i < 6)
        	                Plugin_Var_F0 = MaxX / i;
        	        end
        	end
        	#Convert Plugin_Var_F0 to an integer to avoid subscript error in other
        	#  plugins.
        	Plugin_Var_F0 = fix(Plugin_Var_F0);
	end
end

