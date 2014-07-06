#{
    Title: Plugin_F0Marking_YIN
    
    Finds the fundamental frequency by YIN algorithm.
    
    Stores the fundamental frequency in global variable Plugin_Var_F0(in 
    bin-index form).
    
    Algorithm:

        YIN without parabola interpolation.
        
    Reference:
        
        De Cheveigné, Alain, and Hideki Kawahara. "YIN, a fundamental frequency
        estimator for speech and music." The Journal of the Acoustical Society
        of America 111.4 (2002): 1917-1930.
    
    Function: Plugin_F0Marking_YIN
    
    Parameters:
    
        Spectrum - The decibel-magnitude spectrum.
        (1 Dimensional Real Array)
        
        Phase - The corresponding phase spectrum.
        (1 Dimensional Real Array)
        
        Wave - The time domain signal to be analyzed.
        (1 Dimensional Real Array)

    Input Global Variables:
        
        <FFTSize>
        
        <SampleRate>
        
        <Environment>

    Output Global Variables:
    
        <Plugin_Var_F0>
#}
function Plugin_F0Marking_YIN(Spectrum, Phase, Wave)
        global FFTSize;
        global SampleRate;
        global Environment;
        
        global Plugin_Var_F0;
        
        YIN_W = 300;
        YIN_L = 1024;
        YIN_Threshold = 0.2;
        diffsum = @(t, w) sum((Wave(1:w) - Wave(t:(t + w - 1))) .^ 2);
        d = zeros(1, YIN_L);
        d2 = zeros(1, YIN_L) + 100;
        lmark = -1;
        for i = 1:YIN_L
            d(i) = diffsum(i, YIN_W);
            s = sum(d(1:i));
            d2(i) = d(i) * i / s;
            if(d2(i) < YIN_Threshold)
                if(lmark < 0)
                    lmark = i * 2;
                end
            end
            if(i == lmark)
                break;
            end
        end
        if(lmark < 0)
            lmark = YIN_L;
        end
        [y, p] = min(d2(1:lmark));
        F0 = min(1024, fix(FFTSize / p));
        
        Plugin_Var_F0 = F0;

        #Labels out when called from the Visualizer.
        if(strcmp(Environment, "Visual"))
                text(F0, 0, cstrcat("x ",
                     mat2str(fix(F0 * SampleRate / FFTSize)), "Hz"));
        end
end

