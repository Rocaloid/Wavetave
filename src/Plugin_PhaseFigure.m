#{
    Title: Plugin_PhaseFigure
    
    This plugin plots out the phase spectrum of a FFTSize-size fourier
    transform at the center of the visible area.
    
    Function: Plugin_PhaseFigure
    
    Parameters:
    
        Spectrum - The decibel-magnitude spectrum to be analyzed.
        (1 Dimensional Real Array)
        
        Phase - The corresponding phase spectrum.
        (1 Dimensional Real Array)

    Input Global Variables:
        
        <FFTSize>
        
        <SampleRate>
            
        <SpectrumLowerRange>
            
        <SpectrumUpperRange>

    Output Global Variables:
    
        None.
    
    Dependency:
    
        Plugin_F0Marking_ByPhase
#}
function Plugin_PhaseFigure(Spectrum, Phase)
        global FFTSize;
        global SampleRate;

        global SpectrumLowerRange;
        global SpectrumUpperRange;

        figure(3);
        plot(Phase);
        title("Phase");
        axis([FFTSize / SampleRate * SpectrumLowerRange, FFTSize / ...
            SampleRate * SpectrumUpperRange, - pi, pi]);
        figure(1);
end

