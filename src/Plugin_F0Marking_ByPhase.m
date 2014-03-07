#{
    Title: Plugin_F0Marking_ByPhase
    
    A very precise fundamental frequency detector based on phase difference
    measurement.
    
    Algorithm:
    (start code)
    We treat each bin in frequency domain as a sinusoid as
         y_n(x) = cos(2 * pi * f_n * t(x))
                = cos(2 * pi * n * SampleRate / FFTSize * x / SampleRate)
                = cos(2 * pi * n * x / FFTSize)
        Where n is the bin index, x is the sample index in time domain.
    And we know in the fftshifted phase spectrum,
         phi(x, n) = 2 * pi * n * x / FFTSize
    So the difference between two phase spectrum centered at two successive
       samples is:
         dphi(x, n) = phi(x + 1, n) - phi(x, n)
                    = 2 * pi * n * (x + 1 - x) / FFTSize
                    = 2 * pi * n / FFTSize
    Rearrange the formula, we derive n from dphi:
         n = dphi(x, n) * FFTSize / pi / 2
    To get the frequency in herz,
         f = n * SampleRate / FFTSize
           = dphi(x, n) * SampleRate / pi / 2
    Theoretically the result will be perfectly accurate and precise.
    The actual performance is limited by noise, windowing and discretization.
    (end)
    
    Function: Plugin_F0Marking_ByPhase
    
    Parameters:
    
        Spectrum - The decibel-magnitude spectrum to be analyzed.
        (1 Dimensional Real Array)
        
        Phase - The corresponding phase spectrum.
        (1 Dimensional Real Array)
        
        Wave - The corresponding time-domain singal.
        (1 Dimensional Real Array)
        
        ExtWave - The extended wave. 128 samples longer than Wave.
        (1 Dimensional Real Array)
        
        InnerProcess - Whether call <Plugin_F0Marking> or not inside the
        function.
        0: <Plugin_F0Marking> is called manually.
        1: <Plugin_F0Marking> is called inside this function.

    Input Global Variables:
        
        <FFTSize>
        
        <SampleRate>
        
        <Environment>
    
        <Plugin_Var_F0>

    Output Global Variables:
    
        <Plugin_Var_F0_Exact>
    
    Dependency:
    
        Plugin_F0Marking
#}
function Plugin_F0Marking_ByPhase(Spectrum, Phase, Wave, ExtWave, ...
    InnerProcess = 1)
        global FFTSize;
        global Window;
        global SampleRate;
        global Environment;
        global Plugin_Var_F0;
        #{
            Section: Globals
        
            Variable: Plugin_Var_F0_Exact
            
                A very precise estimation of fundamental frequency(Hertz).
                
                (Real Scalar)
        #}
        global Plugin_Var_F0_Exact;

        #Difference from insuccessive phase spectrum is allowed.
        HopSize = 1;

        #Disable redraw.
        Environment_ = Environment;
        Environment = "Procedure";

        #Find approximated frequency.
        if(InnerProcess)
                Plugin_F0Marking(Spectrum, Phase, Wave);
        end
        #If the approximation is valid.
        if(Plugin_Var_F0 > 1)
                ThisPhase = Phase(Plugin_Var_F0);

                #Find the next phase spectrum.
                X = fft(fftshift(ExtWave(HopSize + 1 : HopSize + FFTSize) .* Window));
                NextArg = arg(X);
                NextPhase = NextArg(Plugin_Var_F0);
                if(NextPhase < ThisPhase)
                        NextPhase += 2 * pi;
                end
                #Differentiate and get the fundamental frequency.
                Delta = NextPhase - ThisPhase;
                Plugin_Var_F0_Exact = Delta / 2 / pi * SampleRate / HopSize;

                #Labels out.
                if(strcmp(Environment_, "Visual"))
                        text(Plugin_Var_F0, Spectrum(Plugin_Var_F0),
                             cstrcat("x ", mat2str(Plugin_Var_F0_Exact), "Hz"));
                end
        end
        Environment = Environment_;
end

